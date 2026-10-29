import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/l10n/l10n.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/datasources/ai_api_service.dart';
import '../../data/datasources/cline_oauth_loopback.dart';
import '../../data/datasources/cline_oauth_service.dart';
import '../../data/repositories/api_provider_repository_impl.dart';
import '../../domain/entities/api_provider.dart';
import '../../domain/entities/oauth_session.dart';
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

/// Klien OAuth Cline (login akun, refresh sesi, saldo).
final clineOAuthServiceProvider = Provider<ClineOAuthService>(
  (ref) => const ClineOAuthService(),
);

/// Pembuat server callback login Cline.
///
/// Seam uji: widget test tidak membuka socket sungguhan, cukup mengganti
/// provider ini dengan fungsi yang mengembalikan null (alur langsung ke
/// tempel tautan).
final clineLoopbackProvider = Provider<Future<ClineLoopbackServer?> Function()>(
  (ref) => ClineLoopbackServer.start,
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
    AuthType authType = AuthType.apiKey,
    String? oauthProvider,
    OAuthSession? oauthSession,
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
            authType: authType,
            oauthProvider: oauthProvider,
            oauthSession: oauthSession,
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
        // Pindah jenis kredensial (API key ↔ akun, atau antar akun) berarti
        // sesi lama tidak berlaku lagi.
        if (existing.oauthProvider != oauthProvider) {
          await repository.clearOAuthSession(targetId);
        }
        final updated = existing.copyWith(
          oauthSession: oauthSession,
          name: name.trim(),
          providerName: providerName.trim(),
          catalogId: catalogId,
          baseUrl: baseUrl.trim(),
          model: model.trim(),
          apiKey: apiKey,
          authType: authType,
          oauthProvider: oauthProvider,
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

  /// Hubungkan akun Cline: validasi tautan lalu simpan provider beserta sesinya.
  ///
  /// Jaringan dipanggil lebih dulu supaya tautan yang salah tidak meninggalkan
  /// provider setengah jadi. Mengembalikan id provider (baru atau lama) dan
  /// sesinya; kegagalan koneksi dilempar apa adanya
  /// ([ApiConnectionException]), sedangkan kegagalan penyimpanan masuk ke
  /// state seperti [saveProvider].
  Future<({String id, OAuthSession session})> connectCline({
    String? id,
    required String name,
    required String providerName,
    required String catalogId,
    required String baseUrl,
    required String model,
    required String link,
    List<String> customModels = const [],
    List<String> removedModels = const [],
  }) async {
    final session = await ref.read(clineOAuthServiceProvider).connect(link);
    return _saveOAuthProvider(
      id: id,
      name: name,
      providerName: providerName,
      catalogId: catalogId,
      baseUrl: baseUrl,
      model: model,
      session: session,
      oauthProvider: kClineOAuthCatalogId,
      customModels: customModels,
      removedModels: removedModels,
    );
  }

  /// Simpan provider akun beserta sesinya; dipakai semua provider OAuth.
  Future<({String id, OAuthSession session})> _saveOAuthProvider({
    required String? id,
    required String name,
    required String providerName,
    required String catalogId,
    required String baseUrl,
    required String model,
    required OAuthSession session,
    required String oauthProvider,
    required List<String> customModels,
    required List<String> removedModels,
  }) async {
    final isNew = id == null;
    final targetId = id ?? const Uuid().v4();
    final current = state.value;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(apiProviderRepositoryProvider);
      final existing = isNew
          ? null
          : current?.providers.where((p) => p.id == id).firstOrNull;
      if (!isNew && existing == null) {
        throw StateError(l10nOf(ref).providerNotFound);
      }

      final provider =
          (existing ??
                  ApiProvider(
                    id: targetId,
                    name: name,
                    baseUrl: baseUrl,
                    model: model,
                  ))
              .copyWith(
                name: name.trim(),
                providerName: providerName.trim(),
                catalogId: catalogId,
                baseUrl: baseUrl.trim(),
                model: model.trim(),
                authType: AuthType.oauth,
                oauthProvider: oauthProvider,
                oauthSession: session,
                customModels: customModels,
                removedModels: removedModels,
              );
      await repository.saveProvider(provider);
      // Provider baru langsung dipakai; provider lama tetap seperti sebelumnya.
      if (isNew) await repository.setActiveProvider(targetId);

      return _loadState();
    });
    return (id: targetId, session: session);
  }

  /// Keluar dari akun provider: hapus sesinya, metadata provider tetap ada.
  Future<void> disconnectAccount(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(apiProviderRepositoryProvider);
      await repository.clearOAuthSession(id);
      return _loadState();
    });
  }
}
