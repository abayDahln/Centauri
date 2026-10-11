import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/app_constants.dart';

/// Penyimpanan terenkripsi native OS untuk API Key (NFR-01).
/// Hanya API Key yang masuk sini; metadata provider disimpan di Hive.
class SecureStorageService {
  SecureStorageService._internal();
  static final SecureStorageService _instance =
      SecureStorageService._internal();
  factory SecureStorageService() => _instance;

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> saveApiKey(String providerId, String apiKey) {
    return _storage.write(
      key: '${AppConstants.apiKeyPrefix}$providerId',
      value: apiKey,
    );
  }

  Future<String?> readApiKey(String providerId) {
    return _storage.read(key: '${AppConstants.apiKeyPrefix}$providerId');
  }

  Future<void> deleteApiKey(String providerId) {
    return _storage.delete(key: '${AppConstants.apiKeyPrefix}$providerId');
  }
}
