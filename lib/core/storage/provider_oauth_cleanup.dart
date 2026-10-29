import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'local_storage_service.dart';
import 'secure_storage_service.dart';

/// Pembersih provider OAuth generasi pertama (Qoder, GitHub Copilot, dan
/// sejenisnya).
///
/// Entri lama itu tidak punya API Key dan tidak pernah bisa berfungsi, jadi
/// metadata Hive-nya dibuang dan token terenkripsinya ikut dihapus. Provider
/// OAuth baru (Cline) punya penanda `oauthProvider` sehingga tidak ikut
/// terhapus — lihat [isLegacyOAuthProviderJson].
///
/// Dipanggil sekali dari `main` setelah [LocalStorageService] siap. Tidak
/// pernah melempar: kegagalan dicatat agar tidak meninggalkan jendela kosong.
Future<void> cleanupLegacyOAuthProviders({
  LocalStorageService? localStorage,
  SecureStorageService? secureStorage,
}) async {
  final storage = localStorage ?? LocalStorageService();
  final secure = secureStorage ?? SecureStorageService();
  try {
    final entries = storage.readProvidersJsonById();
    if (entries.isEmpty) return;

    final oauthIds = <String>[];
    final keptIds = <String>[];
    for (final entry in entries.entries) {
      if (isLegacyOAuthProviderJson(entry.value)) {
        oauthIds.add(entry.key);
      } else {
        keptIds.add(entry.key);
      }
    }
    if (oauthIds.isEmpty) return;

    for (final id in oauthIds) {
      try {
        await storage.deleteProviderJson(id);
        await secure.deleteApiKey(id);
      } catch (e) {
        // Satu entri gagal tidak boleh menghentikan pembersihan entri lain.
        debugPrint('[cleanup] gagal membuang provider lama $id: $e');
      }
      await secure.deleteLegacyOAuthToken(id);
    }

    // Provider aktif tidak boleh menunjuk entri yang baru saja dibuang.
    final activeId = storage.activeProviderId;
    if (activeId != null && oauthIds.contains(activeId)) {
      if (keptIds.isEmpty) {
        await storage.clearActiveProviderId();
      } else {
        await storage.setActiveProviderId(keptIds.first);
      }
    }
  } catch (e) {
    // Migrasi bersifat best-effort: app tetap jalan meski pembersihan gagal.
    debugPrint('[cleanup] gagal membersihkan provider OAuth lama: $e');
  }
}

/// True bila JSON provider memakai bentuk OAuth generasi pertama. Metadata
/// lama memuat objek `oauthConfig` dan/atau `authType: "oauth"` tanpa penanda
/// `oauthProvider`. Provider OAuth baru (mis. Cline) selalu punya penanda itu,
/// sehingga tidak boleh ikut dibuang.
@visibleForTesting
bool isLegacyOAuthProviderJson(String json) {
  try {
    final map = jsonDecode(json);
    if (map is! Map) return false;
    if (map.containsKey('oauthConfig')) return true;
    return map['authType'] == 'oauth' && map['oauthProvider'] == null;
  } catch (_) {
    return false;
  }
}
