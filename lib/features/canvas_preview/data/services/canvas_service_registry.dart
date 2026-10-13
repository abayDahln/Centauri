import 'canvas_webview_service.dart';

/// Registry service WebView per frame agar panel non-canvas (inspector,
/// MCP nanti) bisa menulis ke frame aktif via jalur yang sama seperti
/// overlay: inject JS → inline style. HTML di WebView tetap source of truth.
class CanvasServiceRegistry {
  static final Map<String, CanvasWebviewService> _services = {};

  static void register(String frameId, CanvasWebviewService service) {
    _services[frameId] = service;
  }

  static void unregister(String frameId) {
    _services.remove(frameId);
  }

  static CanvasWebviewService? forFrame(String frameId) =>
      _services[frameId];
}
