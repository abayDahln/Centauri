import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mcp_bridge.dart';

/// Embedded MCP server lokal (Fase 4: Desktop Full).
/// Berjalan di background versi Desktop, di `127.0.0.1` (coba 8765 → 8774).
///
/// - `GET /status` — info server + ringkasan canvas (tanpa auth, localhost saja).
/// - `POST /mcp` — JSON-RPC 2.0: `initialize`, `tools/list`, `tools/call`, `ping`.
/// - `GET /events` — Server-Sent Events: event `state` setiap ada perubahan
///   board (live sync; agent fetch ulang via tools, tanpa refresh aplikasi).
///
/// Semua tulis melewati [McpBridge] (jalur inspector/overlay yang sama).
final mcpServerProvider = Provider<McpServer>((ref) => McpServer());

class McpServer {
  HttpServer? _server;
  McpBridge? _bridge;
  int _stateVersion = 0;

  final Set<_SseClient> _sseClients = {};

  Timer? _heartbeat;

  bool get isRunning => _server != null;
  int? get port => _server?.port;
  String? get endpoint =>
      _server == null ? null : 'http://127.0.0.1:${_server!.port}/mcp';
  int get stateVersion => _stateVersion;

  /// Ikat bridge lalu nyalakan server. Idempoten (panggil sekali).
  Future<void> start({required McpBridge bridge}) async {
    if (isRunning) {
      _bridge = bridge;
      return;
    }
    _bridge = bridge;
    HttpServer? bound;
    for (var port = 8765; port <= 8774; port++) {
      try {
        bound = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
        break;
      } on SocketException {
        continue;
      }
    }
    if (bound == null) {
      debugPrint('[mcp] Gagal bind port 8765-8774. MCP server mati.');
      return;
    }
    _server = bound;
    debugPrint('[mcp] Berjalan di http://127.0.0.1:${bound.port} '
        '(POST /mcp, GET /events, GET /status)');
    _heartbeat = Timer.periodic(const Duration(seconds: 25), (_) {
      _broadcast(event: 'ping', data: {'stateVersion': _stateVersion});
    });
    bound.listen(_route);
  }

  /// Beri tahu semua klien SSE bahwa state berubah (live sync).
  void notifyState() {
    _stateVersion++;
    final snapshot = _bridge?.snapshot();
    _broadcast(event: 'state', data: {
      'stateVersion': _stateVersion,
      if (snapshot != null) ...snapshot,
    });
  }

  Future<void> stop() async {
    _heartbeat?.cancel();
    _heartbeat = null;
    for (final client in _sseClients.toList()) {
      try {
        await client.response.close();
      } catch (_) {}
    }
    _sseClients.clear();
    await _server?.close(force: true);
    _server = null;
  }

  // ---------------------------------------------------------------- rute --

  Future<void> _route(HttpRequest request) async {
    // CORS longgar: localhost saja, agar agent berbasis browser bisa akses.
    request.response.headers
      ..set('Access-Control-Allow-Origin', '*')
      ..set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
      ..set('Access-Control-Allow-Headers', 'Content-Type');

    try {
      if (request.method == 'OPTIONS') {
        request.response.statusCode = HttpStatus.noContent;
        await request.response.close();
        return;
      }
      final path = request.uri.path;
      if (request.method == 'GET' && path == '/status') {
        _handleStatus(request);
        return;
      }
      if (request.method == 'GET' && path == '/events') {
        _handleSse(request);
        return;
      }
      if (request.method == 'POST' && (path == '/mcp' || path == '/')) {
        await _handleRpc(request);
        return;
      }
      request.response.statusCode = HttpStatus.notFound;
      _writeJson(request.response, {'error': 'not found: $path'});
      await request.response.close();
    } catch (e) {
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        _writeJson(request.response, {'error': '$e'});
        await request.response.close();
      } catch (_) {}
    }
  }

  void _handleStatus(HttpRequest request) async {
    _writeJson(request.response, {
      'name': 'centauri-canvas',
      'version': '1.0.0',
      'transport': ['http-json-rpc', 'sse'],
      'mcp': request.uri.replace(path: '/mcp').toString(),
      'sse': request.uri.replace(path: '/events').toString(),
      'stateVersion': _stateVersion,
      'workspace': _bridge?.snapshot(),
    });
    await request.response.close();
  }

  void _handleSse(HttpRequest request) {
    final response = request.response;
    response.headers
      ..set('Content-Type', 'text/event-stream')
      ..set('Cache-Control', 'no-cache')
      ..set('Connection', 'keep-alive');
    response.statusCode = HttpStatus.ok;

    final client = _SseClient(response);
    _sseClients.add(client);
    // Sapaan awal agar agent langsung tahu versi state.
    client.send('state', {
      'stateVersion': _stateVersion,
      if (_bridge?.snapshot() case final snapshot?) ...snapshot,
    });

    // Tetap buka sampai klien pergi; jangan close di sini.
    response.done
        .then((_) => _sseClients.remove(client))
        .catchError((Object _) {
          _sseClients.remove(client);
          return true;
        });
  }

  Future<void> _handleRpc(HttpRequest request) async {
    final raw = await utf8.decodeStream(request);
    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      _writeJson(request.response, _rpcError(null, -32700, 'Parse error'));
      await request.response.close();
      return;
    }

    if (decoded is List) {
      // Batch: proses satu per satu (tanpa notifikasi paralel).
      final out = <Map<String, dynamic>>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) out.add(await _dispatch(item));
      }
      _writeJson(request.response, out);
      await request.response.close();
      return;
    }
    if (decoded is! Map<String, dynamic>) {
      _writeJson(request.response, _rpcError(null, -32600, 'Invalid Request'));
      await request.response.close();
      return;
    }
    final result = await _dispatch(decoded);
    // Notifikasi (tanpa id) tidak dibalas, sesuai JSON-RPC.
    if (!decoded.containsKey('id')) {
      request.response.statusCode = HttpStatus.accepted;
      await request.response.close();
      return;
    }
    _writeJson(request.response, result);
    await request.response.close();
  }

  Future<Map<String, dynamic>> _dispatch(Map<String, dynamic> req) async {
    final id = req['id'];
    final method = req['method'];
    if (method is! String) {
      return _rpcError(id, -32600, 'Invalid Request: method harus string.');
    }
    try {
      switch (method) {
        case 'initialize':
          return _rpcOk(id, {
            'protocolVersion': '2024-11-05',
            'capabilities': {
              'tools': {},
            },
            'serverInfo': {'name': 'centauri-canvas', 'version': '1.0.0'},
          });
        case 'notifications/initialized':
          return _rpcOk(id, {});
        case 'ping':
          return _rpcOk(id, {});
        case 'tools/list':
          return _rpcOk(id, {'tools': toolSchemas()});
        case 'tools/call':
          final params = req['params'];
          if (params is! Map<String, dynamic>) {
            return _rpcError(id, -32602, 'params harus object.');
          }
          final result = await _callTool(
            params['name'],
            params['arguments'],
          );
          return _rpcOk(id, {
            'content': [
              {'type': 'text', 'text': jsonEncode(result)},
            ],
          });
        default:
          return _rpcError(id, -32601, 'Method tidak dikenal: $method');
      }
    } on McpException catch (e) {
      return _rpcError(id, e.code, e.message);
    } catch (e) {
      return _rpcError(id, -32603, 'Internal error: $e');
    }
  }

  Future<Map<String, dynamic>> _callTool(dynamic name, dynamic args) async {
    final bridge = _bridge;
    if (bridge == null) {
      throw McpException('Bridge belum siap. Buka halaman board dulu.');
    }
    final arguments = args is Map<String, dynamic> ? args : <String, dynamic>{};
    if (name is! String) {
      throw McpException('Nama tool harus string.', code: -32602);
    }

    switch (name) {
      case 'get_canvas_structure':
        return bridge.getStructure();
      case 'get_selected_node':
        return bridge.getSelected();
      case 'get_node_html':
        final nodeId = arguments['nodeId'];
        if (nodeId is! String || nodeId.isEmpty) {
          throw McpException('Argumen "nodeId" wajib.', code: -32602);
        }
        return bridge.getNodeHtml(nodeId);
      case 'add_node':
        final html = arguments['html'];
        if (html is! String || html.trim().isEmpty) {
          throw McpException('Argumen "html" wajib.', code: -32602);
        }
        return bridge.addNode(
          pageId: _optString(arguments['pageId'] ?? arguments['frameId']),
          parentId: _optString(arguments['parentId']),
          html: html,
          position: _optString(arguments['position']),
        );
      case 'update_node':
        final nodeId = arguments['nodeId'];
        if (nodeId is! String || nodeId.isEmpty) {
          throw McpException('Argumen "nodeId" wajib.', code: -32602);
        }
        final rawStyles = arguments['styles'];
        Map<String, String>? styles;
        if (rawStyles is Map) {
          styles = {
            for (final e in rawStyles.entries)
              if (e.key is String && e.value != null)
                e.key as String: e.value.toString(),
          };
        }
        return bridge.updateNode(
          pageId: _optString(arguments['pageId'] ?? arguments['frameId']),
          nodeId: nodeId,
          text: _optString(arguments['text']),
          styles: styles,
        );
      case 'delete_node':
        final nodeId = arguments['nodeId'];
        if (nodeId is! String || nodeId.isEmpty) {
          throw McpException('Argumen "nodeId" wajib.', code: -32602);
        }
        return bridge.deleteNode(
          pageId: _optString(arguments['pageId'] ?? arguments['frameId']),
          nodeId: nodeId,
        );
      case 'rearrange_layout':
        return bridge.rearrangeLayout(
          pageId: _optString(arguments['pageId'] ?? arguments['frameId']),
          id: _optString(arguments['id'] ?? arguments['nodeId']),
          dx: _optDouble(arguments['dx']),
          dy: _optDouble(arguments['dy']),
          width: _optDouble(arguments['width']),
          height: _optDouble(arguments['height']),
        );
      default:
        throw McpException('Tool tidak dikenal: $name', code: -32601);
    }
  }

  // ---------------------------------------------------------------- util --

  static String? _optString(dynamic v) =>
      v is String && v.isNotEmpty ? v : null;

  static double? _optDouble(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '');

  /// Skema 7 tools MCP (publik agar bisa diuji + didokumentasikan).
  /// `frameId` masih diterima sebagai alias legacy untuk `pageId`.
  static List<Map<String, dynamic>> toolSchemas() => [
    {
      'name': 'get_canvas_structure',
      'description':
          'Baca struktur workspace: daftar halaman + layers tree DOM halaman aktif.',
      'inputSchema': {'type': 'object', 'properties': {}},
    },
    {
      'name': 'get_selected_node',
      'description':
          'Baca node terpilih: tag, bounding box, dan computed styles.',
      'inputSchema': {'type': 'object', 'properties': {}},
    },
    {
      'name': 'get_node_html',
      'description': 'Ambil HTML satu node berdasarkan id-nya.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'nodeId': {'type': 'string'},
        },
        'required': ['nodeId'],
      },
    },
    {
      'name': 'add_node',
      'description':
          'Tambah elemen HTML ke halaman aktif (atau pageId). parentId opsional (default body).',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'html': {'type': 'string'},
          'parentId': {'type': 'string'},
          'pageId': {'type': 'string'},
          'frameId': {'type': 'string', 'description': 'Deprecated: pakai pageId.'},
          'position': {
            'type': 'string',
            'enum': ['beforeend', 'afterbegin', 'beforebegin', 'afterend'],
          },
        },
        'required': ['html'],
      },
    },
    {
      'name': 'update_node',
      'description':
          'Ubah teks dan/atau inline styles satu node (tulis balik ke DOM).',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'nodeId': {'type': 'string'},
          'text': {'type': 'string'},
          'styles': {'type': 'object'},
          'pageId': {'type': 'string'},
          'frameId': {'type': 'string', 'description': 'Deprecated: pakai pageId.'},
        },
        'required': ['nodeId'],
      },
    },
    {
      'name': 'delete_node',
      'description': 'Hapus satu node dari halaman.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'nodeId': {'type': 'string'},
          'pageId': {'type': 'string'},
          'frameId': {'type': 'string', 'description': 'Deprecated: pakai pageId.'},
        },
        'required': ['nodeId'],
      },
    },
    {
      'name': 'rearrange_layout',
      'description':
          'Geser/ubah ukuran satu node (dx/dy delta CSS, width/height absolut).',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'id': {'type': 'string'},
          'pageId': {'type': 'string'},
          'frameId': {'type': 'string', 'description': 'Deprecated: pakai pageId.'},
          'dx': {'type': 'number'},
          'dy': {'type': 'number'},
          'width': {'type': 'number'},
          'height': {'type': 'number'},
        },
      },
    },
  ];

  Map<String, dynamic> _rpcOk(dynamic id, Map<String, dynamic> result) => {
    'jsonrpc': '2.0',
    'id': id,
    'result': result,
  };

  Map<String, dynamic> _rpcError(dynamic id, int code, String message) => {
    'jsonrpc': '2.0',
    'id': id,
    'error': {'code': code, 'message': message},
  };

  void _writeJson(HttpResponse response, Object body) {
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(body));
  }

  void _broadcast({required String event, required Map<String, dynamic> data}) {
    if (_sseClients.isEmpty) return;
    final payload = 'event: $event\ndata: ${jsonEncode(data)}\n\n';
    for (final client in _sseClients.toList()) {
      try {
        client.response.write(payload);
        client.response.flush().catchError((_) {
          _sseClients.remove(client);
        });
      } catch (_) {
        _sseClients.remove(client);
      }
    }
  }
}

class _SseClient {
  _SseClient(this.response);
  final HttpResponse response;

  void send(String event, Map<String, dynamic> data) {
    try {
      response.write('event: $event\ndata: ${jsonEncode(data)}\n\n');
    } catch (_) {}
  }
}
