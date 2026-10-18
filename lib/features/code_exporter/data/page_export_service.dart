import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../canvas_preview/data/services/canvas_service_registry.dart';

class PageExportException implements Exception {
  PageExportException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Ekspor halaman aktif ke PNG/SVG/PDF (offline-first).
/// - SVG: murni Dart (bungkus HTML dalam foreignObject), tanpa WebView.
/// - PNG: render via WebView halaman (`centauriExportPng`) → data URL.
/// - PDF: bungkus PNG dalam satu halaman PDF (paket `pdf`, murni Dart).
class PageExportService {
  /// Bungkus HTML halaman menjadi SVG standalone.
  String buildStandaloneSvg({
    required String html,
    required double width,
    required double height,
  }) {
    final w = width.isFinite && width > 0 ? width.round() : 1440;
    final h = height.isFinite && height > 0 ? height.round() : 2000;

    final document = html_parser.parse(html);
    for (final script in document.querySelectorAll('script')) {
      script.remove();
    }
    _removeComments(document.documentElement);
    final root = document.documentElement;
    String xhtml;
    if (root != null) {
      root.attributes['xmlns'] = 'http://www.w3.org/1999/xhtml';
      xhtml = root.outerHtml;
    } else {
      xhtml =
          '<div xmlns="http://www.w3.org/1999/xhtml">'
          '${document.body?.innerHtml ?? html}'
          '</div>';
    }
    xhtml = xhtml.replaceFirst(
      RegExp(r'<!DOCTYPE[^>]*>', caseSensitive: false),
      '',
    );
    xhtml = _toStrictXhtml(xhtml);

    return '''<svg xmlns="http://www.w3.org/2000/svg" width="$w" height="$h" viewBox="0 0 $w $h">
  <foreignObject width="100%" height="100%">
    $xhtml
  </foreignObject>
</svg>''';
  }

  static void _removeComments(dom.Element? root) {
    if (root == null) return;
    final toRemove = root.nodes.whereType<dom.Comment>().toList(
      growable: false,
    );
    for (final comment in toRemove) {
      root.nodes.remove(comment);
    }
    for (final child in root.children) {
      _removeComments(child);
    }
  }

  static const _voidElements = {
    'area',
    'base',
    'br',
    'col',
    'embed',
    'hr',
    'img',
    'input',
    'link',
    'meta',
    'param',
    'source',
    'track',
    'wbr',
    'circle',
    'ellipse',
    'line',
    'path',
    'polygon',
    'polyline',
    'rect',
    'stop',
    'use',
  };

  static String _openTagBody({bool stopBeforeClose = false}) {
    const dq = '"';
    const sq = "'";
    final slash = stopBeforeClose ? '|/(?![>$dq$sq])' : '|/';
    return '(?:'
        '$dq[^$dq]*$dq'
        '|$sq[^$sq]*$sq'
        '|[^>$dq$sq/]'
        '$slash'
        ')*';
  }

  static final _voidTagPattern = () {
    final names = _voidElements.join('|');
    return RegExp(
      '<($names)(${_openTagBody(stopBeforeClose: true)})>'
      '(?!\\s*</(?:$names)>)',
      caseSensitive: false,
    );
  }();

  static final _styleTagPattern = RegExp(
    '<style(${_openTagBody()})>',
    caseSensitive: false,
  );

  static final _svgTagPattern = RegExp(
    '<svg(${_openTagBody()})>',
    caseSensitive: false,
  );

  String _toStrictXhtml(String xhtml) {
    final closed = xhtml.replaceAllMapped(
      _voidTagPattern,
      (m) => '<${m.group(1)}${m.group(2)}/>',
    );
    final styled = closed.replaceAllMapped(
      _styleTagPattern,
      (m) => '<style xmlns="http://www.w3.org/1999/xhtml"${m.group(1)}>',
    );
    return styled.replaceAllMapped(
      _svgTagPattern,
      (m) => m.group(1)!.contains('xmlns')
          ? m.group(0)!
          : '<svg xmlns="http://www.w3.org/2000/svg"${m.group(1)}>',
    );
  }

  /// Ukuran dokumen halaman (lebar & tinggi konten) via event `size`.
  /// Fallback 1440×2000 bila WebView belum siap.
  Future<({double width, double height})> _documentSize(String pageId) async {
    final service = CanvasServiceRegistry.forFrame(pageId);
    if (service == null) return (width: 1440.0, height: 2000.0);
    try {
      final future = service.selectionEvents
          .firstWhere((e) => e.type == 'size')
          .timeout(const Duration(seconds: 8));
      await service.requestDocumentSize();
      final event = await future;
      final w = event.contentWidth ?? 0;
      final h = event.contentHeight ?? 0;
      return (width: w > 0 ? w : 1440.0, height: h > 0 ? h : 2000.0);
    } catch (_) {
      return (width: 1440.0, height: 2000.0);
    }
  }

  /// Minta halaman aktif merender PNG. Tunggu event `png`/`pngError`
  /// dari stream service halaman tersebut (timeout 20 detik).
  Future<Uint8List> capturePngBytes(String pageId) async {
    final service = CanvasServiceRegistry.forFrame(pageId);
    if (service == null) {
      throw PageExportException(
        'Halaman belum siap (WebView belum terinisialisasi). Tunggu sebentar.',
      );
    }

    final future = service.selectionEvents
        .firstWhere((e) => e.type == 'png' || e.type == 'pngError')
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () =>
              throw PageExportException('Ekspor PNG timeout. Coba lagi.'),
        );
    await service.requestFramePng(pixelRatio: 2);

    final event = await future;
    if (event.type == 'pngError') {
      throw PageExportException(
        event.errorMessage ?? 'Ekspor PNG gagal tanpa pesan.',
      );
    }
    final dataUrl = event.dataUrl;
    if (dataUrl == null || !dataUrl.startsWith('data:image/png;base64,')) {
      throw PageExportException('Hasil PNG tidak valid.');
    }
    try {
      return base64Decode(dataUrl.substring('data:image/png;base64,'.length));
    } catch (_) {
      throw PageExportException('Hasil PNG rusak (base64 tidak valid).');
    }
  }

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
      throw PageExportException(
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
      throw PageExportException(
        'Gagal menulis file ke $outputPath. Coba lokasi lain.',
      );
    }
  }

  Future<String?> saveSvg({
    required String pageName,
    required String pageId,
    required String html,
  }) async {
    final size = await _documentSize(pageId);
    return _saveText(
      dialogTitle: 'Ekspor halaman sebagai SVG',
      fileName: '${_safeName(pageName)}.svg',
      text: buildStandaloneSvg(
        html: html,
        width: size.width,
        height: size.height,
      ),
    );
  }

  Future<String?> savePng({
    required String pageName,
    required Uint8List pngBytes,
  }) {
    return _saveBytes(
      dialogTitle: 'Ekspor halaman sebagai PNG',
      fileName: '${_safeName(pageName)}.png',
      bytes: pngBytes,
    );
  }

  Future<String?> savePdf({
    required String pageName,
    required Uint8List pdfBytes,
  }) {
    return _saveBytes(
      dialogTitle: 'Ekspor halaman sebagai PDF',
      fileName: '${_safeName(pageName)}.pdf',
      bytes: pdfBytes,
    );
  }

  String _safeName(String title) {
    final cleaned = title
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-')
        .toLowerCase();
    return cleaned.isEmpty ? 'centauri-page' : cleaned;
  }
}
