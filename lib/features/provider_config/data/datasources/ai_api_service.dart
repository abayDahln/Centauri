import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/utils/app_constants.dart';
import '../../domain/entities/api_provider.dart';

/// Exception koneksi API dengan pesan yang aman ditampilkan ke pengguna.
/// Tidak pernah memuat header/API key (NFR-01).
class ApiConnectionException implements Exception {
  ApiConnectionException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// HTTP client dinamis berbasis Dio (TR-03). Dio dibuat per-request agar
/// Base URL, header, dan API Key selalu sesuai provider yang dipilih.
class AiApiService {
  const AiApiService();

  Dio _buildClient(ApiProvider provider) {
    final apiKey = provider.apiKey?.trim() ?? '';
    return Dio(
      BaseOptions(
        // URL endpoint dibangun eksplisit (lihat [resolveEndpoint]) agar
        // tidak bergantung pada penggabungan path Dio yang rawan salah.
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
        },
      ),
    );
  }

  /// Membangun URL endpoint lengkap dari Base URL pengguna.
  ///
  /// Menangani kesalahan penulisan Base URL yang umum:
  ///  - kelebihan trailing slash,
  ///  - sudah menyertakan `/chat/completions` atau `/models`,
  ///  - sudah menyertakan `/v1` atau belum.
  static String resolveEndpoint(String baseUrl, String endpointPath) {
    var base = baseUrl.trim();
    if (base.isEmpty) return endpointPath;

    // Buang query/hash yang tidak sengaja tertempel.
    final queryIndex = base.indexOf(RegExp(r'[?#]'));
    if (queryIndex >= 0) base = base.substring(0, queryIndex);

    // Buang trailing slash.
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }

    // Bila pengguna sudah menempelkan endpoint lengkap, pakai apa adanya.
    for (final suffix in const ['/chat/completions', '/models']) {
      if (base.toLowerCase().endsWith(suffix)) {
        base = base.substring(0, base.length - suffix.length);
        break;
      }
    }

    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }

    final separator = endpointPath.startsWith('/') ? '' : '/';
    return '$base$separator$endpointPath';
  }

  /// Memvalidasi endpoint & kredensial dengan GET {baseUrl}/models (FR-01).
  /// Melempar [ApiConnectionException] jika gagal.
  Future<void> testConnection(ApiProvider provider) async {
    final url = resolveEndpoint(
      provider.normalizedBaseUrl,
      AppConstants.testConnectionPath,
    );
    try {
      final response = await _buildClient(provider).get(
        url,
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: AppConstants.testConnectionTimeout,
        ),
      );
      if (response.statusCode == 200) {
        // Beberapa endpoint membalas JSON non-standar; pastikan bukan HTML.
        _assertNotHtml(response);
        return;
      }
      throw ApiConnectionException(
        'Endpoint membalas dengan status ${response.statusCode}.',
      );
    } on DioException catch (e) {
      throw ApiConnectionException(_mapDioError(e));
    }
  }

  Future<String> generateUI({
    required ApiProvider provider,
    required List<Map<String, dynamic>> messages,
  }) async {
    final url = resolveEndpoint(
      provider.normalizedBaseUrl,
      AppConstants.chatCompletionsPath,
    );

    final Response<ResponseBody> response;
    try {
      response = await _buildClient(provider).post<ResponseBody>(
        url,
        data: {
          'model': provider.model,
          'messages': messages,
          'temperature': 0.2,
          // Minta respons tunggal. Sebagian gateway tetap membalas SSE;
          // keduanya ditangani di bawah.
          'stream': false,
        },
        options: Options(responseType: ResponseType.stream),
      );
    } on DioException catch (e) {
      throw ApiConnectionException(_mapDioError(e));
    }

    final contentType =
        response.headers.value('content-type')?.toLowerCase() ?? '';

    // Rakit body secara incremental dengan batas inaktivitas, supaya
    // generate panjang / gateway lambat tidak kena "connection timeout".
    final body = response.data;
    if (body == null) {
      throw ApiConnectionException('Provider membalas body kosong.\nURL: $url');
    }
    final raw = await _readBodyWithTimeout(
      body,
      timeout: AppConstants.receiveTimeout,
    );

    if (raw.isEmpty) {
      throw ApiConnectionException(
        'Provider membalas body kosong.\nURL: $url',
      );
    }

    // Deteksi HTML lebih awal (halaman web, bukan API).
    final head = raw.trimLeft().toLowerCase();
    if (contentType.contains('text/html') ||
        head.startsWith('<!doctype') ||
        head.startsWith('<html')) {
      throw ApiConnectionException(
        'Endpoint membalas halaman HTML, bukan API JSON. '
        'Base URL kemungkinan salah; arahkan ke endpoint API '
        '(mis. https://api.openai.com/v1).\n'
        'URL: $url\nCuplikan: ${_snippet(raw)}',
      );
    }

    // Respons streaming (Server-Sent Events) meski kita tidak meminta.
    if (contentType.contains('text/event-stream') || raw.contains('data:')) {
      final streamed = _extractFromSse(raw);
      if (streamed != null) return streamed;
    }

    // Respons JSON biasa.
    try {
      final decoded = jsonDecode(raw);
      return _extractContent(decoded);
    } on FormatException {
      throw ApiConnectionException(
        'Respons provider bukan JSON/SSE yang valid.\n'
        'URL: $url\nCuplikan: ${_snippet(raw)}',
      );
    } on ApiConnectionException catch (e) {
      throw ApiConnectionException(
        '${e.message}\nURL: $url\n'
        'Status: ${response.statusCode}, Content-Type: $contentType',
      );
    }
  }

  /// Membaca [ResponseBody] menjadi String, dengan batas inaktivitas antar
  /// chunk ([timeout]) dan batas total [AppConstants.generationTimeout].
  Future<String> _readBodyWithTimeout(
    ResponseBody body, {
    required Duration timeout,
  }) {
    final buffer = StringBuffer();
    final completer = Completer<String>();
    Timer? inactivity;
    Timer? total;

    void finish([Object? error]) {
      if (completer.isCompleted) return;
      inactivity?.cancel();
      total?.cancel();
      if (error != null) {
        completer.completeError(error);
      } else {
        completer.complete(buffer.toString());
      }
    }

    void resetInactivity() {
      inactivity?.cancel();
      inactivity = Timer(timeout, () {
        finish(
          ApiConnectionException(
            'Generate timeout: tidak ada data dari provider selama '
            '${timeout.inSeconds} detik. Coba lagi atau periksa model/server.',
          ),
        );
      });
    }

    resetInactivity();
    total = Timer(AppConstants.generationTimeout, () {
      finish(
        ApiConnectionException(
          'Generate dihentikan: melewati batas waktu total '
          '${AppConstants.generationTimeout.inMinutes} menit.',
        ),
      );
    });

    void onChunk(List<int> bytes) {
      buffer.write(const Utf8Decoder(allowMalformed: true).convert(bytes));
      resetInactivity();
    }

    body.stream.listen(
      onChunk,
      onDone: () => finish(),
      onError: (Object error, StackTrace stack) {
        finish(ApiConnectionException(_mapStreamError(error)));
      },
      cancelOnError: true,
    );

    return completer.future;
  }

  String _mapStreamError(Object error) {
    if (error is DioException) return _mapDioError(error);
    return 'Koneksi ke provider terputus saat menerima data: $error';
  }

  /// Menyusun teks lengkap dari respons Server-Sent Events. Menggabungkan
  /// semua delta content pada `choices[0].delta.content`.
  String? _extractFromSse(dynamic data) {
    if (data is! String) return null;

    final buffer = StringBuffer();
    for (final rawLine in data.split('\n')) {
      var line = rawLine.trim();
      if (line.isEmpty || !line.startsWith('data:')) continue;

      line = line.substring('data:'.length).trim();
      if (line.isEmpty || line == '[DONE]') continue;

      final Map<String, dynamic> chunk;
      try {
        final decoded = jsonDecode(line);
        if (decoded is! Map<String, dynamic>) continue;
        chunk = decoded;
      } on FormatException {
        continue;
      }

      // choices[0].delta.content (streaming standar OpenAI).
      final choices = chunk['choices'];
      if (choices is List && choices.isNotEmpty) {
        final first = choices.first;
        if (first is Map) {
          final delta = first['delta'];
          if (delta is Map) {
            final piece = _contentToString(delta['content']);
            if (piece != null) {
              buffer.write(piece);
              continue;
            }
          }
          // Sebagian gateway memakai message.content walau streaming.
          final message = first['message'];
          if (message is Map) {
            final piece = _contentToString(message['content']);
            if (piece != null) buffer.write(piece);
          }
        }
      } else {
        // Bentuk Ollama streaming: {message: {content}} per baris.
        final message = chunk['message'];
        if (message is Map) {
          final piece = _contentToString(message['content']);
          if (piece != null) buffer.write(piece);
        }
      }
    }

    final result = buffer.toString().trim();
    return result.isEmpty ? null : result;
  }

  /// Mendeteksi respons HTML (bukan JSON API). Gejala paling umum dari
  /// Base URL yang salah: server membalas halaman web / halaman error.
  void _assertNotHtml(Response<dynamic> response) {
    final contentType =
        response.headers.value('content-type')?.toLowerCase() ?? '';
    final data = response.data;
    final looksHtml = data is String &&
        (contentType.contains('text/html') ||
            data.trimLeft().toLowerCase().startsWith('<!doctype') ||
            data.trimLeft().toLowerCase().startsWith('<html'));

    if (!looksHtml) return;

    throw ApiConnectionException(
      'Endpoint membalas halaman HTML, bukan API JSON. '
      'Base URL kemungkinan salah: arahkan ke endpoint API dan sertakan '
      'versi (mis. https://api.openai.com/v1).\n'
      'URL: ${response.requestOptions.uri}\n'
      'Cuplikan: ${_snippet(data)}',
    );
  }

  /// Mengambil teks dari respons chat completion. Menangani variasi bentuk
  /// respons (OpenAI-compatible, Ollama, gateway custom) dan melempar pesan
  /// yang menjelaskan bila struktur respons tidak dikenal, alih-alih
  /// gagal senyap dengan error generik.
  @visibleForTesting
  String extractContent(dynamic data) => _extractContent(data);

  @visibleForTesting
  String? extractFromSse(dynamic data) => _extractFromSse(data);

  String _extractContent(dynamic data) {
    if (data is! Map) {
      // Dio mengembalikan String/List bila content-type bukan JSON, yang
      // biasanya berarti Base URL salah (server membalas halaman HTML).
      throw ApiConnectionException(
        'Respons provider bukan JSON objek (tipe: ${data.runtimeType}). '
        'Periksa Base URL - pastikan mengarah ke endpoint API dan berakhir di '
        '/v1. Cuplikan respons: ${_snippet(data)}',
      );
    }

    // Bentuk standar OpenAI-compatible: choices[0].message.content
    final choices = data['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map) {
        final message = first['message'];
        if (message is Map) {
          final fromContent = _contentToString(message['content']);
          if (fromContent != null) return fromContent;
        }
        // Sebagian provider memakai choices[0].text.
        if (first['text'] is String) {
          final text = (first['text'] as String).trim();
          if (text.isNotEmpty) return text;
        }
      }
    }

    // Bentuk Ollama native: {message: {content}} atau {response}.
    final message = data['message'];
    if (message is Map) {
      final fromContent = _contentToString(message['content']);
      if (fromContent != null) return fromContent;
    }
    final fromText = _contentToString(data['content']);
    if (fromText != null) return fromText;
    if (data['response'] is String) {
      final response = (data['response'] as String).trim();
      if (response.isNotEmpty) return response;
    }

    // Sertakan error provider bila ada, agar mudah didiagnosis.
    final providerError = data['error'];
    if (providerError is Map && providerError['message'] is String) {
      throw ApiConnectionException('Provider: ${providerError['message']}');
    }
    if (providerError is String) {
      throw ApiConnectionException('Provider: $providerError');
    }

    throw ApiConnectionException(
      'Struktur respons provider tidak dikenali. '
      'Kunci: ${data.keys.take(8).join(', ')}. '
      'Cuplikan: ${_snippet(data)}',
    );
  }

  String _snippet(dynamic data) {
    final text = data.toString();
    return text.length > 220 ? '${text.substring(0, 220)}...' : text;
  }

  String _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi timeout. Periksa Base URL atau jaringan Anda.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke endpoint. Periksa Base URL.';
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        if (status == 401 || status == 403) {
          return 'API key tidak valid atau tidak memiliki akses (HTTP $status).';
        }
        if (status == 404) {
          return 'Endpoint tidak ditemukan (HTTP 404). Periksa Base URL.';
        }
        final detail = _providerErrorMessage(e.response?.data);
        if (detail != null) {
          return 'Server menolak request (HTTP ${status ?? 'unknown'}): $detail';
        }
        return 'Server menolak request (HTTP ${status ?? 'unknown'}).';
      case DioExceptionType.cancel:
        return 'Request dibatalkan.';
      default:
        return 'Terjadi kesalahan jaringan yang tidak terduga.';
    }
  }

  /// Mengambil teks dari `content` yang bisa berupa String atau daftar
  /// content-part (format multimodal OpenAI: `[{type:text,text:...}]`).
  String? _contentToString(dynamic content) {
    if (content is String) {
      final trimmed = content.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (content is List) {
      final buffer = StringBuffer();
      for (final part in content) {
        if (part is String) {
          buffer.write(part);
        } else if (part is Map) {
          final text = part['text'];
          if (text is String) {
            buffer.write(text);
          } else if (part['content'] is String) {
            buffer.write(part['content'] as String);
          }
        }
      }
      final joined = buffer.toString().trim();
      return joined.isEmpty ? null : joined;
    }
    return null;
  }

  /// Mengambil pesan error dari body respons provider, agar pengguna tahu
  /// penyebab pasti (mis. nama model salah, kuota habis).
  String? _providerErrorMessage(dynamic data) {
    if (data is Map) {
      final error = data['error'];
      if (error is Map && error['message'] is String) {
        return error['message'] as String;
      }
      if (error is String) return error;
      if (data['message'] is String) return data['message'] as String;
    }
    if (data is String && data.trim().isNotEmpty) {
      final trimmed = data.trim();
      return trimmed.length > 200 ? '${trimmed.substring(0, 200)}...' : trimmed;
    }
    return null;
  }
}
