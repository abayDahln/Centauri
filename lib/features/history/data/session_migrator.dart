import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/storage/local_storage_service.dart';
import '../domain/project.dart';
import 'session_folder_store.dart';

/// Migrasi satu kali proyek-proyek lama dari Hive (JSON utuh, HTML inline)
/// ke konsep baru: satu folder per sesi (`SessionFolderStore`).
///
/// Prinsip **copy-only** seperti migrasi box Hive: folder yang sudah
/// memuat `manifest.json` tidak pernah disentuh — dia selalu lebih baru
/// daripada salinan Hive. Entri Hive tetap dipertahankan sebagai cadangan.
class SessionMigrator {
  SessionMigrator(this._storage, this._sessions);

  final LocalStorageService _storage;
  final SessionFolderStore _sessions;

  /// Pindahkan semua proyek Hive yang belum punya folder sesi. Idempoten:
  /// dipanggil ulang tetap aman (flag + cek `.manifest` per folder).
  void migrateHiveProjects() {
    // Kotak sumber tidak sehat (gagal terbuka / sudah ditutup): JANGAN
    // menulis flag — migrasi ulang akan dicoba di boot berikutnya, dan
    // proyek lama tidak boleh hilang dari riwayat begitu saja.
    if (!_storage.projectsBoxHealthy) return;
    if (_storage.sessionsMigrated) return;
    var migrated = 0;
    for (final json in _storage.readAllProjectsJson()) {
      try {
        final legacy = Project.fromJson(
          jsonDecode(json) as Map<String, dynamic>,
        );
        final dir = _sessions.folderFor(legacy.id);
        final manifest = File(
          '${dir.path}${Platform.pathSeparator}$kSessionManifestName',
        );
        if (manifest.existsSync()) continue; // folder sudah baru: copy-only.
        _sessions.save(legacy);
        migrated++;
      } catch (e) {
        // Satu entri rusak tidak boleh menghentikan migrasi sisanya.
        debugPrint('[migrasi] gagal migrasi proyek: $e');
      }
    }
    if (migrated > 0) {
      debugPrint('[migrasi] $migrated proyek dipindahkan ke folder sesi');
    }
    // Flag tetap ditulis walau tidak ada yang migrasi: berjalannya cek
    // pertama berarti daftar Hive sudah dievaluasi terhadap konsep baru.
    _storage.setSessionsMigrated();
  }
}
