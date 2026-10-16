import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:centauri/features/provider_config/data/oauth/oauth_provider_presets.dart';
import 'package:centauri/features/provider_config/data/services/oauth_service_impl.dart';
import 'package:centauri/features/provider_config/domain/entities/api_provider.dart';
import 'package:centauri/features/provider_config/domain/entities/device_authorization.dart';
import 'package:centauri/features/provider_config/domain/entities/oauth_flow.dart';
import 'package:centauri/features/provider_config/domain/entities/provider_auth_type.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

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

ApiProvider _copilotProvider() => ApiProvider(
  id: 'gh',
  name: 'GitHub Copilot',
  baseUrl: '',
  model: '',
  authType: AuthType.oauth,
  oauthConfig: OAuthProviderPresets.githubCopilot.toOAuthConfig(),
);

DeviceAuthorization _authorization() => DeviceAuthorization(
  flow: OAuthFlow.deviceCode,
  style: DeviceFlowStyle.rfc8628,
  verificationUri: Uri.parse('https://github.com/login/device'),
  userCode: 'ABCD-1234',
  deviceCode: 'DC',
  interval: Duration.zero,
  expiresAt: DateTime.now().add(const Duration(minutes: 1)),
);

void main() {
  group('GitHub Copilot flow', () {
    test('startDeviceFlow memparse kode device GitHub', () async {
      final adapter = _QueueAdapter([
        (
          status: 200,
          body: <String, dynamic>{
            'device_code': 'DC',
            'user_code': 'ABCD-1234',
            'verification_uri': 'https://github.com/login/device',
            'expires_in': 900,
            'interval': 1,
          },
        ),
      ]);
      final service = OAuthServiceImpl(dio: Dio()..httpClientAdapter = adapter);

      final auth = await service.startDeviceFlow(_copilotProvider());

      expect(auth.userCode, 'ABCD-1234');
      expect(auth.deviceCode, 'DC');
    });

    test('poll menukar token GitHub menjadi token Copilot', () async {
      final futureEpoch =
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
          1000;
      final adapter = _QueueAdapter([
        (
          status: 200,
          body: <String, dynamic>{
            'access_token': 'gho_x',
            'token_type': 'bearer',
          },
        ),
        (
          status: 200,
          body: <String, dynamic>{'token': 'cop-y', 'expires_at': futureEpoch},
        ),
      ]);
      final service = OAuthServiceImpl(dio: Dio()..httpClientAdapter = adapter);

      final tokens = await service.pollDeviceFlow(
        _copilotProvider(),
        _authorization(),
        cancel: Completer<void>().future,
      );

      expect(tokens.accessToken, 'cop-y');
      expect(adapter.requests.length, 2);
      expect(adapter.requests.last.uri.host, 'api.github.com');
      expect(adapter.requests.last.headers['Authorization'], 'Bearer gho_x');
      expect(tokens.expiresAt.isAfter(DateTime.now()), isTrue);
    });
  });
}
