import 'dart:convert';

import 'package:flutter/material.dart';

/// Satu simpul pada rantai induk→anak (breadcrumb menu elemen).
@immutable
class NodeAncestor {
  const NodeAncestor({
    required this.id,
    required this.tag,
    required this.label,
  });

  final String id;
  final String tag;

  /// Label ringkas, mis. `section.card` atau `h1 · Reset Password`.
  final String label;

  static NodeAncestor? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    if (id is! String || id.isEmpty) return null;
    final tag = raw['tag'];
    final label = raw['label'];
    return NodeAncestor(
      id: id,
      tag: tag is String ? tag : '',
      label: label is String ? label : '',
    );
  }
}

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
    this.chain = const [],
    this.text = '',
    this.textNodeId = '',
    this.textStyles = const {},
    this.textBox,
    this.textEditable = false,
    this.textRect,
  });

  final String id;
  final String tag;
  final double x;
  final double y;
  final double width;
  final double height;

  /// Subset `getComputedStyle` (mis. display, position, color, fontSize...).
  final Map<String, String> styles;

  /// Rantai elemen dari paling luar sampai yang terpilih (breadcrumb).
  final List<NodeAncestor> chain;

  /// Teks langsung elemen (tanpa teks anak), kosong bila elemen bukan teks.
  final String text;

  /// Id elemen pembawa teks. Sama dengan [id] bila teks ada di elemen ini,
  /// atau id anaknya bila label komponen disimpan di anak (mis. span di
  /// dalam tombol).
  final String textNodeId;

  /// Gaya tipografi elemen pembawa teks, bila berbeda dari [styles].
  final Map<String, String> textStyles;

  /// Kotak isi elemen pembawa teks (setelah padding/border) — lebar wrap
  /// sebenarnya, dipakai editor agar pemenggalan baris sama dengan halaman.
  final Rect? textBox;

  /// True bila [text] bisa diedit inline (elemen teks tanpa anak elemen).
  final bool textEditable;

  /// Kotak teks terlihat dalam koordinat viewport WebView (CSS px).
  final Rect? textRect;

  /// Elemen induk langsung pada [chain], null bila sudah paling luar.
  NodeAncestor? get parent {
    if (chain.length < 2) return null;
    return chain[chain.length - 2];
  }

  static NodeGeometry? tryParse(String id, Map<String, dynamic> json) {
    try {
      final rect = json['rect'];
      if (rect is! Map) return null;
      double numOf(Object? v) => (v as num?)?.toDouble() ?? 0;
      Rect parseRect(Object? raw) {
        if (raw is! Map) return const Rect.fromLTWH(0, 0, 0, 0);
        return Rect.fromLTWH(
          numOf(raw['x']),
          numOf(raw['y']),
          numOf(raw['w'] ?? raw['width']),
          numOf(raw['h'] ?? raw['height']),
        );
      }

      final rawTextStyles = json['textStyles'];
      final textStyles = <String, String>{};
      if (rawTextStyles is Map) {
        rawTextStyles.forEach((k, v) {
          if (k is String && v != null) textStyles[k] = v.toString();
        });
      }
      final rawStyles = json['styles'];
      final styles = <String, String>{};
      if (rawStyles is Map) {
        rawStyles.forEach((k, v) {
          if (k is String && v != null) styles[k] = v.toString();
        });
      }
      final rawChain = json['chain'];
      final chain = <NodeAncestor>[];
      if (rawChain is List) {
        for (final item in rawChain) {
          final ancestor = NodeAncestor.tryParse(item);
          if (ancestor != null) chain.add(ancestor);
        }
      }
      final text = json['text'];
      final hasTextRect = json['textRect'] is Map;
      return NodeGeometry(
        id: id,
        tag: (json['tag'] ?? '').toString(),
        x: numOf(rect['x']),
        y: numOf(rect['y']),
        width: numOf(rect['w'] ?? rect['width']),
        height: numOf(rect['h'] ?? rect['height']),
        styles: styles,
        chain: chain,
        text: text is String ? text : '',
        textNodeId: json['textId'] is String ? json['textId'] as String : '',
        textStyles: textStyles,
        textBox: json['textBox'] is Map ? parseRect(json['textBox']) : null,
        textEditable: json['textEditable'] == true,
        textRect: hasTextRect ? parseRect(json['textRect']) : null,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Event seleksi yang datang dari preview.
class CanvasSelectEvent {
  const CanvasSelectEvent({
    required this.type,
    required this.id,
    this.contentHeight,
    this.contentWidth,
    this.scrollX,
    this.scrollY,
    this.geometry,
    this.dataUrl,
    this.errorMessage,
    this.html,
    this.href,
    this.label,
    this.payload,
  });

  /// `select` saat elemen diklik, `hover` saat pointer melewatinya,
  /// `size` saat JS melaporkan ukuran dokumen (lebar & tinggi konten),
  /// `navigate` saat user mengklik `<a href>` (link antar-halaman / eksternal),
  /// `geometry` saat JS melaporkan bbox + computed style satu node,
  /// `png` saat ekspor PNG selesai (dataUrl PNG),
  /// `pngError` saat ekspor PNG gagal,
  /// `figma` saat ekspor struktur halaman untuk plugin Figma,
  /// `figmaError` saat ekspor Figma gagal,
  /// `html` saat JS mengirim dokumen penuh (sinkronisasi pasca-mutasi MCP),
  /// `outerHtml` saat JS mengirim HTML satu node,
  /// `scroll` saat dokumen digulir (menu elemen harus menyingkir),
  /// `cancelled` saat user menekan Escape di dalam canvas.
  final String type;

  /// Id node (`data-centauri-id`), null saat hover keluar.
  final String? id;

  /// Tinggi konten dokumen (untuk event `size`).
  final double? contentHeight;

  /// Lebar konten dokumen (untuk event `size`).
  final double? contentWidth;

  /// Posisi gulir dokumen (untuk event `scroll`).
  final double? scrollX;
  final double? scrollY;

  /// Geometri node (untuk event `geometry`).
  final NodeGeometry? geometry;

  /// Data URL PNG (untuk event `png`).
  final String? dataUrl;

  /// Pesan error (untuk event `pngError`).
  final String? errorMessage;

  /// HTML dokumen penuh (untuk event `html`) atau satu node (`outerHtml`).
  final String? html;

  /// Target link yang diklik (untuk event `navigate`).
  final String? href;

  /// Label ringkas elemen (untuk event `select`/`editWithAi`), mis.
  /// `button · Masukkan Keranjang`.
  final String? label;

  /// Payload struktur halaman (untuk event `figma`): tree node + ukuran.
  final Map<String, dynamic>? payload;

  static CanvasSelectEvent? tryParse(Object? raw) {
    // webview_windows (Desktop) men-decode JSON sebelum ke Dart, sehingga
    // listener menerima Map. webview_flutter (mobile) via JS channel
    // menerima String mentah. Keduanya didukung.
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
      final width = decoded['width'];
      NodeGeometry? geometry;
      if ((type == 'geometry' || type == 'textLayout') && id is String) {
        geometry = NodeGeometry.tryParse(id, decoded);
      }
      final scrollX = decoded['x'];
      final scrollY = decoded['y'];
      final dataUrl = decoded['dataUrl'];
      final message = decoded['message'];
      final html = decoded['html'];
      final href = decoded['href'];
      final label = decoded['label'];
      final payload = decoded['payload'];
      return CanvasSelectEvent(
        type: type,
        id: id is String ? id : null,
        contentHeight: height is num ? height.toDouble() : null,
        contentWidth: width is num ? width.toDouble() : null,
        scrollX: scrollX is num ? scrollX.toDouble() : null,
        scrollY: scrollY is num ? scrollY.toDouble() : null,
        geometry: geometry,
        dataUrl: dataUrl is String ? dataUrl : null,
        errorMessage: message is String ? message : null,
        html: html is String ? html : null,
        href: href is String ? href : null,
        label: label is String ? label : null,
        payload: payload is Map ? Map<String, dynamic>.from(payload) : null,
      );
    } on FormatException {
      return null;
    }
  }
}

/// Abstraksi WebView preview agar implementasi Android (webview_flutter)
/// dan Windows (webview_windows) bisa diisolasi per-platform.
abstract class CanvasWebviewService {
  /// Inisialisasi controller native + memuat dokumen.
  Future<void> init();

  /// Render HTML halaman. Null = reset ke placeholder kosong.
  Future<void> renderHtml(String? html);

  /// Aktif/matikan mode seleksi elemen.
  ///
  /// Nonaktif (default): klik, hover, dan input berjalan seperti halaman biasa;
  /// hanya `<a href>` antar-halaman yang tetap di-intercept. Aktif: klik
  /// memilih elemen dan menampilkan menu aksi.
  Future<void> setSelectionMode(bool enabled);

  /// Tandai node sebagai terpilih (selection box + scroll into view).
  /// Implementasi JS juga mengirim balik event `geometry`.
  Future<void> selectNode(String? id);

  /// Tandai node sebagai hover (hover box).
  Future<void> hoverNode(String? id);

  /// Warna overlay seleksi (hex `#RRGGBB`) — dikirim dari palet tema supaya
  /// kotak seleksi di dalam WebView ikut warna aksen aplikasi.
  Future<void> setSelectionAccent(String hexColor);

  /// Gulir dokumen ke posisi tertentu (CSS px). Dipakai untuk memulihkan
  /// posisi baca setelah dokumen dirender ulang pasca mutasi.
  Future<void> scrollTo(double x, double y);

  /// Tampilkan HTML parsial saat generate TANPA navigasi: isi dokumen yang
  /// sudah dimuat diganti di tempat, sehingga bridge tetap hidup dan posisi
  /// gulir tidak hilang. [html] null = keluar dari mode pratinjau.
  Future<void> previewHtml(String? html);

  /// Tandai node yang sedang diedit inline (dipakai JS untuk membedakan)
  /// mode edit dari mode seleksi biasa).
  ///
  /// [ringId] adalah elemen yang ring-nya digambar JS — biasanya elemen yang
  /// dipilih di kanvas, bukan target tulis di dalamnya, supaya indikatornya
  /// mengikuti bentuk komponen (border-radius, padding).
  Future<void> setTextEditing(String id, bool editing, {String? ringId});

  /// Tulis teks sambil mengetik tanpa memutus sesi edit: DOM ikut berubah
  /// sehingga ukuran/layout komponen menyesuaikan real-time. JS membalas
  /// dengan event `textLayout` berisi geometri terbaru.
  Future<void> liveTextUpdate(String id, String text);

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

  /// Minta JS merender dokumen halaman menjadi PNG via event `png`/`pngError`.
  /// Hasil tiba asinkron di [selectionEvents].
  Future<void> requestFramePng({double pixelRatio = 2});

  /// Minta JS melaporkan ukuran dokumen (lebar & tinggi konten) via event
  /// `size` (dipakai ekspor SVG tanpa viewport fixed).
  Future<void> requestDocumentSize();

  /// Minta JS mengekspor struktur halaman untuk plugin Figma via event
  /// `figma`/`figmaError`.
  ///
  /// [width] dan [height] > 0 → halaman dirender ulang di iframe dengan
  /// ukuran itu supaya hasilnya memakai layout desktop, bukan ukuran
  /// pratinjau saat ini.
  Future<void> requestFigmaPayload({int width = 0, int height = 0});

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
