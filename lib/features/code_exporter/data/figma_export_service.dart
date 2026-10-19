import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

import '../../canvas_preview/data/services/canvas_service_registry.dart';
import '../../../core/errors/app_error.dart';

/// Kegagalan ekspor Figma; membawa kode yang diterjemahkan di UI.
class FigmaExportException extends AppErrorDetails implements Exception {
  const FigmaExportException(super.code, {super.detail});

  @override
  String toString() => debugLabel;
}

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
  Future<Map<String, dynamic>> collectPayload(String pageId) async {
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
    await service.requestFigmaPayload();

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
