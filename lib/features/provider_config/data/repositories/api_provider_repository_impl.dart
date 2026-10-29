import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/api_provider.dart';
import '../../domain/entities/oauth_session.dart';
import '../../domain/repositories/api_provider_repository.dart';
import '../catalog/provider_catalog.dart';
import '../datasources/cline_oauth_service.dart';

class ApiProviderRepositoryImpl implements ApiProviderRepository {
  ApiProviderRepositoryImpl({
    LocalStorageService? localStorage,
    SecureStorageService? secureStorage,
    ClineOAuthService? clineOAuth,
  }) : _localStorage = localStorage ?? LocalStorageService(),
       _secureStorage = secureStorage ?? SecureStorageService(),
       _clineOAuth = clineOAuth ?? const ClineOAuthService();

  final LocalStorageService _localStorage;
  final SecureStorageService _secureStorage;
  final ClineOAuthService _clineOAuth;

  @override
  Future<List<ApiProvider>> getProviders() async {
    final jsonList = _localStorage.readAllProvidersJson();
    return jsonList
        .map(
          (json) => _normalize(
            ApiProvider.fromJson(jsonDecode(json) as Map<String, dynamic>),
          ),
        )
        .toList();
  }

  /// Melengkapi field baru pada provider lama: `catalogId` dicocokkan dari
  /// Base URL ke katalog template; bila tidak ada yang cocok, dianggap custom.
  /// Provider baru selalu sudah membawa `catalogId`, jadi langsung dikembalikan.
  ApiProvider _normalize(ApiProvider provider) {
    if (provider.catalogId != null) return provider;

    final base = provider.normalizedBaseUrl;
    if (base.isNotEmpty) {
      for (final entry in ProviderCatalog.all) {
        if (entry.baseUrl.trim() == base) {
          return provider.copyWith(
            catalogId: entry.id,
            providerName: entry.name,
          );
        }
      }
    }
    return provider.copyWith(catalogId: kCustomCatalogId);
  }

  @override
  Future<ApiProvider?> getActiveProvider() async {
    final providers = await getProviders();
    if (providers.isEmpty) return null;

    final activeId = _localStorage.activeProviderId;
    final provider = providers.firstWhere(
      (p) => p.id == activeId,
      orElse: () => providers.first,
    );
    return _withCredentials(provider);
  }

  @override
  Future<ApiProvider?> getProviderById(String id) async {
    final providers = await getProviders();
    ApiProvider? provider;
    for (final p in providers) {
      if (p.id == id) provider = p;
    }
    if (provider == null) return null;
    return _withCredentials(provider);
  }

  /// Menempelkan kredensial runtime ke [provider]: sesi OAuth untuk provider
  /// yang masuk dengan akun, API Key untuk sisanya. Kredensial tidak pernah
  /// disimpan di Hive, jadi selalu dibaca ulang dari secure storage.
  Future<ApiProvider> _withCredentials(ApiProvider provider) async {
    if (provider.usesOAuth) {
      final session = await _secureStorage.readOAuthSession(provider.id);
      if (session == null) return provider;
      // Hanya Cline yang endpoint refresh-nya diketahui. Sesi provider akun
      // lain dipakai apa adanya; bila kedaluwarsa, pengguna masuk ulang.
      if (provider.oauthProvider != kClineOAuthCatalogId) {
        return provider.copyWith(oauthSession: session);
      }
      return provider.copyWith(
        oauthSession: await _refreshIfExpiring(provider.id, session),
      );
    }
    final apiKey = await _secureStorage.readApiKey(provider.id);
    return provider.copyWith(apiKey: apiKey);
  }

  /// Perpanjang sesi yang hampir habis (margin 5 menit) dan simpan hasilnya.
  ///
  /// Cline merotasi refresh token, jadi access + refresh token baru harus
  /// ditulis bersamaan. Kegagalan refresh tidak menggagalkan pemuatan
  /// provider: sesi lama dikembalikan supaya aplikasi tetap terbuka, dan
  /// request berikutnya yang melaporkan token tidak berlaku.
  Future<OAuthSession> _refreshIfExpiring(
    String providerId,
    OAuthSession session,
  ) async {
    if (!session.isExpiringSoon) return session;
    try {
      final refreshed = await _clineOAuth.refresh(session);
      await _secureStorage.saveOAuthSession(providerId, refreshed);
      return refreshed;
    } on AppErrorDetails catch (e) {
      debugPrint('[oauth] refresh gagal untuk $providerId: ${e.debugLabel}');
      return session;
    }
  }

  @override
  Future<void> saveProvider(ApiProvider provider) async {
    if (provider.usesOAuth) {
      // Sesi null berarti tidak ada sesi baru untuk ditulis; sesi lama sengaja
      // dibiarkan utuh supaya Simpan (mis. hanya ganti model) tidak pernah
      // mengeluarkan pengguna dari akunnya.
      final session = provider.oauthSession;
      if (session != null) {
        await _secureStorage.saveOAuthSession(provider.id, session);
      }
    } else if (provider.apiKey != null) {
      await _secureStorage.saveApiKey(provider.id, provider.apiKey!);
    }
    _localStorage.writeProviderJson(provider.id, jsonEncode(provider.toJson()));

    final activeId = _localStorage.activeProviderId;
    if (activeId == null) {
      await _localStorage.setActiveProviderId(provider.id);
    }
  }

  @override
  Future<void> clearApiKey(String id) => _secureStorage.deleteApiKey(id);

  @override
  Future<void> clearOAuthSession(String id) =>
      _secureStorage.deleteOAuthSession(id);

  @override
  Future<void> deleteProvider(String id) async {
    await _localStorage.deleteProviderJson(id);
    await _secureStorage.deleteApiKey(id);
    await _secureStorage.deleteOAuthSession(id);

    if (_localStorage.activeProviderId == id) {
      final remaining = await getProviders();
      if (remaining.isNotEmpty) {
        await _localStorage.setActiveProviderId(remaining.first.id);
      }
    }
  }

  @override
  Future<void> setActiveProvider(String id) {
    return _localStorage.setActiveProviderId(id);
  }
}
