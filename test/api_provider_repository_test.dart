import 'dart:io';

import 'package:centauri/core/errors/app_error.dart';
import 'package:centauri/core/storage/local_storage_service.dart';
import 'package:centauri/core/storage/secure_storage_service.dart';
import 'package:centauri/core/utils/app_constants.dart';
import 'package:centauri/features/provider_config/data/datasources/ai_api_service.dart';
import 'package:centauri/features/provider_config/data/datasources/cline_oauth_service.dart';
import 'package:centauri/features/provider_config/data/repositories/api_provider_repository_impl.dart';
import 'package:centauri/features/provider_config/domain/entities/api_provider.dart';
import 'package:centauri/features/provider_config/domain/entities/oauth_session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_secure_storage.dart';
import 'helpers/hive_teardown.dart';

void main() {
  late Directory tempRoot;
  late LocalStorageService storage;
  late FakeSecureStorageChannel fake;
  late ApiProviderRepositoryImpl repo;

  final session = OAuthSession(
    accessToken: 'acc-token',
    refreshToken: 'ref-token',
    expiresAt: DateTime.utc(2026, 11, 1, 12),
    userId: 'user-1',
    email: 'orang@contoh.com',
    displayName: 'Orang',
  );

  ApiProvider cline({OAuthSession? withSession}) => ApiProvider(
    id: 'cline-1',
    name: 'Cline',
    providerName: 'Cline',
    catalogId: kClineOAuthCatalogId,
    authType: AuthType.oauth,
    oauthProvider: 'cline',
    baseUrl: 'https://api.cline.bot/api/v1',
    model: 'anthropic/claude-sonnet-4.5',
    oauthSession: withSession,
  );

  const groq = ApiProvider(
    id: 'groq-1',
    name: 'Groq',
    providerName: 'Groq',
    catalogId: 'groq',
    baseUrl: 'https://api.groq.com/openai/v1',
    model: 'llama-3.3-70b-versatile',
    apiKey: 'gsk-secret',
  );

  /// Repository dengan klien OAuth tertentu (palsu saat menguji refresh).
  ApiProviderRepositoryImpl repoWith(ClineOAuthService oauth) =>
      ApiProviderRepositoryImpl(
        localStorage: storage,
        secureStorage: SecureStorageService(),
        clineOAuth: oauth,
      );

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('centauri_provider_repo_');
    storage = LocalStorageService();
    await storage.init(path: '${tempRoot.path}${Platform.pathSeparator}hive');
    fake = FakeSecureStorageChannel()..install();
    repo = repoWith(const ClineOAuthService());
  });

  tearDown(() async {
    fake.uninstall();
    await closeHiveForTests();
    if (tempRoot.existsSync()) await tempRoot.delete(recursive: true);
  });

  group('Sesi OAuth pada repository', () {
    test('saveProvider menyimpan sesi ke secure storage', () async {
      await repo.saveProvider(cline(withSession: session));

      expect(
        fake.data.keys,
        contains('${AppConstants.oauthSessionPrefix}cline-1'),
      );
      final raw = fake.data['${AppConstants.oauthSessionPrefix}cline-1']!;
      expect(raw, contains('acc-token'));
      expect(raw, contains('ref-token'));
    });

    test('getProviderById mengisi sesi dari secure storage', () async {
      await repo.saveProvider(cline(withSession: session));

      final loaded = await repo.getProviderById('cline-1');
      expect(loaded, isNotNull);
      expect(loaded!.usesOAuth, isTrue);
      expect(loaded.oauthSession?.accessToken, 'acc-token');
      expect(loaded.bearerToken, 'acc-token');
      expect(loaded.apiKey, isNull);
    });

    test('getActiveProvider mengisi sesi provider aktif', () async {
      await repo.saveProvider(cline(withSession: session));

      final active = await repo.getActiveProvider();
      expect(active?.id, 'cline-1');
      expect(active?.oauthSession?.refreshToken, 'ref-token');
    });

    test('token tidak ikut masuk JSON provider di Hive', () async {
      await repo.saveProvider(cline(withSession: session));

      final json = storage.readProvidersJsonById()['cline-1']!;
      expect(json, contains('oauthProvider'));
      expect(json, isNot(contains('acc-token')));
      expect(json, isNot(contains('ref-token')));
      expect(json, isNot(contains('oauthSession')));
    });

    test('provider tanpa sesi tetap tersimpan (belum masuk)', () async {
      await repo.saveProvider(cline());

      final loaded = await repo.getProviderById('cline-1');
      expect(loaded, isNotNull);
      expect(loaded!.oauthSession, isNull);
      expect(loaded.bearerToken, isNull);
      expect(fake.data, isEmpty);
    });

    test('deleteProvider ikut menghapus sesi', () async {
      await repo.saveProvider(cline(withSession: session));
      await repo.deleteProvider('cline-1');

      expect(fake.data, isEmpty);
      expect(await repo.getProviderById('cline-1'), isNull);
    });

    test('sesi hampir habis diperpanjang dan hasilnya disimpan', () async {
      final expiring = OAuthSession(
        accessToken: 'acc-lama',
        refreshToken: 'ref-lama',
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 1)),
        userId: 'user-1',
      );
      final oauth = FakeClineOAuth(
        result: OAuthSession(
          accessToken: 'acc-baru',
          refreshToken: 'ref-baru',
          expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
          userId: 'user-1',
        ),
      );
      final repo = repoWith(oauth);
      await repo.saveProvider(cline(withSession: expiring));

      final loaded = await repo.getProviderById('cline-1');

      expect(oauth.refreshCalls, 1);
      expect(loaded?.oauthSession?.accessToken, 'acc-baru');
      // Rotasi: refresh token baru ikut tersimpan di secure storage.
      final raw = fake.data['${AppConstants.oauthSessionPrefix}cline-1']!;
      expect(raw, contains('acc-baru'));
      expect(raw, contains('ref-baru'));
      expect(raw, isNot(contains('ref-lama')));
    });

    test('sesi yang masih panjang tidak memicu refresh', () async {
      final oauth = FakeClineOAuth(result: session);
      final repo = repoWith(oauth);
      await repo.saveProvider(cline(withSession: session));

      final loaded = await repo.getProviderById('cline-1');

      expect(oauth.refreshCalls, 0);
      expect(loaded?.oauthSession?.accessToken, 'acc-token');
    });

    test('refresh gagal tidak menggagalkan pemuatan provider', () async {
      final expiring = OAuthSession(
        accessToken: 'acc-lama',
        refreshToken: 'ref-lama',
        expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
        userId: 'user-1',
      );
      final oauth = FakeClineOAuth(
        error: const ApiConnectionException(AppErrorCode.apiUnauthorized),
      );
      final repo = repoWith(oauth);
      await repo.saveProvider(cline(withSession: expiring));

      final loaded = await repo.getProviderById('cline-1');

      expect(oauth.refreshCalls, 1);
      expect(loaded?.oauthSession?.accessToken, 'acc-lama');
    });

    test('provider API key tetap memakai jalur API key', () async {
      await repo.saveProvider(groq);

      final loaded = await repo.getProviderById('groq-1');
      expect(loaded?.apiKey, 'gsk-secret');
      expect(loaded?.oauthSession, isNull);
      expect(
        fake.data.keys.any(
          (k) => k.startsWith(AppConstants.oauthSessionPrefix),
        ),
        isFalse,
      );
    });
  });
}

/// Pengganti [ClineOAuthService] yang mencatat panggilan refresh.
class FakeClineOAuth extends ClineOAuthService {
  FakeClineOAuth({this.result, this.error});

  final OAuthSession? result;
  final Object? error;
  int refreshCalls = 0;

  @override
  Future<OAuthSession> refresh(OAuthSession session) async {
    refreshCalls++;
    final failure = error;
    if (failure != null) throw failure;
    return result!;
  }
}
