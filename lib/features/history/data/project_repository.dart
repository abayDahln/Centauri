import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage_service.dart';
import '../domain/project.dart';

/// Akses penyimpanan proyek (Hive). Nilai disimpan sebagai JSON string.
class ProjectRepository {
  ProjectRepository({LocalStorageService? storage})
    : _storage = storage ?? LocalStorageService();

  final LocalStorageService _storage;

  List<Project> getAll() {
    return _storage
        .readAllProjectsJson()
        .map((json) => Project.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }

  void save(Project project) {
    _storage.writeProjectJson(
      project.id,
      jsonEncode(project.toJson()),
    );
    if (_storage.activeProjectId == null) {
      _storage.setActiveProjectId(project.id);
    }
  }

  Future<void> delete(String id) async {
    await _storage.deleteProjectJson(id);
    if (_storage.activeProjectId == id) {
      await _storage.clearActiveProjectId();
    }
  }

  String? get activeProjectId => _storage.activeProjectId;

  Future<void> setActiveProjectId(String id) =>
      _storage.setActiveProjectId(id);

  Future<void> clearActiveProjectId() => _storage.clearActiveProjectId();
}

final projectRepositoryProvider = Provider<ProjectRepository>(
  (ref) => ProjectRepository(),
);
