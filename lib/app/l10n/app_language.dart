import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';

/// Satu bahasa antarmuka yang bisa dipilih pengguna.
///
/// [nativeName] sengaja tidak diterjemahkan: orang yang terlanjur memilih
/// bahasa yang tidak ia mengerti tetap bisa menemukan bahasanya sendiri di
/// daftar, apa pun bahasa aplikasi saat itu.
class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.nativeName,
    required this.englishName,
  });

  /// Kode locale yang dipakai `MaterialApp` dan disimpan di Hive.
  final String code;

  /// Nama bahasa dalam bahasa aslinya.
  final String nativeName;

  /// Nama bahasa dalam bahasa Inggris, untuk pembaca yang tidak mengenali
  /// tulisan aslinya (mis. aksara Arab/Thai/CJK).
  final String englishName;

  Locale get locale => Locale(code);

  static const AppLanguage english = AppLanguage(
    code: 'en',
    nativeName: 'English',
    englishName: 'English',
  );

  static const AppLanguage indonesian = AppLanguage(
    code: 'id',
    nativeName: 'Bahasa Indonesia',
    englishName: 'Indonesian',
  );

  /// Semua bahasa yang didukung; urutan ini yang tampil di daftar pemilih.
  ///
  /// Menambah bahasa = tambah satu file ARB di `lib/l10n` (lihat `l10n.yaml`);
  /// daftar ini hanya menentukan nama dan urutannya. Bahasa yang belum punya
  /// ARB otomatis tidak muncul di pemilih — lihat [supportedLocales].
  static const List<AppLanguage> all = [
    english,
    indonesian,
    AppLanguage(
      code: 'zh',
      nativeName: '简体中文',
      englishName: 'Chinese (Simplified)',
    ),
    AppLanguage(
      code: 'ja',
      nativeName: '日本語',
      englishName: 'Japanese',
    ),
    AppLanguage(
      code: 'ko',
      nativeName: '한국어',
      englishName: 'Korean',
    ),
    AppLanguage(
      code: 'ru',
      nativeName: 'Русский',
      englishName: 'Russian',
    ),
    AppLanguage(
      code: 'de',
      nativeName: 'Deutsch',
      englishName: 'German',
    ),
    AppLanguage(
      code: 'ar',
      nativeName: 'العربية',
      englishName: 'Arabic',
    ),
    AppLanguage(
      code: 'fr',
      nativeName: 'Français',
      englishName: 'French',
    ),
    AppLanguage(
      code: 'pt',
      nativeName: 'Português',
      englishName: 'Portuguese',
    ),
    AppLanguage(
      code: 'th',
      nativeName: 'ไทย',
      englishName: 'Thai',
    ),
    AppLanguage(
      code: 'fil',
      nativeName: 'Filipino',
      englishName: 'Filipino',
    ),
  ];

  /// Cari bahasa dari kode tersimpan. Kode lengkap seperti `en_US` dicocokkan
  /// lewat subtag utamanya. Kode kosong/tak dikenal jatuh ke Inggris.
  static AppLanguage byCode(String? code) {
    if (code == null || code.isEmpty) return english;
    final primary = code.split('_').first.toLowerCase();
    for (final language in all) {
      if (language.code == primary) return language;
    }
    return english;
  }

  /// Bahasa yang benar-benar tersedia: hanya yang sudah punya file ARB.
  ///
  /// Dipakai `MaterialApp`/`testApp` supaya locale yang tidak punya delegasi
  /// tidak pernah diminta — kalau tidak, `AppLocalizations.of` akan gagal.
  static List<Locale> get supportedLocales {
    final generated = AppLocalizations.supportedLocales
        .map((locale) => locale.languageCode)
        .toSet();
    return all
        .where((language) => generated.contains(language.code))
        .map((language) => language.locale)
        .toList(growable: false);
  }
}
