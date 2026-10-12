import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';

import 'canvas_shell.dart';
import 'canvas_webview_service.dart';

/// Implementasi canvas WebView untuk Windows memakai `webview_windows`
/// (WebView2 runtime).
class WindowsCanvasWebviewService implements CanvasWebviewService {
  final WebviewController _controller = WebviewController();
  final StreamController<CanvasSelectEvent> _selectionEvents =
      StreamController<CanvasSelectEvent>.broadcast();

  StreamSubscription<dynamic>? _messageSubscription;

  bool _ready = false;
  bool _disposed = false;
  String? _pendingHtml;
  double? _pendingViewportWidth;
  double _pendingZoom = 1;

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

    await _controller.loadStringContent(canvasShellHtml);

    // Pastikan DOM shell sudah siap sebelum executeScript.
    await _waitForDomReady();
    // Beri tahu shell bahwa skala ditangani zoomFactor native WebView2.
    await _controller.executeScript('window.centauriSetNativeZoom(true)');
    _ready = true;

    if (_pendingViewportWidth != null) {
      await setViewportWidth(_pendingViewportWidth);
    }
    if (_pendingZoom != 1) {
      await setZoom(_pendingZoom);
    }
    if (_pendingHtml != null) {
      final html = _pendingHtml;
      _pendingHtml = null;
      await renderHtml(html);
    }
  }

  Future<void> _waitForDomReady() async {
    final completer = Completer<void>();
    late StreamSubscription<LoadingState> subscription;

    subscription = _controller.loadingState.listen((state) {
      if (state == LoadingState.navigationCompleted && !completer.isCompleted) {
        completer.complete();
      }
    });

    // Fallback timeout bila event tidak pernah datang.
    await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {});
    await subscription.cancel();
  }

  @override
  Future<void> renderHtml(String? html) async {
    _pendingHtml = html;
    if (!_ready || _disposed) return;
    if (html == null) {
      await _controller.executeScript('window.clearCanvas()');
      return;
    }
    await _controller.executeScript('window.renderCanvas(${jsonEncode(html)})');
  }

  @override
  Future<void> setViewportWidth(double? widthPx) async {
    _pendingViewportWidth = widthPx;
    if (!_ready || _disposed) return;
    await _controller.executeScript('window.setViewport(${widthPx ?? 'null'})');
  }

  @override
  Future<void> setZoom(double factor) async {
    _pendingZoom = factor;
    if (!_ready || _disposed) return;
    // ZoomFactor WebView2 menskalakan piksel CSS: viewport CSS menjadi
    // (lebar widget * dpr) / (dpr * factor), sehingga desain tetap pada lebar
    // CSS aslinya namun dirender tajam saat board di-zoom.
    final clamped = factor.clamp(0.1, 5.0);
    await _controller.setZoomFactor(clamped);
  }

  @override
  Future<void> selectNode(String? id) async {
    if (!_ready || _disposed) return;
    await _controller.executeScript(
      'window.centauriSelect(${id == null ? 'null' : jsonEncode(id)})',
    );
  }

  @override
  Future<void> hoverNode(String? id) async {
    if (!_ready || _disposed) return;
    await _controller.executeScript(
      'window.centauriHover(${id == null ? 'null' : jsonEncode(id)})',
    );
  }

  @override
  Widget buildView() => Webview(_controller);

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _messageSubscription?.cancel();
    await _selectionEvents.close();
    await _controller.dispose();
  }
}
