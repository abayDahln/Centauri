import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/utils/app_constants.dart';
import '../../domain/entities/oauth_session.dart';
import 'ai_api_service.dart';

/// Klien OAuth Cline.
///
/// Cline hanya mengirim `code` ke `vscode://saoudrizwan.claude-dev/auth`, jadi
/// Centauri tidak bisa menerima callback sendiri: pengguna menempel tautan
/// login sekali, lalu sesinya disimpan di secure storage oleh repository.
///
/// Semua request memakai header `Authorization: Bearer workos:<token>`; tanpa
/// prefix itu Cline membalas 401 (lihat spike di rencana).
class ClineOAuthService {
  const ClineOAuthService({Dio? dio}) : _injectedDio = dio;

  /// Seam pengujian: bila diisi, dipakai sebagai ganti klien bawaan.
  final Dio? _injectedDio;

  static const String baseUrl = 'https://api.cline.bot/api/v1';

  static final Dio _sharedDio = Dio(
    BaseOptions(
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.testConnectionTimeout,
    ),
  );

  Dio get _client => _injectedDio ?? _sharedDio;

  /// URL halaman login Cline.
  ///
  /// [callbackUrl] dikirim sebagai tujuan akhir setelah login. Cline
  /// menyimpannya di parameter `state`; bila dihormati, browser mendarat di
  /// alamat itu (loopback aplikasi) sehingga kode sesi diterima otomatis.
  static String authorizeUrl({String? callbackUrl}) {
    final uri = Uri.parse('$baseUrl/auth/authorize');
    return uri
        .replace(
          queryParameters: {
            'client_type': 'extension',
            if (callbackUrl != null && callbackUrl.isNotEmpty)
              'callback_url': callbackUrl,
          },
        )
        .toString();
  }

  // ------------------------------------------------------------ decode link --

  /// Ambil `code` dari tautan yang ditempel pengguna.
  ///
  /// Menerima URL `vscode://`, URL loopback dengan query `?code=`, atau
  /// base64 mentah. Null bila tautan berupa URL tanpa parameter `code`.
  static String? extractCode(String pasted) {
    final text = pasted.trim();
    if (text.isEmpty) return null;

    final looksLikeUrl = text.contains('://') || text.startsWith('http');
    if (!looksLikeUrl) return text;

    final marker = text.indexOf('code=');
    if (marker < 0) return null;

    var value = text.substring(marker + 'code='.length);
    final cut = value.indexOf(RegExp(r'[&#]'));
    if (cut >= 0) value = value.substring(0, cut);
    value = value.trim();
    if (value.isEmpty) return null;

    try {
      return Uri.decodeComponent(value);
    } catch (_) {
      // Persen-encoding rusak: pakai apa adanya.
      return value;
    }
  }

  /// Urai sesi dari tautan login tanpa menyentuh jaringan.
  ///
  /// Isi `code` adalah base64url dari JSON sesi plus ekor biner, jadi teks
  /// diambil sampai kurung kurawal penutup terakhir. Null bila tidak bisa
  /// diurai atau token wajibnya kosong.
  static OAuthSession? decodeSession(String pasted) {
    final code = extractCode(pasted);
    if (code == null) return null;

    final payload = _decodePayload(code);
    if (payload == null) return null;

    final accessToken = payload['accessToken'];
    final refreshToken = payload['refreshToken'];
    if (accessToken is! String || accessToken.isEmpty) return null;
    if (refreshToken is! String || refreshToken.isEmpty) return null;

    final email = _string(payload['email']);
    return OAuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      // Tanpa `expiresAt` sesi dianggap segera kedaluwarsa: satu kali refresh
      // berikutnya akan mengisi waktu yang sebenarnya.
      expiresAt: _expiryFrom(payload['expiresAt']) ?? DateTime.now().toUtc(),
      email: email,
      displayName: _displayName(payload),
    );
  }

  static Map<String, dynamic>? _decodePayload(String code) {
    var normalized = code.trim().replaceAll('=', '');
    if (normalized.isEmpty) return null;

    final remainder = normalized.length % 4;
    if (remainder > 0) {
      normalized = normalized.padRight(
        normalized.length + (4 - remainder),
        '=',
      );
    }
    normalized = normalized.replaceAll('-', '+').replaceAll('_', '/');

    try {
      final text = utf8.decode(base64Decode(normalized), allowMalformed: true);
      final end = text.lastIndexOf('}');
      if (end < 0) return null;

      final decoded = jsonDecode(text.substring(0, end + 1));
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------- jaringan --

  /// Validasi token, ambil profil, lalu kembalikan sesi lengkap.
  ///
  /// Melempar [ApiConnectionException] bila tautan tidak bisa diurai
  /// ([AppErrorCode.apiUnauthorized]) atau tokennya ditolak Cline.
  Future<OAuthSession> connect(String pasted) async {
    final session = decodeSession(pasted);
    if (session == null) {
      throw const ApiConnectionException(
        AppErrorCode.apiUnauthorized,
        detail: 'tautan login tidak memuat sesi',
      );
    }

    final profile = await _fetchProfile(session.accessToken);
    return session.copyWith(
      userId: profile.userId,
      email: profile.email ?? session.email,
      displayName: profile.displayName ?? session.displayName,
    );
  }

  /// Tukar refresh token lama dengan sesi baru.
  ///
  /// Cline merotasi refresh token: hasilnya wajib disimpan utuh, kalau tidak
  /// sesi berikutnya mati.
  Future<OAuthSession> refresh(OAuthSession session) async {
    final url = '$baseUrl/auth/refresh';

    final Response<dynamic> response;
    try {
      response = await _client.post<dynamic>(
        url,
        data: {
          'grantType': 'refresh_token',
          'refreshToken': session.refreshToken,
        },
        options: Options(headers: _jsonHeaders()),
      );
    } on DioException catch (e) {
      throw ApiConnectionException(
        AiApiService.mapDioError(e),
        detail: AiApiService.dioErrorDetail(e, url: url),
      );
    }

    final data = _asMap(response.data);
    final accessToken = data?['accessToken'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw const ApiConnectionException(
        AppErrorCode.apiBadResponse,
        detail: 'accessToken kosong pada respons refresh',
      );
    }

    final rotated = data!['refreshToken'];
    return session.copyWith(
      accessToken: accessToken,
      // Respons tanpa refreshToken baru: token lama masih berlaku.
      refreshToken: rotated is String && rotated.isNotEmpty ? rotated : null,
      expiresAt: _expiryFrom(data['expiresAt']) ?? session.expiresAt,
    );
  }

  /// Saldo akun dalam dolar. Nilainya bisa negatif (utang).
  Future<double> fetchBalance(OAuthSession session) async {
    final userId = session.userId?.trim() ?? '';
    if (userId.isEmpty) {
      throw const ApiConnectionException(
        AppErrorCode.apiBadResponse,
        detail: 'userId belum tersedia',
      );
    }

    final data = await _get(
      '$baseUrl/users/$userId/balance',
      session.accessToken,
    );
    final raw = data?['balance'];
    final micro = raw is num ? raw.toDouble() : double.tryParse('${raw ?? ''}');
    if (micro == null) {
      throw const ApiConnectionException(
        AppErrorCode.apiBadResponse,
        detail: 'balance tidak dikenali',
      );
    }
    // Cline menyimpan saldo dalam mikro-USD.
    return micro / 1000000;
  }

  Future<({String? userId, String? email, String? displayName})> _fetchProfile(
    String accessToken,
  ) async {
    final data = await _get('$baseUrl/users/me', accessToken);
    if (data == null) return (userId: null, email: null, displayName: null);

    final userId = _string(data['id']) ?? _string(data['userId']);
    return (
      userId: userId,
      email: _string(data['email']),
      displayName: _displayName(data),
    );
  }

  /// GET dengan header OAuth, lalu buka bungkus `data` bila ada.
  Future<Map<String, dynamic>?> _get(String url, String accessToken) async {
    final Response<dynamic> response;
    try {
      response = await _client.get<dynamic>(
        url,
        options: Options(headers: _oauthHeaders(accessToken)),
      );
    } on DioException catch (e) {
      throw ApiConnectionException(
        AiApiService.mapDioError(e),
        detail: AiApiService.dioErrorDetail(e, url: url),
      );
    }
    return _asMap(response.data);
  }

  Map<String, String> _jsonHeaders() => const {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Map<String, String> _oauthHeaders(String accessToken) => {
    ..._jsonHeaders(),
    'Authorization': 'Bearer workos:$accessToken',
  };

  /// Respons Cline kadang dibungkus `{data: {...}}`; buka bungkusnya.
  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) return null;
      try {
        return _asMap(jsonDecode(text));
      } catch (_) {
        return null;
      }
    }
    if (value is! Map) return null;
    final map = value.cast<String, dynamic>();
    final inner = map['data'];
    return inner is Map ? inner.cast<String, dynamic>() : map;
  }

  static String? _string(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _displayName(Map<String, dynamic> data) {
    final name = _string(data['name']);
    if (name != null) return name;

    final parts = [
      _string(data['firstName']),
      _string(data['lastName']),
    ].whereType<String>().toList();
    return parts.isEmpty ? null : parts.join(' ');
  }

  /// Waktu kedaluwarsa bisa berupa ISO string atau epoch (detik/milidetik).
  static DateTime? _expiryFrom(dynamic raw) {
    if (raw is num) {
      final ms = raw < 100000000000 ? (raw * 1000).round() : raw.round();
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    }
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;
      final asInt = int.tryParse(trimmed);
      if (asInt != null) return _expiryFrom(asInt);
      return DateTime.tryParse(trimmed)?.toUtc();
    }
    return null;
  }
}
