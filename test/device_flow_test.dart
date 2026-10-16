import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:centauri/features/provider_config/data/catalog/provider_models.dart';
import 'package:centauri/features/provider_config/data/oauth/oauth_provider_presets.dart';
import 'package:centauri/features/provider_config/data/services/oauth_service_impl.dart';
import 'package:centauri/features/provider_config/domain/entities/api_provider.dart';
import 'package:centauri/features/provider_config/domain/entities/device_authorization.dart';
import 'package:centauri/features/provider_config/domain/entities/oauth_config.dart';
import 'package:centauri/features/provider_config/domain/entities/oauth_flow.dart';
import 'package:centauri/features/provider_config/domain/entities/provider_auth_type.dart';
import 'package:centauri/features/provider_config/domain/services/oauth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Adapter Dio yang mengembalikan respons berurutan (mendukung 202 → 200).
class _QueueAdapter implements HttpClientAdapter {
  _QueueAdapter(this.responses);

  final List<({int status, Map<String, dynamic> body})> responses;
  final List<RequestOptions> requests = [];
  int _index = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final i = _index < responses.length ? _index : responses.length - 1;
    _index++;
    final response = responses[i];
    return ResponseBody.fromString(
      jsonEncode(response.body),
      response.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiProvider _qoderProvider() => ApiProvider(
  id: 'q',
  name: 'Qoder',
  baseUrl: '',
  model: '',
  authType: AuthType.oauth,
  oauthConfig: const OAuthConfig(
    authorizationUrl: 'https://qoder.com/device/selectAccounts',
    tokenUrl: 'https://openapi.qoder.sh/api/v1/deviceToken/poll',
    clientId: '',
    flow: OAuthFlow.deviceCode,
    deviceFlowStyle: DeviceFlowStyle.qoder,
    isTokenOnly: true,
    isExperimental: true,
  ),
);

ApiProvider _rfcProvider() => ApiProvider(
  id: 'r',
  name: 'RFC',
  baseUrl: '',
  model: '',
  authType: AuthType.oauth,
  oauthConfig: const OAuthConfig(
    authorizationUrl: 'https://auth.example.com/device',
    tokenUrl: 'https://auth.example.com/token',
    clientId: 'client-1',
    scopes: ['s1'],
    flow: OAuthFlow.deviceCode,
    deviceFlowStyle: DeviceFlowStyle.rfc8628,
  ),
);

DeviceAuthorization _rfcAuthorization({DateTime? expiresAt}) =>
    DeviceAuthorization(
      flow: OAuthFlow.deviceCode,
      style: DeviceFlowStyle.rfc8628,
      verificationUri: Uri.parse('https://auth.example.com/activate'),
      userCode: 'WDJB-MJHT',
      deviceCode: 'DC',
      interval: Duration.zero,
      expiresAt: expiresAt ?? DateTime.now().add(const Duration(minutes: 1)),
    );

void main() {
  group('helper murni', () {
    test('buildQoderLoginUrl menambahkan challenge/machine_id/nonce', () {
      final uri = buildQoderLoginUrl(
        'https://qoder.com/device/selectAccounts',
        challenge: 'CH',
        machineId: 'MID',
        nonce: 'NONCE',
      );
      expect(uri.host, 'qoder.com');
      expect(uri.queryParameters['challenge'], 'CH');
      expect(uri.queryParameters['challenge_method'], 'S256');
      expect(uri.queryParameters['machine_id'], 'MID');
      expect(uri.queryParameters['nonce'], 'NONCE');
    });

    test('deriveUserCode menghasilkan 8 hex uppercase', () {
      final code = deriveUserCode('d3b07384-d9a0-4c1b-8f3a-1234567890ab');
      expect(code, 'D3B07384');
      expect(code.length, 8);
    });
  });

  group('preset Qoder', () {
    test('memakai device flow Qoder dan token-only', () {
      final config = OAuthProviderPresets.qoder.toOAuthConfig();
      expect(config.flow, OAuthFlow.deviceCode);
      expect(config.deviceFlowStyle, DeviceFlowStyle.qoder);
      expect(config.isTokenOnly, isTrue);
    });

    test('preset Copilot mengambil daftar model live dari endpoint khusus', () {
      expect(
        OAuthProviderPresets.githubCopilot.modelsUrl,
        'https://api.githubcopilot.com/v1/models',
      );
    });

    test('preset Qoder memakai daftar model hardcode (ala 9Router)', () {
      // Daftar model kini terpusat di ProviderModelCatalog (hardcode), bukan
      // lagi di preset; API Qoder tidak punya endpoint /models publik.
      final set = ProviderModelCatalog.forProvider('qoder');
      expect(set, isNotNull);
      expect(set!.alias, 'qd');
      final ids = set.models.map((m) => m.id).toList();
      for (final id in ['auto', 'ultimate', 'qmodel_38max', 'dmodel', 'gmodel']) {
        expect(ids, contains(id));
      }
      expect(OAuthProviderPresets.qoder.modelsUrl, isEmpty);
    });
  });

  group('Qoder device flow', () {
    test('startDeviceFlow menghasilkan URL login + kode + nonce', () async {
      final service = OAuthServiceImpl(
        dio: Dio()..httpClientAdapter = _QueueAdapter([]),
      );

      final auth = await service.startDeviceFlow(_qoderProvider());

      expect(auth.style, DeviceFlowStyle.qoder);
      expect(auth.verificationUri.queryParameters['challenge'], isNotNull);
      expect(auth.verificationUri.queryParameters['machine_id'], isNotNull);
      expect(auth.userCode.length, 8);
      expect(auth.deviceCode, auth.verificationUri.queryParameters['nonce']);
      expect(auth.codeVerifier, isNotNull);
    });

    test('poll: 202 lalu 200 token → sukses tanpa refresh token', () async {
      final adapter = _QueueAdapter([
        (status: 202, body: <String, dynamic>{}),
        (status: 200, body: <String, dynamic>{'token': 'dt-abc'}),
      ]);
      final service = OAuthServiceImpl(dio: Dio()..httpClientAdapter = adapter);
      final start = await service.startDeviceFlow(_qoderProvider());
      final auth = DeviceAuthorization(
        flow: start.flow,
        style: start.style,
        verificationUri: start.verificationUri,
        userCode: start.userCode,
        deviceCode: start.deviceCode,
        codeVerifier: start.codeVerifier,
        interval: Duration.zero,
        expiresAt: DateTime.now().add(const Duration(minutes: 1)),
      );

      final tokens = await service.pollDeviceFlow(
        _qoderProvider(),
        auth,
        cancel: Completer<void>().future,
      );

      expect(tokens.accessToken, 'dt-abc');
      expect(tokens.refreshToken, isNull);
      expect(
        tokens.expiresAt.isAfter(DateTime.now().add(const Duration(days: 29))),
        isTrue,
      );
      // Poll memakai GET + query param nonce/verifier/challenge_method.
      final poll = adapter.requests.last;
      expect(poll.method, 'GET');
      expect(poll.uri.queryParameters['nonce'], auth.deviceCode);
      expect(poll.uri.queryParameters['verifier'], auth.codeVerifier);
      expect(poll.uri.queryParameters['challenge_method'], 'S256');
      expect(poll.headers['User-Agent'], 'Go-http-client/2.0');
    });

    test('poll: 200 memparse refresh_token + expires_at (ms-epoch)', () async {
      final futureMs =
          DateTime.now().add(const Duration(days: 10)).millisecondsSinceEpoch;
      final adapter = _QueueAdapter([
        (
          status: 200,
          body: <String, dynamic>{
            'token': 'dt-xyz',
            'refresh_token': 'rt-1',
            'expires_at': futureMs,
          },
        ),
      ]);
      final service = OAuthServiceImpl(dio: Dio()..httpClientAdapter = adapter);
      final start = await service.startDeviceFlow(_qoderProvider());
      final auth = DeviceAuthorization(
        flow: start.flow,
        style: start.style,
        verificationUri: start.verificationUri,
        userCode: start.userCode,
        deviceCode: start.deviceCode,
        codeVerifier: start.codeVerifier,
        interval: Duration.zero,
        expiresAt: DateTime.now().add(const Duration(minutes: 1)),
      );

      final tokens = await service.pollDeviceFlow(
        _qoderProvider(),
        auth,
        cancel: Completer<void>().future,
      );

      expect(tokens.accessToken, 'dt-xyz');
      expect(tokens.refreshToken, 'rt-1');
      expect(tokens.expiresAt.millisecondsSinceEpoch, futureMs);
    });
  });

  group('RFC 8628 device flow', () {
    test('startDeviceFlow memparse kode device/user + verification URI', () async {
      final adapter = _QueueAdapter([
        (
          status: 200,
          body: <String, dynamic>{
            'device_code': 'DC',
            'user_code': 'WDJB-MJHT',
            'verification_uri': 'https://auth.example.com/activate',
            'expires_in': 600,
            'interval': 1,
          },
        ),
      ]);
      final service = OAuthServiceImpl(dio: Dio()..httpClientAdapter = adapter);

      final auth = await service.startDeviceFlow(_rfcProvider());

      expect(auth.deviceCode, 'DC');
      expect(auth.userCode, 'WDJB-MJHT');
      expect(auth.verificationUri.toString(), 'https://auth.example.com/activate');
      expect(auth.interval, const Duration(seconds: 1));
    });

    test('poll: authorization_pending lalu sukses', () async {
      final adapter = _QueueAdapter([
        (status: 400, body: <String, dynamic>{'error': 'authorization_pending'}),
        (
          status: 200,
          body: <String, dynamic>{'access_token': 'AT', 'expires_in': 3600},
        ),
      ]);
      final service = OAuthServiceImpl(dio: Dio()..httpClientAdapter = adapter);

      final tokens = await service.pollDeviceFlow(
        _rfcProvider(),
        _rfcAuthorization(),
        cancel: Completer<void>().future,
      );

      expect(tokens.accessToken, 'AT');
      expect(adapter.requests.length, 2);
    });

    test('poll: access_denied → OAuthException', () async {
      final adapter = _QueueAdapter([
        (status: 400, body: <String, dynamic>{'error': 'access_denied'}),
      ]);
      final service = OAuthServiceImpl(dio: Dio()..httpClientAdapter = adapter);

      await expectLater(
        () => service.pollDeviceFlow(
          _rfcProvider(),
          _rfcAuthorization(),
          cancel: Completer<void>().future,
        ),
        throwsA(isA<OAuthException>()),
      );
    });

    test('poll: kedaluwarsa → OAuthException', () async {
      final service = OAuthServiceImpl(
        dio: Dio()..httpClientAdapter = _QueueAdapter([]),
      );

      await expectLater(
        () => service.pollDeviceFlow(
          _rfcProvider(),
          _rfcAuthorization(
            expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
          ),
          cancel: Completer<void>().future,
        ),
        throwsA(isA<OAuthException>()),
      );
    });

    test('poll: dibatalkan → OAuthException', () async {
      final adapter = _QueueAdapter([
        (status: 400, body: <String, dynamic>{'error': 'authorization_pending'}),
      ]);
      final service = OAuthServiceImpl(dio: Dio()..httpClientAdapter = adapter);
      final cancel = Completer<void>();

      final future = service.pollDeviceFlow(
        _rfcProvider(),
        _rfcAuthorization(),
        cancel: cancel.future,
      );
      cancel.complete();

      await expectLater(future, throwsA(isA<OAuthException>()));
    });
  });
}
