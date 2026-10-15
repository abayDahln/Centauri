import 'dart:convert';

import 'package:centauri/features/provider_config/domain/entities/api_provider.dart';
import 'package:centauri/features/provider_config/domain/entities/oauth_config.dart';
import 'package:centauri/features/provider_config/domain/entities/oauth_token_set.dart';
import 'package:centauri/features/provider_config/domain/entities/provider_auth_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final provider = ApiProvider(
    id: 'abc-123',
    name: 'Groq Cloud',
    baseUrl: 'https://api.groq.com/openai/v1/',
    model: 'llama3-8b-8192',
    apiKey: 'gsk-super-secret',
  );

  group('ApiProvider', () {
    test('normalizedBaseUrl strips trailing slash', () {
      expect(provider.normalizedBaseUrl, 'https://api.groq.com/openai/v1');

      const noSlash = ApiProvider(
        id: 'x',
        name: 'x',
        baseUrl: 'https://api.openai.com/v1',
        model: 'gpt-4o',
      );
      expect(noSlash.normalizedBaseUrl, 'https://api.openai.com/v1');
    });

    test('toJson never serializes apiKey', () {
      final json = provider.toJson();
      expect(json.containsKey('apiKey'), isFalse);
      expect(jsonEncode(json), isNot(contains('gsk-super-secret')));
    });

    test('fromJson restores fields without apiKey', () {
      final restored = ApiProvider.fromJson(
        jsonDecode(jsonEncode(provider.toJson())) as Map<String, dynamic>,
      );

      expect(restored.id, provider.id);
      expect(restored.name, provider.name);
      expect(restored.baseUrl, provider.baseUrl);
      expect(restored.model, provider.model);
      expect(restored.apiKey, isNull);
    });

    test('copyWith preserves unmasked fields', () {
      final edited = provider.copyWith(model: 'mixtral-8x7b');
      expect(edited.model, 'mixtral-8x7b');
      expect(edited.id, provider.id);
      expect(edited.name, provider.name);
    });
  });

  group('ApiProvider OAuth', () {
    const oauthConfig = OAuthConfig(
      authorizationUrl: 'https://auth.example.com/authorize',
      tokenUrl: 'https://auth.example.com/token',
      clientId: 'client-1',
      scopes: ['s'],
    );

    test('fromJson tanpa authType default ke apiKey (backward-compatible)', () {
      // JSON provider lama di Hive tidak punya field authType.
      final legacy = ApiProvider.fromJson({
        'id': 'old',
        'name': 'Old',
        'baseUrl': 'https://api.openai.com/v1',
        'model': 'gpt-4o',
      });

      expect(legacy.authType, AuthType.apiKey);
      expect(legacy.oauthConfig, isNull);
      expect(legacy.usesOAuth, isFalse);
    });

    test('toJson memuat authType + oauthConfig, tidak memuat token/apiKey', () {
      final oauthProvider = ApiProvider(
        id: 'o1',
        name: 'Google',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
        model: 'gemini-2.0-flash',
        authType: AuthType.oauth,
        oauthConfig: oauthConfig,
        oauthToken: OAuthTokenSet(
          accessToken: 'super-secret-access',
          refreshToken: 'super-secret-refresh',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        ),
      );

      final json = oauthProvider.toJson();
      expect(json['authType'], 'oauth');
      expect(json['oauthConfig'], isA<Map>());
      expect(json.containsKey('apiKey'), isFalse);
      expect(json.containsKey('oauthToken'), isFalse);

      final encoded = jsonEncode(json);
      expect(encoded, isNot(contains('super-secret-access')));
      expect(encoded, isNot(contains('super-secret-refresh')));
    });

    test('oauthConfig bertahan lewat toJson/fromJson', () {
      final oauthProvider = ApiProvider(
        id: 'o1',
        name: 'Google',
        baseUrl: 'https://api.example.com/v1',
        model: 'm',
        authType: AuthType.oauth,
        oauthConfig: oauthConfig,
      );

      final restored = ApiProvider.fromJson(
        jsonDecode(jsonEncode(oauthProvider.toJson())) as Map<String, dynamic>,
      );

      expect(restored.authType, AuthType.oauth);
      expect(restored.usesOAuth, isTrue);
      expect(restored.oauthConfig?.clientId, 'client-1');
      expect(restored.oauthConfig?.tokenUrl, oauthConfig.tokenUrl);
    });

    test('bearerToken memprioritaskan token OAuth di atas API key', () {
      final oauthProvider = ApiProvider(
        id: 'o1',
        name: 'x',
        baseUrl: 'https://api.example.com/v1',
        model: 'm',
        apiKey: 'api-key-value',
        authType: AuthType.oauth,
        oauthToken: OAuthTokenSet(
          accessToken: 'oauth-access',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        ),
      );
      expect(oauthProvider.bearerToken, 'oauth-access');

      final apiKeyProvider = provider;
      expect(apiKeyProvider.bearerToken, 'gsk-super-secret');
    });

    test('clearOauthToken menghapus token runtime', () {
      final oauthProvider = ApiProvider(
        id: 'o1',
        name: 'x',
        baseUrl: 'https://api.example.com/v1',
        model: 'm',
        authType: AuthType.oauth,
        oauthToken: OAuthTokenSet(
          accessToken: 'a',
          expiresAt: DateTime.now(),
        ),
      );
      expect(oauthProvider.copyWith(clearOauthToken: true).oauthToken, isNull);
    });
  });
}
