import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

import '../../../core/errors/app_error.dart';

/// Kegagalan menyimpan kode; membawa kode yang diterjemahkan di UI.
class CodeExportException extends AppErrorDetails implements Exception {
  const CodeExportException(super.code, {super.detail});

  @override
  String toString() => debugLabel;
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
        AppErrorCode.exportWriteFailed,
        detail: outputPath,
      );
    }
  }
}
