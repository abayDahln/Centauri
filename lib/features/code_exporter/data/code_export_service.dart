import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

class CodeExportException implements Exception {
  CodeExportException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Copy + simpan kode hasil export (FR-05).
class CodeExportService {
  Future<void> copyToClipboard(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
  }

  /// Menyimpan kode ke file pilihan pengguna.
  /// Return null jika pengguna membatalkan dialog; melempar
  /// [CodeExportException] jika penulisan gagal.
  Future<String?> saveToFile({
    required String fileName,
    required String code,
  }) async {
    final outputPath = await FilePicker.saveFile(
      dialogTitle: 'Simpan kode Centauri',
      fileName: fileName,
      type: FileType.any,
    );
    if (outputPath == null) return null;

    try {
      final file = File(outputPath);
      await file.writeAsString(code);
      return outputPath;
    } catch (_) {
      throw CodeExportException(
        'Gagal menulis file ke $outputPath. Salin kode ke clipboard sebagai alternatif.',
      );
    }
  }
}
