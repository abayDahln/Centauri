import 'dart:convert';

import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/api_provider.dart';
import '../../domain/repositories/api_provider_repository.dart';

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
    final apiKey = await _secureStorage.readApiKey(provider.id);
    return provider.copyWith(apiKey: apiKey);
  }

  @override
  Future<ApiProvider?> getProviderById(String id) async {
    final providers = await getProviders();
    ApiProvider? provider;
    for (final p in providers) {
      if (p.id == id) provider = p;
    }
    if (provider == null) return null;
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
