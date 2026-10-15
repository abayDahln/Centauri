import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/app_constants.dart';

/// Kegagalan secure storage (native OS) yang aman ditampilkan ke pengguna.
/// Tidak pernah memuat API key (NFR-01).
class SecureStorageException implements Exception {
  SecureStorageException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Penyimpanan terenkripsi native OS untuk API Key (NFR-01).
/// Hanya API Key yang masuk sini; metadata provider disimpan di Hive.
///
/// Konfigurasi per-platform sengaja eksplisit agar key benar-benar terlindungi
/// oleh keystore OS (Android Keystore / Windows DPAPI):
///  - Android: EncryptedSharedPreferences (AES-256, master key di Keystore).
///  - Windows: DPAPI (data dienkripsi dengan kredensial akun pengguna).
///  - iOS/macOS: Keychain (default aman).
class SecureStorageService {
  SecureStorageService._internal();
  static final SecureStorageService _instance =
      SecureStorageService._internal();
  factory SecureStorageService() => _instance;

  static const AndroidOptions _androidOptions = AndroidOptions(
    // Master key disimpan di Android Keystore, bukan di SharedPreferences
    // biasa; ini jalur enkripsi standar yang direkomendasikan plugin.
    encryptedSharedPreferences: true,
    // Bila data tidak bisa didekripsi (mis. keystore berubah setelah restore
    // backup / reinstall), jangan crash: reset agar user bisa mengisi ulang.
    resetOnError: true,
  );

  static const WindowsOptions _windowsOptions = WindowsOptions(
    // false = skema penyimpanan baru (DPAPI) yang tidak menoleransi karakter
    // terlarang di nama key; id provider kita aman (uuid + prefix).
    useBackwardCompatibility: false,
  );

  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  static const MacOsOptions _macOsOptions = MacOsOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: _androidOptions,
    wOptions: _windowsOptions,
    iOptions: _iosOptions,
    mOptions: _macOsOptions,
  );

  String _keyFor(String providerId) =>
      '${AppConstants.apiKeyPrefix}$providerId';

  String _tokenKeyFor(String providerId) =>
      '${AppConstants.oauthTokenPrefix}$providerId';

  /// Simpan API Key. Melempar [SecureStorageException] bila native storage
  /// gagal, agar kegagalan tidak senyap (key tidak tersimpan tanpa disadari).
  Future<void> saveApiKey(String providerId, String apiKey) async {
    try {
      await _storage.write(key: _keyFor(providerId), value: apiKey);
    } catch (e) {
      throw SecureStorageException(
        'Gagal menyimpan API key secara terenkripsi: $e',
      );
    }
  }

  /// Baca API Key. Null bila belum ada. Melempar [SecureStorageException]
  /// hanya bila kegagalan bukan sekadar "key tidak ditemukan".
  Future<String?> readApiKey(String providerId) async {
    try {
      return await _storage.read(key: _keyFor(providerId));
    } catch (e) {
      throw SecureStorageException(
        'Gagal membaca API key terenkripsi: $e',
      );
    }
  }

  /// Hapus API Key. Kegagalan penghapusan tidak fatal (best-effort).
  Future<void> deleteApiKey(String providerId) async {
    try {
      await _storage.delete(key: _keyFor(providerId));
    } catch (e) {
      // Key mungkin belum ada / storage belum siap. Jangan gagalkan operasi
      // hapus provider; key yatim tidak berbahaya (tak ada provider-nya).
      throw SecureStorageException('Gagal menghapus API key: $e');
    }
  }

  // ------------------------------------------------------- oauth token set --

  /// Simpan token set OAuth (JSON) secara terenkripsi. Melempar
  /// [SecureStorageException] bila gagal, agar token tidak hilang senyap.
  Future<void> saveTokenSet(String providerId, String json) async {
    try {
      await _storage.write(key: _tokenKeyFor(providerId), value: json);
    } catch (e) {
      throw SecureStorageException(
        'Gagal menyimpan token OAuth secara terenkripsi: $e',
      );
    }
  }

  /// Baca token set OAuth (JSON). Null bila belum ada.
  Future<String?> readTokenSet(String providerId) async {
    try {
      return await _storage.read(key: _tokenKeyFor(providerId));
    } catch (e) {
      throw SecureStorageException(
        'Gagal membaca token OAuth terenkripsi: $e',
      );
    }
  }

  /// Hapus token set OAuth (best-effort).
  Future<void> deleteTokenSet(String providerId) async {
    try {
      await _storage.delete(key: _tokenKeyFor(providerId));
    } catch (e) {
      throw SecureStorageException('Gagal menghapus token OAuth: $e');
    }
  }
}
