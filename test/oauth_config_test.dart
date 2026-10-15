import 'package:centauri/features/provider_config/data/services/oauth_service_impl.dart';
import 'package:centauri/features/provider_config/domain/entities/oauth_config.dart';
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
    });
  });
}
