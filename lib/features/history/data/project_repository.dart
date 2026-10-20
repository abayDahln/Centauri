import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage_service.dart';
import '../domain/project.dart';
import 'session_folder_store.dart';
import 'session_migrator.dart';

/// Akses penyimpanan proyek. Sejak konsep "satu folder per sesi":
///
/// - **Sumber kebenaran** = folder sesi (`SessionFolderStore`) berisi
///   `manifest.json` + satu file HTML per halaman.
/// - Hive hanya menyimpan *pointer* project aktif (meta box); kotak JSON
///   lama (`centauri_projects`) tinggal dipakai `SessionMigrator` sebagai
///   sumber migrasi copy-only.
///
/// Semua metode IO sinkron: folder root dihitung saat init aplikasi, jadi
/// baca/tulis file per-akses tetap murah saat dipanggil dari UI.
///
/// Root sesi tidak tersedia → repository **tidak menulis ke mana-mana**
/// (bukan ke folder temp yang bisa dibersihkan Windows); `isPersisting`
/// melaporkan kondisinya, dan banner penyimpanan punya jalur tampil sendiri.
class ProjectRepository {
  ProjectRepository({LocalStorageService? storage, this.sessions})
    : _storage = storage ?? LocalStorageService();

  final LocalStorageService _storage;
  SessionFolderStore? sessions;

  /// Penyimpanan sesi aktif; null bila folder root tidak tersedia.
  SessionFolderStore? get _sessionStore {
    final direct = sessions;
    if (direct != null) return direct;
    final Directory? root = _storage.sessionsRoot;
    if (root == null) return null;
    return sessions = SessionFolderStore(root);
  }

  /// True bila ada folder sesi aktif yang bisa menampung data.
  bool get isPersisting => _sessionStore != null;

  /// Semua proyek dari folder sesi, urut pengubahan terbaru. Jalur pertama
  /// kali juga menitipkan migrasi proyek Hive -> folder (copy-only).
  List<Project> getAll() {
    final store = _sessionStore;
    if (store == null) {
      _warnOnce();
      return const [];
    }
    try {
      _ensureMigrated(store);
      return store.loadAll();
    } catch (e) {
      // Daftar riwayat tidak boleh mati total gara-gara satu folder rusak.
      return const [];
    }
  }

  bool _migrationChecked = false;

  void _ensureMigrated(SessionFolderStore store) {
    if (_migrationChecked) return;
    _migrationChecked = true;
    SessionMigrator(_storage, store).migrateHiveProjects();
  }

  /// Muat satu sesi utuh (manifest + HTML tiap halaman) langsung dari
  /// foldernya; `null` bila folder tidak ada, rusak, atau root unavailable.
  Project? loadSession(String id) => _sessionStore?.load(id);

  /// Lihat `SessionFolderStore.save`: tulis manifest + file HTML + pointer.
  void save(Project project) {
    final store = _sessionStore;
    if (store == null) {
      _warnOnce();
      return;
    }
    store.save(project);
    if (_storage.activeProjectId == null) {
      _storage.setActiveProjectId(project.id);
    }
  }

  Future<void> delete(String id) async {
    final store = _sessionStore;
    if (store == null) {
      _warnOnce();
    } else {
      store.delete(id);
    }
    if (_storage.activeProjectId == id) {
      await _storage.clearActiveProjectId();
    }
  }

  String? get activeProjectId => _storage.activeProjectId;

  Future<void> setActiveProjectId(String id) => _storage.setActiveProjectId(id);

  Future<void> clearActiveProjectId() => _storage.clearActiveProjectId();

  bool _warnedUnavailable = false;
  void _warnOnce() {
    if (_warnedUnavailable) return;
    _warnedUnavailable = true;
    debugPrint('[riwayat] folder sesi tidak tersedia; penyimpanan nonaktif');
  }
}

final projectRepositoryProvider = Provider<ProjectRepository>(
  (ref) => ProjectRepository(),
);
