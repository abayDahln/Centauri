import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_palette.dart';
import '../config/theme.dart';
import '../l10n/app_language.dart';
import '../l10n/l10n.dart';
import '../l10n/locale_provider.dart';
import 'app_dialog.dart';
import 'stitch_widgets.dart';

/// Tombol pemilih bahasa UI (ikon globe) untuk top bar / app bar.
class LanguageMenuButton extends ConsumerWidget {
  const LanguageMenuButton({super.key, this.size = 36, this.iconSize = 18});

  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SoftIconButton(
      icon: Icons.language,
      tooltip: context.l10n.languageTooltip,
      size: size,
      iconSize: iconSize,
      onPressed: () => showLanguageDialog(context),
    );
  }
}

/// Buka dialog pilih bahasa UI.
Future<void> showLanguageDialog(BuildContext context) {
  return showAppDialog<void>(
    context: context,
    builder: (_) => const LanguageDialog(),
  );
}

/// Daftar bahasa. Nama ditulis dalam bahasa aslinya supaya pengguna yang tidak
/// mengerti bahasa aktif tetap menemukan bahasanya.
class LanguageDialog extends ConsumerWidget {
  const LanguageDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = ref.watch(appLanguageProvider);
    final available = _availableLanguages();

    return Dialog(
      backgroundColor: context.palette.bgElevated,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.xl,
        side: BorderSide(color: context.palette.borderSubtle),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Text(
                l10n.languageDialogTitle,
                style: context.text.panelTitle,
              ),
            ),
            Divider(height: 1, color: context.palette.borderSubtle),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: available.length,
                itemBuilder: (context, index) {
                  final language = available[index];
                  return _LanguageRow(
                    language: language,
                    selected: language.code == current.code,
                    onTap: () {
                      ref.read(appLanguageProvider.notifier).select(language);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Hanya tampilkan bahasa yang file ARB-nya sudah ada. Bahasa tanpa
  /// terjemahan hanya akan menampilkan Inggris, jadi lebih baik disembunyikan.
  static List<AppLanguage> _availableLanguages() {
    final generated = AppLocalizations.supportedLocales
        .map((locale) => locale.languageCode)
        .toSet();
    return AppLanguage.all
        .where((language) => generated.contains(language.code))
        .toList(growable: false);
  }
}

class _LanguageRow extends StatefulWidget {
  const _LanguageRow({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_LanguageRow> createState() => _LanguageRowState();
}

class _LanguageRowState extends State<_LanguageRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: selected
              ? context.palette.selectionBg
              : _hovered
              ? context.palette.hoverBg
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.language.nativeName,
                      style: context.text.ui.copyWith(
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selected
                            ? context.palette.primary
                            : context.palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      widget.language.englishName,
                      style: context.text.caption,
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check, size: 16, color: context.palette.primary),
            ],
          ),
        ),
      ),
    );
  }
}
