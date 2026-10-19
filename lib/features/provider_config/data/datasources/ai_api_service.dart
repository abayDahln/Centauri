import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/utils/app_constants.dart';
import '../../domain/entities/api_provider.dart';

/// Exception koneksi API.
///
/// Membawa [code] yang diterjemahkan di lapisan UI (lihat
/// `localizedAppError`) dan [detail] teknis untuk log — detail tidak pernah
/// memuat header/API key (NFR-01).
class ApiConnectionException extends AppErrorDetails implements Exception {
  const ApiConnectionException(super.code, {super.detail});

  @override
  String toString() => debugLabel;
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
  ///
  /// Khusus OpenRouter, header atribusi ikut dikirim: model tertentu (mis.
  /// rilis agentic) menolak request dari app yang tidak dikenal dengan 403.
  Map<String, String> _headers(ApiProvider provider) {
    final bearer = provider.bearerToken?.trim() ?? '';
    final isOpenRouter = provider.normalizedBaseUrl.toLowerCase().contains(
      'openrouter.ai',
    );
    return {
      'Content-Type': 'application/json',
      if (bearer.isNotEmpty) 'Authorization': 'Bearer $bearer',
      if (isOpenRouter) ...{
        'HTTP-Referer': AppConstants.appReferer,
        'X-OpenRouter-Title': AppConstants.appName,
        'X-OpenRouter-Categories': 'native-app-builder',
      },
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

  /// Memvalidasi endpoint & kredensial dengan GET {baseUrl}/models (FR-01),
  /// lalu memastikan model yang dipilih memang tersedia. Kredensial bisa valid
  /// sementara modelnya tidak ada; tanpa pemeriksaan ini Test selalu hijau dan
  /// kesalahannya baru muncul saat chat.
  /// Melempar [ApiConnectionException] jika gagal.
  Future<void> testConnection(ApiProvider provider) async {
    final url = resolveEndpoint(
      provider.normalizedBaseUrl,
      AppConstants.testConnectionPath,
    );

    final Response<dynamic> response;
    try {
      response = await _clientFor(provider).get(
        url,
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: AppConstants.testConnectionTimeout,
        ),
      );
    } on DioException catch (e) {
      throw ApiConnectionException(
        mapDioError(e),
        detail: dioErrorDetail(e, url: url),
      );
    }

    if (response.statusCode != 200) {
      throw ApiConnectionException(
        AppErrorCode.apiRejected,
        detail: 'HTTP ${response.statusCode}',
      );
    }

    // Beberapa endpoint membalas JSON non-standar; pastikan bukan HTML.
    _assertNotHtml(response);
    _assertModelAvailable(response.data, provider.model);
  }

  /// Memastikan [model] tercantum di daftar /models.
  ///
  /// Dilewati bila respons tidak memuat daftar model sama sekali (gateway
  /// lokal atau proxy tertentu tidak menyediakannya) agar Test tidak gagal
  /// palsu.
  void _assertModelAvailable(dynamic data, String model) {
    final wanted = model.trim();
    if (wanted.isEmpty) return;

    final ids = _modelIds(data);
    if (ids.isEmpty) return;

    final target = wanted.toLowerCase();
    final found = ids.any((id) {
      final value = id.trim().toLowerCase();
      // Ollama menambahkan ':latest' untuk model yang sama.
      return value == target || value == '$target:latest';
    });
    if (found) return;

    throw ApiConnectionException(
      AppErrorCode.apiModelUnavailable,
      detail: 'model=$wanted',
    );
  }

  /// Mengambil id model dari berbagai bentuk respons /models: OpenAI
  /// (data[].id), Ollama (models[].name), atau array polos.
  List<String> _modelIds(dynamic data) {
    var value = data;
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) return const [];
      try {
        value = jsonDecode(text);
      } on FormatException {
        return const [];
      }
    }

    final ids = <String>[];
    void collect(dynamic item) {
      if (item is String) {
        if (item.trim().isNotEmpty) ids.add(item);
        return;
      }
      if (item is! Map) return;
      for (final key in const ['id', 'name', 'model']) {
        final candidate = item[key];
        if (candidate is String && candidate.trim().isNotEmpty) {
          ids.add(candidate);
          return;
        }
      }
    }

    if (value is List) {
      value.forEach(collect);
    } else if (value is Map) {
      for (final key in const ['data', 'models']) {
        final list = value[key];
        if (list is List) list.forEach(collect);
      }
    }
    return ids;
  }

  Future<String> generateUI({
    required ApiProvider provider,
    required List<Map<String, dynamic>> messages,
    CancelToken? cancelToken,
  }) async {
    final token = cancelToken ?? CancelToken();

    if (provider.normalizedBaseUrl.isEmpty) {
      throw ApiConnectionException(
        AppErrorCode.apiNoChatEndpoint,
        detail: 'Base URL kosong',
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
          // max_tokens tidak dikirim: provider memakai batas maksimum modelnya,
          // dan nilai besar justru ditolak saat input + max_tokens melewati
          // context window (mis. OpenRouter HTTP 400).
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
        mapDioError(e),
        detail: dioErrorDetail(
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
      throw ApiConnectionException(
        AppErrorCode.apiBadResponse,
        detail: 'Body kosong | $url',
      );
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
      throw ApiConnectionException(
        AppErrorCode.apiBadResponse,
        detail: 'Body kosong | $url',
      );
    }

    // Deteksi HTML lebih awal (halaman web, bukan API).
    final head = raw.trimLeft().toLowerCase();
    if (contentType.contains('text/html') ||
        head.startsWith('<!doctype') ||
        head.startsWith('<html')) {
      throw ApiConnectionException(
        AppErrorCode.apiBadResponse,
        detail: 'HTML | $url | ${_snippet(raw)}',
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
        AppErrorCode.apiBadResponse,
        detail: 'Bukan JSON/SSE | $url | ${_snippet(raw)}',
      );
    } on ApiConnectionException catch (e) {
      // Status 200 dengan body error berarti provider melaporkan kegagalan di
      // dalam respons sukses (mis. upstream overload); baris status hanya
      // menambah kebisingan saat dicatat sebagai detail.
      final statusLine = response.statusCode == 200
          ? ''
          : 'Status: ${response.statusCode}, Content-Type: $contentType';
      throw ApiConnectionException(
        e.code,
        detail: [e.detail, statusLine, url].whereType<String>().join(' | '),
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

    // Pembatalan dari UI: hentikan baca & tandai sebagai cancelled.
    if (cancelToken != null) {
      cancelWatch = Completer<void>();
      cancelToken.whenCancel.then((_) {
        if (!cancelWatch!.isCompleted) {
          finish(ApiConnectionException(AppErrorCode.cancelled));
        }
      });
      if (cancelToken.isCancelled) {
        finish(ApiConnectionException(AppErrorCode.cancelled));
        return completer.future;
      }
    }

    void resetInactivity() {
      inactivity?.cancel();
      inactivity = Timer(timeout, () {
        finish(
          ApiConnectionException(
            AppErrorCode.apiTimeout,
            detail: 'Tidak ada data selama ${timeout.inSeconds} detik',
          ),
        );
      });
    }

    resetInactivity();
    total = Timer(AppConstants.generationTimeout, () {
      finish(
        ApiConnectionException(
          AppErrorCode.generationTimeout,
          detail:
              'Batas total ${AppConstants.generationTimeout.inMinutes} menit',
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
        finish(
          error is DioException
              ? ApiConnectionException(
                  mapDioError(error),
                  detail: dioErrorDetail(error),
                )
              : ApiConnectionException(
                  AppErrorCode.apiConnectionBroken,
                  detail: error.toString(),
                ),
        );
      },
      cancelOnError: true,
    );

    return completer.future;
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
      AppErrorCode.apiBadResponse,
      detail: 'HTML | ${response.requestOptions.uri} | ${_snippet(data)}',
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
        AppErrorCode.apiBadResponse,
        detail: 'Bukan JSON objek (${data.runtimeType}) | ${_snippet(data)}',
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
      throw ApiConnectionException(
        AppErrorCode.apiProviderReported,
        detail: providerError['message'] as String,
      );
    }
    if (providerError is String) {
      throw ApiConnectionException(
        AppErrorCode.apiProviderReported,
        detail: providerError,
      );
    }

    throw ApiConnectionException(
      AppErrorCode.apiBadResponse,
      detail:
          'Kunci tak dikenal: ${data.keys.take(8).join(', ')} | '
          '${_snippet(data)}',
    );
  }

  String _snippet(dynamic data) {
    final text = data.toString();
    return text.length > 220 ? '${text.substring(0, 220)}...' : text;
  }

  /// Mengklasifikasikan [DioException] jadi [AppErrorCode]. Teksnya disusun
  /// lapisan UI (`localizedAppError`) supaya ikut bahasa UI yang aktif; pesan
  /// mentah provider tetap tersimpan lewat [dioErrorDetail] untuk log.
  static AppErrorCode mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppErrorCode.apiTimeout;
      case DioExceptionType.connectionError:
        return AppErrorCode.apiUnreachable;
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        // Kunci bisa valid tetapi ditolak untuk model atau kebijakan tertentu
        // (OpenRouter membalas 403) — kode unauthorized tetap paling dekat.
        if (status == 401 || status == 403) {
          return AppErrorCode.apiUnauthorized;
        }
        // Model gratis sering kehabisan kapasitas upstream (HTTP 429).
        if (status == 429) return AppErrorCode.apiRateLimited;
        if (status == 404) return AppErrorCode.apiNotFound;
        return AppErrorCode.apiRejected;
      case DioExceptionType.cancel:
        return AppErrorCode.cancelled;
      case DioExceptionType.badCertificate:
        return AppErrorCode.apiCertificate;
      case DioExceptionType.transformTimeout:
      case DioExceptionType.unknown:
        return AppErrorCode.apiSendFailed;
    }
  }

  /// Rincian teknis dari [DioException] untuk log — TIDAK ditampilkan ke
  /// pengguna. `default` (type unknown) tidak dijadikan "kesalahan jaringan"
  /// mentah-mentah: penyebab asli (`e.error`) disertakan supaya salah URL, DNS
  /// gagal, dan TLS bisa dibedakan saat menelusuri masalah.
  ///
  /// [responseBody] diisi pemanggil yang memakai `ResponseType.stream`
  /// (body-nya tidak didekode Dio). [url] dan [model] menempelkan konteks
  /// request yang ditolak provider supaya salah URL vs salah model kelihatan.
  static String? dioErrorDetail(
    DioException e, {
    String? responseBody,
    String? url,
    String? model,
  }) {
    // Sumber pesan detail provider: body yang sudah dibaca pemanggil lebih
    // dulu, jatuh ke data respons Dio (Map/String) bila ada.
    final parts = <String>[];
    final status = e.response?.statusCode;
    if (status != null) parts.add('HTTP $status');
    final providerMessage = _providerErrorMessage(
      responseBody ?? e.response?.data,
    );
    if (providerMessage != null) parts.add(providerMessage);
    final trimmedUrl = url?.trim() ?? '';
    if (trimmedUrl.isNotEmpty) parts.add(trimmedUrl);
    final trimmedModel = model?.trim() ?? '';
    if (trimmedModel.isNotEmpty) parts.add('model=$trimmedModel');
    if (parts.isNotEmpty) return parts.join(' | ');
    final raw = e.error?.toString() ?? e.message ?? '';
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.length > 200 ? '${trimmed.substring(0, 200)}...' : trimmed;
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
