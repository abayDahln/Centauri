import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_clipboard/super_clipboard.dart';

import '../../../../app/config/theme.dart';
import '../../../history/presentation/history_provider.dart';
import '../../../prompt_editor/data/attachment_service.dart';
import '../../../prompt_editor/domain/attachment.dart';
import '../../../prompt_editor/domain/prompt_templates.dart';
import '../../domain/viewport_mode.dart';
import '../provider/canvas_provider.dart';
import 'attachment_strip.dart';

/// Bar prompt mengambang di bawah board (gaya Stitch):
/// input besar membulat, chip design token, dan tombol kirim.
/// Mendukung lampiran gambar via tombol, drag & drop, atau paste (Ctrl+V).
class PromptBar extends ConsumerStatefulWidget {
  const PromptBar({super.key});

  /// Lebar minimum kartu prompt.
  static const double minWidth = 420;

  /// Lebar maksimum kartu prompt (agar tidak membentang penuh saat fullscreen).
  static const double maxWidth = 760;

  @override
  ConsumerState<PromptBar> createState() => _PromptBarState();
}

class _PromptBarState extends ConsumerState<PromptBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _attachmentService = const AttachmentService();
  bool _dragging = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final hasAttachments = ref.read(canvasProvider).attachments.isNotEmpty;
    if (text.isEmpty && !hasAttachments) return;
    _controller.clear();
    await ref
        .read(canvasProvider.notifier)
        .submitPrompt(
          text.isEmpty ? 'Analisa gambar ini.' : text,
          designToken: ref.read(canvasProvider).selectedToken,
          viewport: ref.read(canvasProvider).viewport,
        );
    // Auto-save percakapan + board ke riwayat.
    ref.read(historyProvider.notifier).persistCurrent();
  }

  // ------------------------------------------------------- attachment adds --

  void _addAttachment(Attachment attachment) {
    final error = ref.read(canvasProvider.notifier).addAttachment(attachment);
    if (error != null) _toast(error);
  }

  void _addFromBytes(String name, Uint8List bytes) {
    try {
      _addAttachment(_attachmentService.fromBytes(name, bytes));
    } on AttachmentException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: AttachmentFormats.allExtensions.toList(),
    );
    if (result == null) return;
    for (final file in result.files) {
      final bytes = file.bytes;
      if (bytes == null) continue;
      _addFromBytes(file.name, bytes);
    }
  }

  Future<void> _onDrop(DropDoneDetails details) async {
    setState(() => _dragging = false);
    for (final file in details.files) {
      if (!AttachmentFormats.isSupported(file.name)) {
        _toast('Format "${file.name}" tidak didukung.');
        continue;
      }
      try {
        final bytes = await file.readAsBytes();
        _addFromBytes(file.name, bytes);
      } catch (_) {
        _toast('Gagal membaca "${file.name}".');
      }
    }
  }

  /// Tempel gambar dari clipboard (Ctrl+V).
  Future<void> _pasteFromClipboard() async {
    try {
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) return;
      final reader = await clipboard.read();
      if (reader.canProvide(Formats.png)) {
        final bytes = await _readAll(reader, Formats.png);
        if (bytes != null && bytes.isNotEmpty) {
          _addFromBytes('pasted.png', bytes);
          return;
        }
      }
      if (reader.canProvide(Formats.jpeg)) {
        final bytes = await _readAll(reader, Formats.jpeg);
        if (bytes != null && bytes.isNotEmpty) {
          _addFromBytes('pasted.jpg', bytes);
          return;
        }
      }
      // Jika clipboard berisi teks biasa, biarkan field menanganinya.
    } catch (_) {
      // Abaikan kegagalan clipboard (mis. platform tak mendukung).
    }
  }

  Future<Uint8List?> _readAll(ClipboardReader reader, FileFormat format) async {
    final completer = Completer<Uint8List?>();
    reader.getFile(format, (file) async {
      try {
        final bytes = await file.readAll();
        if (!completer.isCompleted) completer.complete(bytes);
      } catch (_) {
        if (!completer.isCompleted) completer.complete(null);
      }
    });
    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => null,
    );
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------------------------------------------------------------- build --

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(canvasProvider);
    final selectedTokenId = state.selectedToken?.id;

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final minWidth = available < PromptBar.minWidth
            ? available
            : PromptBar.minWidth;
        final maxWidth = available < PromptBar.maxWidth
            ? available
            : PromptBar.maxWidth;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: minWidth, maxWidth: maxWidth),
            child: DropTarget(
              onDragEntered: (_) => setState(() => _dragging = true),
              onDragExited: (_) => setState(() => _dragging = false),
              onDragDone: _onDrop,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: AppRadius.xl,
                  border: Border.all(
                    color: _dragging
                        ? AppColors.accentPrimary
                        : AppColors.borderSubtle,
                    width: _dragging ? 1.6 : 1,
                  ),
                  boxShadow: AppColors.shadowRaised,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.attachments.isNotEmpty) ...[
                      AttachmentStrip(
                        attachments: state.attachments,
                        onRemove: (id) => ref
                            .read(canvasProvider.notifier)
                            .removeAttachment(id),
                      ),
                      const SizedBox(height: 8),
                    ],
                    // Baris kontrol: viewport (checkbox) + design token.
                    Row(
                      children: [
                        _ViewportSelector(
                          selected: state.viewport,
                          onChanged: (mode) => ref
                              .read(canvasProvider.notifier)
                              .setViewport(mode),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 1,
                          height: 18,
                          color: AppColors.borderSubtle,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 26,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: designTokenPresets.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 6),
                              itemBuilder: (context, index) {
                                final preset = designTokenPresets[index];
                                final selected = preset.id == selectedTokenId;
                                return _TokenChip(
                                  label: preset.label,
                                  selected: selected,
                                  onTap: () => ref
                                      .read(canvasProvider.notifier)
                                      .setSelectedToken(
                                        selected ? null : preset,
                                      ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _AttachButton(onPressed: _pickFiles),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Focus(
                            onKeyEvent: (node, event) {
                              // Enter = kirim, Shift+Enter = baris baru.
                              if (event is KeyDownEvent &&
                                  event.logicalKey ==
                                      LogicalKeyboardKey.enter &&
                                  !HardwareKeyboard.instance.isShiftPressed) {
                                if (!state.isGenerating) _send();
                                return KeyEventResult.handled;
                              }
                              // Ctrl+V: tempel gambar dari clipboard.
                              if (event is KeyDownEvent &&
                                  event.logicalKey ==
                                      LogicalKeyboardKey.keyV &&
                                  HardwareKeyboard.instance.isControlPressed) {
                                _pasteFromClipboard();
                              }
                              return KeyEventResult.ignored;
                            },
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              minLines: 1,
                              maxLines: 4,
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              style: const TextStyle(
                                fontFamily: AppFonts.uiFamily,
                                fontFamilyFallback: AppFonts.uiFallback,
                                fontSize: 13.5,
                                color: AppColors.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                hintText:
                                    'What would you like to change or create?',
                                hintStyle: TextStyle(
                                  fontFamily: AppFonts.uiFamily,
                                  fontFamilyFallback: AppFonts.uiFallback,
                                  fontSize: 13.5,
                                  color: AppColors.textDisabled,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _SendButton(
                          busy: state.isGenerating,
                          onPressed: state.isGenerating ? null : _send,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Tombol lampirkan berkas.
class _AttachButton extends StatelessWidget {
  const _AttachButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Lampirkan gambar / file (${AttachmentFormats.acceptLabel})',
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.pill,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: const Icon(
            Icons.add_photo_alternate_outlined,
            size: 20,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Pemilih viewport sebagai toggle kecil di dalam prompt bar.
/// Murni hint untuk generate BERIKUTNYA — tidak mengubah frame yang sudah ada.
/// Bila user menyebut viewport eksplisit di teks prompt ("...viewport: desktop"),
/// teks tersebut menang atas tombol ini.
class _ViewportSelector extends StatelessWidget {
  const _ViewportSelector({required this.selected, required this.onChanged});

  final ViewportMode selected;
  final ValueChanged<ViewportMode> onChanged;

  static const _icons = {
    ViewportMode.mobile: Icons.smartphone_outlined,
    ViewportMode.tablet: Icons.tablet_mac_outlined,
    ViewportMode.desktop: Icons.desktop_windows_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.bgSunken,
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ViewportMode.values.map((mode) {
          final active = mode == selected;
          return Tooltip(
            message: '${mode.label} - ${mode.widthLabel} (target generate)',
            child: GestureDetector(
              onTap: () => onChanged(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: active ? AppColors.bgSurface : Colors.transparent,
                  borderRadius: AppRadius.pill,
                  boxShadow: active ? AppColors.shadowSoft : null,
                ),
                child: Icon(
                  _icons[mode],
                  size: 15,
                  color: active
                      ? AppColors.accentPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TokenChip extends StatelessWidget {
  const _TokenChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.bgSunken,
          borderRadius: AppRadius.pill,
          border: Border.all(
            color: selected ? AppColors.accentPrimary : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.uiFamily,
            fontFamilyFallback: AppFonts.uiFallback,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.accentPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          backgroundColor: AppColors.accentPrimary,
        ),
        child: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.arrow_upward, size: 18),
      ),
    );
  }
}
