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
  bool _disposed = false;

  /// True saat dokumen konten sedang dimuat (navigasi awal harus diizinkan).
  bool _loadingDocument = false;

  /// Base URL dokumen konten agar link relatif (`home.html`) teresolusi.
  static const String _baseUrl = 'https://centauri.local/';

  @override
  Stream<CanvasSelectEvent> get selectionEvents => _selectionEvents.stream;

  @override
  Future<void> init() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            // Navigasi awal (loadHtmlString) harus diizinkan.
            if (_loadingDocument) return NavigationDecision.navigate;
            final url = request.url;
            if (url.startsWith('about:') ||
                url.startsWith('data:') ||
                url.startsWith('blob:')) {
              return NavigationDecision.navigate;
            }
            // Navigasi top-level lain (klik link yang lolos intersep JS):
            // cegat, teruskan ke Dart.
            final uri = Uri.tryParse(url);
            final href = (uri != null && uri.host == 'centauri.local')
                ? uri.path.replaceFirst('/', '') +
                      (uri.query.isEmpty ? '' : '?${uri.query}')
                : url;
            if (!_selectionEvents.isClosed) {
              _selectionEvents.add(
                CanvasSelectEvent(type: 'navigate', id: null, href: href),
              );
            }
            return NavigationDecision.prevent;
          },
        ),
      )
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

    _loadingDocument = true;
    try {
      if (html == null || html.isEmpty) {
        // Bridge tetap dipasang walau dokumen kosong: pratinjau saat generate
        // butuh `window.centauriPreview` sebelum halaman pertama ada.
        await _controller.loadHtmlString(
          injectBridge(_emptyDocument),
          baseUrl: _baseUrl,
        );
        return;
      }
      final document = injectBridge(html);
      await _controller.loadHtmlString(document, baseUrl: _baseUrl);
    } finally {
      _loadingDocument = false;
    }
  }

  @override
  Future<void> setSelectionMode(bool enabled) async {
    if (!_ready || _disposed) return;
    await _safeRun(
      "window.centauriSetMode('${enabled ? 'select' : 'interact'}')",
    );
  }

  @override
  Future<void> requestDocumentSize() async {
    if (!_ready || _disposed) return;
    await _safeRun('window.centauriGetSize()');
  }

  @override
  Future<void> requestFigmaPayload({int width = 0, int height = 0}) async {
    if (!_ready || _disposed) return;
    await _safeRun('window.centauriExportFigma($width, $height)');
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
      'dx': ?dx,
      'dy': ?dy,
      'w': ?width,
      'h': ?height,
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
  Future<void> addNode(
    String? parentId,
    String html, {
    String? position,
  }) async {
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
  Future<void> scrollTo(double x, double y) async {
    if (!_ready || _disposed) return;
    await _safeRun('window.centauriScrollTo($x, $y)');
  }

  /// Batas payload yang masih aman lewat channel JS di mobile.
  static const int _maxPreviewChars = 400000;

  @override
  Future<void> previewHtml(String? html) async {
    if (!_ready || _disposed) return;
    if (html == null) {
      await _safeRun(
        'window.centauriPreviewEnd && window.centauriPreviewEnd()',
      );
      return;
    }
    if (html.length > _maxPreviewChars) return;
    await _safeRun(
      'window.centauriPreview && window.centauriPreview('
      '${jsonEncode({'html': html})})',
    );
  }

  @override
  Future<void> setSelectionAccent(String hexColor) async {
    if (!_ready || _disposed) return;
    await _safeRun('window.centauriSetAccent(${jsonEncode(hexColor)})');
  }

  @override
  Future<void> liveTextUpdate(String id, String text) async {
    if (!_ready || _disposed) return;
    await _safeRun(
      'window.centauriLiveText(${jsonEncode(id)}, ${jsonEncode(text)})',
    );
  }

  @override
  Future<void> setTextEditing(String id, bool editing, {String? ringId}) async {
    if (!_ready || _disposed) return;
    await _safeRun(
      'window.centauriSetTextEditing(${jsonEncode(id)}, '
      '${editing ? 'true' : 'false'}, '
      '${jsonEncode(ringId ?? id)})',
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
