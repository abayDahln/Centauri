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
/// Base URL, header, dan kredensial selalu sesuai provider yang dipilih.
class AiApiService {
  const AiApiService({this.clientFactory});

  /// Seam pengujian: bila diisi, dipakai sebagai ganti `_buildClient`.
  final Dio Function(ApiProvider provider)? clientFactory;

  Dio _clientFor(ApiProvider provider) {
    final factory = clientFactory;
    if (factory == null) return _buildClient(provider);
    // Klien uji (mis. Dio dengan adapter palsu) tetap harus memakai header
    // autentikasi yang sama seperti klien produksi.
    final dio = factory(provider);
    dio.options.headers.addAll(_headers(provider));
    return dio;
  }

  /// Header bersama (Content-Type + Authorization) untuk semua request.
  Map<String, String> _headers(ApiProvider provider) {
    final bearer = provider.bearerToken?.trim() ?? '';
    return {
      'Content-Type': 'application/json',
      if (bearer.isNotEmpty) 'Authorization': 'Bearer $bearer',
    };
  }

  Dio _buildClient(ApiProvider provider) {
    final dio = Dio(
      BaseOptions(
        // URL endpoint dibangun eksplisit (lihat [resolveEndpoint]) agar
        // tidak bergantung pada penggabungan path Dio yang rawan salah.
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: _headers(provider),
      ),
    );

    return dio;
  }

  /// Daftar token pembatalan aktif, dipakai [cancelAll] agar UI bisa
  /// menghentikan generate yang sedang berjalan (Fase 5: UX cancel).
  static final Set<CancelToken> _activeTokens = {};

  /// Batalkan semua request generate yang sedang berjalan.
  static void cancelAll() {
    for (final token in _activeTokens.toList()) {
      if (!token.isCancelled) token.cancel('Dibatalkan oleh pengguna.');
    }
    _activeTokens.clear();
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
      final response = await _clientFor(provider).get(
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
      throw ApiConnectionException(mapDioError(e));
    }
  }

  Future<String> generateUI({
    required ApiProvider provider,
    required List<Map<String, dynamic>> messages,
    CancelToken? cancelToken,
  }) async {
    final token = cancelToken ?? CancelToken();

    if (provider.normalizedBaseUrl.isEmpty) {
      throw ApiConnectionException(
        'Provider ini tidak punya alamat chat. Periksa Base URL provider '
        'atau pilih layanan yang mendukung chat.',
      );
    }

    final url = resolveEndpoint(
      provider.normalizedBaseUrl,
      AppConstants.chatCompletionsPath,
    );

    // Daftarkan token agar bisa dibatalkan dari UI (cancel generate).
    _activeTokens.add(token);

    final Response<ResponseBody> response;
    try {
      response = await _clientFor(provider).post<ResponseBody>(
        url,
        data: {
          'model': provider.model,
          'messages': messages,
          'temperature': AppConstants.designTemperature,
          'max_tokens': AppConstants.designMaxTokens,
          // Minta respons tunggal. Sebagian gateway tetap membalas SSE;
          // keduanya ditangani di bawah.
          'stream': false,
        },
        options: Options(responseType: ResponseType.stream),
        cancelToken: token,
      );
    } on DioException catch (e) {
      _activeTokens.remove(token);
      // Respons diminta sebagai stream, jadi Dio tidak mendekode body error.
      // Body dibaca manual agar pesan asli provider (mis. OpenRouter:
      // "No endpoints found for <model>") ikut tampil, bukan pesan generik.
      final errorBody = await _readErrorBody(e);
      throw ApiConnectionException(
        mapDioError(
          e,
          responseBody: errorBody,
          url: url,
          model: provider.model,
        ),
      );
    }

    final contentType =
        response.headers.value('content-type')?.toLowerCase() ?? '';

    // Rakit body secara incremental dengan batas inaktivitas, supaya
    // generate panjang / gateway lambat tidak kena "connection timeout".
    final body = response.data;
    if (body == null) {
      _activeTokens.remove(token);
      throw ApiConnectionException('Provider membalas body kosong.\nURL: $url');
    }
    String raw;
    try {
      raw = await _readBodyWithTimeout(
        body,
        timeout: AppConstants.receiveTimeout,
        cancelToken: token,
      );
    } finally {
      _activeTokens.remove(token);
    }

    if (raw.isEmpty) {
      throw ApiConnectionException('Provider membalas body kosong.\nURL: $url');
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
    CancelToken? cancelToken,
  }) {
    final buffer = StringBuffer();
    final completer = Completer<String>();
    Timer? inactivity;
    Timer? total;
    StreamSubscription<List<int>>? subscription;
    Completer<void>? cancelWatch;

    void finish([Object? error]) {
      if (completer.isCompleted) return;
      inactivity?.cancel();
      total?.cancel();
      cancelWatch?.complete();
      subscription?.cancel();
      if (error != null) {
        completer.completeError(error);
      } else {
        completer.complete(buffer.toString());
      }
    }

    // Pembatalan dari UI: hentikan baca & lempar penanda khusus cancel.
    if (cancelToken != null) {
      cancelWatch = Completer<void>();
      cancelToken.whenCancel.then((_) {
        if (!cancelWatch!.isCompleted) {
          finish(ApiConnectionException('__CANCELLED__'));
        }
      });
      if (cancelToken.isCancelled) {
        finish(ApiConnectionException('__CANCELLED__'));
        return completer.future;
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

    subscription = body.stream.listen(
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
    if (error is DioException) return mapDioError(error);
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
    final looksHtml =
        data is String &&
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

  /// Menyusun pesan error dari [DioException] agar pengguna tahu penyebab
  /// pastinya. `default` (type unknown) TIDAK dijadikan "kesalahan jaringan"
  /// mentah-mentah: penyebab asli (`e.error`) disertakan supaya pengguna bisa
  /// membedakan URL salah, DNS gagal, TLS, dan sebagainya.
  ///
  /// [responseBody] diisi pemanggil yang memakai `ResponseType.stream`
  /// (body-nya tidak didekode Dio). [url] dan [model] menempelkan konteks
  /// request yang ditolak provider supaya salah URL vs salah model kelihatan.
  static String mapDioError(
    DioException e, {
    String? responseBody,
    String? url,
    String? model,
  }) {
    // Sumber pesan detail provider: body yang sudah dibaca pemanggil lebih
    // dulu, jatuh ke data respons Dio (Map/String) bila ada.
    final detailSource = responseBody ?? e.response?.data;
    final context = _requestContext(url: url, model: model);
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
          return 'Kunci akses tidak valid atau tidak memiliki akses '
              '(HTTP $status).';
        }
        if (status == 404) {
          // 404 pada API OpenAI-compatible paling sering berarti model tidak
          // ada (mis. OpenRouter: "No endpoints found for <model>"), bukan
          // Base URL salah. Pesan asli provider disertakan agar pengguna tahu
          // penyebab pastinya.
          final detail = _providerErrorMessage(detailSource);
          if (detail != null) {
            return 'Endpoint atau model tidak ditemukan (HTTP 404): $detail'
                '$context';
          }
          return 'Endpoint atau model tidak ditemukan (HTTP 404). '
              'Periksa Base URL dan nama model.$context';
        }
        final detail = _providerErrorMessage(detailSource);
        if (detail != null) {
          return 'Server menolak request (HTTP ${status ?? 'unknown'}): $detail'
              '$context';
        }
        return 'Server menolak request (HTTP ${status ?? 'unknown'}).$context';
      case DioExceptionType.cancel:
        return 'Request dibatalkan.';
      case DioExceptionType.badCertificate:
        return 'Sertifikat server tidak valid. Periksa Base URL.';
      case DioExceptionType.transformTimeout:
      case DioExceptionType.unknown:
        final detail = _mapUnknownError(e);
        return detail == null
            ? 'Tidak dapat mengirim request. Periksa koneksi lalu coba lagi.'
            : 'Tidak dapat mengirim request: $detail. '
                  'Periksa jaringan atau Base URL, lalu coba lagi.';
    }
  }

  /// Baris konteks (URL final + model) untuk pesan error. Kosong bila keduanya
  /// tidak diketahui, sehingga pemanggil lama tidak berubah perilakunya.
  static String _requestContext({String? url, String? model}) {
    final buffer = StringBuffer();
    final trimmedUrl = url?.trim() ?? '';
    if (trimmedUrl.isNotEmpty) buffer.write('\nURL: $trimmedUrl');
    final trimmedModel = model?.trim() ?? '';
    if (trimmedModel.isNotEmpty) buffer.write('\nModel: $trimmedModel');
    return buffer.toString();
  }

  /// Membaca body respons error yang tidak didekode Dio.
  ///
  /// Dengan `ResponseType.stream`, `e.response.data` berisi [ResponseBody]
  /// mentah; tanpa dibaca, pesan asli provider hilang dan pengguna hanya
  /// melihat pesan generik.
  static Future<String?> _readErrorBody(DioException e) async {
    final data = e.response?.data;
    if (data is String) return data;
    if (data is! ResponseBody) return null;
    try {
      return await _drainBody(data.stream).timeout(_errorBodyTimeout);
    } catch (_) {
      return null;
    }
  }

  /// Batas tunggu membaca body error. Body yang tidak kunjung tutup tidak boleh
  /// membuat UI menggantung di status "mengirim".
  static const Duration _errorBodyTimeout = Duration(seconds: 5);

  /// Menggabungkan body stream jadi String, dibatasi [maxBytes] supaya halaman
  /// HTML panjang (gejala Base URL salah) tidak dihabiskan sia-sia.
  static Future<String> _drainBody(Stream<List<int>> stream) async {
    const maxBytes = 4096;
    final merged = <int>[];
    await for (final chunk in stream) {
      merged.addAll(chunk);
      if (merged.length >= maxBytes) break;
    }
    return const Utf8Decoder(allowMalformed: true).convert(merged);
  }

  /// Detail error asli untuk `DioExceptionType.unknown` (mis. "No host
  /// specified in URI" saat Base URL kosong) — dibungkus sebagai pesan
  /// pendek yang aman ditampilkan.
  static String? _mapUnknownError(DioException e) {
    final raw = e.error?.toString() ?? e.message ?? '';
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.length > 200 ? '${trimmed.substring(0, 200)}...' : trimmed;
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
  ///
  /// Body dari respons bergaya stream tiba sebagai String JSON mentah; itu
  /// diuraikan dulu supaya `error.message` provider ikut terangkat.
  static String? _providerErrorMessage(dynamic data) {
    var value = data;
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) return null;
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map || decoded is String) value = decoded;
      } on FormatException {
        // Bukan JSON (mis. halaman HTML dari Base URL salah): pakai teksnya
        // mentah, dipotong agar tetap pendek.
        return text.length > 200 ? '${text.substring(0, 200)}...' : text;
      }
    }
    if (value is Map) {
      final error = value['error'];
      if (error is Map && error['message'] is String) {
        return error['message'] as String;
      }
      if (error is String) return error;
      if (value['message'] is String) return value['message'] as String;
    }
    if (value is String && value.trim().isNotEmpty) {
      final trimmed = value.trim();
      return trimmed.length > 200 ? '${trimmed.substring(0, 200)}...' : trimmed;
    }
    return null;
  }
}
