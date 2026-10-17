import 'dart:convert';

import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/api_provider.dart';
import '../../domain/repositories/api_provider_repository.dart';
import '../catalog/provider_catalog.dart';

class ApiProviderRepositoryImpl implements ApiProviderRepository {
  ApiProviderRepositoryImpl({
    LocalStorageService? localStorage,
    SecureStorageService? secureStorage,
  }) : _localStorage = localStorage ?? LocalStorageService(),
       _secureStorage = secureStorage ?? SecureStorageService();

  final LocalStorageService _localStorage;
  final SecureStorageService _secureStorage;

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
    return _withApiKey(provider);
  }

  @override
  Future<ApiProvider?> getProviderById(String id) async {
    final providers = await getProviders();
    ApiProvider? provider;
    for (final p in providers) {
      if (p.id == id) provider = p;
    }
    if (provider == null) return null;
    return _withApiKey(provider);
  }

  /// Menempelkan API Key runtime (dari secure storage) ke [provider].
  Future<ApiProvider> _withApiKey(ApiProvider provider) async {
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
  Future<void> clearApiKey(String id) => _secureStorage.deleteApiKey(id);

  @override
  Future<void> deleteProvider(String id) async {
    await _localStorage.deleteProviderJson(id);
    await _secureStorage.deleteApiKey(id);

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
