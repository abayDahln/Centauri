import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';

import 'canvas_shell.dart';
import 'canvas_webview_service.dart';

/// Implementasi canvas WebView untuk Windows memakai `webview_windows`
/// (WebView2 runtime).
///
/// Arsitektur render: dokumen konten dimuat LANGSUNG via `loadStringContent`
/// (WebView2 `NavigateToString`) dengan bridge JS di-inject ke dalam HTML
/// (lihat [injectBridge]). Tidak ada iframe — menghilangkan kelas bug
/// "frame kosong + bridge mati" pada konteks `about:blank`.
class WindowsCanvasWebviewService implements CanvasWebviewService {
  final WebviewController _controller = WebviewController();
  final StreamController<CanvasSelectEvent> _selectionEvents =
      StreamController<CanvasSelectEvent>.broadcast();

  StreamSubscription<dynamic>? _messageSubscription;
  StreamSubscription<LoadingState>? _loadStateSubscription;

  bool _ready = false;
  bool _disposed = false;
  String? _pendingHtml;
  double? _pendingViewportWidth;
  double _pendingZoom = 1;

  /// Completer yang di-reset setiap renderHtml: menandai navigasi dokumen
  /// konten selesai (navigationCompleted top-level).
  Completer<void>? _navigationCompleter;

  @override
  Stream<CanvasSelectEvent> get selectionEvents => _selectionEvents.stream;

  @override
  Future<void> init() async {
    await _controller.initialize();
    await _controller.setBackgroundColor(const Color(0xFFFFFFFF));

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

    // Gagal navigasi (mis. WebView2 rusak) jangan diam: catat + laporkan ke
    // stream agar frame menampilkan pesan error, bukan putih kosong.
    _controller.onLoadError.listen((status) {
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

  @override
  Future<void> renderHtml(String? html) async {
    _pendingHtml = html;
    if (!_ready || _disposed) return;

    if (html == null || html.isEmpty) {
      await _controller.loadStringContent(_emptyDocument);
      return;
    }

    // Inject bridge (native zoom aktif di Windows) lalu muat sebagai dokumen
    // konten nyata. Ini juga menyelesaikan masalah event JS→Dart yang dulu
    // mati karena dokumen shell `about:blank` tanpa chrome.webview.
    final document = injectBridge(html, nativeZoom: true);

    _navigationCompleter = Completer<void>();
    await _controller.loadStringContent(document);
    // Tunggu navigasi selesai agar setViewport/setZoom tidak balapan dengan
    // pemuatan dokumen (dulu `_waitForDomReady` bisa selesai prematur).
    await _navigationCompleter!.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {},
    );

    // Terapkan state tampilan yang mungkin sudah berubah.
    await setViewportWidth(_pendingViewportWidth);
    await setZoom(_pendingZoom);
  }

  @override
  Future<void> setViewportWidth(double? widthPx) async {
    _pendingViewportWidth = widthPx;
    if (!_ready || _disposed) return;
    await _safeExecute('window.setViewport(${widthPx ?? 'null'})');
  }

  @override
  Future<void> setZoom(double factor) async {
    _pendingZoom = factor;
    if (!_ready || _disposed) return;
    // ZoomFactor WebView2 menskalakan piksel CSS: viewport CSS menjadi
    // (lebar widget * dpr) / (dpr * factor), sehingga desain tetap pada lebar
    // CSS aslinya namun dirender tajam saat board di-zoom.
    final clamped = factor.clamp(0.1, 5.0);
    try {
      await _controller.setZoomFactor(clamped);
    } catch (e) {
      debugPrint('[canvas] setZoomFactor gagal: $e');
    }
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
  Future<void> addNode(String? parentId, String html, {String? position}) async {
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

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _messageSubscription?.cancel();
    await _loadStateSubscription?.cancel();
    await _selectionEvents.close();
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
