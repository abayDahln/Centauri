import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:webview_windows/webview_windows.dart';

import 'canvas_shell.dart';
import 'canvas_webview_service.dart';

/// Implementasi canvas WebView untuk Windows memakai `webview_windows`
/// (WebView2 runtime).
///
/// Arsitektur render: dokumen konten ditulis ke BERKAS lokal di folder temp
/// unik per-instance, folder itu di-map ke host virtual `https://<host>/`,
/// lalu dimuat via `loadUrl`. Bridge JS di-inject ke dalam HTML (lihat
/// [injectBridge]) dan tidak ada iframe.
///
/// Kenapa file + virtual host, bukan `loadStringContent`?
/// `loadStringContent` = WebView2 `NavigateToString`, yang memberi dokumen
/// origin `about:blank` (opaque). Origin opaque MEMBLOKIR pemuatan subresource
/// jaringan (mis. gambar https://picsum.photos/...), sehingga semua gambar
/// gagal → fallback gradien + alt muncul. Dengan memetakan folder ke host
/// virtual ber-protokol `https`, dokumen punya origin web normal dan gambar
/// eksternal dimuat seperti browser biasa.
class WindowsCanvasWebviewService implements CanvasWebviewService {
  final WebviewController _controller = WebviewController();
  final StreamController<CanvasSelectEvent> _selectionEvents =
      StreamController<CanvasSelectEvent>.broadcast();

  StreamSubscription<dynamic>? _messageSubscription;
  StreamSubscription<LoadingState>? _loadStateSubscription;
  StreamSubscription<String>? _urlSubscription;

  /// Error navigasi diabaikan sampai waktu ini: kita sendiri yang
  /// membatalkan navigasi internal (lihat [_onUrlChanged]).
  DateTime? _ignoreLoadErrorUntil;

  bool _ready = false;
  bool _disposed = false;
  String? _pendingHtml;

  /// Host virtual unik per-instance + folder temp-nya. Dipetakan dengan
  /// [WebviewController.addVirtualHostNameMapping] agar dokumen punya origin
  /// `https://<host>/` (bukan `about:blank`).
  final String _virtualHost = 'canvas-${const Uuid().v4()}.local';
  Directory? _tempDir;
  File? _documentFile;

  /// Completer yang di-reset setiap renderHtml: menandai navigasi dokumen
  /// konten selesai (navigationCompleted top-level).
  Completer<void>? _navigationCompleter;

  @override
  Stream<CanvasSelectEvent> get selectionEvents => _selectionEvents.stream;

  @override
  Future<void> init() async {
    await _controller.initialize();
    await _controller.setBackgroundColor(const Color(0xFFFFFFFF));
    // Dokumen konten ditulis ulang in-place; matikan cache agar WebView2 selalu
    // memuat versi terbaru (bukan index.html lama).
    try {
      await _controller.setCacheDisabled(true);
    } catch (e) {
      debugPrint('[canvas] setCacheDisabled gagal: $e');
    }

    // Siapkan folder temp + host virtual SEBELUM dokumen pertama dimuat.
    await _ensureVirtualHost();

    _messageSubscription = _controller.webMessage.listen((message) {
      final event = CanvasSelectEvent.tryParse(message);
      if (event != null && !_selectionEvents.isClosed) {
        _selectionEvents.add(event);
      }
    });

    // Navigasi selesai (dokumen konten) → lepaskan renderHtml yang menunggu.
    _loadStateSubscription = _controller.loadingState.listen((state) {
      if (state == LoadingState.navigationCompleted) {
        final completer = _navigationCompleter;
        if (completer != null && !completer.isCompleted) completer.complete();
      }
    });

    // Navigasi yang dipicu JS di dalam halaman (mis. `location.href`) tidak
    // boleh dimuat WebView: batalkan lalu teruskan ke host sebagai pindah
    // halaman. Tanpa ini WebView2 gagal memuat file yang tidak ada.
    _urlSubscription = _controller.url.listen(_onUrlChanged);

    // Gagal navigasi (mis. WebView2 rusak) jangan diam: catat + laporkan ke
    // stream agar frame menampilkan pesan error, bukan putih kosong.
    _controller.onLoadError.listen((status) {
      final ignoreUntil = _ignoreLoadErrorUntil;
      if (ignoreUntil != null && DateTime.now().isBefore(ignoreUntil)) {
        return;
      }
      // Dokumen lokal yang navigasinya dibatalkan bukan kegagalan nyata.
      if (status == WebErrorStatus.WebErrorStatusConnectionAborted) {
        debugPrint('[canvas] navigasi dibatalkan (diabaikan)');
        return;
      }
      debugPrint('[canvas] WebView load error: $status');
      if (!_selectionEvents.isClosed) {
        _selectionEvents.add(
          CanvasSelectEvent(
            type: 'error',
            id: null,
            errorMessage: 'WebView gagal memuat: $status',
          ),
        );
      }
    });

    _ready = true;

    if (_pendingHtml != null) {
      final html = _pendingHtml;
      _pendingHtml = null;
      await renderHtml(html);
    }
  }

  /// Siapkan folder temp + mapping host virtual. Idempoten.
  Future<void> _ensureVirtualHost() async {
    if (_tempDir != null) return;
    try {
      final dir = await Directory.systemTemp.createTemp('centauri_canvas_');
      _tempDir = dir;
      _documentFile = File('${dir.path}${Platform.pathSeparator}index.html');
      await dir.create(recursive: true);
      await _controller.addVirtualHostNameMapping(
        _virtualHost,
        dir.path,
        WebviewHostResourceAccessKind.allow,
      );
    } catch (e) {
      debugPrint('[canvas] gagal menyiapkan virtual host: $e');
      _tempDir = null;
      _documentFile = null;
    }
  }

  /// Tulis [document] ke berkas lalu muat via URL host virtual (origin https).
  /// Fallback ke `loadStringContent` bila file/virtual host tak tersedia.
  Future<void> _loadDocument(String document) async {
    await _ensureVirtualHost();
    if (_documentFile == null) {
      await _controller.loadStringContent(document);
      return;
    }
    try {
      await _documentFile!.writeAsString(document, flush: true);
      // Cache-buster: tiap render memuat URL berbeda agar WebView2 tidak
      // menyajikan berkas lama dari cache (dokumen ditulis ulang in-place).
      final stamp = DateTime.now().microsecondsSinceEpoch;
      await _controller.loadUrl('https://$_virtualHost/index.html?v=$stamp');
    } catch (e) {
      debugPrint('[canvas] load file gagal, fallback loadStringContent: $e');
      await _controller.loadStringContent(document);
    }
  }

  @override
  Future<void> renderHtml(String? html) async {
    _pendingHtml = html;
    if (!_ready || _disposed) return;

    if (html == null || html.isEmpty) {
      await _loadDocument(_emptyDocument);
      return;
    }

    // Inject bridge lalu muat sebagai dokumen konten nyata. Origin web
    // (https://host-virtual) membuat gambar eksternal dapat dimuat.
    final document = injectBridge(html);

    _navigationCompleter = Completer<void>();
    await _loadDocument(document);
    await _navigationCompleter!.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {},
    );
  }

  @override
  Future<void> setSelectionMode(bool enabled) async {
    if (!_ready || _disposed) return;
    await _safeExecute(
      "window.centauriSetMode('${enabled ? 'select' : 'interact'}')",
    );
  }

  @override
  Future<void> requestDocumentSize() async {
    if (!_ready || _disposed) return;
    await _safeExecute('window.centauriGetSize()');
  }

  @override
  Future<void> requestFigmaPayload({int width = 0, int height = 0}) async {
    if (!_ready || _disposed) return;
    await _safeExecute('window.centauriExportFigma($width, $height)');
  }

  @override
  Future<void> selectNode(String? id) async {
    if (!_ready || _disposed) return;
    await _safeExecute(
      'window.centauriSelect(${id == null ? 'null' : jsonEncode(id)})',
    );
  }

  @override
  Future<void> requestNodeGeometry(String id) async {
    if (!_ready || _disposed) return;
    await _safeExecute('window.centauriInspect(${jsonEncode(id)})');
  }

  @override
  Future<void> applyNodeStyle(String id, Map<String, String> patch) async {
    if (!_ready || _disposed) return;
    await _safeExecute(
      'window.centauriApplyStyle(${jsonEncode(id)}, ${jsonEncode(patch)})',
    );
  }

  @override
  Future<void> moveResizeNode(
    String id, {
    double? dx,
    double? dy,
    double? width,
    double? height,
  }) async {
    if (!_ready || _disposed) return;
    final box = <String, Object?>{
      if (dx != null) 'dx': dx,
      if (dy != null) 'dy': dy,
      if (width != null) 'w': width,
      if (height != null) 'h': height,
    };
    await _safeExecute(
      'window.centauriMoveResize(${jsonEncode(id)}, ${jsonEncode(box)})',
    );
  }

  @override
  Future<void> requestFramePng({double pixelRatio = 2}) async {
    if (!_ready || _disposed) return;
    await _safeExecute('window.centauriExportPng($pixelRatio)');
  }

  @override
  Future<void> addNode(
    String? parentId,
    String html, {
    String? position,
  }) async {
    if (!_ready || _disposed) return;
    await _safeExecute(
      'window.centauriAddNode('
      '${parentId == null ? 'null' : jsonEncode(parentId)}, '
      '${jsonEncode(html)}, '
      '${jsonEncode(position ?? 'beforeend')})',
    );
  }

  @override
  Future<void> setNodeText(String id, String text) async {
    if (!_ready || _disposed) return;
    await _safeExecute(
      'window.centauriSetText(${jsonEncode(id)}, ${jsonEncode(text)})',
    );
  }

  @override
  Future<void> deleteNode(String id) async {
    if (!_ready || _disposed) return;
    await _safeExecute('window.centauriDeleteNode(${jsonEncode(id)})');
  }

  @override
  Future<void> requestHtml() async {
    if (!_ready || _disposed) return;
    await _safeExecute('window.centauriGetHtml()');
  }

  @override
  Future<void> requestOuterHtml(String id) async {
    if (!_ready || _disposed) return;
    await _safeExecute('window.centauriGetOuterHtml(${jsonEncode(id)})');
  }

  @override
  Future<void> hoverNode(String? id) async {
    if (!_ready || _disposed) return;
    await _safeExecute(
      'window.centauriHover(${id == null ? 'null' : jsonEncode(id)})',
    );
  }

  @override
  Widget buildView() => Webview(_controller);

  /// Tangkap navigasi yang dipicu halaman sendiri (mis. `location.href`).
  /// Navigasi dibatalkan agar WebView tidak memuat URL yang tidak ada, lalu
  /// host yang mengganti halaman lewat event `navigate`.
  void _onUrlChanged(String url) {
    if (_disposed) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (uri.scheme == 'about' || uri.scheme == 'data' || uri.scheme == 'blob') {
      return;
    }
    String? href;
    if (uri.host == _virtualHost) {
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.isEmpty) return;
      final file = Uri.decodeComponent(segments.last);
      // Dokumen aktif kita sendiri (index.html) — bukan pindah halaman.
      if (file == 'index.html') return;
      href = file;
    } else if (uri.scheme == 'http' || uri.scheme == 'https') {
      href = url;
    }
    if (href == null) return;

    _ignoreLoadErrorUntil = DateTime.now().add(const Duration(seconds: 2));
    _controller.stop();
    if (!_selectionEvents.isClosed) {
      _selectionEvents.add(
        CanvasSelectEvent(type: 'navigate', id: null, href: href),
      );
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _messageSubscription?.cancel();
    await _loadStateSubscription?.cancel();
    await _urlSubscription?.cancel();
    await _selectionEvents.close();
    // Lepas mapping host virtual + hapus folder temp (jangan bocorkan file).
    try {
      await _controller.removeVirtualHostNameMapping(_virtualHost);
    } catch (e) {
      debugPrint('[canvas] gagal menghapus virtual host: $e');
    }
    try {
      final dir = _tempDir;
      if (dir != null && dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('[canvas] gagal menghapus folder temp: $e');
    }
    _tempDir = null;
    _documentFile = null;
    await _controller.dispose();
  }

  /// `executeScript` yang aman: kegagalan JS (mis. fungsi bridge belum ada
  /// karena dokumen belum siap) dilaporkan, bukan jadi unhandled error.
  Future<void> _safeExecute(String script) async {
    try {
      await _controller.executeScript(script);
    } catch (e) {
      debugPrint('[canvas] executeScript gagal: $e');
    }
  }

  static const String _emptyDocument =
      '<!DOCTYPE html><html><body style="margin:0;height:100vh;'
      'display:flex;align-items:center;justify-content:center;'
      'background:#FFFFFF"></body></html>';
}
