import '../entities/api_provider.dart';
import '../entities/oauth_token_set.dart';

abstract class ApiProviderRepository {
  /// Semua provider tersimpan (tanpa API Key; key dibaca terpisah).
  Future<List<ApiProvider>> getProviders();

  /// Provider aktif beserta kredensialnya (API Key atau token OAuth yang sudah
  /// di-refresh bila perlu), atau null jika belum ada provider yang
  /// dikonfigurasi.
  Future<ApiProvider?> getActiveProvider();

  /// Provider beserta kredensialnya berdasarkan [id], atau null bila tidak
  /// ditemukan. Dipakai agar Test Connection saat edit bisa memakai kredensial
  /// tersimpan bila form tidak mengisi key baru.
  Future<ApiProvider?> getProviderById(String id);

  /// Menyimpan (tambah/edit) metadata provider. Jika [ApiProvider.apiKey]
  /// null, key lama di secure storage dipertahankan.
  Future<void> saveProvider(ApiProvider provider);

  Future<void> deleteProvider(String id);

  Future<void> setActiveProvider(String id);

  // ------------------------------------------------------------- oauth ----

  /// Token bearer siap pakai (API key atau access token OAuth), melakukan
  /// refresh proaktif bila token OAuth hampir kedaluwarsa. Null bila tidak ada.
  Future<String?> resolveBearerToken(ApiProvider provider);

  /// Simpan token set OAuth (terenkripsi).
  Future<void> saveTokenSet(String providerId, OAuthTokenSet tokens);

  /// Baca token set OAuth, atau null bila belum ada / rusak.
  Future<OAuthTokenSet?> getTokenSet(String providerId);

  /// Hapus token set OAuth.
  Future<void> deleteTokenSet(String providerId);
}
