import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/utils/app_constants.dart';
import '../../domain/entities/api_provider.dart';
import '../../domain/entities/oauth_config.dart';
import '../../domain/entities/oauth_token_set.dart';
import '../../domain/services/oauth_service.dart';
import '../../domain/services/redirect_receiver.dart';
import 'browser_launcher.dart';
import 'loopback_redirect_server.dart';
import 'pkce.dart';

/// Implementasi [OAuthService] memakai loopback redirect (desktop) dan
/// Authorization Code + PKCE.
class OAuthServiceImpl implements OAuthService {
  OAuthServiceImpl({
    Dio? dio,
    BrowserLauncher? browserLauncher,
    RedirectReceiver Function()? receiverFactory,
    Duration? flowTimeout,
  }) : _dio = dio ?? Dio(),
       _browserLauncher = browserLauncher ?? const BrowserLauncher(),
       _receiverFactory = receiverFactory ?? LoopbackRedirectServer.new,
       _flowTimeout = flowTimeout ?? AppConstants.oauthFlowTimeout;

  final Dio _dio;
  final BrowserLauncher _browserLauncher;
  final RedirectReceiver Function() _receiverFactory;
  final Duration _flowTimeout;

  @override
  Future<OAuthTokenSet> authorize(ApiProvider provider) async {
    final config = provider.oauthConfig;
    if (config == null) {
      throw OAuthException('Provider ini belum dikonfigurasi untuk OAuth.');
    }

    final receiver = _receiverFactory();
    final redirectUri = await receiver.start(port: config.redirectPort);
    try {
      final verifier = config.usePkce ? Pkce.createVerifier() : null;
      final state = Pkce.createState();
      final authUrl = buildAuthorizationUrl(
        config,
        redirectUri: redirectUri,
        state: state,
        codeChallenge: verifier == null ? null : Pkce.challenge(verifier),
      );

      final opened = await _browserLauncher.open(authUrl);
      if (!opened) {
        throw OAuthException('Tidak dapat membuka browser untuk login.');
      }

      final result = await receiver.waitForCallback(timeout: _flowTimeout);
      if (result.error != null) {
        final detail = result.errorDescription ?? result.error!;
        throw OAuthException('Login ditolak oleh provider: $detail');
      }
      if (!result.isSuccess) {
        throw OAuthException('Login tidak selesai: kode otorisasi tidak diterima.');
      }
      if (result.state != state) {
        throw OAuthException(
          'State OAuth tidak cocok. Proses dihentikan demi keamanan (CSRF).',
        );
      }

      return await _exchangeCode(
        config: config,
        code: result.code!,
        redirectUri: redirectUri,
        codeVerifier: verifier,
      );
    } finally {
      await receiver.stop();
    }
  }

  @override
  Future<OAuthTokenSet> refresh(
    ApiProvider provider,
    OAuthTokenSet current,
  ) async {
    final config = provider.oauthConfig;
    if (config == null) {
      throw OAuthException('Provider ini belum dikonfigurasi untuk OAuth.');
    }
    if (!current.canRefresh) {
      throw OAuthException(
        'Sesi login tidak dapat diperbarui (tidak ada refresh token). '
        'Silakan hubungkan ulang.',
      );
    }

    final response = await _postToken(
      config.tokenUrl,
      {
        'grant_type': 'refresh_token',
        'refresh_token': current.refreshToken!,
        'client_id': config.clientId,
        ...config.extraTokenParams,
      },
    );
    return _parseTokenResponse(response, previous: current);
  }

  @override
  Future<void> revoke(ApiProvider provider, OAuthTokenSet tokens) async {
    final config = provider.oauthConfig;
    final url = config?.revocationUrl;
    if (config == null || url == null) return; // best-effort: tak ada endpoint.

    final token = tokens.refreshToken ?? tokens.accessToken;
    try {
      await _dio.post<dynamic>(
        url,
        data: {'token': token, 'client_id': config.clientId},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'Accept': 'application/json'},
          validateStatus: (_) => true,
        ),
      );
    } on DioException catch (e) {
      throw OAuthException(_mapDioError(e));
    }
  }

  Future<OAuthTokenSet> _exchangeCode({
    required OAuthConfig config,
    required String code,
    required Uri redirectUri,
    required String? codeVerifier,
  }) async {
    final response = await _postToken(config.tokenUrl, {
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': redirectUri.toString(),
      'client_id': config.clientId,
      'code_verifier': ?codeVerifier,
      ...config.extraTokenParams,
    });
    return _parseTokenResponse(response);
  }

  OAuthTokenSet _parseTokenResponse(
    Map<String, dynamic> response, {
    OAuthTokenSet? previous,
  }) {
    try {
      return OAuthTokenSet.fromTokenResponse(response, previous: previous);
    } on FormatException catch (e) {
      throw OAuthException('Respons token provider tidak valid: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> _postToken(
    String url,
    Map<String, String> body,
  ) async {
    try {
      final response = await _dio.post<dynamic>(
        url,
        data: body,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'Accept': 'application/json'},
          responseType: ResponseType.json,
        ),
      );
      final data = response.data;
      if (data is Map) return data.cast<String, dynamic>();
      throw OAuthException('Respons token provider tidak dikenali.');
    } on DioException catch (e) {
      throw OAuthException(_mapDioError(e));
    } on FormatException catch (e) {
      throw OAuthException('Respons token provider tidak valid: ${e.message}');
    }
  }

  String _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi ke server OAuth timeout. Periksa jaringan Anda.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server OAuth. Periksa jaringan Anda.';
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final detail = _providerError(e.response?.data);
        if (detail != null) {
          return 'Server OAuth menolak (HTTP $status): $detail';
        }
        return 'Server OAuth menolak permintaan (HTTP ${status ?? 'unknown'}).';
      default:
        return 'Terjadi kesalahan jaringan saat autentikasi OAuth.';
    }
  }

  String? _providerError(dynamic data) {
    if (data is Map) {
      if (data['error_description'] is String) {
        return data['error_description'] as String;
      }
      final error = data['error'];
      if (error is String) return error;
      if (error is Map && error['message'] is String) {
        return error['message'] as String;
      }
    }
    return null;
  }
}

/// Membangun authorization URL dari [config] beserta parameter PKCE/state.
///
/// Dipisah sebagai fungsi murni agar mudah diuji tanpa menjalankan server.
@visibleForTesting
Uri buildAuthorizationUrl(
  OAuthConfig config, {
  required Uri redirectUri,
  required String state,
  String? codeChallenge,
}) {
  final base = Uri.parse(config.authorizationUrl);
  final params = <String, String>{
    ...base.queryParameters,
    'response_type': 'code',
    'client_id': config.clientId,
    'redirect_uri': redirectUri.toString(),
    'state': state,
    if (config.scopes.isNotEmpty) 'scope': config.scopes.join(' '),
    'code_challenge': ?codeChallenge,
    if (codeChallenge != null) 'code_challenge_method': 'S256',
    if (config.audience != null) 'audience': config.audience!,
    ...config.extraAuthParams,
  };
  return base.replace(queryParameters: params);
}
