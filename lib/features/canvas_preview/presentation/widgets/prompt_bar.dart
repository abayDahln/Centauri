import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_clipboard/super_clipboard.dart';

import '../../../../app/config/app_palette.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/l10n/error_messages.dart';
import '../../../../app/l10n/l10n.dart';
import '../../../history/presentation/history_provider.dart';
import '../../../prompt_editor/data/attachment_service.dart';
import '../../../prompt_editor/domain/attachment.dart';
import '../../domain/page.dart';
import '../../domain/prompt_mention.dart';
import '../provider/workspace_provider.dart';
import 'attachment_strip.dart';
import 'chat_side_panel.dart';

/// Bar prompt mengambang di bawah board (gaya Stitch):
/// input besar membulat, lampiran gambar, dan tombol kirim.
/// Gaya desain ditulis langsung di prompt oleh user, atau direkomendasikan AI.
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
    final hasAttachments = ref.read(workspaceProvider).attachments.isNotEmpty;
    if (text.isEmpty && !hasAttachments) return;
    _controller.clear();
    // Pastikan user melihat percakapan: buka panel & pindah ke tab Chat.
    ref.read(panelTabProvider.notifier).select(PanelTab.chat);
    ref.read(panelVisibleProvider.notifier).show();
    await ref
        .read(workspaceProvider.notifier)
        .submitPrompt(text.isEmpty ? context.l10n.promptAnalyzeImage : text);
    // Auto-save percakapan + board ke riwayat.
    ref.read(historyProvider.notifier).persistCurrent();
  }

  /// Hentikan generate yang sedang berjalan (tombol Stop).
  void _stop() => ref.read(workspaceProvider.notifier).cancelGeneration();

  // ------------------------------------------------------- attachment adds --

  void _addAttachment(Attachment attachment) {
    final error = ref
        .read(workspaceProvider.notifier)
        .addAttachment(attachment);
    if (error != null) _toast(error);
  }

  void _addFromBytes(String name, Uint8List bytes) {
    try {
      _addAttachment(_attachmentService.fromBytes(name, bytes));
    } on AttachmentException catch (e) {
      _toast(localizedAppError(context.l10n, e));
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
    // Teks diambil sebelum `await` di dalam loop (celah async).
    final l10n = context.l10n;
    for (final file in details.files) {
      if (!AttachmentFormats.isSupported(file.name)) {
        _toast(l10n.promptUnsupportedFormat(file.name));
        continue;
      }
      try {
        final bytes = await file.readAsBytes();
        _addFromBytes(file.name, bytes);
      } catch (_) {
        _toast(l10n.promptReadFailed(file.name));
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
    final state = ref.watch(workspaceProvider);

    // Mention elemen dari menu kanvas: fokuskan input agar user bisa
    // langsung menulis instruksinya.
    ref.listen<List<PromptMention>>(
      workspaceProvider.select((s) => s.mentions),
      (previous, next) {
        final hadElement = previous?.any((m) => m.isElement) ?? false;
        if (!hadElement && next.any((m) => m.isElement)) {
          _focusNode.requestFocus();
        }
      },
    );

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
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: context.palette.bgSurface,
                  borderRadius: AppRadius.md,
                  border: Border.all(
                    color: _dragging
                        ? context.palette.primary
                        : context.palette.borderSubtle,
                    width: _dragging ? 1.4 : 1,
                  ),
                  boxShadow: context.palette.shadowSoft,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state.mentions.isNotEmpty) ...[
                      _MentionStrip(
                        mentions: state.mentions,
                        onRemove: (mention) => ref
                            .read(workspaceProvider.notifier)
                            .removeMention(mention),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (state.attachments.isNotEmpty) ...[
                      AttachmentStrip(
                        attachments: state.attachments,
                        onRemove: (id) => ref
                            .read(workspaceProvider.notifier)
                            .removeAttachment(id),
                      ),
                      const SizedBox(height: 8),
                    ],
                    // Baris input: lampiran, field teks, tombol kirim.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _MentionButton(
                          pages: state.pages,
                          onPage: (page) => ref
                              .read(workspaceProvider.notifier)
                              .addPageMention(page),
                          onAllPages: () => ref
                              .read(workspaceProvider.notifier)
                              .addAllPagesMention(),
                        ),
                        _AttachButton(onPressed: _pickFiles),
                        const SizedBox(width: 4),
                        Expanded(
                          // Samakan tinggi baris dengan tombol 40px agar teks
                          // selalu di tengah vertikal (single-line). Saat
                          // multiline, kontainer ikut tumbuh ke atas.
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 36),
                            alignment: AlignmentDirectional.centerStart,
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
                                    HardwareKeyboard
                                        .instance
                                        .isControlPressed) {
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
                                style: TextStyle(
                                  fontFamily: AppFonts.uiFamily,
                                  fontFamilyFallback: AppFonts.uiFallback,
                                  fontSize: 14,
                                  color: context.palette.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  hintText: context.l10n.promptPlaceholder,
                                  hintStyle: TextStyle(
                                    fontFamily: AppFonts.uiFamily,
                                    fontFamilyFallback: AppFonts.uiFallback,
                                    fontSize: 14,
                                    color: context.palette.textDisabled,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _SendButton(
                          busy: state.isGenerating,
                          onPressed: state.isGenerating ? _stop : _send,
                          onStop: _stop,
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
      message: context.l10n.promptAttachTooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.sm,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(
            Icons.add_photo_alternate_outlined,
            size: 18,
            color: context.palette.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.busy,
    required this.onPressed,
    required this.onStop,
  });

  final bool busy;
  final VoidCallback? onPressed;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    // Saat generating, tombol berubah menjadi Stop (kotak) agar jelas bisa
    // dibatalkan — bukan spinner mati yang membingungkan.
    if (busy) {
      return Tooltip(
        message: context.l10n.promptStopTooltip,
        child: SizedBox(
          width: 36,
          height: 36,
          child: FilledButton(
            onPressed: onStop,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
              backgroundColor: context.palette.statusError,
            ),
            child: const Icon(Icons.stop_rounded, size: 18),
          ),
        ),
      );
    }

    return SizedBox(
      width: 36,
      height: 36,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
          backgroundColor: context.palette.primary,
        ),
        child: const Icon(Icons.arrow_upward, size: 18),
      ),
    );
  }
}

/// Deretan chip mention (elemen / halaman) di atas field prompt.
class _MentionStrip extends StatelessWidget {
  const _MentionStrip({required this.mentions, required this.onRemove});

  final List<PromptMention> mentions;
  final ValueChanged<PromptMention> onRemove;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final mention in mentions)
            _MentionChip(mention: mention, onRemove: () => onRemove(mention)),
        ],
      ),
    );
  }
}

class _MentionChip extends StatelessWidget {
  const _MentionChip({required this.mention, required this.onRemove});

  final PromptMention mention;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final icon = switch (mention.kind) {
      PromptMentionKind.element => Icons.ads_click,
      PromptMentionKind.page => Icons.web_asset_outlined,
      PromptMentionKind.allPages => Icons.layers_outlined,
    };
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsetsDirectional.only(start: 9, end: 2),
      decoration: BoxDecoration(
        color: context.palette.primarySoft,
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: context.palette.primary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              mention.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.uiFamily,
                fontFamilyFallback: AppFonts.uiFallback,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: context.palette.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: onRemove,
            borderRadius: AppRadius.pill,
            child: Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.close,
                size: 12,
                color: context.palette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tombol untuk menyebut satu halaman atau semua halaman.
class _MentionButton extends StatelessWidget {
  const _MentionButton({
    required this.pages,
    required this.onPage,
    required this.onAllPages,
  });

  static const String _allPagesValue = '__all_pages__';

  final List<AppPage> pages;
  final ValueChanged<AppPage> onPage;
  final VoidCallback onAllPages;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.l10n.promptMentionPagesTooltip,
      child: PopupMenuButton<String>(
        tooltip: '',
        enabled: pages.isNotEmpty,
        padding: EdgeInsets.zero,
        onSelected: (value) {
          if (value == _allPagesValue) {
            onAllPages();
            return;
          }
          for (final page in pages) {
            if (page.id == value) {
              onPage(page);
              return;
            }
          }
        },
        itemBuilder: (context) => [
          for (final page in pages)
            PopupMenuItem<String>(
              value: page.id,
              height: 36,
              child: Text(
                page.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.uiSmall,
              ),
            ),
          if (pages.length > 1) ...[
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: _allPagesValue,
              height: 36,
              child: Text(
                context.l10n.commonAllPages,
                style: context.text.uiSmall,
              ),
            ),
          ],
        ],
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(
            Icons.alternate_email,
            size: 18,
            color: pages.isEmpty
                ? context.palette.textDisabled
                : context.palette.textSecondary,
          ),
        ),
      ),
    );
  }
}
