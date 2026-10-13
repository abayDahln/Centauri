import 'dart:convert';

import 'package:flutter/material.dart';

/// Geometri + gaya terkomputasi satu node DOM, dilaporkan JS bridge.
/// HTML tetap source of truth; model ini hanya cache tampilan untuk overlay
/// native (Fase 1). Tidak ada layout engine di Dart.
class NodeGeometry {
  const NodeGeometry({
    required this.id,
    required this.tag,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.styles = const {},
  });

  final String id;
  final String tag;
  final double x;
  final double y;
  final double width;
  final double height;

  /// Subset `getComputedStyle` (mis. display, position, color, fontSize...).
  final Map<String, String> styles;

  static NodeGeometry? tryParse(String id, Map<String, dynamic> json) {
    try {
      final rect = json['rect'];
      if (rect is! Map) return null;
      double numOf(Object? v) => (v as num?)?.toDouble() ?? 0;
      final rawStyles = json['styles'];
      final styles = <String, String>{};
      if (rawStyles is Map) {
        rawStyles.forEach((k, v) {
          if (k is String && v != null) styles[k] = v.toString();
        });
      }
      return NodeGeometry(
        id: id,
        tag: (json['tag'] ?? '').toString(),
        x: numOf(rect['x']),
        y: numOf(rect['y']),
        width: numOf(rect['w'] ?? rect['width']),
        height: numOf(rect['h'] ?? rect['height']),
        styles: styles,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Event seleksi yang datang dari canvas (picker di dalam iframe).
class CanvasSelectEvent {
  const CanvasSelectEvent({
    required this.type,
    required this.id,
    this.contentHeight,
    this.geometry,
    this.dataUrl,
    this.errorMessage,
    this.html,
  });

  /// `select` saat elemen diklik, `hover` saat pointer melewatinya,
  /// `resize` saat dokumen melaporkan tinggi kontennya,
  /// `geometry` saat JS melaporkan bbox + computed style satu node,
  /// `png` saat ekspor PNG selesai (dataUrl PNG),
  /// `pngError` saat ekspor PNG gagal,
  /// `html` saat JS mengirim dokumen penuh (sinkronisasi pasca-mutasi MCP),
  /// `outerHtml` saat JS mengirim HTML satu node.
  final String type;

  /// Id node (`data-centauri-id`), null saat hover keluar.
  final String? id;

  /// Tinggi konten dokumen (untuk event `resize`).
  final double? contentHeight;

  /// Geometri node (untuk event `geometry`).
  final NodeGeometry? geometry;

  /// Data URL PNG (untuk event `png`).
  final String? dataUrl;

  /// Pesan error (untuk event `pngError`).
  final String? errorMessage;

  /// HTML dokumen penuh (untuk event `html`) atau satu node (`outerHtml`).
  final String? html;

  static CanvasSelectEvent? tryParse(Object? raw) {
    // webview_windows (Desktop) men-decode JSON sebelum ke Dart, sehingga
    // listener menerima Map. webview_flutter (mobile) via JS channel
    // menerima String mentah. Keduanya didukung agar bridge hidup di
    // semua platform — sebelumnya Map selalu dibuang (return null) dan
    // seluruh event JS->Dart di Windows mati diam-diam.
    final Map<String, dynamic> decoded;
    if (raw is Map<String, dynamic>) {
      decoded = raw;
    } else if (raw is Map) {
      decoded = Map<String, dynamic>.from(raw);
    } else if (raw is String) {
      if (raw.trim().isEmpty) return null;
      try {
        final value = jsonDecode(raw);
        if (value is! Map<String, dynamic>) return null;
        decoded = value;
      } on FormatException {
        return null;
      }
    } else {
      return null;
    }
    try {
      final type = decoded['type'];
      if (type is! String) return null;
      final id = decoded['id'];
      final height = decoded['height'];
      NodeGeometry? geometry;
      if (type == 'geometry' && id is String) {
        geometry = NodeGeometry.tryParse(id, decoded);
      }
      final dataUrl = decoded['dataUrl'];
      final message = decoded['message'];
      final html = decoded['html'];
      return CanvasSelectEvent(
        type: type,
        id: id is String ? id : null,
        contentHeight: height is num ? height.toDouble() : null,
        geometry: geometry,
        dataUrl: dataUrl is String ? dataUrl : null,
        errorMessage: message is String ? message : null,
        html: html is String ? html : null,
      );
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
  /// Implementasi JS juga mengirim balik event `geometry` agar overlay
  /// native bisa menggambar box yang akurat.
  Future<void> selectNode(String? id);

  /// Tandai node sebagai hover (hover box).
  Future<void> hoverNode(String? id);

  /// Minta JS melaporkan `geometry` satu node via event stream.
  /// Dipakai setelah select dari layers panel / setelah move-resize.
  Future<void> requestNodeGeometry(String id);

  /// Tulis patch inline style ke DOM: `el.style[k] = v`.
  /// HTML tetap truth; ini satu-satunya jalur tulis Fase 1.
  Future<void> applyNodeStyle(String id, Map<String, String> patch);

  /// Pindah/ubah ukuran via inline style (relative-position aman + w/h).
  /// Move sebagai DELTA CSS px (dx/dy ditambah ke left/top), resize sebagai
  /// ukuran absolut (width/height). HTML tetap truth.
  Future<void> moveResizeNode(
    String id, {
    double? dx,
    double? dy,
    double? width,
    double? height,
  });

  /// Minta JS merender dokumen frame menjadi PNG via event `png`/`pngError`.
  /// Hasil tiba asinkron di [selectionEvents] (Fase 3).
  Future<void> requestFramePng({double pixelRatio = 2});

  /// Mutasi DOM untuk MCP bridge (Fase 4). Hasil akhir selalu disinkronkan
  /// ulang via [requestHtml] agar HTML tetap source of truth.
  /// [position]: beforeend/afterbegin/beforebegin/afterend (default beforeend).
  Future<void> addNode(String? parentId, String html, {String? position});
  Future<void> setNodeText(String id, String text);
  Future<void> deleteNode(String id);

  /// Minta JS mengirim dokumen penuh (`html`) / satu node (`outerHtml`).
  Future<void> requestHtml();
  Future<void> requestOuterHtml(String id);

  /// Event seleksi/hover yang berasal dari klik di dalam canvas.
  Stream<CanvasSelectEvent> get selectionEvents;

  /// Widget WebView. Hanya valid setelah [init] selesai.
  Widget buildView();

  Future<void> dispose();
}
