import 'package:centauri/app/l10n/app_language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppLanguage.all memuat 12 bahasa dengan kode unik', () {
    final codes = AppLanguage.all.map((l) => l.code).toList();
    expect(codes, ['en', 'id', 'zh', 'ja', 'ko', 'ru', 'de', 'ar', 'fr', 'pt', 'th', 'fil']);
    expect(codes.toSet().length, codes.length);
  });

  test('AppLanguage.byCode memakai subtag utama', () {
    expect(AppLanguage.byCode('en_US').code, 'en');
    expect(AppLanguage.byCode('pt_BR').code, 'pt');
    expect(AppLanguage.byCode('zh_Hans').code, 'zh');
  });

  test('AppLanguage.byCode jatuh ke Inggris untuk kode kosong/tak dikenal', () {
    expect(AppLanguage.byCode(null), AppLanguage.english);
    expect(AppLanguage.byCode(''), AppLanguage.english);
    expect(AppLanguage.byCode('xyz'), AppLanguage.english);
  });

  test('supportedLocales hanya berisi bahasa yang punya ARB', () {
    final codes = AppLanguage.supportedLocales.map((l) => l.languageCode);
    for (final language in AppLanguage.all) {
      expect(codes.contains(language.code), isTrue,
          reason: 'ARB untuk ${language.code} belum ada atau belum di-generate');
    }
  });
}
