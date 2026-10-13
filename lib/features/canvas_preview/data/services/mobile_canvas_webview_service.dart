import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'canvas_shell.dart';
import 'canvas_webview_service.dart';

/// Implementasi canvas WebView untuk Android (dan iOS) memakai
/// `webview_flutter`.
///
/// Arsitektur render: dokumen konten dimuat LANGSUNG via `loadHtmlString`
/// dengan bridge JS di-inject ke dalam HTML (lihat [injectBridge]). Tidak ada
/// iframe — menghilangkan kelas bug "frame kosong + bridge mati".
class MobileCanvasWebviewService implements CanvasWebviewService {
  late final WebViewController _controller;
  final StreamController<CanvasSelectEvent> _selectionEvents =
      StreamController<CanvasSelectEvent>.broadcast();

  bool _ready = false;
  String? _pendingHtml;
  double? _pendingViewportWidth;
  double _pendingZoom = 1;
  bool _disposed = false;

  @override
  Stream<CanvasSelectEvent> get selectionEvents => _selectionEvents.stream;

  @override
  Future<void> init() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..addJavaScriptChannel(
        'centauriBridge',
        onMessageReceived: (message) {
          final event = CanvasSelectEvent.tryParse(message.message);
          if (event != null && !_selectionEvents.isClosed) {
            _selectionEvents.add(event);
          }
        },
      );

    _ready = true;

    // Push state yang mungkin sudah berubah sebelum init selesai.
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
      await _controller.loadHtmlString(_emptyDocument);
      return;
    }

    // Inject bridge (mobile TIDAK pakai native zoom → transform CSS).
    final document = injectBridge(html, nativeZoom: false);
    await _controller.loadHtmlString(document);

    // Terapkan state tampilan yang mungkin sudah berubah sebelum dokumen siap.
    await setViewportWidth(_pendingViewportWidth);
    await setZoom(_pendingZoom);
  }

  @override
  Future<void> setViewportWidth(double? widthPx) async {
    _pendingViewportWidth = widthPx;
    if (!_ready || _disposed) return;
    await _safeRun('window.setViewport(${widthPx ?? 'null'})');
  }

  @override
  Future<void> setZoom(double factor) async {
    _pendingZoom = factor;
    if (!_ready || _disposed) return;
    await _safeRun('window.setZoom($factor)');
  }

  @override
  Future<void> selectNode(String? id) async {
    if (!_ready || _disposed) return;
    await _safeRun(
      'window.centauriSelect(${id == null ? 'null' : jsonEncode(id)})',
    );
  }

  @override
  Future<void> requestNodeGeometry(String id) async {
    if (!_ready || _disposed) return;
    await _safeRun('window.centauriInspect(${jsonEncode(id)})');
  }

  @override
  Future<void> applyNodeStyle(String id, Map<String, String> patch) async {
    if (!_ready || _disposed) return;
    await _safeRun(
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
    await _safeRun(
      'window.centauriMoveResize(${jsonEncode(id)}, ${jsonEncode(box)})',
    );
  }

  @override
  Future<void> requestFramePng({double pixelRatio = 2}) async {
    if (!_ready || _disposed) return;
    await _safeRun('window.centauriExportPng($pixelRatio)');
  }

  @override
  Future<void> addNode(String? parentId, String html, {String? position}) async {
    if (!_ready || _disposed) return;
    await _safeRun(
      'window.centauriAddNode('
      '${parentId == null ? 'null' : jsonEncode(parentId)}, '
      '${jsonEncode(html)}, '
      '${jsonEncode(position ?? 'beforeend')})',
    );
  }

  @override
  Future<void> setNodeText(String id, String text) async {
    if (!_ready || _disposed) return;
    await _safeRun(
      'window.centauriSetText(${jsonEncode(id)}, ${jsonEncode(text)})',
    );
  }

  @override
  Future<void> deleteNode(String id) async {
    if (!_ready || _disposed) return;
    await _safeRun('window.centauriDeleteNode(${jsonEncode(id)})');
  }

  @override
  Future<void> requestHtml() async {
    if (!_ready || _disposed) return;
    await _safeRun('window.centauriGetHtml()');
  }

  @override
  Future<void> requestOuterHtml(String id) async {
    if (!_ready || _disposed) return;
    await _safeRun('window.centauriGetOuterHtml(${jsonEncode(id)})');
  }

  @override
  Future<void> hoverNode(String? id) async {
    if (!_ready || _disposed) return;
    await _safeRun(
      'window.centauriHover(${id == null ? 'null' : jsonEncode(id)})',
    );
  }

  @override
  Widget buildView() => WebViewWidget(controller: _controller);

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _selectionEvents.close();
  }

  /// `runJavaScript` yang aman: kegagalan JS (mis. bridge belum ada karena
  /// dokumen belum siap) dilaporkan, bukan jadi unhandled error.
  Future<void> _safeRun(String script) async {
    try {
      await _controller.runJavaScript(script);
    } catch (e) {
      debugPrint('[canvas] runJavaScript gagal: $e');
    }
  }

  static const String _emptyDocument =
      '<!DOCTYPE html><html><body style="margin:0;height:100vh;'
      'display:flex;align-items:center;justify-content:center;'
      'background:#FFFFFF"></body></html>';
}
