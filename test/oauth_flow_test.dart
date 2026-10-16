import 'dart:convert';
import 'dart:typed_data';

import 'package:centauri/features/provider_config/data/services/browser_launcher.dart';
import 'package:centauri/features/provider_config/data/services/oauth_service_impl.dart';
import 'package:centauri/features/provider_config/domain/entities/api_provider.dart';
import 'package:centauri/features/provider_config/domain/entities/oauth_config.dart';
import 'package:centauri/features/provider_config/domain/entities/oauth_token_set.dart';
import 'package:centauri/features/provider_config/domain/entities/provider_auth_type.dart';
import 'package:centauri/features/provider_config/domain/services/oauth_service.dart';
import 'package:centauri/features/provider_config/domain/services/redirect_receiver.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Adapter Dio palsu: mencatat request terakhir dan membalas JSON tetap.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.body);

  final Map<String, dynamic> body;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Browser palsu: mencatat URL otorisasi yang "dibuka".
class _FakeBrowser implements BrowserLauncher {
  Uri? opened;

  @override
  Future<bool> open(Uri url) async {
    opened = url;
    return true;
  }
}

/// Penerima redirect palsu: mengembalikan hasil dari [resultBuilder], yang
/// dapat membaca `state` dari URL yang dibuka browser.
class _FakeReceiver implements RedirectReceiver {
  _FakeReceiver(this.resultBuilder);

  final OAuthRedirectResult Function() resultBuilder;
  Uri? startedUri;
  bool stopped = false;

  @override
  Future<Uri> start({int? port, String? path}) async {
    startedUri = Uri.parse(
      'http://127.0.0.1:5555${path ?? '/callback'}',
    );
    return startedUri!;
  }

  @override
  Future<OAuthRedirectResult> waitForCallback({required Duration timeout}) async {
    return resultBuilder();
  }

  @override
  Future<void> stop() async {
    stopped = true;
  }
}

ApiProvider _provider({OAuthConfig? config}) => ApiProvider(
  id: 'p1',
  name: 'Test',
  baseUrl: 'https://api.example.com/v1',
  model: 'm',
  authType: AuthType.oauth,
  oauthConfig:
      config ??
      const OAuthConfig(
        authorizationUrl: 'https://auth.example.com/authorize',
        tokenUrl: 'https://auth.example.com/token',
        clientId: 'client-1',
        scopes: ['s1'],
      ),
);

void main() {
  group('OAuthServiceImpl.authorize', () {
    test('menjalankan alur PKCE dan mengembalikan token set', () async {
      final adapter = _FakeAdapter({
        'access_token': 'AT',
        'refresh_token': 'RT',
        'expires_in': 3600,
      });
      final dio = Dio()..httpClientAdapter = adapter;
      final browser = _FakeBrowser();
      final receiver = _FakeReceiver(() {
        final state = browser.opened!.queryParameters['state'];
        return OAuthRedirectResult(code: 'CODE', state: state);
      });
      final service = OAuthServiceImpl(
        dio: dio,
        browserLauncher: browser,
        receiverFactory: () => receiver,
      );

      final tokens = await service.authorize(_provider());

      expect(tokens.accessToken, 'AT');
      expect(tokens.refreshToken, 'RT');
      expect(receiver.stopped, isTrue);

      // Parameter PKCE terkirim pada authorization URL.
      final authQuery = browser.opened!.queryParameters;
      expect(authQuery['code_challenge_method'], 'S256');
      expect(authQuery['code_challenge'], isNotNull);
      expect(authQuery['state'], isNotNull);

      // code_verifier dikirim ke token endpoint.
      expect(adapter.lastRequest!.data.toString(), contains('code_verifier'));
      expect(
        adapter.lastRequest!.data.toString(),
        contains('authorization_code'),
      );
    });

    test('menolak state yang tidak cocok (CSRF)', () async {
      final adapter = _FakeAdapter({'access_token': 'AT'});
      final dio = Dio()..httpClientAdapter = adapter;
      final receiver = _FakeReceiver(
        () => const OAuthRedirectResult(code: 'CODE', state: 'WRONG'),
      );
      final service = OAuthServiceImpl(
        dio: dio,
        browserLauncher: _FakeBrowser(),
        receiverFactory: () => receiver,
      );

      await expectLater(
        () => service.authorize(_provider()),
        throwsA(isA<OAuthException>()),
      );
      expect(receiver.stopped, isTrue);
      expect(adapter.lastRequest, isNull); // tidak ada tukar token
    });

    test('meneruskan error provider ke pemanggil', () async {
      final service = OAuthServiceImpl(
        dio: Dio()..httpClientAdapter = _FakeAdapter({}),
        browserLauncher: _FakeBrowser(),
        receiverFactory: () => _FakeReceiver(
          () => const OAuthRedirectResult(
            error: 'access_denied',
            errorDescription: 'User menolak',
          ),
        ),
      );

      await expectLater(
        () => service.authorize(_provider()),
        throwsA(
          predicate(
            (e) => e is OAuthException && e.message.contains('User menolak'),
          ),
        ),
      );
    });

    test('melempar bila provider tidak punya konfigurasi OAuth', () async {
      final service = OAuthServiceImpl(
        dio: Dio()..httpClientAdapter = _FakeAdapter({}),
        browserLauncher: _FakeBrowser(),
        receiverFactory: () => _FakeReceiver(() => const OAuthRedirectResult()),
      );
      final plain = ApiProvider(
        id: 'p2',
        name: 'Plain',
        baseUrl: 'https://api.example.com/v1',
        model: 'm',
      );

      await expectLater(
        () => service.authorize(plain),
        throwsA(isA<OAuthException>()),
      );
    });
  });

  group('OAuthServiceImpl.refresh', () {
    test('memakai grant refresh_token dan mempertahankan refresh token lama',
        () async {
      final adapter = _FakeAdapter({'access_token': 'AT2', 'expires_in': 3600});
      final dio = Dio()..httpClientAdapter = adapter;
      final service = OAuthServiceImpl(
        dio: dio,
        browserLauncher: _FakeBrowser(),
        receiverFactory: () => _FakeReceiver(() => const OAuthRedirectResult()),
      );
      final current = OAuthTokenSet(
        accessToken: 'AT1',
        refreshToken: 'RT1',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );

      final refreshed = await service.refresh(_provider(), current);

      expect(refreshed.accessToken, 'AT2');
      expect(refreshed.refreshToken, 'RT1');
      expect(adapter.lastRequest!.data.toString(), contains('refresh_token'));
      expect(adapter.lastRequest!.data.toString(), contains('grant_type'));
    });

    test('melempar bila tidak ada refresh token', () async {
      final service = OAuthServiceImpl(
        dio: Dio()..httpClientAdapter = _FakeAdapter({}),
        browserLauncher: _FakeBrowser(),
        receiverFactory: () => _FakeReceiver(() => const OAuthRedirectResult()),
      );
      final current = OAuthTokenSet(
        accessToken: 'AT1',
        expiresAt: DateTime.now(),
      );

      await expectLater(
        () => service.refresh(_provider(), current),
        throwsA(isA<OAuthException>()),
      );
    });
  });

  group('OAuthServiceImpl.revoke', () {
    test('no-op tanpa revocation URL', () async {
      final service = OAuthServiceImpl(
        dio: Dio()..httpClientAdapter = _FakeAdapter({}),
        browserLauncher: _FakeBrowser(),
        receiverFactory: () => _FakeReceiver(() => const OAuthRedirectResult()),
      );
      final tokens = OAuthTokenSet(
        accessToken: 'AT',
        expiresAt: DateTime.now(),
      );

      await service.revoke(_provider(), tokens); // tidak melempar
    });

    test('memanggil revocation URL bila tersedia', () async {
      final adapter = _FakeAdapter({});
      final service = OAuthServiceImpl(
        dio: Dio()..httpClientAdapter = adapter,
        browserLauncher: _FakeBrowser(),
        receiverFactory: () => _FakeReceiver(() => const OAuthRedirectResult()),
      );
      final provider = _provider(
        config: const OAuthConfig(
          authorizationUrl: 'https://auth.example.com/authorize',
          tokenUrl: 'https://auth.example.com/token',
          clientId: 'c',
          revocationUrl: 'https://auth.example.com/revoke',
        ),
      );

      await service.revoke(
        provider,
        OAuthTokenSet(accessToken: 'AT', expiresAt: DateTime.now()),
      );

      expect(adapter.lastRequest!.uri.toString(), contains('/revoke'));
      expect(adapter.lastRequest!.data.toString(), contains('token'));
    });
  });
}
