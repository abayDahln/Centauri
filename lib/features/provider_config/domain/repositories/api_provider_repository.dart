import '../entities/api_provider.dart';

abstract class ApiProviderRepository {
  /// Semua provider tersimpan (tanpa API Key; key dibaca terpisah).
  Future<List<ApiProvider>> getProviders();

  /// Provider aktif beserta API Key-nya yang sudah didekripsi, atau null
  /// jika belum ada provider yang dikonfigurasi.
  Future<ApiProvider?> getActiveProvider();

  /// Menyimpan (tambah/edit) metadata provider. Jika [ApiProvider.apiKey]
  /// null, key lama di secure storage dipertahankan.
  Future<void> saveProvider(ApiProvider provider);

  Future<void> deleteProvider(String id);

  Future<void> setActiveProvider(String id);
}
