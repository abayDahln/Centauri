import 'package:centauri/app/l10n/error_messages.dart';
import 'package:centauri/core/errors/app_error.dart';
import 'package:centauri/l10n/generated/app_localizations_en.dart';
import 'package:centauri/l10n/generated/app_localizations_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final en = AppLocalizationsEn();
  final id = AppLocalizationsId();

  test('kode error diterjemahkan sesuai bahasa UI', () {
    expect(
      localizedAppError(en, const AppErrorDetails(AppErrorCode.apiTimeout)),
      en.errorApiTimeout,
    );
    expect(
      localizedAppError(id, const AppErrorDetails(AppErrorCode.apiTimeout)),
      id.errorApiTimeout,
    );
    expect(
      localizedAppError(en, const AppErrorDetails(AppErrorCode.apiTimeout)),
      isNot(id.errorApiTimeout),
    );
  });

  test('detail teknis tidak bocor ke pesan yang tampil', () {
    final message = localizedAppError(
      en,
      const AppErrorDetails(
        AppErrorCode.apiNotFound,
        detail: 'HTTP 404 | https://api.example.com/v1 | model=gpt-9',
      ),
    );

    expect(message, en.errorApiNotFound);
    expect(message, isNot(contains('404')));
    expect(message, isNot(contains('api.example.com')));
  });

  test('pesan provider diteruskan apa adanya', () {
    final message = localizedAppError(
      en,
      const AppErrorDetails(
        AppErrorCode.apiProviderReported,
        detail: 'model not found: gpt-99',
      ),
    );

    expect(message, contains('model not found: gpt-99'));
  });

  test('apiProviderReported tanpa detail jatuh ke pesan umum', () {
    expect(
      localizedAppError(
        en,
        const AppErrorDetails(AppErrorCode.apiProviderReported),
      ),
      en.commonGenericError,
    );
  });

  test('placeholder terisi dari data error', () {
    expect(
      localizedAppError(
        en,
        const AppErrorDetails(AppErrorCode.attachmentTooLarge, maxMb: 8),
      ),
      contains('8'),
    );
    expect(
      localizedAppError(
        en,
        const AppErrorDetails(
          AppErrorCode.attachmentUnsupported,
          formats: 'PNG, JPG',
        ),
      ),
      contains('PNG, JPG'),
    );
    expect(
      localizedAppError(
        id,
        const AppErrorDetails(AppErrorCode.importNewerVersion, version: 'v2'),
      ),
      contains('v2'),
    );
    expect(
      localizedAppError(
        id,
        const AppErrorDetails(AppErrorCode.importUnusable, name: 'x.mydesign'),
      ),
      contains('x.mydesign'),
    );
    expect(
      localizedAppError(
        en,
        const AppErrorDetails(
          AppErrorCode.attachmentEmpty,
          name: 'catatan.png',
        ),
      ),
      contains('catatan.png'),
    );
  });

  test('debugLabel memuat kode dan detail untuk log', () {
    expect(
      const AppErrorDetails(AppErrorCode.exportTimeout).debugLabel,
      'AppErrorCode.exportTimeout',
    );
    expect(
      const AppErrorDetails(
        AppErrorCode.exportTimeout,
        detail: '20 detik',
      ).debugLabel,
      contains('20 detik'),
    );
  });
}
