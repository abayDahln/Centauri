import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'local_storage_service.dart';
import 'secure_storage_service.dart';

/// Pembersih satu kali: membuang provider lama yang ber-autentikasi OAuth.
///
/// Centauri tidak lagi mendukung login provider; hanya provider berbasis API
/// Key. Provider OAuth yang tersimpan di perangkat (Qoder, GitHub Copilot,
/// dan sejenisnya) tidak punya API Key sehingga tidak mungkin berfungsi —
/// entri Hive-nya dibuang dan token OAuth terenkripsinya ikut dihapus.
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
      if (_isLegacyOAuthProvider(entry.value)) {
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

/// True bila JSON provider lama memakai autentikasi OAuth. Metadata lama masih
/// memuat `authType: "oauth"` dan/atau objek `oauthConfig`.
bool _isLegacyOAuthProvider(String json) {
  try {
    final map = jsonDecode(json);
    if (map is! Map) return false;
    return map['authType'] == 'oauth' || map.containsKey('oauthConfig');
  } catch (_) {
    return false;
  }
}
