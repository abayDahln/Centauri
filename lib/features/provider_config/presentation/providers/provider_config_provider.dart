import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/datasources/ai_api_service.dart';
import '../../data/repositories/api_provider_repository_impl.dart';
import '../../data/services/oauth_service_impl.dart';
import '../../domain/entities/api_provider.dart';
import '../../domain/entities/oauth_config.dart';
import '../../domain/entities/oauth_token_set.dart';
import '../../domain/entities/provider_auth_type.dart';
import '../../domain/repositories/api_provider_repository.dart';
import '../../domain/services/oauth_service.dart';

final oauthServiceProvider = Provider<OAuthService>((ref) => OAuthServiceImpl());

final apiProviderRepositoryProvider = Provider<ApiProviderRepository>((ref) {
  return ApiProviderRepositoryImpl(
    localStorage: LocalStorageService(),
    secureStorage: SecureStorageService(),
    oauthService: ref.read(oauthServiceProvider),
  );
});

final aiApiServiceProvider = Provider<AiApiService>((ref) {
  return AiApiService(
    resolveBearerToken: (provider) =>
        ref.read(apiProviderRepositoryProvider).resolveBearerToken(provider),
  );
});

/// Status koneksi OAuth sebuah provider (untuk ditampilkan di UI).
enum OAuthStatus { none, connected, expiring, disconnected }

class ProviderConfigState {
  const ProviderConfigState({
    this.providers = const [],
    this.activeProvider,
    this.oauthStatus = const {},
  });

  final List<ApiProvider> providers;
  final ApiProvider? activeProvider;

  /// Status OAuth per provider id (hanya berisi provider ber-authType oauth).
  final Map<String, OAuthStatus> oauthStatus;

  OAuthStatus statusFor(String providerId) =>
      oauthStatus[providerId] ?? OAuthStatus.none;

  ProviderConfigState copyWith({
    List<ApiProvider>? providers,
    ApiProvider? activeProvider,
    Map<String, OAuthStatus>? oauthStatus,
  }) {
    return ProviderConfigState(
      providers: providers ?? this.providers,
      activeProvider: activeProvider ?? this.activeProvider,
      oauthStatus: oauthStatus ?? this.oauthStatus,
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

    final statuses = <String, OAuthStatus>{};
    for (final provider in providers) {
      if (!provider.usesOAuth) continue;
      final tokens = await repository.getTokenSet(provider.id);
      statuses[provider.id] = _statusFor(tokens);
    }

    return ProviderConfigState(
      providers: providers,
      activeProvider: active,
      oauthStatus: statuses,
    );
  }

  static OAuthStatus _statusFor(OAuthTokenSet? tokens) {
    if (tokens == null) return OAuthStatus.disconnected;
    // Token kedaluwarsa tanpa refresh token tidak bisa dipulihkan otomatis.
    if (tokens.isExpired && !tokens.canRefresh) return OAuthStatus.disconnected;
    if (tokens.needsRefresh) return OAuthStatus.expiring;
    return OAuthStatus.connected;
  }

  /// Tambah (id == null) atau edit provider. [apiKey] null berarti
  /// pertahankan key lama di secure storage. Mengembalikan id provider
  /// (baru atau lama) agar pemanggil bisa langsung menjalankan alur OAuth.
  Future<String> saveProvider({
    String? id,
    required String name,
    required String baseUrl,
    required String model,
    String? apiKey,
    AuthType authType = AuthType.apiKey,
    OAuthConfig? oauthConfig,
  }) async {
    final targetId = id ?? const Uuid().v4();
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(apiProviderRepositoryProvider);

      if (id == null) {
        await repository.saveProvider(
          ApiProvider(
            id: targetId,
            name: name.trim(),
            baseUrl: baseUrl.trim(),
            model: model.trim(),
            apiKey: apiKey,
            authType: authType,
            oauthConfig: oauthConfig,
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
            authType: authType,
            oauthConfig: oauthConfig,
          ),
        );
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

  // ------------------------------------------------------------- oauth ----

  /// Jalankan alur OAuth untuk provider [id] dan simpan token yang diperoleh.
  /// Melempar [OAuthException] bila gagal.
  Future<void> connectOAuth(String id) async {
    final repository = ref.read(apiProviderRepositoryProvider);
    final provider = await repository.getProviderById(id);
    if (provider == null) {
      throw StateError('Provider tidak ditemukan.');
    }
    if (!provider.usesOAuth || provider.oauthConfig == null) {
      throw OAuthException('Provider ini belum dikonfigurasi untuk OAuth.');
    }

    final tokens = await ref.read(oauthServiceProvider).authorize(provider);
    await repository.saveTokenSet(id, tokens);
    state = await AsyncValue.guard(_loadState);
  }

  /// Cabut token OAuth provider [id] (best-effort) lalu hapus dari storage.
  Future<void> disconnectOAuth(String id) async {
    final repository = ref.read(apiProviderRepositoryProvider);
    final provider = await repository.getProviderById(id);
    final tokens = await repository.getTokenSet(id);
    if (provider != null && tokens != null) {
      try {
        await ref.read(oauthServiceProvider).revoke(provider, tokens);
      } catch (_) {
        // Best-effort: tetap hapus token lokal meski revoke gagal.
      }
    }
    await repository.deleteTokenSet(id);
    state = await AsyncValue.guard(_loadState);
  }
}
