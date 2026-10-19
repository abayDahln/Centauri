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
Widget testApp({
  required Widget home,
  Locale locale = testLocaleId,
  ThemeData? theme,
  List<Override> overrides = const [],
  bool localeFromProvider = false,
}) {
  Widget app(Locale resolved) => MaterialApp(
    locale: resolved,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLanguage.supportedLocales,
    theme: theme,
    home: home,
  );

  return ProviderScope(
    overrides: overrides,
    child: localeFromProvider
        ? Consumer(
            builder: (_, ref, _) =>
                app(ref.watch(appLanguageProvider).locale),
          )
        : app(locale),
  );
}

/// Paksa bahasa UI tanpa menyentuh Hive (box tidak terbuka di test).
///
/// Default Indonesia karena ekspektasi teks di test memakai teks Indonesia.
List<Override> languageOverride([AppLanguage language = AppLanguage.indonesian]) => [
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
