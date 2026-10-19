import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes.dart';
import 'config/theme.dart';
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

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      locale: language.locale,
      supportedLocales: AppLanguage.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) {
        if (!AppTitleBar.isSupported || child == null) {
          return child ?? const SizedBox.shrink();
        }
        return Scaffold(
          backgroundColor: AppColors.bgBase,
          body: Column(
            children: [
              const AppTitleBar(),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}
