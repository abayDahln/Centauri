import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../../../core/errors/app_error.dart';
import '../domain/project.dart';

/// Kegagalan impor/ekspor berkas proyek; membawa kode yang diterjemahkan di UI.
class MydesignException extends AppErrorDetails implements Exception {
  const MydesignException(
    super.code, {
    super.detail,
    super.name,
    super.version,
  });

  @override
  String toString() => debugLabel;
}

/// Format file proyek offline Centauri (`.mydesign`, JSON).
/// Envelope: `{app:'centauri', format:'mydesign', version:1, exportedAt, project:{...}}`.
/// `project` memakai skema yang sama dengan [Project.toJson] agar kompatibel
/// dengan penyimpanan Hive.
class MydesignService {
  static const int currentVersion = 2;
  static const String fileExtension = 'mydesign';

  /// Bangun JSON envelope dari proyek.
  String buildMydesignJson(Project project) {
    final envelope = {
      'app': 'centauri',
      'format': 'mydesign',
      'version': currentVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'project': project.toJson(),
    };
    return const JsonEncoder.withIndent('  ').convert(envelope);
  }

  /// Parse + validasi isi file `.mydesign` (atau JSON polos berisi project).
  /// Melempar [MydesignException] bila format tidak valid.
  Project parseMydesign(String raw) {
    final decoded = _tryDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const MydesignException(AppErrorCode.importInvalidFile);
    }

    // Terima dua bentuk: envelope .mydesign ATAU JSON project mentah.
    final Map<String, dynamic> projectJson;
    if (decoded['format'] == 'mydesign' || decoded.containsKey('project')) {
      if (decoded['app'] != 'centauri' || decoded['format'] != 'mydesign') {
        throw const MydesignException(AppErrorCode.importNotProject);
      }
      final version = decoded['version'];
      if (version is num && version > currentVersion) {
        throw MydesignException(
          AppErrorCode.importNewerVersion,
          version: 'v$version',
        );
      }
      final project = decoded['project'];
      if (project is! Map<String, dynamic>) {
        throw const MydesignException(AppErrorCode.importUnusable);
      }
      projectJson = project;
    } else {
      projectJson = decoded;
    }

    try {
      final project = Project.fromJson(projectJson);
      if (project.pages.isEmpty && project.messages.isEmpty) {
        throw const MydesignException(AppErrorCode.importEmpty);
      }
      return project;
    } catch (e) {
      if (e is MydesignException) rethrow;
      throw MydesignException(AppErrorCode.importUnusable, detail: '$e');
    }
  }

  dynamic _tryDecode(String raw) {
    try {
      return jsonDecode(raw.trim());
    } catch (_) {
      throw const MydesignException(AppErrorCode.importInvalidFile);
    }
  }

  /// Simpan proyek ke file `.mydesign` pilihan pengguna.
  /// Return path bila berhasil, null bila pengguna membatalkan.
  ///
  /// [dialogTitle] dikirim dari UI agar judul dialog mengikuti bahasa aktif;
  /// lapisan data tidak menyimpan teks yang terlihat pengguna.
  Future<String?> saveToFile(
    Project project, {
    required String dialogTitle,
  }) async {
    final safeTitle = project.title
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .trim();
    final fallback = safeTitle.isEmpty ? 'centauri-project' : safeTitle;
    final outputPath = await FilePicker.saveFile(
      dialogTitle: dialogTitle,
      fileName: '$fallback.$fileExtension',
      type: FileType.custom,
      allowedExtensions: [fileExtension],
    );
    if (outputPath == null) return null;

    try {
      final file = File(outputPath);
      await file.writeAsString(buildMydesignJson(project));
      return outputPath;
    } catch (_) {
      throw MydesignException(
        AppErrorCode.exportWriteFailed,
        detail: outputPath,
      );
    }
  }

  /// Buka dialog pilih file lalu parse menjadi [Project].
  /// Return null bila pengguna membatalkan. Melempar [MydesignException]
  /// bila file tidak valid.
  Future<Project?> pickAndLoad({required String dialogTitle}) async {
    final result = await FilePicker.pickFiles(
      dialogTitle: dialogTitle,
      type: FileType.custom,
      allowedExtensions: [fileExtension, 'json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.first;
    String? raw;
    if (picked.bytes != null) {
      raw = utf8.decode(picked.bytes!, allowMalformed: true);
    } else if (picked.path != null) {
      try {
        raw = await File(picked.path!).readAsString();
      } catch (e) {
        throw MydesignException(
          AppErrorCode.importUnusable,
          name: picked.name,
          detail: '$e',
        );
      }
    }
    if (raw == null || raw.trim().isEmpty) {
      throw MydesignException(AppErrorCode.importEmpty, name: picked.name);
    }
    return parseMydesign(raw);
  }
}
