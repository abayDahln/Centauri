import 'dart:convert';

import 'package:centauri/core/storage/provider_oauth_cleanup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isLegacyOAuthProviderJson', () {
    test('bentuk lama dengan oauthConfig dianggap legacy', () {
      final json = jsonEncode({
        'id': 'old',
        'name': 'Qoder',
        'authType': 'oauth',
        'oauthConfig': {'clientId': 'client-1'},
      });

      expect(isLegacyOAuthProviderJson(json), isTrue);
    });

    test('authType oauth tanpa penanda oauthProvider dianggap legacy', () {
      final json = jsonEncode({
        'id': 'old',
        'name': 'Copilot',
        'authType': 'oauth',
      });

      expect(isLegacyOAuthProviderJson(json), isTrue);
    });

    test('provider OAuth baru (Cline) tidak ikut dibuang', () {
      final json = jsonEncode({
        'id': 'claude-1',
        'name': 'Cline',
        'catalogId': 'cline',
        'authType': 'oauth',
        'oauthProvider': 'cline',
        'baseUrl': 'https://api.cline.bot/api/v1',
        'model': 'anthropic/claude-sonnet-4.5',
      });

      expect(isLegacyOAuthProviderJson(json), isFalse);
    });

    test('provider API key biasa tidak tersentuh', () {
      final json = jsonEncode({
        'id': 'groq-1',
        'name': 'Groq',
        'authType': 'apiKey',
        'baseUrl': 'https://api.groq.com/openai/v1',
        'model': 'llama-3.3-70b-versatile',
      });

      expect(isLegacyOAuthProviderJson(json), isFalse);
    });

    test('JSON rusak tidak melempar', () {
      expect(isLegacyOAuthProviderJson('{bukan json'), isFalse);
    });
  });
}
