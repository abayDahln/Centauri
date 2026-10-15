import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../domain/project.dart';

class MydesignException implements Exception {
  MydesignException(this.message);
  final String message;

  @override
  String toString() => message;
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
      throw MydesignException(
        'File bukan JSON yang valid. Pilih file .mydesign dari Centauri.',
      );
    }

    // Terima dua bentuk: envelope .mydesign ATAU JSON project mentah.
    final Map<String, dynamic> projectJson;
    if (decoded['format'] == 'mydesign' || decoded.containsKey('project')) {
      if (decoded['app'] != 'centauri' || decoded['format'] != 'mydesign') {
        throw MydesignException(
          'File bukan proyek Centauri (.mydesign) yang valid.',
        );
      }
      final version = decoded['version'];
      if (version is num && version > currentVersion) {
        throw MydesignException(
          'File dibuat oleh Centauri versi lebih baru (v$version). '
          'Perbarui aplikasi terlebih dahulu.',
        );
      }
      final project = decoded['project'];
      if (project is! Map<String, dynamic>) {
        throw MydesignException('Bagian "project" rusak di file ini.');
      }
      projectJson = project;
    } else {
      projectJson = decoded;
    }

    try {
      final project = Project.fromJson(projectJson);
      if (project.pages.isEmpty && project.messages.isEmpty) {
        throw MydesignException('Proyek di file ini kosong.');
      }
      return project;
    } catch (e) {
      if (e is MydesignException) rethrow;
      throw MydesignException('Isi proyek rusak: $e');
    }
  }

  dynamic _tryDecode(String raw) {
    try {
      return jsonDecode(raw.trim());
    } catch (_) {
      throw MydesignException(
        'File bukan JSON yang valid. Pilih file .mydesign dari Centauri.',
      );
    }
  }

  /// Simpan proyek ke file `.mydesign` pilihan pengguna.
  /// Return path bila berhasil, null bila pengguna membatalkan.
  Future<String?> saveToFile(Project project) async {
    final safeTitle = project.title
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .trim();
    final fallback = safeTitle.isEmpty ? 'centauri-project' : safeTitle;
    final outputPath = await FilePicker.saveFile(
      dialogTitle: 'Simpan proyek Centauri',
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
        'Gagal menulis file ke $outputPath. Coba lokasi lain.',
      );
    }
  }

  /// Buka dialog pilih file lalu parse menjadi [Project].
  /// Return null bila pengguna membatalkan. Melempar [MydesignException]
  /// bila file tidak valid.
  Future<Project?> pickAndLoad() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Buka proyek Centauri',
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
      } catch (_) {
        throw MydesignException(
          'Gagal membaca file ${picked.name}. Coba file lain.',
        );
      }
    }
    if (raw == null || raw.trim().isEmpty) {
      throw MydesignException('File ${picked.name} kosong.');
    }
    return parseMydesign(raw);
  }
}
