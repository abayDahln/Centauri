import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_palette.dart';
import '../config/theme.dart';
import '../config/theme_provider.dart';
import '../l10n/l10n.dart';
import 'app_dialog.dart';
import 'stitch_widgets.dart';

/// Tombol pemilih tampilan (ikon palette) untuk top bar / app bar.
class AppearanceMenuButton extends StatelessWidget {
  const AppearanceMenuButton({super.key, this.size = 36, this.iconSize = 18});

  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return SoftIconButton(
      icon: Icons.palette_outlined,
      tooltip: context.l10n.appearanceTooltip,
      size: size,
      iconSize: iconSize,
      onPressed: () => showAppearanceDialog(context),
    );
  }
}

/// Buka dialog pilih mode tampilan dan warna aksen.
Future<void> showAppearanceDialog(BuildContext context) {
  return showAppDialog<void>(
    context: context,
    builder: (_) => const AppearanceDialog(),
  );
}

/// Mode tema dan warna utama. Setiap perubahan langsung dipakai — dialog tidak
/// perlu tombol simpan.
class AppearanceDialog extends ConsumerWidget {
  const AppearanceDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selection = ref.watch(appThemeProvider);
    final notifier = ref.read(appThemeProvider.notifier);

    return Dialog(
      backgroundColor: context.palette.bgElevated,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.xl,
        side: BorderSide(color: context.palette.borderSubtle),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Text(l10n.appearanceTitle, style: context.text.panelTitle),
            ),
            Divider(height: 1, color: context.palette.borderSubtle),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.appearanceModeLabel,
                    style: context.text.sectionTitle,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SoftSegmented<AppThemeMode>(
                      selected: selection.mode,
                      onChanged: notifier.selectMode,
                      height: 34,
                      segments: [
                        SoftSegment(
                          value: AppThemeMode.system,
                          label: l10n.appearanceModeSystem,
                        ),
                        SoftSegment(
                          value: AppThemeMode.light,
                          label: l10n.appearanceModeLight,
                        ),
                        SoftSegment(
                          value: AppThemeMode.dark,
                          label: l10n.appearanceModeDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.appearancePrimaryLabel,
                    style: context.text.sectionTitle,
                  ),
                  const SizedBox(height: 10),
                  _SwatchRow(
                    selected: selection.primary,
                    onSelect: notifier.selectPrimary,
                  ),
                  const SizedBox(height: 20),
                  const _Preview(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: notifier.reset,
                    child: Text(l10n.appearanceReset),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.commonDone),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Deretan preset warna. Nama warna dipakai sebagai label aksesibilitas dan
/// tooltip, bukan teks yang tampil di layar.
class _SwatchRow extends StatelessWidget {
  const _SwatchRow({required this.selected, required this.onSelect});

  final AppAccentPreset selected;
  final ValueChanged<AppAccentPreset> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final preset in AppAccentPreset.values)
          _Swatch(
            label: _presetLabel(l10n, preset),
            color: _swatchColor(context, preset),
            selected: preset == selected,
            onTap: () => onSelect(preset),
          ),
      ],
    );
  }
}

class _Swatch extends StatefulWidget {
  const _Swatch({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_Swatch> createState() => _SwatchState();
}

class _SwatchState extends State<_Swatch> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final border = widget.selected
        ? palette.textPrimary
        : _hovered
        ? palette.borderStrong
        : palette.borderSubtle;

    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: Tooltip(
        message: widget.label,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: border,
                  width: widget.selected ? 2 : 1,
                ),
              ),
              child: widget.selected
                  ? Icon(Icons.check, size: 16, color: onAccent(widget.color))
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Pratinjau kecil: kanvas, panel, dan tombol memakai warna yang sedang aktif,
/// sehingga pengguna melihat hasilnya sebelum menutup dialog.
class _Preview extends StatelessWidget {
  const _Preview();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.bgBase,
        borderRadius: AppRadius.md,
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 74,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.primary,
              borderRadius: AppRadius.sm,
            ),
            child: Text(
              'Aa',
              style: context.text.label.copyWith(color: palette.onPrimary),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 74,
            height: 26,
            decoration: BoxDecoration(
              color: palette.bgSurface,
              borderRadius: AppRadius.sm,
              border: Border.all(color: palette.borderSubtle),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: palette.primary,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Warna swatch mengikuti mode aktif supaya yang dilihat = yang dipakai.
Color _swatchColor(BuildContext context, AppAccentPreset preset) =>
    Theme.of(context).brightness == Brightness.dark
    ? liftForDark(preset.seedColor)
    : preset.seedColor;

String _presetLabel(AppLocalizations l10n, AppAccentPreset preset) =>
    switch (preset) {
      AppAccentPreset.blue => l10n.colorBlue,
      AppAccentPreset.indigo => l10n.colorIndigo,
      AppAccentPreset.violet => l10n.colorViolet,
      AppAccentPreset.teal => l10n.colorTeal,
      AppAccentPreset.green => l10n.colorGreen,
      AppAccentPreset.amber => l10n.colorAmber,
      AppAccentPreset.rose => l10n.colorRose,
      AppAccentPreset.slate => l10n.colorSlate,
    };
