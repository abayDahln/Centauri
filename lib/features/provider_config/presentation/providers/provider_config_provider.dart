import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/datasources/ai_api_service.dart';
import '../../data/repositories/api_provider_repository_impl.dart';
import '../../domain/entities/api_provider.dart';
import '../../domain/repositories/api_provider_repository.dart';

final apiProviderRepositoryProvider = Provider<ApiProviderRepository>((ref) {
  return ApiProviderRepositoryImpl(
    localStorage: LocalStorageService(),
    secureStorage: SecureStorageService(),
  );
});

final aiApiServiceProvider = Provider<AiApiService>((ref) => AiApiService());

class ProviderConfigState {
  const ProviderConfigState({this.providers = const [], this.activeProvider});

  final List<ApiProvider> providers;
  final ApiProvider? activeProvider;

  ProviderConfigState copyWith({
    List<ApiProvider>? providers,
    ApiProvider? activeProvider,
  }) {
    return ProviderConfigState(
      providers: providers ?? this.providers,
      activeProvider: activeProvider ?? this.activeProvider,
    );
  }
}

final providerConfigProvider =
    AsyncNotifierProvider<ProviderConfigNotifier, ProviderConfigState>(
      ProviderConfigNotifier.new,
    );

class ProviderConfigNotifier extends AsyncNotifier<ProviderConfigState> {
  @override
  Future<ProviderConfigState> build() async {
    return _loadState();
  }

  Future<ProviderConfigState> _loadState() async {
    final repository = ref.read(apiProviderRepositoryProvider);
    final providers = await repository.getProviders();
    final active = await repository.getActiveProvider();
    return ProviderConfigState(providers: providers, activeProvider: active);
  }

  /// Tambah (id == null) atau edit provider. [apiKey] null berarti
  /// pertahankan key lama di secure storage.
  Future<void> saveProvider({
    String? id,
    required String name,
    required String baseUrl,
    required String model,
    String? apiKey,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(apiProviderRepositoryProvider);

      if (id == null) {
        await repository.saveProvider(
          ApiProvider(
            id: const Uuid().v4(),
            name: name.trim(),
            baseUrl: baseUrl.trim(),
            model: model.trim(),
            apiKey: apiKey,
          ),
        );
      } else {
        final current = state.value;
        final existing = current?.providers
            .where((p) => p.id == id)
            .firstOrNull;
        if (existing == null) {
          throw StateError('Provider tidak ditemukan.');
        }
        await repository.saveProvider(
          existing.copyWith(
            name: name.trim(),
            baseUrl: baseUrl.trim(),
            model: model.trim(),
            apiKey: apiKey,
          ),
        );
      }

      return _loadState();
    });
  }

  Future<void> deleteProvider(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(apiProviderRepositoryProvider);
      await repository.deleteProvider(id);
      return _loadState();
    });
  }

  Future<void> setActiveProvider(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(apiProviderRepositoryProvider);
      await repository.setActiveProvider(id);
      return _loadState();
    });
  }

  /// Validasi kredensial ke endpoint provider (FR-01).
  /// Melempar [ApiConnectionException] jika gagal.
  Future<void> testConnection(ApiProvider provider) async {
    await ref.read(aiApiServiceProvider).testConnection(provider);
  }
}
