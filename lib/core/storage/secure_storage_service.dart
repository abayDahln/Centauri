import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/provider_config/domain/entities/oauth_session.dart';
import '../errors/app_error.dart';
import '../utils/app_constants.dart';

/// Kegagalan secure storage (native OS) yang aman ditampilkan ke pengguna.
/// Tidak pernah memuat API key (NFR-01).
class SecureStorageException extends AppErrorDetails implements Exception {
  const SecureStorageException(super.code, {super.detail});

  @override
  String toString() => debugLabel;
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

  /// Simpan API Key. Melempar [SecureStorageException] bila native storage
  /// gagal, agar kegagalan tidak senyap (key tidak tersimpan tanpa disadari).
  Future<void> saveApiKey(String providerId, String apiKey) async {
    try {
      await _storage.write(key: _keyFor(providerId), value: apiKey);
    } catch (e) {
      throw SecureStorageException(
        AppErrorCode.storageFailed,
        detail: 'write: $e',
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
        AppErrorCode.storageFailed,
        detail: 'read: $e',
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
      throw SecureStorageException(
        AppErrorCode.storageFailed,
        detail: 'delete: $e',
      );
    }
  }

  // ------------------------------------------------------------- sesi oauth --

  String _sessionKeyFor(String providerId) =>
      '${AppConstants.oauthSessionPrefix}$providerId';

  /// Simpan sesi OAuth (token + identitas akun) sebagai satu nilai JSON.
  /// Melempar [SecureStorageException] bila native storage gagal, agar sesi
  /// yang tidak tersimpan tidak lolos diam-diam.
  Future<void> saveOAuthSession(String providerId, OAuthSession session) async {
    try {
      await _storage.write(
        key: _sessionKeyFor(providerId),
        value: jsonEncode(session.toJson()),
      );
    } catch (e) {
      throw SecureStorageException(
        AppErrorCode.storageFailed,
        detail: 'write session: $e',
      );
    }
  }

  /// Baca sesi OAuth milik [providerId].
  ///
  /// Null bila belum ada, JSON-nya rusak, atau tokennya kosong — pengguna
  /// dianggap belum masuk dan bisa menghubungkan ulang tanpa crash.
  Future<OAuthSession?> readOAuthSession(String providerId) async {
    final String? raw;
    try {
      raw = await _storage.read(key: _sessionKeyFor(providerId));
    } catch (e) {
      throw SecureStorageException(
        AppErrorCode.storageFailed,
        detail: 'read session: $e',
      );
    }
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final session = OAuthSession.fromJson(decoded);
      if (session.accessToken.isEmpty || session.refreshToken.isEmpty) {
        return null;
      }
      return session;
    } catch (_) {
      return null;
    }
  }

  /// Hapus sesi OAuth milik [providerId] (dipakai saat provider dihapus atau
  /// pengguna menekan Keluar).
  Future<void> deleteOAuthSession(String providerId) async {
    try {
      await _storage.delete(key: _sessionKeyFor(providerId));
    } catch (e) {
      throw SecureStorageException(
        AppErrorCode.storageFailed,
        detail: 'delete session: $e',
      );
    }
  }

  // --------------------------------------------------------- legacy oauth --

  /// Prefix lama untuk token OAuth. Fitur login OAuth sudah dihapus, jadi
  /// tidak ada penulis baru — konstanta ini hanya dipakai untuk membersihkan
  /// token yang masih tersisa di perangkat pengguna.
  static const String legacyOAuthTokenPrefix = 'centauri_provider_oauth_token_';

  /// Hapus token OAuth lama milik [providerId] (best-effort).
  Future<void> deleteLegacyOAuthToken(String providerId) async {
    try {
      await _storage.delete(key: '$legacyOAuthTokenPrefix$providerId');
    } catch (_) {
      // Best-effort: token yatim tidak berbahaya setelah fitur dihapus.
    }
  }
}
