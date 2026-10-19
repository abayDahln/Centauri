import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/l10n/l10n.dart';
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

final aiApiServiceProvider = Provider<AiApiService>(
  (ref) => const AiApiService(),
);

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
  /// pertahankan key lama di secure storage. Provider baru langsung dijadikan
  /// aktif. Mengembalikan id provider (baru atau lama).
  Future<String> saveProvider({
    String? id,
    required String name,
    required String providerName,
    required String catalogId,
    required String baseUrl,
    required String model,
    String? apiKey,
    List<String> customModels = const [],
    List<String> removedModels = const [],
  }) async {
    final isNew = id == null;
    final targetId = id ?? const Uuid().v4();
    // Ambil provider saat ini sebelum state diubah ke loading.
    final current = state.value;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(apiProviderRepositoryProvider);

      if (isNew) {
        await repository.saveProvider(
          ApiProvider(
            id: targetId,
            name: name.trim(),
            providerName: providerName.trim(),
            catalogId: catalogId,
            baseUrl: baseUrl.trim(),
            model: model.trim(),
            apiKey: apiKey,
            customModels: customModels,
            removedModels: removedModels,
          ),
        );
        // Provider yang baru ditambahkan langsung dipakai.
        await repository.setActiveProvider(targetId);
      } else {
        final existing = current?.providers
            .where((p) => p.id == id)
            .firstOrNull;
        if (existing == null) {
          throw StateError(l10nOf(ref).providerNotFound);
        }
        final updated = existing.copyWith(
          name: name.trim(),
          providerName: providerName.trim(),
          catalogId: catalogId,
          baseUrl: baseUrl.trim(),
          model: model.trim(),
          apiKey: apiKey,
          customModels: customModels,
          removedModels: removedModels,
        );
        await repository.saveProvider(updated);
      }

      return _loadState();
    });
    return targetId;
  }

  Future<void> deleteProvider(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(apiProviderRepositoryProvider);
      await repository.deleteProvider(id);
      return _loadState();
    });
  }

  /// Menghapus API Key tersimpan milik [id]. Dipanggil setelah Simpan bila
  /// pengguna menekan Reset, lalu memuat ulang state agar provider aktif tidak
  /// lagi membawa key lama.
  Future<void> clearApiKey(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(apiProviderRepositoryProvider);
      await repository.clearApiKey(id);
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
