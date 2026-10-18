import '../entities/api_provider.dart';

abstract class ApiProviderRepository {
  /// Semua provider tersimpan (tanpa API Key; key dibaca terpisah).
  Future<List<ApiProvider>> getProviders();

  /// Provider aktif beserta API Key-nya, atau null jika belum ada provider
  /// yang dikonfigurasi.
  Future<ApiProvider?> getActiveProvider();

  /// Provider beserta API Key-nya berdasarkan [id], atau null bila tidak
  /// ditemukan. Dipakai agar Test Connection saat edit bisa memakai key
  /// tersimpan bila form tidak mengisi key baru.
  Future<ApiProvider?> getProviderById(String id);

  /// Menyimpan (tambah/edit) metadata provider. Jika [ApiProvider.apiKey]
  /// null, key lama di secure storage dipertahankan.
  Future<void> saveProvider(ApiProvider provider);

  /// Menghapus API Key tersimpan milik [id] dari secure storage. Dipanggil saat
  /// Simpan setelah pengguna menekan Reset di form provider, sehingga Batal
  /// tetap mempertahankan key lama.
  Future<void> clearApiKey(String id);

  Future<void> deleteProvider(String id);

  Future<void> setActiveProvider(String id);
}
