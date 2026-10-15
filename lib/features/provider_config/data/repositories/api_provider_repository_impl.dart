import 'dart:convert';

import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/api_provider.dart';
import '../../domain/entities/oauth_token_set.dart';
import '../../domain/repositories/api_provider_repository.dart';
import '../../domain/services/oauth_service.dart';
import '../services/oauth_service_impl.dart';

class ApiProviderRepositoryImpl implements ApiProviderRepository {
  ApiProviderRepositoryImpl({
    LocalStorageService? localStorage,
    SecureStorageService? secureStorage,
    OAuthService? oauthService,
  }) : _localStorage = localStorage ?? LocalStorageService(),
       _secureStorage = secureStorage ?? SecureStorageService(),
       _oauthService = oauthService ?? OAuthServiceImpl();

  final LocalStorageService _localStorage;
  final SecureStorageService _secureStorage;
  final OAuthService _oauthService;

  @override
  Future<List<ApiProvider>> getProviders() async {
    final jsonList = _localStorage.readAllProvidersJson();
    return jsonList
        .map(
          (json) =>
              ApiProvider.fromJson(jsonDecode(json) as Map<String, dynamic>),
        )
        .toList();
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

  /// Menempelkan kredensial runtime (API Key atau token OAuth) ke [provider].
  ///
  /// Untuk provider OAuth, token di-refresh proaktif bila hampir kedaluwarsa.
  /// Kegagalan refresh tidak melempar: token lama dikembalikan apa adanya
  /// sehingga permintaan berikutnya gagal 401 dan UI dapat menyarankan login
  /// ulang, alih-alih menggagalkan pemuatan provider.
  Future<ApiProvider> _withCredentials(ApiProvider provider) async {
    if (provider.usesOAuth) {
      final tokens = await getTokenSet(provider.id);
      if (tokens == null) return provider;
      var current = tokens;
      if (tokens.needsRefresh && tokens.canRefresh) {
        try {
          current = await _oauthService.refresh(provider, tokens);
          await saveTokenSet(provider.id, current);
        } catch (_) {
          // Biarkan token lama; refresh akan dicoba lagi pada permintaan
          // berikutnya.
        }
      }
      return provider.copyWith(oauthToken: current);
    }

    final apiKey = await _secureStorage.readApiKey(provider.id);
    return provider.copyWith(apiKey: apiKey);
  }

  @override
  Future<void> saveProvider(ApiProvider provider) async {
    if (provider.apiKey != null) {
      await _secureStorage.saveApiKey(provider.id, provider.apiKey!);
    }
    _localStorage.writeProviderJson(provider.id, jsonEncode(provider.toJson()));

    final activeId = _localStorage.activeProviderId;
    if (activeId == null) {
      await _localStorage.setActiveProviderId(provider.id);
    }
  }

  @override
  Future<void> deleteProvider(String id) async {
    // Cabut token OAuth (best-effort) sebelum data dihapus, agar sesi tidak
    // menggantung di sisi provider.
    final tokens = await getTokenSet(id);
    if (tokens != null) {
      final provider = await getProviderById(id);
      if (provider != null) {
        try {
          await _oauthService.revoke(provider, tokens);
        } catch (_) {
          // Best-effort: kegagalan revoke tidak menghalangi penghapusan lokal.
        }
      }
    }

    await _localStorage.deleteProviderJson(id);
    await _secureStorage.deleteApiKey(id);
    await _secureStorage.deleteTokenSet(id);

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

  // ------------------------------------------------------------- oauth ----

  @override
  Future<String?> resolveBearerToken(ApiProvider provider) async {
    final withCredentials = await _withCredentials(provider);
    return withCredentials.bearerToken;
  }

  @override
  Future<void> saveTokenSet(String providerId, OAuthTokenSet tokens) {
    return _secureStorage.saveTokenSet(providerId, jsonEncode(tokens.toJson()));
  }

  @override
  Future<OAuthTokenSet?> getTokenSet(String providerId) async {
    final raw = await _secureStorage.readTokenSet(providerId);
    if (raw == null || raw.isEmpty) return null;
    try {
      return OAuthTokenSet.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      // Token rusak / format lama: anggap belum terhubung.
      return null;
    }
  }

  @override
  Future<void> deleteTokenSet(String providerId) {
    return _secureStorage.deleteTokenSet(providerId);
  }
}
