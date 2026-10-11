import 'dart:convert';

import 'package:centauri/features/provider_config/domain/entities/api_provider.dart';
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
}
