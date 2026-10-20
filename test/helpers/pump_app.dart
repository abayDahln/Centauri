import 'package:centauri/app/config/app_palette.dart';
import 'package:centauri/app/config/theme.dart';
import 'package:centauri/app/config/theme_provider.dart';
import 'package:centauri/app/l10n/app_language.dart';
import 'package:centauri/app/l10n/locale_provider.dart';
import 'package:centauri/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// Bahasa default di test: Indonesia. Seluruh ekspektasi teks Indonesia yang
/// sudah ada tetap valid tanpa ditulis ulang; teks Inggris diuji terpisah.
const Locale testLocaleId = Locale('id');
const Locale testLocaleEn = Locale('en');

/// `MaterialApp` yang sudah punya delegasi lokalisasi.
///
/// Dipakai menggantikan `MaterialApp(...)` polos di test — tanpa delegate,
/// `AppLocalizations.of(context)` (non-nullable) akan melempar.
///
/// [localeFromProvider] dipakai test pemilih bahasa: locale mengikuti
/// `appLanguageProvider` persis seperti `CentauriApp`, bukan dipatok.
///
/// [themeFromProvider] dipakai test pemilih tampilan: tema mengikuti
/// `appThemeProvider` (mode + warna aksen) persis seperti `CentauriApp`.
/// [palette] memasang satu palet tetap tanpa provider.
Widget testApp({
  required Widget home,
  Locale locale = testLocaleId,
  ThemeData? theme,
  AppPalette? palette,
  Brightness brightness = Brightness.light,
  List<Override> overrides = const [],
  bool localeFromProvider = false,
  bool themeFromProvider = false,
}) {
  return ProviderScope(
    overrides: overrides,
    child: Consumer(
      builder: (context, ref, _) {
        final resolvedLocale = localeFromProvider
            ? ref.watch(appLanguageProvider).locale
            : locale;
        final resolvedTheme = themeFromProvider
            ? _themeFromSelection(ref.watch(appThemeProvider))
            : theme ??
                  (palette == null
                      ? null
                      : AppTheme.build(
                          palette: palette,
                          brightness: brightness,
                        ));

        return MaterialApp(
          locale: resolvedLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLanguage.supportedLocales,
          theme: resolvedTheme,
          home: home,
        );
      },
    ),
  );
}

/// Mode `system` di test memakai terang (platform brightness default test).
ThemeData _themeFromSelection(AppThemeSelection selection) {
  final dark = selection.mode == AppThemeMode.dark;
  return dark
      ? AppTheme.dark(selection.darkPalette)
      : AppTheme.light(selection.lightPalette);
}

/// Paksa bahasa UI tanpa menyentuh Hive (box tidak terbuka di test).
///
/// Default Indonesia karena ekspektasi teks di test memakai teks Indonesia.
List<Override> languageOverride([
  AppLanguage language = AppLanguage.indonesian,
]) => [
  appLanguageProvider.overrideWith(() => _TestLanguageNotifier(language.code)),
];

/// Dipakai test yang mem-pump seluruh `MaterialApp.router` aplikasi: mengganti
/// pembacaan bahasa dari storage dengan nilai tetap.
class _TestLanguageNotifier extends AppLanguageNotifier {
  _TestLanguageNotifier(this._code);

  final String _code;

  @override
  AppLanguage build() => AppLanguage.byCode(_code);

  @override
  Future<void> select(AppLanguage language) async => state = language;
}
