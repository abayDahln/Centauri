import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../canvas_preview/data/services/canvas_service_registry.dart';
import '../../canvas_preview/data/services/canvas_webview_service.dart';
import '../../canvas_preview/domain/dom_tree.dart';
import '../../canvas_preview/domain/page.dart';
import '../../canvas_preview/presentation/provider/workspace_provider.dart';

class McpException implements Exception {
  McpException(this.message, {this.code = -32603});
  final String message;
  final int code;

  @override
  String toString() => message;
}

/// Jembatan antara MCP server dan state aplikasi.
/// Baca: langsung dari [workspaceProvider].
/// Tulis: SELALU via jalur yang sama seperti seleksi/overlay —
/// inject JS → minta HTML penuh → rebuild tree → [WorkspaceNotifier.updatePageHtml].
/// HTML di WebView tetap source of truth; tidak ada state ganda.
class McpBridge {
  McpBridge(this._container);

  final ProviderContainer _container;

  WorkspaceState get _state => _container.read(workspaceProvider);
  WorkspaceNotifier get _notifier =>
      _container.read(workspaceProvider.notifier);

  AppPage _resolvePage(String? pageId) {
    final state = _state;
    if (pageId != null) {
      for (final p in state.pages) {
        if (p.id == pageId) return p;
      }
      throw McpException('Page "$pageId" tidak ditemukan.', code: -32602);
    }
    final active = state.activePage;
    if (active == null) {
      throw McpException(
        'Belum ada halaman aktif. Generate UI dulu atau sertakan pageId.',
        code: -32602,
      );
    }
    return active;
  }

  CanvasWebviewService _serviceFor(String pageId) {
    final service = CanvasServiceRegistry.forFrame(pageId);
    if (service == null) {
      throw McpException(
        'WebView halaman "$pageId" belum siap. Tunggu sebentar lalu coba lagi.',
      );
    }
    return service;
  }

  /// Tunggu SATU event bertipe [types] dari halaman, dengan timeout.
  Future<CanvasSelectEvent> _awaitEvent(
    CanvasWebviewService service,
    Set<String> types, {
    Duration timeout = const Duration(seconds: 12),
  }) {
    return service.selectionEvents
        .firstWhere((e) => types.contains(e.type))
        .timeout(
          timeout,
          onTimeout: () => throw McpException(
            'Timeout menunggu WebView (kemungkinan halaman sibuk). Coba lagi.',
          ),
        );
  }

  /// Terapkan mutasi JS lalu sinkronkan HTML + tree ke Dart.
  Future<Map<String, dynamic>> _mutateAndSync({
    required AppPage page,
    required Future<void> Function(CanvasWebviewService service) mutate,
  }) async {
    final service = _serviceFor(page.id);
    final htmlFuture = _awaitEvent(service, {'html'});
    await mutate(service);
    await service.requestHtml();
    final event = await htmlFuture;
    final html = event.html;
    if (html == null || html.trim().isEmpty) {
      throw McpException('Sinkronisasi HTML gagal (dokumen kosong).');
    }
    final tree = await buildDomTreeInIsolate(html);
    _notifier.updatePageHtml(
      pageId: page.id,
      stampedHtml: tree.stampedHtml,
      tree: tree,
    );
    return {'ok': true, 'pageId': page.id, 'nodeCount': tree.nodeCount};
  }

  // ---------------------------------------------------------------- baca --

  Map<String, dynamic> snapshot() {
    final state = _state;
    return {
      'pages': [
        for (final p in state.pages)
          {
            'id': p.id,
            'name': p.name,
            'slug': p.slug,
            'nodeCount': p.domTree?.nodeCount ?? 0,
          },
      ],
      'activePageId': state.activePageId,
      'selectedNodeId': state.selectedNodeId,
    };
  }

  Map<String, dynamic> getStructure() => {
    'ok': true,
    ...snapshot(),
    'layers': _state.activePage?.domTree?.root.toJson(),
  };

  Map<String, dynamic> getSelected() {
    final state = _state;
    final id = state.selectedNodeId;
    final geometry = state.selectedNodeGeometry;
    if (id == null || geometry == null) {
      return {'ok': true, 'selected': null};
    }
    return {
      'ok': true,
      'selected': {
        'pageId': state.activePageId,
        'nodeId': id,
        'tag': geometry.tag,
        'rect': {
          'x': geometry.x,
          'y': geometry.y,
          'width': geometry.width,
          'height': geometry.height,
        },
        'styles': geometry.styles,
      },
    };
  }

  Future<Map<String, dynamic>> getNodeHtml(String nodeId) async {
    final page = _resolvePage(null);
    final service = _serviceFor(page.id);
    final future = _awaitEvent(service, {'outerHtml', 'outerHtmlError'});
    await service.requestOuterHtml(nodeId);
    final event = await future;
    if (event.type != 'outerHtml' || event.html == null) {
      throw McpException('Node "$nodeId" tidak ditemukan.', code: -32602);
    }
    return {
      'ok': true,
      'pageId': page.id,
      'nodeId': nodeId,
      'html': event.html,
    };
  }

  // --------------------------------------------------------------- tulis --

  Future<Map<String, dynamic>> addNode({
    String? pageId,
    String? parentId,
    required String html,
    String? position,
  }) async {
    final page = _resolvePage(pageId);
    const allowed = {'beforeend', 'afterbegin', 'beforebegin', 'afterend'};
    final pos = (position ?? 'beforeend').trim();
    if (!allowed.contains(pos)) {
      throw McpException(
        'position harus salah satu: ${allowed.join(', ')}.',
        code: -32602,
      );
    }
    if (html.trim().isEmpty) {
      throw McpException('html tidak boleh kosong.', code: -32602);
    }
    if (parentId != null) {
      final tree = page.domTree;
      if (tree == null || tree.findById(parentId) == null) {
        throw McpException(
          'parentId "$parentId" tidak ditemukan.',
          code: -32602,
        );
      }
    }
    return _mutateAndSync(
      page: page,
      mutate: (service) =>
          service.addNode(parentId, html.trim(), position: pos),
    );
  }

  Future<Map<String, dynamic>> updateNode({
    String? pageId,
    required String nodeId,
    String? text,
    Map<String, String>? styles,
  }) async {
    final page = _resolvePage(pageId);
    final tree = page.domTree;
    if (tree == null || tree.findById(nodeId) == null) {
      throw McpException('Node "$nodeId" tidak ditemukan.', code: -32602);
    }
    if (text == null && (styles == null || styles.isEmpty)) {
      throw McpException('Sertakan "text" dan/atau "styles".', code: -32602);
    }
    return _mutateAndSync(
      page: page,
      mutate: (service) async {
        if (text != null) await service.setNodeText(nodeId, text);
        if (styles != null && styles.isNotEmpty) {
          await service.applyNodeStyle(nodeId, styles);
        }
      },
    );
  }

  Future<Map<String, dynamic>> deleteNode({
    String? pageId,
    required String nodeId,
  }) async {
    final page = _resolvePage(pageId);
    final tree = page.domTree;
    if (tree == null || tree.findById(nodeId) == null) {
      throw McpException('Node "$nodeId" tidak ditemukan.', code: -32602);
    }
    return _mutateAndSync(
      page: page,
      mutate: (service) => service.deleteNode(nodeId),
    );
  }

  /// Pindah/ubah ukuran satu node (satu-satunya tool layout sekarang).
  /// Delta CSS via inline style.
  Future<Map<String, dynamic>> rearrangeLayout({
    String? pageId,
    String? id,
    double? dx,
    double? dy,
    double? width,
    double? height,
  }) async {
    final nodeId = id;
    if (nodeId == null) {
      throw McpException('Sertakan "id" node.', code: -32602);
    }
    final page = _resolvePage(pageId);
    final tree = page.domTree;
    if (tree == null || tree.findById(nodeId) == null) {
      throw McpException('Node "$nodeId" tidak ditemukan.', code: -32602);
    }
    return _mutateAndSync(
      page: page,
      mutate: (service) => service.moveResizeNode(
        nodeId,
        dx: dx,
        dy: dy,
        width: width,
        height: height,
      ),
    );
  }
}
