import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'config/app_palette.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'config/theme_provider.dart';
import 'l10n/app_language.dart';
import 'l10n/l10n.dart';
import 'l10n/locale_provider.dart';
import 'widgets/app_title_bar.dart';

class CentauriApp extends ConsumerWidget {
  const CentauriApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Bahasa UI dipilih pengguna (default Inggris) dan disimpan di Hive.
    // Percakapan dengan AI tidak memakai nilai ini — Alpha mengikuti bahasa
    // pesan yang dikirim pengguna.
    final language = ref.watch(appLanguageProvider);
    // Tampilan aplikasi (mode terang/gelap + warna aksen). Hanya chrome
    // aplikasi yang berubah; prototype HTML di canvas tidak terpengaruh.
    final appearance = ref.watch(appThemeProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(appearance.lightPalette),
      darkTheme: AppTheme.dark(appearance.darkPalette),
      themeMode: appearance.flutterMode,
      routerConfig: appRouter,
      locale: language.locale,
      supportedLocales: AppLanguage.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) {
        if (!AppTitleBar.isSupported || child == null) {
          return child ?? const SizedBox.shrink();
        }
        // Warna dasar jendela ikut tema supaya tidak ada kedipan terang saat
        // resize di mode gelap (jendela desktop frameless).
        return _WindowBackgroundSync(
          color: context.palette.bgBase,
          child: Scaffold(
            backgroundColor: context.palette.bgBase,
            body: Column(
              children: [
                const AppTitleBar(),
                Expanded(child: child),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Menyamakan latar jendela native dengan palet aktif.
class _WindowBackgroundSync extends StatefulWidget {
  const _WindowBackgroundSync({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  State<_WindowBackgroundSync> createState() => _WindowBackgroundSyncState();
}

class _WindowBackgroundSyncState extends State<_WindowBackgroundSync> {
  @override
  void initState() {
    super.initState();
    _apply();
  }

  @override
  void didUpdateWidget(covariant _WindowBackgroundSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color) _apply();
  }

  Future<void> _apply() async {
    if (!AppTitleBar.isSupported) return;
    try {
      await windowManager.setBackgroundColor(widget.color);
    } catch (_) {
      // Tidak fatal: hanya mencegah kedipan saat resize.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
