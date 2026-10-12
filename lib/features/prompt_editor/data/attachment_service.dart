import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../domain/attachment.dart';

class AttachmentException implements Exception {
  AttachmentException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Memuat dan memvalidasi lampiran dari berbagai sumber (file, drag&drop,
/// clipboard). Batas ukuran menjaga permintaan tetap wajar.
class AttachmentService {
  const AttachmentService();

  /// Batas per file (base64 menambah ~33%, jadi jaga tetap moderat).
  static const int maxBytes = 8 * 1024 * 1024; // 8 MB

  /// Batas jumlah lampiran per prompt.
  static const int maxCount = 6;

  final _uuid = const Uuid();

  /// Bangun lampiran dari nama file + byte konten mentah.
  /// Melempar [AttachmentException] bila format tak didukung atau terlalu besar.
  Attachment fromBytes(String fileName, Uint8List bytes) {
    if (bytes.isEmpty) {
      throw AttachmentException('File "$fileName" kosong.');
    }
    if (bytes.length > maxBytes) {
      throw AttachmentException(
        'File "$fileName" terlalu besar (maks ${maxBytes ~/ (1024 * 1024)} MB).',
      );
    }
    final resolved = AttachmentFormats.resolve(fileName);
    if (resolved == null) {
      throw AttachmentException(
        'Format "$fileName" tidak didukung. Didukung: ${AttachmentFormats.acceptLabel}.',
      );
    }
    return Attachment(
      id: _uuid.v4(),
      name: fileName,
      mimeType: resolved.mime,
      bytes: bytes,
      isText: resolved.isText,
    );
  }

  /// Bangun lampiran dari gambar hasil paste (clipboard). Nama dibuat otomatis.
  Attachment fromPastedImage(Uint8List bytes, {String? mimeType}) {
    final mime = mimeType ?? 'image/png';
    final ext = mime.contains('jpeg')
        ? 'jpg'
        : mime.split('/').last.replaceAll('+xml', '');
    return fromBytes('pasted-image.${ext.isEmpty ? 'png' : ext}', bytes);
  }
}
