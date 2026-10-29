import 'dart:convert';

import 'package:centauri/features/provider_config/domain/entities/api_provider.dart';
import 'package:centauri/features/provider_config/domain/entities/oauth_session.dart';
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

    test('daftar model kustom & terhapus ikut tersimpan', () {
      final withModels = provider.copyWith(
        customModels: const ['my-model'],
        removedModels: const ['llama3-8b-8192'],
      );
      final restored = ApiProvider.fromJson(
        jsonDecode(jsonEncode(withModels.toJson())) as Map<String, dynamic>,
      );

      expect(restored.customModels, ['my-model']);
      expect(restored.removedModels, ['llama3-8b-8192']);
    });

    test('provider lama tanpa daftar model tetap terbaca', () {
      final restored = ApiProvider.fromJson(
        jsonDecode(jsonEncode(provider.toJson())) as Map<String, dynamic>,
      );

      expect(restored.customModels, isEmpty);
      expect(restored.removedModels, isEmpty);
    });

    test('copyWith preserves unmasked fields', () {
      final edited = provider.copyWith(model: 'mixtral-8x7b');
      expect(edited.model, 'mixtral-8x7b');
      expect(edited.id, provider.id);
      expect(edited.name, provider.name);
    });

    test('bearerToken memakai API Key', () {
      expect(provider.bearerToken, 'gsk-super-secret');
    });

    test('bearerToken null bila tanpa API Key', () {
      const noKey = ApiProvider(
        id: 'x',
        name: 'x',
        baseUrl: 'https://api.openai.com/v1',
        model: 'gpt-4o',
      );
      expect(noKey.bearerToken, isNull);
    });

    test('fromJson mengabaikan field OAuth lama (backward-compatible)', () {
      // Metadata provider lama di Hive bisa masih memuat authType/oauthConfig;
      // field itu tidak lagi dipakai dan harus diabaikan tanpa error.
      final legacy = ApiProvider.fromJson({
        'id': 'old',
        'name': 'Old',
        'baseUrl': 'https://api.openai.com/v1',
        'model': 'gpt-4o',
        'authType': 'oauth',
        'oauthConfig': {'clientId': 'client-1'},
      });

      expect(legacy.id, 'old');
      expect(legacy.baseUrl, 'https://api.openai.com/v1');
      expect(legacy.bearerToken, isNull);
    });

    test('toJson membawa providerName & catalogId, tetap tanpa apiKey', () {
      const entry = ApiProvider(
        id: 'p1',
        name: 'Kerja',
        providerName: 'Groq',
        catalogId: 'groq',
        baseUrl: 'https://api.groq.com/openai/v1',
        model: 'llama-3.3-70b-versatile',
        apiKey: 'secret',
      );

      final json = entry.toJson();
      expect(json['providerName'], 'Groq');
      expect(json['catalogId'], 'groq');
      expect(json.containsKey('apiKey'), isFalse);
    });

    test('fromJson memulihkan providerName & catalogId', () {
      const entry = ApiProvider(
        id: 'p1',
        name: 'Kerja',
        providerName: 'Groq',
        catalogId: 'groq',
        baseUrl: 'https://api.groq.com/openai/v1',
        model: 'llama-3.3-70b-versatile',
      );

      final restored = ApiProvider.fromJson(
        jsonDecode(jsonEncode(entry.toJson())) as Map<String, dynamic>,
      );

      expect(restored.providerName, 'Groq');
      expect(restored.catalogId, 'groq');
      expect(restored.usesTemplate, isTrue);
    });

    test('data lama tanpa providerName/catalogId tetap terbaca', () {
      final legacy = ApiProvider.fromJson({
        'id': 'old',
        'name': 'Groq Cloud',
        'baseUrl': 'https://api.groq.com/openai/v1',
        'model': 'llama-3.3-70b-versatile',
      });

      // Nama label dipakai sebagai nama provider agar kartu daftar tetap
      // informatif; catalogId diisi saat normalisasi di repository.
      expect(legacy.providerName, 'Groq Cloud');
      expect(legacy.catalogId, isNull);
      expect(legacy.usesTemplate, isFalse);
    });

    test('usesTemplate false untuk provider custom', () {
      final custom = provider.copyWith(catalogId: kCustomCatalogId);
      expect(custom.usesTemplate, isFalse);
    });

    test('authType default apiKey dan ikut tersimpan', () {
      expect(provider.authType, AuthType.apiKey);
      expect(provider.usesOAuth, isFalse);
      expect(provider.toJson()['authType'], 'apiKey');
    });

    test('provider OAuth menyimpan penanda tanpa token di JSON', () {
      final oauth = provider.copyWith(
        authType: AuthType.oauth,
        oauthProvider: kClineOAuthCatalogId,
        oauthSession: OAuthSession(
          accessToken: 'access-rahasia',
          refreshToken: 'refresh-rahasia',
          expiresAt: DateTime.utc(2026, 10, 28, 12),
          userId: 'usr-1',
        ),
      );

      final json = oauth.toJson();
      expect(json['authType'], 'oauth');
      expect(json['oauthProvider'], kClineOAuthCatalogId);
      expect(jsonEncode(json), isNot(contains('access-rahasia')));
      expect(jsonEncode(json), isNot(contains('refresh-rahasia')));
    });

    test('fromJson memulihkan authType, penanda, dan tanpa sesi', () {
      final oauth = provider.copyWith(
        authType: AuthType.oauth,
        oauthProvider: kClineOAuthCatalogId,
        oauthSession: OAuthSession(
          accessToken: 'a',
          refreshToken: 'r',
          expiresAt: DateTime.utc(2026, 10, 28, 12),
        ),
      );
      final restored = ApiProvider.fromJson(
        jsonDecode(jsonEncode(oauth.toJson())) as Map<String, dynamic>,
      );

      expect(restored.authType, AuthType.oauth);
      expect(restored.oauthProvider, kClineOAuthCatalogId);
      expect(restored.usesOAuth, isTrue);
      expect(restored.oauthSession, isNull);
      expect(restored.bearerToken, isNull);
    });

    test('bearerToken memakai sesi OAuth, bukan apiKey', () {
      final oauth = provider.copyWith(
        authType: AuthType.oauth,
        oauthProvider: kClineOAuthCatalogId,
        oauthSession: OAuthSession(
          accessToken: 'token-sesi',
          refreshToken: 'r',
          expiresAt: DateTime.utc(2026, 10, 28, 12),
        ),
      );

      expect(oauth.bearerToken, 'token-sesi');
      expect(oauth.copyWith(clearOAuthSession: true).bearerToken, isNull);
    });

    test('authType tak dikenal jatuh ke apiKey', () {
      final restored = ApiProvider.fromJson({
        'id': 'x',
        'name': 'X',
        'baseUrl': 'https://api.openai.com/v1',
        'model': 'gpt-4o',
        'authType': 'samar',
      });

      expect(restored.authType, AuthType.apiKey);
    });

    test('bentuk OAuth lama dibaca sebagai API key', () {
      final legacy = ApiProvider.fromJson({
        'id': 'old',
        'name': 'Old',
        'baseUrl': 'https://api.openai.com/v1',
        'model': 'gpt-4o',
        'authType': 'oauth',
        'oauthConfig': {'clientId': 'client-1'},
      });

      expect(legacy.authType, AuthType.apiKey);
      expect(legacy.oauthProvider, isNull);
      expect(legacy.bearerToken, isNull);
    });
  });
}
