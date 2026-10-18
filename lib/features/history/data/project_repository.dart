import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage_service.dart';
import '../domain/project.dart';
import 'session_folder_store.dart';

/// Akses penyimpanan proyek. Sejak konsep "satu folder per sesi":
///
/// - **Sumber kebenaran** = folder sesi (`SessionFolderStore`) berisi
///   `manifest.json` + satu file HTML per halaman.
/// - Hive hanya menyimpan *pointer* project aktif (meta box); kotak JSON
///   lama (`centauri_projects`) tetap diisi sebagai cadangan migrasi
///   (lihat `SessionMigrator`) tapi tidak dibaca lagi di semua jalur normal.
///
/// Semua metode IO sinkron: folder root dihitung saat init aplikasi, jadi
/// baca/tulis file per-akses tetap murah saat dipanggil dari UI.
class ProjectRepository {
  ProjectRepository({LocalStorageService? storage, this.sessions})
    : _storage = storage ?? LocalStorageService();

  final LocalStorageService _storage;
  SessionFolderStore? sessions;

  SessionFolderStore get _sessionStore {
    final direct = sessions;
    if (direct != null) return direct;
    return sessions = SessionFolderStore(_defaultRoot());
  }

  /// Root tanpa init asinkron: pakai hasil init bila ada, garis cadangan
  /// Windows memakai env LOCALAPPDATA (edge case yang jarang terjadi: app
  /// berjalan sebelum LocalStorageService.init selesai).
  Directory _defaultRoot() {
    final preset = _storage.sessionsRoot;
    if (preset != null) return preset;
    final env = Platform.environment['LOCALAPPDATA'];
    if (env != null && env.isNotEmpty) {
      return Directory(
        '$env${Platform.pathSeparator}Centauri${Platform.pathSeparator}sessions',
      );
    }
    // Fallback terakhir (selain Windows tanpa env): biarkan konservatif,
    // tanpa menimpa apa pun — store gagal disimpan hanya akan tercatat.
    return Directory.systemTemp;
  }

  /// Semua proyek dari folder sesi, urut pengubahan terbaru.
  List<Project> getAll() {
    try {
      return _sessionStore.loadAll();
    } catch (e) {
      // Daftar riwayat tidak boleh mati total gara-gara satu folder rusak.
      return const [];
    }
  }

  /// Lihat `SessionFolderStore.save`: tulis manifest + file HTML + pointer.
  void save(Project project) {
    _sessionStore.save(project);
    if (_storage.activeProjectId == null) {
      _storage.setActiveProjectId(project.id);
    }
  }

  Future<void> delete(String id) async {
    _sessionStore.delete(id);
    if (_storage.activeProjectId == id) {
      await _storage.clearActiveProjectId();
    }
  }

  String? get activeProjectId => _storage.activeProjectId;

  Future<void> setActiveProjectId(String id) => _storage.setActiveProjectId(id);

  Future<void> clearActiveProjectId() => _storage.clearActiveProjectId();
}

final projectRepositoryProvider = Provider<ProjectRepository>(
  (ref) => ProjectRepository(),
);
