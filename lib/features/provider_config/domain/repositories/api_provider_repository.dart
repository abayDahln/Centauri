import '../entities/api_provider.dart';

abstract class ApiProviderRepository {
  /// Semua provider tersimpan (tanpa API Key; key dibaca terpisah).
  Future<List<ApiProvider>> getProviders();

  /// Provider aktif beserta API Key-nya yang sudah didekripsi, atau null
  /// jika belum ada provider yang dikonfigurasi.
  Future<ApiProvider?> getActiveProvider();

  /// Provider beserta API Key-nya yang sudah didekripsi berdasarkan [id],
  /// atau null bila tidak ditemukan. Dipakai agar Test Connection saat edit
  /// bisa memakai key tersimpan bila form tidak mengisi key baru.
  Future<ApiProvider?> getProviderById(String id);

  /// Menyimpan (tambah/edit) metadata provider. Jika [ApiProvider.apiKey]
  /// null, key lama di secure storage dipertahankan.
  Future<void> saveProvider(ApiProvider provider);

  Future<void> deleteProvider(String id);

  Future<void> setActiveProvider(String id);
}
