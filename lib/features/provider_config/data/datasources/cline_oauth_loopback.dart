import 'dart:async';
import 'dart:io';

/// Server HTTP sementara di loopback untuk menerima callback login Cline.
///
/// Cline mengarahkan browser ke `vscode://saoudrizwan.claude-dev/auth?code=…`,
/// tautan yang tidak bisa ditangkap aplikasi lain. Karena itu alur otomatis
/// memakai `callback_url` loopback: kalau Cline menghormatinya, browser mendarat
/// di server ini dan kode sesi diterima tanpa copy-paste. Bila Cline tetap
/// mengarahkan ke `vscode://`, [waitForCode] selesai dengan null dan UI
/// menawarkan tempel tautan sebagai jalan lain.
class ClineLoopbackServer {
  ClineLoopbackServer._(this._server);

  final HttpServer _server;
  final Completer<String?> _code = Completer<String?>();

  /// Mulai mendengarkan di port acak pada 127.0.0.1.
  static Future<ClineLoopbackServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final loopback = ClineLoopbackServer._(server);
    loopback._listen();
    return loopback;
  }

  /// Alamat yang dikirim ke Cline sebagai tujuan akhir login.
  String get callbackUrl => 'http://127.0.0.1:${_server.port}/cline-callback';

  void _listen() {
    _server.listen((request) async {
      final code = request.uri.queryParameters['code'];
      try {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.html
          ..write(_donePage);
        await request.response.close();
      } catch (_) {
        // Browser menutup koneksi lebih dulu; kode tetap dipakai.
      }
      if (!_code.isCompleted) _code.complete(code);
    });
  }

  /// Menunggu kode dari browser. Null bila [timeout] habis atau dibatalkan
  /// lewat [close].
  Future<String?> waitForCode({Duration timeout = const Duration(minutes: 5)}) {
    return _code.future.timeout(timeout, onTimeout: () => null);
  }

  /// Tutup server. Menunggu yang sedang berjalan selesai dengan null.
  Future<void> close() async {
    if (!_code.isCompleted) _code.complete(null);
    try {
      await _server.close(force: true);
    } catch (_) {
      // Sudah tertutup.
    }
  }

  static const String _donePage =
      '<!doctype html><meta charset="utf-8">'
      '<title>Centauri</title>'
      '<body style="font-family:system-ui;padding:48px;text-align:center">'
      '<h1 style="font-size:18px">Cline connected</h1>'
      '<p style="color:#666">You can close this window and go back to Centauri.</p>';
}
