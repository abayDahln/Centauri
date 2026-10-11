import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'canvas_shell.dart';
import 'canvas_webview_service.dart';

/// Implementasi canvas WebView untuk Android (dan iOS) memakai
/// `webview_flutter`.
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
      ..setBackgroundColor(const Color(0xFF0F0F11))
      ..addJavaScriptChannel(
        'centauriBridge',
        onMessageReceived: (message) {
          final event = CanvasSelectEvent.tryParse(message.message);
          if (event != null && !_selectionEvents.isClosed) {
            _selectionEvents.add(event);
          }
        },
      );

    await _controller.loadHtmlString(canvasShellHtml);
    _ready = true;

    // Push state yang mungkin sudah berubah sebelum init selesai.
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

  @override
  Future<void> renderHtml(String? html) async {
    _pendingHtml = html;
    if (!_ready || _disposed) return;
    if (html == null) {
      await _controller.runJavaScript('window.clearCanvas()');
      return;
    }
    await _controller.runJavaScript('window.renderCanvas(${jsonEncode(html)})');
  }

  @override
  Future<void> setViewportWidth(double? widthPx) async {
    _pendingViewportWidth = widthPx;
    if (!_ready || _disposed) return;
    await _controller.runJavaScript('window.setViewport(${widthPx ?? 'null'})');
  }

  @override
  Future<void> setZoom(double factor) async {
    _pendingZoom = factor;
    if (!_ready || _disposed) return;
    await _controller.runJavaScript('window.setZoom($factor)');
  }

  @override
  Future<void> selectNode(String? id) async {
    if (!_ready || _disposed) return;
    await _controller.runJavaScript(
      'window.centauriSelect(${id == null ? 'null' : jsonEncode(id)})',
    );
  }

  @override
  Future<void> hoverNode(String? id) async {
    if (!_ready || _disposed) return;
    await _controller.runJavaScript(
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
}
