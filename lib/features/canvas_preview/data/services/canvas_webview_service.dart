import 'dart:convert';

import 'package:flutter/material.dart';

/// Event seleksi yang datang dari canvas (picker di dalam iframe).
class CanvasSelectEvent {
  const CanvasSelectEvent({required this.type, required this.id});

  /// `select` saat elemen diklik, `hover` saat pointer melewatinya.
  final String type;

  /// Id node (`data-centauri-id`), null saat hover keluar.
  final String? id;

  static CanvasSelectEvent? tryParse(Object? raw) {
    if (raw is! String || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final type = decoded['type'];
      if (type is! String) return null;
      final id = decoded['id'];
      return CanvasSelectEvent(type: type, id: id is String ? id : null);
    } on FormatException {
      return null;
    }
  }
}

/// Abstraksi WebView canvas agar implementasi Android (webview_flutter)
/// dan Windows (webview_windows) bisa diisolasi per-platform.
abstract class CanvasWebviewService {
  /// Inisialisasi controller native + memuat shell HTML.
  Future<void> init();

  /// Render HTML hasil generate. Null = reset canvas ke placeholder.
  Future<void> renderHtml(String? html);

  /// Atur lebar viewport canvas (null = lebar penuh). FR-07.
  Future<void> setViewportWidth(double? widthPx);

  /// Faktor zoom CSS pada stage canvas (1.0 = normal).
  Future<void> setZoom(double factor);

  /// Tandai node sebagai terpilih (selection box + scroll into view).
  Future<void> selectNode(String? id);

  /// Tandai node sebagai hover (hover box).
  Future<void> hoverNode(String? id);

  /// Event seleksi/hover yang berasal dari klik di dalam canvas.
  Stream<CanvasSelectEvent> get selectionEvents;

  /// Widget WebView. Hanya valid setelah [init] selesai.
  Widget buildView();

  Future<void> dispose();
}
