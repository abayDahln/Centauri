import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../utils/app_constants.dart';
import 'sessions_root.dart';

/// Hasil inisialisasi penyimpanan, dibaca UI untuk menampilkan banner.
class StorageStatus {
  const StorageStatus({this.directory, this.error});

  final String? directory;

  /// null = semua box terbuka; selain itu = daftar box yang gagal dibuka.
  final String? error;

  bool get isHealthy => error == null;
}

/// Local database (Hive) untuk metadata provider dan riwayat proyek (FR-06).
/// Nilai disimpan sebagai JSON string agar tidak perlu Hive type adapter.
///
/// Inisialisasi dilakukan lewat [init] (dipanggil di `main`). [init] tidak
/// pernah melempar: kegagalan (mis. box di-lock instance app lain) dicatat di
/// [status] sehingga UI tetap jalan dan bisa menawarkan coba lagi — dulu
/// exception di sini menghentikan `main()` dan meninggalkan jendela kosong.
/// Operasi baca tetap mengembalikan nilai kosong dan tulis diabaikan bila box
/// belum terbuka.
class LocalStorageService {
  LocalStorageService._internal();
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;

  Box<String>? _providersBox;
  Box<String>? _metaBox;
  Box<String>? _projectsBox;
  Directory? _sessionsRoot;

  /// Root folder sesi (sumber kebenaran proyek). Diisi saat [init]; `null`
  /// selama init belum berjalan atau gagal (repository memakai fallback).
  Directory? get sessionsRoot => _sessionsRoot;

  StorageStatus _status = const StorageStatus();
  StorageStatus get status => _status;

  bool get isReady =>
      _providersBox != null && _metaBox != null && _projectsBox != null;

  /// Buka semua box. Panggil ulang untuk mencoba lagi setelah kegagalan.
  ///
  /// [path] memaksa folder data (dipakai test agar tetap terisolasi di temp
  /// dir dan tidak menyentuh penyimpanan pengguna sungguhan).
  Future<StorageStatus> init({String? path, String? sessionsPath}) async {
    final failures = <String>[];
    String? directory;
    try {
      directory = await _prepareHive(path);
    } catch (e) {
      return _status = StorageStatus(error: 'Gagal menyiapkan folder data: $e');
    }
    await _open(
      AppConstants.providersBoxName,
      (box) => _providersBox = box,
      failures,
    );
    await _open(AppConstants.metaBoxName, (box) => _metaBox = box, failures);
    await _open(
      AppConstants.projectsBoxName,
      (box) => _projectsBox = box,
      failures,
    );
    await _prepareSessionsRoot(sessionsPath);

    return _status = StorageStatus(
      directory: directory,
      error: failures.isEmpty ? null : failures.join(' · '),
    );
  }

  /// Siapkan root folder sesi (proyek berbasis file). Kegagalan tidak boleh
  /// menggagalkan init Hive — repository memakai fallback sinkron.
  ///
  /// [sessionsPath] memaksa root (dipakai test agar tetap terisolasi).
  Future<void> _prepareSessionsRoot(String? sessionsPath) async {
    try {
      _sessionsRoot = sessionsPath != null
          ? Directory(sessionsPath)
          : await defaultSessionsRoot();
      await _sessionsRoot!.create(recursive: true);
    } catch (e) {
      debugPrint('[storage] folder sesi tidak tersedia: $e');
    }
  }

  Future<void> _open(
    String name,
    void Function(Box<String> box) assign,
    List<String> failures,
  ) async {
    try {
      assign(await Hive.openBox<String>(name));
    } catch (e) {
      failures.add('$name: $e');
    }
  }

  /// Pilih folder data. Windows pindah ke `%LOCALAPPDATA%\Centauri\data`
  /// (default `hive_flutter` menaruh box di root `Documents`, yang bentrok
  /// antar instance dan bercampur dengan file aplikasi lain). Data lama
  /// disalin ke folder baru, file asli dibiarkan sebagai cadangan.
  Future<String?> _prepareHive(String? path) async {
    if (path != null) {
      Hive.init(path);
      return path;
    }
    if (!Platform.isWindows) {
      await Hive.initFlutter();
      return null;
    }

    final target = _windowsDataDir();
    if (target == null) {
      await Hive.initFlutter();
      return null;
    }
    await target.create(recursive: true);
    await _migrateLegacyBoxes(target);
    Hive.init(target.path);
    return target.path;
  }

  static String _join(String a, String b) => '$a${Platform.pathSeparator}$b';

  static Directory? _windowsDataDir() {
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData == null || localAppData.isEmpty) return null;
    return Directory(_join(_join(localAppData, 'Centauri'), 'data'));
  }

  /// Salin box `.hive` lama dari folder Documents (sebelum dipindah) ke
  /// [target] bila belum ada. Copy-only: tidak pernah menimpa file baru, jadi
  /// tidak bisa memulihkan data bila box baru sempat dibuat kosong lebih
  /// dulu — pilihan sadar daripada berisiko menimpa data yang lebih baru.
  static Future<void> _migrateLegacyBoxes(Directory target) async {
    final boxNames = [
      AppConstants.providersBoxName,
      AppConstants.metaBoxName,
      AppConstants.projectsBoxName,
    ];
    File boxIn(String dir, String name) => File(_join(dir, '$name.hive'));
    if (boxNames.every((n) => boxIn(target.path, n).existsSync())) return;

    for (final legacy in _legacyDocumentsDirs()) {
      for (final name in boxNames) {
        final source = boxIn(legacy, name);
        final dest = boxIn(target.path, name);
        if (!source.existsSync() || dest.existsSync()) continue;
        try {
          await source.copy(dest.path);
        } catch (_) {
          // Copy gagal (mis. sedang dipakai): biarkan box baru mulai kosong.
        }
      }
      return;
    }
  }

  static List<String> _legacyDocumentsDirs() {
    final env = Platform.environment;
    final candidates = <String>[];
    void add(String? root) {
      if (root == null || root.isEmpty) return;
      candidates.add(_join(root, 'Documents'));
    }

    add(env['USERPROFILE']);
    add(env['OneDrive']);
    return candidates;
  }

  // ------------------------------------------------------------- providers --

  List<String> readAllProvidersJson() =>
      _providersBox?.values.toList() ?? const [];

  /// Seluruh provider sebagai pasangan id → JSON. Dipakai migrasi/bersih-bersih
  /// yang perlu menyasar provider tertentu berdasarkan id-nya.
  Map<String, String> readProvidersJsonById() {
    final box = _providersBox;
    if (box == null) return const {};
    final result = <String, String>{};
    for (final key in box.keys) {
      final value = box.get(key);
      if (key is String && value is String) result[key] = value;
    }
    return result;
  }

  void writeProviderJson(String id, String json) =>
      _providersBox?.put(id, json);

  Future<void> deleteProviderJson(String id) async => _providersBox?.delete(id);

  String? get activeProviderId =>
      _metaBox?.get(AppConstants.activeProviderIdKey);

  Future<void> setActiveProviderId(String id) async =>
      _metaBox?.put(AppConstants.activeProviderIdKey, id);

  Future<void> clearActiveProviderId() async =>
      _metaBox?.delete(AppConstants.activeProviderIdKey);

  // ------------------------------------------------------------- projects --

  List<String> readAllProjectsJson() =>
      _projectsBox?.values.toList() ?? const [];

  void writeProjectJson(String id, String json) => _projectsBox?.put(id, json);

  Future<void> deleteProjectJson(String id) async => _projectsBox?.delete(id);

  String? get activeProjectId => _metaBox?.get(AppConstants.activeProjectIdKey);

  Future<void> setActiveProjectId(String id) async =>
      _metaBox?.put(AppConstants.activeProjectIdKey, id);

  Future<void> clearActiveProjectId() async =>
      _metaBox?.delete(AppConstants.activeProjectIdKey);

  // ---------------------------------------------------------------- flags --

  /// Penanda satu kali migrasi proyek Hive -> folder sesi. `false` selama
  /// belum berjalan (atau box gagal terbuka — migrasi akan mencoba lagi).
  bool get sessionsMigrated {
    final box = _metaBox;
    if (box == null || !box.isOpen) return false;
    return box.get(AppConstants.sessionsMigratedKey) != null;
  }

  Future<void> setSessionsMigrated() =>
      _metaBox?.put(AppConstants.sessionsMigratedKey, '1') ?? Future.value();

  // --------------------------------------------------------------- bahasa --

  /// Kode bahasa UI pilihan pengguna. `null` = belum pernah memilih; aplikasi
  /// memakai default Inggris.
  String? get appLocale => _metaBox?.get(AppConstants.appLocaleKey);

  Future<void> setAppLocale(String code) async =>
      _metaBox?.put(AppConstants.appLocaleKey, code);

  /// Kotak proyek siap dibaca (terbuka dan belum ditutup). Dipakai migrator
  /// agar flag sekali-jalan tidak tertulis padahal daftar proyek tak terbaca.
  bool get projectsBoxHealthy => _projectsBox != null && _projectsBox!.isOpen;

  /// Untuk test: paksa status root sesi (null = tidak tersedia).
  void debugSetSessionsRoot(Directory? root) => _sessionsRoot = root;
}

/// Status penyimpanan untuk UI: banner peringatan + tombol coba lagi.
final storageStatusProvider =
    NotifierProvider<StorageStatusNotifier, StorageStatus>(
      StorageStatusNotifier.new,
    );

class StorageStatusNotifier extends Notifier<StorageStatus> {
  @override
  StorageStatus build() => LocalStorageService().status;

  /// Buka ulang box (mis. setelah instance app lain ditutup).
  Future<void> retry() async {
    state = await LocalStorageService().init();
  }
}
