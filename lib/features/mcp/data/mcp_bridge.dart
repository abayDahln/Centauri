import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../canvas_preview/data/services/canvas_service_registry.dart';
import '../../canvas_preview/data/services/canvas_webview_service.dart';
import '../../canvas_preview/domain/board_frame.dart';
import '../../canvas_preview/domain/dom_tree.dart';
import '../../canvas_preview/presentation/provider/canvas_provider.dart';

class McpException implements Exception {
  McpException(this.message, {this.code = -32603});
  final String message;
  final int code;

  @override
  String toString() => message;
}

/// Jembatan antara MCP server dan state aplikasi (Fase 4: Desktop Full).
/// Baca: langsung dari [canvasProvider].
/// Tulis: SELALU via jalur yang sama seperti inspector/overlay —
/// inject JS → minta HTML penuh → rebuild tree → [updateFrameHtml].
/// HTML di WebView tetap source of truth; tidak ada state ganda.
class McpBridge {
  McpBridge(this._container);

  final ProviderContainer _container;

  CanvasState get _state => _container.read(canvasProvider);
  CanvasNotifier get _notifier => _container.read(canvasProvider.notifier);

  BoardFrame _resolveFrame(String? frameId) {
    final state = _state;
    if (frameId != null) {
      for (final f in state.frames) {
        if (f.id == frameId) return f;
      }
      throw McpException('Frame "$frameId" tidak ditemukan.', code: -32602);
    }
    final active = state.activeFrame;
    if (active == null) {
      throw McpException(
        'Belum ada frame aktif. Generate UI dulu atau sertakan frameId.',
        code: -32602,
      );
    }
    return active;
  }

  CanvasWebviewService _serviceFor(String frameId) {
    final service = CanvasServiceRegistry.forFrame(frameId);
    if (service == null) {
      throw McpException(
        'WebView frame "$frameId" belum siap. Tunggu sebentar lalu coba lagi.',
      );
    }
    return service;
  }

  /// Tunggu SATU event bertipe [types] dari frame, dengan timeout.
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
            'Timeout menunggu WebView (kemungkinan frame sibuk). Coba lagi.',
          ),
        );
  }

  /// Terapkan mutasi JS lalu sinkronkan HTML + tree ke Dart.
  Future<Map<String, dynamic>> _mutateAndSync({
    required BoardFrame frame,
    required Future<void> Function(CanvasWebviewService service) mutate,
  }) async {
    final service = _serviceFor(frame.id);
    final htmlFuture = _awaitEvent(service, {'html'});
    await mutate(service);
    // Minta dokumen penuh SETELAH mutasi dikirim.
    await service.requestHtml();
    final event = await htmlFuture;
    final html = event.html;
    if (html == null || html.trim().isEmpty) {
      throw McpException('Sinkronisasi HTML gagal (dokumen kosong).');
    }
    final tree = await buildDomTreeInIsolate(html);
    _notifier.updateFrameHtml(
      frameId: frame.id,
      stampedHtml: tree.stampedHtml,
      tree: tree,
    );
    return {'ok': true, 'frameId': frame.id, 'nodeCount': tree.nodeCount};
  }

  // ---------------------------------------------------------------- baca --

  Map<String, dynamic> snapshot() {
    final state = _state;
    return {
      'frames': [
        for (final f in state.frames)
          {
            'id': f.id,
            'title': f.title,
            'width': f.size.width,
            'height': f.size.height,
            'offsetX': f.offset.dx,
            'offsetY': f.offset.dy,
            'nodeCount': f.domTree?.nodeCount ?? 0,
          },
      ],
      'activeFrameId': state.activeFrameId,
      'selectedNodeId': state.selectedNodeId,
    };
  }

  Map<String, dynamic> getStructure() => {
    'ok': true,
    ...snapshot(),
    'layers': _state.activeFrame?.domTree?.root.toJson(),
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
        'frameId': state.activeFrameId,
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
    final frame = _resolveFrame(null);
    final service = _serviceFor(frame.id);
    final future = _awaitEvent(service, {'outerHtml', 'outerHtmlError'});
    await service.requestOuterHtml(nodeId);
    final event = await future;
    if (event.type != 'outerHtml' || event.html == null) {
      throw McpException('Node "$nodeId" tidak ditemukan.', code: -32602);
    }
    return {'ok': true, 'frameId': frame.id, 'nodeId': nodeId, 'html': event.html};
  }

  // --------------------------------------------------------------- tulis --

  Future<Map<String, dynamic>> addNode({
    String? frameId,
    String? parentId,
    required String html,
    String? position,
  }) async {
    final frame = _resolveFrame(frameId);
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
      final tree = frame.domTree;
      if (tree == null || tree.findById(parentId) == null) {
        throw McpException('parentId "$parentId" tidak ditemukan.', code: -32602);
      }
    }
    return _mutateAndSync(
      frame: frame,
      mutate: (service) =>
          service.addNode(parentId, html.trim(), position: pos),
    );
  }

  Future<Map<String, dynamic>> updateNode({
    String? frameId,
    required String nodeId,
    String? text,
    Map<String, String>? styles,
  }) async {
    final frame = _resolveFrame(frameId);
    final tree = frame.domTree;
    if (tree == null || tree.findById(nodeId) == null) {
      throw McpException('Node "$nodeId" tidak ditemukan.', code: -32602);
    }
    if (text == null && (styles == null || styles.isEmpty)) {
      throw McpException(
        'Sertakan "text" dan/atau "styles".',
        code: -32602,
      );
    }
    return _mutateAndSync(
      frame: frame,
      mutate: (service) async {
        if (text != null) await service.setNodeText(nodeId, text);
        if (styles != null && styles.isNotEmpty) {
          await service.applyNodeStyle(nodeId, styles);
        }
      },
    );
  }

  Future<Map<String, dynamic>> deleteNode({
    String? frameId,
    required String nodeId,
  }) async {
    final frame = _resolveFrame(frameId);
    final tree = frame.domTree;
    if (tree == null || tree.findById(nodeId) == null) {
      throw McpException('Node "$nodeId" tidak ditemukan.', code: -32602);
    }
    return _mutateAndSync(
      frame: frame,
      mutate: (service) => service.deleteNode(nodeId),
    );
  }

  /// Pindah/ubah ukuran frame ATAU node (satu-satunya tool layout).
  /// Frame: geser offset board (snap ikut berlaku, garis tampil live).
  /// Node: delta CSS via inline style (jalur overlay Fase 1).
  Future<Map<String, dynamic>> rearrangeLayout({
    String target = 'node',
    String? frameId,
    String? id,
    double? dx,
    double? dy,
    double? width,
    double? height,
  }) async {
    if (target == 'frame') {
      final frame = _resolveFrame(frameId ?? id);
      final deltaX = dx ?? 0;
      final deltaY = dy ?? 0;
      if (deltaX == 0 && deltaY == 0) {
        throw McpException('Sertakan dx dan/atau dy.', code: -32602);
      }
      _notifier.moveFrame(frame.id, Offset(deltaX, deltaY));
      final updated = _notifierFrame(frame.id);
      return {
        'ok': true,
        'target': 'frame',
        'frameId': frame.id,
        'offsetX': updated?.offset.dx,
        'offsetY': updated?.offset.dy,
      };
    }

    // target node (default).
    final nodeId = id;
    if (nodeId == null) {
      throw McpException('Sertakan "id" node.', code: -32602);
    }
    final frame = _resolveFrame(frameId);
    final tree = frame.domTree;
    if (tree == null || tree.findById(nodeId) == null) {
      throw McpException('Node "$nodeId" tidak ditemukan.', code: -32602);
    }
    return _mutateAndSync(
      frame: frame,
      mutate: (service) => service.moveResizeNode(
        nodeId,
        dx: dx,
        dy: dy,
        width: width,
        height: height,
      ),
    );
  }

  BoardFrame? _notifierFrame(String frameId) {
    for (final f in _state.frames) {
      if (f.id == frameId) return f;
    }
    return null;
  }
}
