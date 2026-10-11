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

  bool _ready = false;
  bool _disposed = false;
  String? _pendingHtml;
  double? _pendingViewportWidth;

  @override
  Future<void> init() async {
    await _controller.initialize();
    await _controller.setBackgroundColor(const Color(0xFF0F0F11));
    await _controller.loadStringContent(canvasShellHtml);

    // Pastikan DOM shell sudah siap sebelum executeScript.
    await _waitForDomReady();
    _ready = true;

    if (_pendingViewportWidth != null) {
      await setViewportWidth(_pendingViewportWidth);
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
    await completer.future
        .timeout(const Duration(seconds: 5), onTimeout: () {});
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
    await _controller.executeScript(
      'window.renderCanvas(${jsonEncode(html)})',
    );
  }

  @override
  Future<void> setViewportWidth(double? widthPx) async {
    _pendingViewportWidth = widthPx;
    if (!_ready || _disposed) return;
    await _controller.executeScript(
      'window.setViewport(${widthPx ?? 'null'})',
    );
  }

  @override
  Widget buildView() => Webview(_controller);

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _controller.dispose();
  }
}
