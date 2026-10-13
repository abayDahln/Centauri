import 'package:hive_flutter/hive_flutter.dart';

import '../utils/app_constants.dart';

/// Local database (Hive) untuk metadata provider dan riwayat proyek (FR-06).
/// Nilai disimpan sebagai JSON string agar tidak perlu Hive type adapter.
///
/// Inisialisasi dilakukan lewat [init] (dipanggil di `main`). Bila belum
/// diinisialisasi, operasi baca mengembalikan nilai kosong dan operasi tulis
/// diabaikan, sehingga UI tidak crash pada kondisi tak terduga (mis. test atau
/// kegagalan storage).
class LocalStorageService {
  LocalStorageService._internal();
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;

  Box<String>? _providersBox;
  Box<String>? _metaBox;
  Box<String>? _projectsBox;

  bool get isReady =>
      _providersBox != null && _metaBox != null && _projectsBox != null;

  Future<void> init() async {
    _providersBox ??= await Hive.openBox<String>(
      AppConstants.providersBoxName,
    );
    _metaBox ??= await Hive.openBox<String>(AppConstants.metaBoxName);
    _projectsBox ??= await Hive.openBox<String>(
      AppConstants.projectsBoxName,
    );
  }

  // ------------------------------------------------------------- providers --

  List<String> readAllProvidersJson() =>
      _providersBox?.values.toList() ?? const [];

  void writeProviderJson(String id, String json) =>
      _providersBox?.put(id, json);

  Future<void> deleteProviderJson(String id) async =>
      _providersBox?.delete(id);

  String? get activeProviderId =>
      _metaBox?.get(AppConstants.activeProviderIdKey);

  Future<void> setActiveProviderId(String id) async =>
      _metaBox?.put(AppConstants.activeProviderIdKey, id);

  // ------------------------------------------------------------- projects --

  List<String> readAllProjectsJson() =>
      _projectsBox?.values.toList() ?? const [];

  void writeProjectJson(String id, String json) => _projectsBox?.put(id, json);

  Future<void> deleteProjectJson(String id) async => _projectsBox?.delete(id);

  String? get activeProjectId =>
      _metaBox?.get(AppConstants.activeProjectIdKey);

  Future<void> setActiveProjectId(String id) async =>
      _metaBox?.put(AppConstants.activeProjectIdKey, id);

  Future<void> clearActiveProjectId() async =>
      _metaBox?.delete(AppConstants.activeProjectIdKey);

  // ------------------------------------------------- presets & prompting --

  static const _customPresetsKey = 'custom_presets_json';
  static const _systemPromptKey = 'system_prompt_override';

  /// JSON array preset kustom (Fase 4: Custom Bebas). Kosong bila belum ada.
  String? readCustomPresetsJson() => _metaBox?.get(_customPresetsKey);

  void writeCustomPresetsJson(String json) =>
      _metaBox?.put(_customPresetsKey, json);

  /// Override system prompt (null/empty = pakai bawaan `uiSystemPrompt`).
  String? readSystemPromptOverride() => _metaBox?.get(_systemPromptKey);

  Future<void> writeSystemPromptOverride(String? value) async {
    if (value == null || value.trim().isEmpty) {
      await _metaBox?.delete(_systemPromptKey);
    } else {
      await _metaBox?.put(_systemPromptKey, value);
    }
  }
}
