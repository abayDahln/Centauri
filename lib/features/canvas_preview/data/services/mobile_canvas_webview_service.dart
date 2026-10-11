import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'canvas_shell.dart';
import 'canvas_webview_service.dart';

/// Implementasi canvas WebView untuk Android (dan iOS) memakai
/// `webview_flutter`.
class MobileCanvasWebviewService implements CanvasWebviewService {
  late final WebViewController _controller;

  bool _ready = false;
  String? _pendingHtml;
  double? _pendingViewportWidth;
  bool _disposed = false;

  @override
  Future<void> init() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F0F11))
      ..addJavaScriptChannel(
        'centauriBridge',
        onMessageReceived: (_) {},
      );

    await _controller.loadHtmlString(canvasShellHtml);
    _ready = true;

    // Push state yang mungkin sudah berubah sebelum init selesai.
    if (_pendingViewportWidth != null) {
      await setViewportWidth(_pendingViewportWidth);
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
    await _controller.runJavaScript(
      'window.renderCanvas(${jsonEncode(html)})',
    );
  }

  @override
  Future<void> setViewportWidth(double? widthPx) async {
    _pendingViewportWidth = widthPx;
    if (!_ready || _disposed) return;
    await _controller.runJavaScript(
      'window.setViewport(${widthPx ?? 'null'})',
    );
  }

  @override
  Widget buildView() => WebViewWidget(controller: _controller);

  @override
  Future<void> dispose() async {
    _disposed = true;
  }
}
