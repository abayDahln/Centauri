import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../canvas_preview/data/services/canvas_service_registry.dart';

class FrameExportException implements Exception {
  FrameExportException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Ekspor frame aktif ke PNG/SVG/PDF (Fase 3, offline-first).
/// - SVG: murni Dart (bungkus HTML dalam foreignObject), tanpa WebView.
/// - PNG: render via WebView frame (`centauriExportPng`) → data URL.
/// - PDF: bungkus PNG dalam satu halaman PDF (paket `pdf`, murni Dart).
class FrameExportService {
  /// Bungkus HTML frame menjadi SVG standalone.
  /// Catatan: gambar eksternal tetap berupa URL (butuh internet saat
  /// dilihat); konten HTML/CSS sendiri sepenuhnya offline.
  String buildStandaloneSvg({
    required String html,
    required double width,
    required double height,
  }) {
    final w = width.isFinite && width > 0 ? width.round() : 390;
    final h = height.isFinite && height > 0 ? height.round() : 844;
    final escaped = html
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    return '''<svg xmlns="http://www.w3.org/2000/svg" width="$w" height="$h" viewBox="0 0 $w $h">
  <foreignObject width="100%" height="100%">
    <div xmlns="http://www.w3.org/1999/xhtml" style="width:${w}px;height:${h}px;margin:0;padding:0;overflow:hidden;font-family:Inter,system-ui,sans-serif;font-size:14px;color:#18181B;background:#FFFFFF;">HTML frame Centauri (lihat file .html untuk konten penuh):</div>
  </foreignObject>
  <!-- sumber:
$escaped
-->
</svg>''';
  }

  /// Minta frame aktif merender PNG. Tunggu event `png`/`pngError`
  /// dari stream service frame tersebut (timeout 20 detik).
  Future<Uint8List> capturePngBytes(String frameId) async {
    final service = CanvasServiceRegistry.forFrame(frameId);
    if (service == null) {
      throw FrameExportException(
        'Frame belum siap (WebView belum terinisialisasi). Tunggu sebentar.',
      );
    }

    final future = service.selectionEvents
        .firstWhere((e) => e.type == 'png' || e.type == 'pngError')
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw FrameExportException(
            'Ekspor PNG timeout. Coba lagi.',
          ),
        );
    await service.requestFramePng(pixelRatio: 2);

    final event = await future;
    if (event.type == 'pngError') {
      throw FrameExportException(
        event.errorMessage ?? 'Ekspor PNG gagal tanpa pesan.',
      );
    }
    final dataUrl = event.dataUrl;
    if (dataUrl == null || !dataUrl.startsWith('data:image/png;base64,')) {
      throw FrameExportException('Hasil PNG tidak valid.');
    }
    try {
      return base64Decode(dataUrl.substring('data:image/png;base64,'.length));
    } catch (_) {
      throw FrameExportException('Hasil PNG rusak (base64 tidak valid).');
    }
  }

  /// Bungkus PNG menjadi PDF satu halaman (ukuran mengikuti gambar).
  Future<Uint8List> buildPdfFromPng(Uint8List pngBytes) async {
    final doc = pw.Document();
    final image = pw.MemoryImage(pngBytes);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) => pw.Center(child: pw.Image(image)),
      ),
    );
    return doc.save();
  }

  Future<String?> _saveBytes({
    required String dialogTitle,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final outputPath = await FilePicker.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      type: FileType.any,
    );
    if (outputPath == null) return null;
    try {
      await File(outputPath).writeAsBytes(bytes, flush: true);
      return outputPath;
    } catch (_) {
      throw FrameExportException(
        'Gagal menulis file ke $outputPath. Coba lokasi lain.',
      );
    }
  }

  Future<String?> _saveText({
    required String dialogTitle,
    required String fileName,
    required String text,
  }) async {
    final outputPath = await FilePicker.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      type: FileType.any,
    );
    if (outputPath == null) return null;
    try {
      await File(outputPath).writeAsString(text, flush: true);
      return outputPath;
    } catch (_) {
      throw FrameExportException(
        'Gagal menulis file ke $outputPath. Coba lokasi lain.',
      );
    }
  }

  Future<String?> saveSvg({
    required String frameTitle,
    required String html,
    required double width,
    required double height,
  }) {
    final name = _safeName(frameTitle);
    return _saveText(
      dialogTitle: 'Ekspor frame sebagai SVG',
      fileName: '$name.svg',
      text: buildStandaloneSvg(html: html, width: width, height: height),
    );
  }

  Future<String?> savePng({
    required String frameTitle,
    required Uint8List pngBytes,
  }) {
    return _saveBytes(
      dialogTitle: 'Ekspor frame sebagai PNG',
      fileName: '${_safeName(frameTitle)}.png',
      bytes: pngBytes,
    );
  }

  Future<String?> savePdf({
    required String frameTitle,
    required Uint8List pdfBytes,
  }) {
    return _saveBytes(
      dialogTitle: 'Ekspor frame sebagai PDF',
      fileName: '${_safeName(frameTitle)}.pdf',
      bytes: pdfBytes,
    );
  }

  String _safeName(String title) {
    final cleaned = title
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-')
        .toLowerCase();
    return cleaned.isEmpty ? 'centauri-frame' : cleaned;
  }
}
