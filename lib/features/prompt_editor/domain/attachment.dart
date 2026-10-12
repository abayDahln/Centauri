import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// Lampiran (gambar / dokumen) yang dikirim user bersama prompt.
///
/// Format teks (svg/html) dikirim sebagai teks agar model bisa membacanya,
/// sedangkan gambar raster (jpg/png/webp/gif) dikirim sebagai data URL agar
/// bisa diproses model vision.
@immutable
class Attachment {
  const Attachment({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.bytes,
    this.isText = false,
  });

  final String id;
  final String name;
  final String mimeType;
  final Uint8List bytes;

  /// True untuk format berbasis teks (svg, html) yang dikirim sebagai teks.
  final bool isText;

  int get sizeBytes => bytes.length;

  String get dataUrl => 'data:$mimeType;base64,${base64Encode(bytes)}';

  String get textContent => utf8.decode(bytes, allowMalformed: true);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'mimeType': mimeType,
    'bytes': base64Encode(bytes),
    'isText': isText,
  };

  static Attachment fromJson(Map<String, dynamic> json) => Attachment(
    id: json['id'] as String,
    name: json['name'] as String,
    mimeType: json['mimeType'] as String,
    bytes: base64Decode(json['bytes'] as String),
    isText: json['isText'] as bool? ?? false,
  );
}

/// Format lampiran yang didukung.
class AttachmentFormats {
  AttachmentFormats._();

  /// Gambar raster -> dikirim sebagai data URL (vision).
  static const Map<String, String> rasterByExtension = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'gif': 'image/gif',
    'bmp': 'image/bmp',
  };

  /// Format berbasis teks -> dikirim sebagai teks mentah.
  static const Map<String, String> textByExtension = {
    'svg': 'image/svg+xml',
    'html': 'text/html',
    'htm': 'text/html',
    'css': 'text/css',
    'txt': 'text/plain',
    'md': 'text/markdown',
  };

  static Set<String> get allExtensions => {
    ...rasterByExtension.keys,
    ...textByExtension.keys,
  };

  static String get acceptLabel =>
      allExtensions.map((e) => '.$e').join(', ');

  /// Tentukan MIME + apakah teks dari ekstensi file. Null bila tidak didukung.
  static ({String mime, bool isText})? resolve(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) return null;
    final ext = fileName.substring(dot + 1).toLowerCase();
    if (rasterByExtension.containsKey(ext)) {
      return (mime: rasterByExtension[ext]!, isText: false);
    }
    if (textByExtension.containsKey(ext)) {
      return (mime: textByExtension[ext]!, isText: true);
    }
    return null;
  }

  static bool isSupported(String fileName) => resolve(fileName) != null;
}

/// Helper: apakah sebuah file gambar raster bisa didekode Flutter (untuk
/// pratinjau). SVG tidak bisa langsung, jadi dibuatkan thumbnail kotak.
Future<bool> canDecodeImage(Uint8List bytes) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    await codec.getNextFrame();
    return true;
  } catch (_) {
    return false;
  }
}
