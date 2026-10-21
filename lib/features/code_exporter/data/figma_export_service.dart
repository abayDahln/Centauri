import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:super_clipboard/super_clipboard.dart';

import '../../canvas_preview/data/services/canvas_service_registry.dart';
import '../../../core/errors/app_error.dart';
import 'figma_svg_builder.dart';

/// Kegagalan ekspor Figma; membawa kode yang diterjemahkan di UI.
class FigmaExportException extends AppErrorDetails implements Exception {
  const FigmaExportException(super.code, {super.detail});

  @override
  String toString() => debugLabel;
}

/// Format clipboard untuk SVG.
///
/// Windows: format kustom `image/svg+xml` (dipakai Figma/Chromium).
/// macOS: UTI `public.svg-image`. Linux: MIME `image/svg+xml`.
const SimpleFileFormat _svgClipboardFormat = SimpleFileFormat(
  windowsFormats: ['image/svg+xml'],
  mimeTypes: ['image/svg+xml'],
  uniformTypeIdentifiers: ['public.svg-image'],
);

/// Ekspor desain halaman aktif ke **payload Figma** yang dikonsumsi plugin
/// companion Centauri (`figma-plugin/`).
///
/// Mekanisme: JS bridge (`window.centauriExportFigma`) men-serialisasi DOM
/// halaman (bbox + computed style + teks) → payload JSON → disimpan sebagai
/// file `.centauri-figma.json` dan/atau disalin ke clipboard. Plugin Figma
/// membaca payload itu lalu merekonstruksi frame/layer yang bisa diedit.
class FigmaExportService {
  static const String fileExtension = 'centauri-figma.json';
  static const String format = 'centauri-figma';
  static const int currentVersion = 1;

  /// Ambil payload struktur halaman dari WebView via event `figma`/`figmaError`.
  ///
  /// [width] dan [height] > 0 → halaman dirender ulang pada ukuran itu
  /// (layout desktop), 0 → memakai ukuran pratinjau saat ini.
  Future<Map<String, dynamic>> collectPayload(
    String pageId, {
    int width = 0,
    int height = 0,
  }) async {
    final service = CanvasServiceRegistry.forFrame(pageId);
    if (service == null) {
      throw const FigmaExportException(AppErrorCode.exportNotReady);
    }

    final future = service.selectionEvents
        .firstWhere((e) => e.type == 'figma' || e.type == 'figmaError')
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () =>
              throw const FigmaExportException(AppErrorCode.exportTimeout),
        );
    await service.requestFigmaPayload(width: width, height: height);

    final event = await future;
    if (event.type == 'figmaError') {
      throw FigmaExportException(
        AppErrorCode.exportFailed,
        detail: event.errorMessage,
      );
    }
    final payload = event.payload;
    if (payload == null) {
      throw const FigmaExportException(AppErrorCode.exportEmptyResult);
    }
    return payload;
  }

  /// Validasi + serialisasi payload menjadi JSON rapi untuk plugin.
  String buildFigmaJson(Map<String, dynamic> payload) {
    final nodes = payload['nodes'];
    if (nodes is! List || nodes.isEmpty) {
      throw const FigmaExportException(AppErrorCode.exportNoElements);
    }
    final page = payload['page'];
    final normalized = <String, dynamic>{
      'app': 'centauri',
      'format': format,
      'version': currentVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'page': page is Map ? page : const <String, dynamic>{},
      'nodes': nodes,
    };
    return const JsonEncoder.withIndent('  ').convert(normalized);
  }

  /// Hitung total node (rekursif) untuk pesan status.
  int countNodes(Map<String, dynamic> payload) {
    final nodes = payload['nodes'];
    if (nodes is! List) return 0;
    int walk(dynamic node) {
      if (node is! Map) return 0;
      final children = node['children'];
      var total = 1;
      if (children is List) {
        for (final child in children) {
          total += walk(child);
        }
      }
      return total;
    }

    var total = 0;
    for (final node in nodes) {
      total += walk(node);
    }
    return total;
  }

  /// Bangun SVG murni dari payload halaman.
  ///
  /// SVG ini yang ditempel ke board Figma: tiap elemen jadi group, teks jadi
  /// text layer, gambar jadi image layer, dan halaman jadi satu frame.
  String buildPasteableSvg(Map<String, dynamic> payload) {
    final nodes = payload['nodes'];
    if (nodes is! List || nodes.isEmpty) {
      throw const FigmaExportException(AppErrorCode.exportNoElements);
    }
    return const FigmaSvgBuilder().build(payload);
  }

  /// Salin SVG ke clipboard supaya bisa langsung ditempel di Figma.
  ///
  /// Ditulis dua format: `image/svg+xml` (dipakai Figma/Chromium) dan teks
  /// polos (cadangan untuk aplikasi lain). Bila clipboard sistem tidak
  /// tersedia, jatuh ke clipboard Flutter.
  Future<void> copySvgToClipboard(String svg) async {
    final writer = SystemClipboard.instance;
    if (writer == null) {
      await Clipboard.setData(ClipboardData(text: svg));
      return;
    }
    try {
      final item = DataWriterItem();
      // Format kustom "image/svg+xml" dibaca Figma/Chromium; teks polos
      // dipakai sebagai cadangan bila aplikasi hanya membaca teks.
      item.add(_svgClipboardFormat(Uint8List.fromList(utf8.encode(svg))));
      item.add(Formats.plainText(svg));
      await writer.write([item]);
    } catch (_) {
      // Fallback ke clipboard Flutter bila format SVG ditolak platform.
      await Clipboard.setData(ClipboardData(text: svg));
    }
  }

  /// Simpan payload sebagai file `.centauri-figma.json`.
  /// Return path bila berhasil, null bila pengguna membatalkan.
  Future<String?> saveToFile({
    required String pageName,
    required String json,
  }) async {
    final outputPath = await FilePicker.saveFile(
      dialogTitle: 'Ekspor payload Figma',
      fileName: '${_safeName(pageName)}.$fileExtension',
      type: FileType.any,
    );
    if (outputPath == null) return null;
    try {
      await File(outputPath).writeAsString(json, flush: true);
      return outputPath;
    } catch (_) {
      throw FigmaExportException(
        AppErrorCode.exportWriteFailed,
        detail: outputPath,
      );
    }
  }

  /// Salin payload ke clipboard agar bisa ditempel langsung di plugin Figma.
  Future<void> copyToClipboard(String json) async {
    await Clipboard.setData(ClipboardData(text: json));
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
