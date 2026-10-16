import 'package:centauri/features/provider_config/data/services/oauth_service_impl.dart';
import 'package:centauri/features/provider_config/domain/entities/oauth_config.dart';
import 'package:centauri/features/provider_config/domain/entities/oauth_flow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const config = OAuthConfig(
    authorizationUrl: 'https://accounts.example.com/o/oauth2/v2/auth',
    tokenUrl: 'https://oauth2.example.com/token',
    clientId: 'client-123',
    scopes: ['scope.a', 'scope.b'],
    audience: 'https://api.example.com',
    extraAuthParams: {'access_type': 'offline'},
  );

  final redirectUri = Uri.parse('http://127.0.0.1:5555/callback');

  group('buildAuthorizationUrl', () {
    test('includes core OAuth params', () {
      final uri = buildAuthorizationUrl(
        config,
        redirectUri: redirectUri,
        state: 'STATE123',
        codeChallenge: 'CHALLENGE',
      );

      expect(uri.host, 'accounts.example.com');
      final q = uri.queryParameters;
      expect(q['response_type'], 'code');
      expect(q['client_id'], 'client-123');
      expect(q['redirect_uri'], 'http://127.0.0.1:5555/callback');
      expect(q['state'], 'STATE123');
      expect(q['scope'], 'scope.a scope.b');
      expect(q['audience'], 'https://api.example.com');
      expect(q['access_type'], 'offline');
    });

    test('adds PKCE params only when a challenge is provided', () {
      final withPkce = buildAuthorizationUrl(
        config,
        redirectUri: redirectUri,
        state: 's',
        codeChallenge: 'CHALLENGE',
      );
      expect(withPkce.queryParameters['code_challenge'], 'CHALLENGE');
      expect(withPkce.queryParameters['code_challenge_method'], 'S256');

      final withoutPkce = buildAuthorizationUrl(
        config,
        redirectUri: redirectUri,
        state: 's',
      );
      expect(withoutPkce.queryParameters.containsKey('code_challenge'), isFalse);
      expect(
        withoutPkce.queryParameters.containsKey('code_challenge_method'),
        isFalse,
      );
    });

    test('preserves existing query params on the authorization URL', () {
      const withQuery = OAuthConfig(
        authorizationUrl: 'https://auth.example.com/authorize?tenant=acme',
        tokenUrl: 'https://auth.example.com/token',
        clientId: 'c',
      );
      final uri = buildAuthorizationUrl(
        withQuery,
        redirectUri: redirectUri,
        state: 's',
      );
      expect(uri.queryParameters['tenant'], 'acme');
      expect(uri.queryParameters['client_id'], 'c');
    });
  });

  group('OAuthConfig serialization', () {
    test('round-trips through JSON', () {
      final restored = OAuthConfig.fromJson(config.toJson());
      expect(restored.authorizationUrl, config.authorizationUrl);
      expect(restored.tokenUrl, config.tokenUrl);
      expect(restored.clientId, config.clientId);
      expect(restored.scopes, config.scopes);
      expect(restored.audience, config.audience);
      expect(restored.extraAuthParams, config.extraAuthParams);
      expect(restored.usePkce, isTrue);
      expect(restored.isExperimental, isFalse);
      expect(restored.flow, OAuthFlow.authorizationCode);
      expect(restored.deviceFlowStyle, DeviceFlowStyle.rfc8628);
      expect(restored.isTokenOnly, isFalse);
    });

    test('round-trips device flow fields', () {
      const device = OAuthConfig(
        authorizationUrl: 'https://qoder.com/device/selectAccounts',
        tokenUrl: 'https://openapi.qoder.sh/api/v1/deviceToken/poll',
        clientId: '',
        flow: OAuthFlow.deviceCode,
        deviceFlowStyle: DeviceFlowStyle.qoder,
        isTokenOnly: true,
      );
      final restored = OAuthConfig.fromJson(device.toJson());
      expect(restored.flow, OAuthFlow.deviceCode);
      expect(restored.deviceFlowStyle, DeviceFlowStyle.qoder);
      expect(restored.isTokenOnly, isTrue);
    });

    test('JSON lama tanpa field baru memakai default', () {
      final legacy = config.toJson()
        ..remove('flow')
        ..remove('deviceFlowStyle')
        ..remove('isTokenOnly')
        ..remove('tokenExchange')
        ..remove('tokenBodyFormat')
        ..remove('importSource');
      final restored = OAuthConfig.fromJson(legacy);
      expect(restored.flow, OAuthFlow.authorizationCode);
      expect(restored.deviceFlowStyle, DeviceFlowStyle.rfc8628);
      expect(restored.isTokenOnly, isFalse);
      expect(restored.tokenExchange, TokenExchangeStyle.none);
      expect(restored.tokenBodyFormat, TokenBodyFormat.form);
      expect(restored.importSource, isNull);
    });

    test('round-trips tokenExchange/tokenBodyFormat/callbackPath', () {
      const enriched = OAuthConfig(
        authorizationUrl: 'https://auth.openai.com/oauth/authorize',
        tokenUrl: 'https://auth.openai.com/oauth/token',
        clientId: 'app_x',
        tokenExchange: TokenExchangeStyle.githubCopilot,
        tokenBodyFormat: TokenBodyFormat.json,
        redirectPort: 1455,
        callbackPath: '/auth/callback',
      );
      final restored = OAuthConfig.fromJson(enriched.toJson());
      expect(restored.tokenExchange, TokenExchangeStyle.githubCopilot);
      expect(restored.tokenBodyFormat, TokenBodyFormat.json);
      expect(restored.redirectPort, 1455);
      expect(restored.callbackPath, '/auth/callback');
    });

    test('round-trips importSource', () {
      const imported = OAuthConfig(
        authorizationUrl: '',
        tokenUrl: '',
        clientId: '',
        flow: OAuthFlow.importToken,
        importSource: ImportSource.cursor,
        isTokenOnly: true,
      );
      final restored = OAuthConfig.fromJson(imported.toJson());
      expect(restored.flow, OAuthFlow.importToken);
      expect(restored.importSource, ImportSource.cursor);
    });
  });
}
