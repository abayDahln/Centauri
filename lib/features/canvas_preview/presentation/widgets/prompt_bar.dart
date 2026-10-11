import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/theme.dart';
import '../../../prompt_editor/domain/prompt_templates.dart';
import '../../domain/viewport_mode.dart';
import '../provider/canvas_provider.dart';

/// Bar prompt mengambang di bawah board (gaya Stitch):
/// input besar membulat, chip design token, dan tombol kirim.
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

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await ref
        .read(canvasProvider.notifier)
        .submitPrompt(
          text,
          designToken: ref.read(canvasProvider).selectedToken,
          viewport: ref.read(canvasProvider).viewport,
        );
  }

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
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: AppRadius.xl,
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: AppColors.shadowRaised,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Baris kontrol: viewport (checkbox) + design token.
                  Row(
                    children: [
                      _ViewportSelector(
                        selected: state.viewport,
                        onChanged: (mode) =>
                            ref.read(canvasProvider.notifier).setViewport(mode),
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
                                    .setSelectedToken(selected ? null : preset),
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
                            return KeyEventResult.ignored;
                          },
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            enabled: !state.isGenerating,
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
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
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
        );
      },
    );
  }
}

/// Pemilih viewport sebagai toggle kecil (checkbox) di dalam prompt bar.
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
            message: '${mode.label} - ${mode.widthLabel}',
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
