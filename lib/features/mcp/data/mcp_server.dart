import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mcp_bridge.dart';

/// Embedded MCP server lokal (Fase 4: Desktop Full).
/// Berjalan di background versi Desktop, di `127.0.0.1` (coba 8765 → 8774).
///
/// - `GET /status` — info server + ringkasan workspace (tanpa auth, localhost saja).
/// - `POST /mcp` — JSON-RPC 2.0: `initialize`, `tools/list`, `tools/call`, `ping`.
/// - `GET /events` — Server-Sent Events: event `state` setiap ada perubahan
///   (live sync; agent fetch ulang via tools, tanpa refresh aplikasi).
///
/// Tool bekerja di level sesi (bukan node) dan hemat token: agen mulai dari
/// `list_sessions` (metadata saja), lalu `get_session` (chat + indeks
/// halaman), lalu `get_page_html` per halaman yang dibutuhkan. Tulis via
/// `write_page` / `delete_page` / `post_to_chat`, berlaku ke SEMUA sesi.
/// Semua mutasi melewati [McpBridge] (file sesi = sumber kebenaran,
/// workspace di-sync bila sesinya sedang aktif).
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
    debugPrint(
      '[mcp] Berjalan di http://127.0.0.1:${bound.port} '
      '(POST /mcp, GET /events, GET /status)',
    );
    _heartbeat = Timer.periodic(const Duration(seconds: 25), (_) {
      _broadcast(event: 'ping', data: {'stateVersion': _stateVersion});
    });
    bound.listen(_route);
  }

  /// Beri tahu semua klien SSE bahwa state berubah (live sync).
  void notifyState() {
    _stateVersion++;
    final snapshot = _bridge?.snapshot();
    _broadcast(
      event: 'state',
      data: {'stateVersion': _stateVersion, if (snapshot != null) ...snapshot},
    );
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
    // Frame SSE harus keluar seketika; tanpa ini greeting awal tertahan di
    // buffer Dart dan klien baru melihat header saja.
    response.bufferOutput = false;

    final client = _SseClient(response);
    _sseClients.add(client);
    // Sapaan awal agar agent langsung tahu versi state.
    client.send('state', {
      'stateVersion': _stateVersion,
      if (_bridge?.snapshot() case final snapshot?) ...snapshot,
    });
    response.flush().catchError((Object _) => true);

    // Tetap buka sampai klien pergi; jangan close di sini.
    response.done.then((_) => _sseClients.remove(client)).catchError((
      Object _,
    ) {
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
            'capabilities': {'tools': {}},
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
          final result = await _callTool(params['name'], params['arguments']);
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
      throw McpException('Server MCP belum siap. Buka board dulu.');
    }
    final arguments = args is Map<String, dynamic> ? args : <String, dynamic>{};
    if (name is! String) {
      throw McpException('Nama tool harus string.', code: -32602);
    }

    String requiredSessionId() {
      final sessionId = arguments['sessionId'];
      if (sessionId is! String || sessionId.isEmpty) {
        throw McpException('Argumen "sessionId" wajib.', code: -32602);
      }
      return sessionId;
    }

    switch (name) {
      case 'list_sessions':
        return bridge.listSessions();
      case 'get_session':
        return bridge.getSession(
          requiredSessionId(),
          limit: _optInt(arguments['limit']) ?? 50,
          offset: _optInt(arguments['offset']) ?? 0,
        );
      case 'get_page_html':
        final pageId = arguments['pageId'];
        if (pageId is! String || pageId.isEmpty) {
          throw McpException('Argumen "pageId" wajib.', code: -32602);
        }
        return bridge.getPageHtml(requiredSessionId(), pageId);
      case 'write_page':
        final html = arguments['html'];
        if (html is! String || html.trim().isEmpty) {
          throw McpException('Argumen "html" wajib.', code: -32602);
        }
        final result = await bridge.writePage(
          sessionId: requiredSessionId(),
          pageId: _optString(arguments['pageId']),
          name: _optString(arguments['name']),
          html: html,
        );
        notifyState();
        return result;
      case 'delete_page':
        final pageId = arguments['pageId'];
        if (pageId is! String || pageId.isEmpty) {
          throw McpException('Argumen "pageId" wajib.', code: -32602);
        }
        final result = bridge.deletePage(requiredSessionId(), pageId);
        notifyState();
        return result;
      case 'post_to_chat':
        final text = arguments['text'];
        if (text is! String || text.trim().isEmpty) {
          throw McpException('Argumen "text" wajib.', code: -32602);
        }
        final result = bridge.postToChat(requiredSessionId(), text);
        notifyState();
        return result;
      default:
        throw McpException('Tool tidak dikenal: $name', code: -32601);
    }
  }

  // ---------------------------------------------------------------- util --

  static String? _optString(dynamic v) =>
      v is String && v.isNotEmpty ? v : null;

  static int? _optInt(dynamic v) =>
      v is num ? v.toInt() : int.tryParse(v?.toString() ?? '');

  /// Skema 6 tools MCP (publik agar bisa diuji + didokumentasikan).
  /// Dirancang hemat token: listing hanya metadata, konten besar diminta
  /// per halaman. Deskripsi berbahasa Inggris karena dikonsumsi agen,
  /// bukan pengguna aplikasi.
  static List<Map<String, dynamic>> toolSchemas() => [
    {
      'name': 'list_sessions',
      'description':
          'List all chat sessions with metadata only (id, title, timestamps, '
          'message/page counts). Always start here; never fetch full session '
          'content unless needed.',
      'inputSchema': {'type': 'object', 'properties': {}},
    },
    {
      'name': 'get_session',
      'description':
          'Read one session: paginated chat messages (each text capped at '
          '800 chars; "ui" messages are page generations) plus a design-page '
          'index (id/name/slug) WITHOUT html. Use get_page_html per page for '
          'full HTML.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'sessionId': {'type': 'string'},
          'limit': {'type': 'integer', 'description': 'Default 50.'},
          'offset': {'type': 'integer', 'description': 'Default 0.'},
        },
        'required': ['sessionId'],
      },
    },
    {
      'name': 'get_page_html',
      'description':
          'Read the full self-contained HTML of one design page. Fetch only '
          'the pages you actually need.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'sessionId': {'type': 'string'},
          'pageId': {'type': 'string'},
        },
        'required': ['sessionId', 'pageId'],
      },
    },
    {
      'name': 'write_page',
      'description':
          'Create (pass "name") or replace (pass "pageId") a design page in '
          'ANY session; the app UI updates live when that session is open. '
          'html must be ONE self-contained, fluid-responsive document: inline '
          'CSS/JS only, no CDN, no fixed widths, viewport meta included.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'sessionId': {'type': 'string'},
          'pageId': {
            'type': 'string',
            'description': 'Existing page to replace.',
          },
          'name': {
            'type': 'string',
            'description': 'Title for a new page (omit when replacing).',
          },
          'html': {'type': 'string'},
        },
        'required': ['sessionId', 'html'],
      },
    },
    {
      'name': 'delete_page',
      'description': 'Delete a design page from a session.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'sessionId': {'type': 'string'},
          'pageId': {'type': 'string'},
        },
        'required': ['sessionId', 'pageId'],
      },
    },
    {
      'name': 'post_to_chat',
      'description':
          'Post an explanation message into a session chat; it appears as a '
          'normal assistant reply. Use after design changes so the user sees '
          'what you did.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'sessionId': {'type': 'string'},
          'text': {'type': 'string'},
        },
        'required': ['sessionId', 'text'],
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
