import 'package:flutter/material.dart';

/// Abstraksi WebView canvas agar implementasi Android (webview_flutter)
/// dan Windows (webview_windows) bisa diisolasi per-platform.
abstract class CanvasWebviewService {
  /// Inisialisasi controller native + memuat shell HTML.
  Future<void> init();

  /// Render HTML hasil generate. Null = reset canvas ke placeholder.
  Future<void> renderHtml(String? html);

  /// Atur lebar viewport canvas (null = lebar penuh). FR-07.
  Future<void> setViewportWidth(double? widthPx);

  /// Widget WebView. Hanya valid setelah [init] selesai.
  Widget buildView();

  Future<void> dispose();
}
