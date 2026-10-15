import 'dart:async';
import 'dart:io';

import '../../../../core/utils/app_constants.dart';
import '../../domain/services/redirect_receiver.dart';

/// Penerima redirect OAuth berbasis loopback (RFC 8252) untuk desktop.
///
/// Menjalankan `HttpServer` kecil di `127.0.0.1` pada port ephemeral. Browser
/// sistem mengarahkan pengguna kembali ke `http://127.0.0.1:<port>/callback`
/// setelah login, lalu server menangkap `code`/`state` dari query string.
///
/// Trafik ke `127.0.0.1` tidak melewati Windows Defender Firewall, sehingga
/// tidak perlu aturan inbound apa pun.
class LoopbackRedirectServer implements RedirectReceiver {
  HttpServer? _server;
  Completer<OAuthRedirectResult>? _completer;
  Uri? _redirectUri;

  /// Redirect URI aktif (tersedia setelah [start]).
  Uri? get redirectUri => _redirectUri;

  @override
  Future<Uri> start({int? port}) async {
    await stop();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port ?? 0);
    _server = server;
    final redirectUri = Uri.parse(
      'http://${AppConstants.oauthLoopbackHost}:${server.port}'
      '${AppConstants.oauthRedirectPath}',
    );
    _redirectUri = redirectUri;
    _completer = Completer<OAuthRedirectResult>();
    _server!.listen(_handleRequest);
    return redirectUri;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final completer = _completer;
    // Abaikan permintaan lain (mis. /favicon.ico) agar tidak menutup flow.
    if (request.uri.path != AppConstants.oauthRedirectPath) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    final query = request.uri.queryParameters;
    final result = OAuthRedirectResult(
      code: query['code'],
      state: query['state'],
      error: query['error'],
      errorDescription: query['error_description'],
    );

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write(_html(result.isSuccess));
    await request.response.close();

    if (completer != null && !completer.isCompleted) {
      completer.complete(result);
    }
  }

  @override
  Future<OAuthRedirectResult> waitForCallback({
    required Duration timeout,
  }) {
    final completer = _completer;
    if (completer == null) {
      return Future.value(
        const OAuthRedirectResult(error: 'server_not_started'),
      );
    }
    return completer.future.timeout(
      timeout,
      onTimeout: () => const OAuthRedirectResult(error: 'timeout'),
    );
  }

  @override
  Future<void> stop() async {
    final server = _server;
    _server = null;
    _completer = null;
    _redirectUri = null;
    if (server != null) {
      await server.close(force: true);
    }
  }

  String _html(bool success) {
    final title = success ? 'Login berhasil' : 'Login gagal';
    final message = success
        ? 'Autentikasi selesai. Anda dapat menutup tab ini dan kembali ke Centauri.'
        : 'Terjadi masalah saat login. Silakan kembali ke Centauri dan coba lagi.';
    return '''
<!doctype html>
<html lang="id">
<head><meta charset="utf-8"><title>$title</title>
<style>
  body{background:#181818;color:#e6e6e6;font-family:Segoe UI,system-ui,sans-serif;
       display:flex;height:100vh;margin:0;align-items:center;justify-content:center}
  .card{max-width:420px;padding:32px;border:1px solid #333;border-radius:12px;text-align:center}
  h1{font-size:18px;margin:0 0 12px}
  p{color:#a0a0a0;font-size:13px;line-height:1.6;margin:0}
</style></head>
<body><div class="card"><h1>$title</h1><p>$message</p></div></body>
</html>''';
  }
}
