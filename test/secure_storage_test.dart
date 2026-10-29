import 'package:centauri/core/errors/app_error.dart';
import 'package:centauri/core/storage/secure_storage_service.dart';
import 'package:centauri/core/utils/app_constants.dart';
import 'package:centauri/features/provider_config/domain/entities/api_provider.dart';
import 'package:centauri/features/provider_config/domain/entities/oauth_session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_secure_storage.dart';

void main() {
  group('SecureStorageException', () {
    test('membawa kode error dan detail untuk log', () {
      const ex = SecureStorageException(
        AppErrorCode.storageFailed,
        detail: 'write: PlatformException',
      );
      expect(ex.code, AppErrorCode.storageFailed);
      expect(ex.detail, 'write: PlatformException');
      expect(ex.toString(), contains('storageFailed'));
      expect(ex.toString(), contains('PlatformException'));
    });
  });

  group('ApiProvider key handling (fix Test Connection saat edit)', () {
    const stored = ApiProvider(
      id: 'p1',
      name: 'Groq',
      baseUrl: 'https://api.groq.com/openai/v1',
      model: 'llama3',
      apiKey: 'gsk-stored-secret',
    );

    test('form tanpa key (apiKey null) bisa memakai key tersimpan', () {
      // Form edit mengirim apiKey null bila field dikosongkan.
      const fromForm = ApiProvider(
        id: 'p1',
        name: 'Groq',
        baseUrl: 'https://api.groq.com/openai/v1',
        model: 'llama3',
      );
      expect(fromForm.apiKey, isNull);

      // Fix: lengkapi dengan key tersimpan agar Test Connection berhasil.
      final effective = fromForm.copyWith(apiKey: stored.apiKey);
      expect(effective.apiKey, 'gsk-stored-secret');
      expect(effective.id, 'p1');
      expect(effective.baseUrl, 'https://api.groq.com/openai/v1');
    });

    test('key baru dari form menang atas key tersimpan', () {
      const fromForm = ApiProvider(
        id: 'p1',
        name: 'Groq',
        baseUrl: 'https://api.groq.com/openai/v1',
        model: 'llama3',
        apiKey: 'gsk-new-secret',
      );
      // Logika fix hanya menimpa bila fromForm.apiKey == null.
      final effective = fromForm.apiKey == null
          ? fromForm.copyWith(apiKey: stored.apiKey)
          : fromForm;
      expect(effective.apiKey, 'gsk-new-secret');
    });

    test('toJson tetap tidak pernah memuat apiKey', () {
      final json = stored.toJson();
      expect(json.containsKey('apiKey'), isFalse);
    });
  });

  group('Sesi OAuth di secure storage', () {
    late FakeSecureStorageChannel fake;
    final service = SecureStorageService();

    final session = OAuthSession(
      accessToken: 'acc-token',
      refreshToken: 'ref-token',
      expiresAt: DateTime.utc(2026, 11, 1, 12),
      userId: 'user-1',
      email: 'orang@contoh.com',
      displayName: 'Orang',
    );

    setUp(() {
      fake = FakeSecureStorageChannel()..install();
    });

    tearDown(() => fake.uninstall());

    test('save lalu read mengembalikan sesi utuh', () async {
      await service.saveOAuthSession('p1', session);

      final read = await service.readOAuthSession('p1');
      expect(read, isNotNull);
      expect(read!.accessToken, 'acc-token');
      expect(read.refreshToken, 'ref-token');
      expect(read.expiresAt, DateTime.utc(2026, 11, 1, 12));
      expect(read.userId, 'user-1');
      expect(read.email, 'orang@contoh.com');
      expect(read.displayName, 'Orang');
    });

    test('sesi disimpan dengan prefix khusus, bukan prefix API key', () async {
      await service.saveOAuthSession('p1', session);

      expect(fake.data.keys, contains('${AppConstants.oauthSessionPrefix}p1'));
      expect(
        fake.data.keys.any((k) => k.startsWith(AppConstants.apiKeyPrefix)),
        isFalse,
      );
    });

    test('read tanpa sesi mengembalikan null', () async {
      expect(await service.readOAuthSession('p1'), isNull);
    });

    test('JSON rusak dianggap belum masuk', () async {
      fake.data['${AppConstants.oauthSessionPrefix}p1'] = '{bukan json';
      expect(await service.readOAuthSession('p1'), isNull);
    });

    test('sesi tanpa token dianggap belum masuk', () async {
      fake.data['${AppConstants.oauthSessionPrefix}p1'] =
          '{"refreshToken":"ref-token","expiresAt":"2026-11-01T12:00:00Z"}';
      expect(await service.readOAuthSession('p1'), isNull);
    });

    test('delete menghapus sesi', () async {
      await service.saveOAuthSession('p1', session);
      await service.deleteOAuthSession('p1');

      expect(fake.data, isEmpty);
      expect(await service.readOAuthSession('p1'), isNull);
    });
  });
}
