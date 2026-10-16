import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/app_constants.dart';
import '../../domain/entities/api_provider.dart';
import '../../domain/entities/device_authorization.dart';
import '../../domain/entities/oauth_config.dart';
import '../../domain/entities/oauth_flow.dart';
import '../../domain/entities/oauth_token_set.dart';
import '../../domain/services/oauth_service.dart';
import '../../domain/services/redirect_receiver.dart';
import 'browser_launcher.dart';
import 'loopback_redirect_server.dart';
import 'pkce.dart';

/// Implementasi [OAuthService] memakai loopback redirect (desktop) untuk
/// Authorization Code + PKCE, dan polling untuk Device Authorization Grant
/// (RFC 8628 maupun dialek custom Qoder).
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
    if (config.flow == OAuthFlow.importToken) {
      throw OAuthException(
        'Provider ini memakai impor token lokal, bukan alur browser.',
      );
    }

    final receiver = _receiverFactory();
    final redirectUri = await receiver.start(
      port: config.redirectPort,
      path: config.callbackPath,
    );
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

      final tokens = await _exchangeCode(
        config: config,
        code: result.code!,
        redirectUri: redirectUri,
        codeVerifier: verifier,
        state: state,
      );
      return await _applyTokenExchange(config, tokens);
    } finally {
      await receiver.stop();
    }
  }

  @override
  Future<DeviceAuthorization> startDeviceFlow(ApiProvider provider) async {
    final config = provider.oauthConfig;
    if (config == null) {
      throw OAuthException('Provider ini belum dikonfigurasi untuk OAuth.');
    }
    if (config.flow != OAuthFlow.deviceCode) {
      throw OAuthException('Provider ini bukan device flow.');
    }
    switch (config.deviceFlowStyle) {
      case DeviceFlowStyle.qoder:
        return _startQoderDeviceFlow(config);
      case DeviceFlowStyle.kilocode:
        return _startKilocodeDeviceFlow(config);
      case DeviceFlowStyle.codebuddy:
        return _startCodebuddyDeviceFlow(config);
      case DeviceFlowStyle.glm:
        return _startGlmDeviceFlow(config);
      case DeviceFlowStyle.kiro:
        return _startKiroDeviceFlow(config);
      case DeviceFlowStyle.rfc8628:
        return _startRfc8628DeviceFlow(config);
    }
  }

  @override
  Future<OAuthTokenSet> pollDeviceFlow(
    ApiProvider provider,
    DeviceAuthorization authorization, {
    required Future<void> cancel,
  }) async {
    final config = provider.oauthConfig;
    if (config == null) {
      throw OAuthException('Provider ini belum dikonfigurasi untuk OAuth.');
    }

    var interval = authorization.interval;
    while (DateTime.now().isBefore(authorization.expiresAt)) {
      if (await _sleepOrCancel(interval, cancel)) {
        throw OAuthException('Dibatalkan.');
      }
      final outcome = await _pollOnce(config, authorization);
      switch (outcome) {
        case _PollSuccess(:final tokens):
          return _applyTokenExchange(config, tokens);
        case _PollPending():
          continue;
        case _PollSlowDown():
          interval += const Duration(seconds: 2);
          continue;
        case _PollDenied(:final message):
          throw OAuthException(message);
      }
    }
    throw OAuthException('Waktu tunggu habis sebelum otorisasi selesai.');
  }

  /// Qoder: kode device (`nonce`) + PKCE di-generate lokal, URL login disusun
  /// di klien. Tidak ada request awal ke server.
  DeviceAuthorization _startQoderDeviceFlow(OAuthConfig config) {
    final verifier = Pkce.createVerifier();
    final challenge = Pkce.challenge(verifier);
    final nonce = const Uuid().v4();
    final machineId = const Uuid().v4();
    return DeviceAuthorization(
      flow: OAuthFlow.deviceCode,
      style: DeviceFlowStyle.qoder,
      verificationUri: buildQoderLoginUrl(
        config.authorizationUrl,
        challenge: challenge,
        machineId: machineId,
        nonce: nonce,
      ),
      userCode: deriveUserCode(nonce),
      deviceCode: nonce,
      codeVerifier: verifier,
      interval: const Duration(seconds: 2),
      expiresAt: DateTime.now().add(_flowTimeout),
    );
  }

  /// RFC 8628: minta kode device/user dari endpoint device_authorization.
  Future<DeviceAuthorization> _startRfc8628DeviceFlow(OAuthConfig config) async {
    final response = await _postFormAllowingStatus(config.authorizationUrl, {
      'client_id': config.clientId,
      if (config.scopes.isNotEmpty) 'scope': config.scopes.join(' '),
      ...config.extraAuthParams,
    });
    final data = response.data;
    final map = data is Map
        ? data.cast<String, dynamic>()
        : const <String, dynamic>{};
    if (response.statusCode != 200) {
      final detail = _providerError(map);
      throw OAuthException(
        detail == null
            ? 'Gagal memulai device flow (HTTP ${response.statusCode}).'
            : 'Gagal memulai device flow: $detail',
      );
    }

    final deviceCode = map['device_code'] as String?;
    final userCode = map['user_code'] as String?;
    final verificationUri = map['verification_uri'] as String?;
    if (deviceCode == null || userCode == null || verificationUri == null) {
      throw OAuthException('Respons device authorization tidak lengkap.');
    }
    final complete = map['verification_uri_complete'] as String?;
    final expiresIn = _intFrom(map['expires_in']) ?? 900;
    final interval = _intFrom(map['interval']) ?? 5;

    return DeviceAuthorization(
      flow: OAuthFlow.deviceCode,
      style: DeviceFlowStyle.rfc8628,
      verificationUri: Uri.parse(verificationUri),
      verificationUriComplete: complete == null ? null : Uri.tryParse(complete),
      userCode: userCode,
      deviceCode: deviceCode,
      interval: Duration(seconds: interval),
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
    );
  }

  /// Kilo Code: POST JSON tanpa body untuk meminta kode, respons memuat
  /// `code` + `verificationUrl` (+ `expiresIn`). Polling memakai
  /// `GET {tokenUrl}/{code}`.
  Future<DeviceAuthorization> _startKilocodeDeviceFlow(
    OAuthConfig config,
  ) async {
    final response = await _postJsonAllowingStatus(config.authorizationUrl, {});
    final map = _asMap(response.data);
    final status = response.statusCode ?? 0;
    if (status != 200 && status != 201) {
      final detail = _providerError(map);
      throw OAuthException(
        detail == null
            ? 'Gagal memulai device flow Kilo Code (HTTP $status).'
            : 'Gagal memulai device flow Kilo Code: $detail',
      );
    }

    final code = map['code'] as String?;
    final verificationUrl = map['verificationUrl'] as String?;
    if (code == null || verificationUrl == null) {
      throw OAuthException('Respons device authorization Kilo Code tidak lengkap.');
    }
    final expiresIn = _intFrom(map['expiresIn']) ?? 300;

    return DeviceAuthorization(
      flow: OAuthFlow.deviceCode,
      style: DeviceFlowStyle.kilocode,
      verificationUri: Uri.parse(verificationUrl),
      userCode: map['userCode'] as String? ?? code,
      deviceCode: code,
      interval: const Duration(seconds: 3),
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
    );
  }

  Future<_PollOutcome> _pollOnce(
    OAuthConfig config,
    DeviceAuthorization authorization,
  ) {
    switch (authorization.style) {
      case DeviceFlowStyle.qoder:
        return _pollQoder(config, authorization);
      case DeviceFlowStyle.kilocode:
        return _pollKilocode(config, authorization);
      case DeviceFlowStyle.codebuddy:
        return _pollCodebuddy(config, authorization);
      case DeviceFlowStyle.glm:
        return _pollGlm(config, authorization);
      case DeviceFlowStyle.kiro:
        return _pollKiro(config, authorization);
      case DeviceFlowStyle.rfc8628:
        return _pollRfc8628(config, authorization);
    }
  }

  Future<_PollOutcome> _pollQoder(
    OAuthConfig config,
    DeviceAuthorization authorization,
  ) async {
    final verifier = authorization.codeVerifier;
    if (verifier == null || verifier.isEmpty) {
      return const _PollDenied('Verifier Qoder hilang; ulangi login.');
    }
    // Endpoint polling Qoder memakai GET + query param (bukan POST form):
    //   {tokenUrl}?nonce=...&verifier=...&challenge_method=S256
    final base = Uri.parse(config.tokenUrl);
    final url = base.replace(
      queryParameters: {
        ...base.queryParameters,
        'nonce': authorization.deviceCode,
        'verifier': verifier,
        'challenge_method': 'S256',
      },
    );
    final response = await _getAllowingStatus(
      url.toString(),
      headers: {'User-Agent': 'Go-http-client/2.0'},
    );
    final status = response.statusCode ?? 0;
    final map = _asMap(response.data);

    // 202/404 = pengguna belum berotorisasi di browser; terus menunggu.
    if (status == 202 || status == 404) return const _PollPending();
    if (status == 200) {
      final token = map['token'] as String?;
      if (token == null || token.isEmpty) {
        return const _PollDenied('Respons token Qoder tidak memuat token.');
      }
      final refresh = map['refresh_token'] as String?;
      return _PollSuccess(
        OAuthTokenSet(
          accessToken: token,
          refreshToken: (refresh == null || refresh.isEmpty) ? null : refresh,
          expiresAt: _qoderExpiry(map),
        ),
      );
    }
    final detail = _providerError(map);
    return _PollDenied(
      detail == null
          ? 'Server Qoder menolak (HTTP $status).'
          : 'Server Qoder menolak: $detail',
    );
  }

  /// Masa berlaku token Qoder: `expires_at` (ms-epoch, angka/string) →
  /// `expires_in` (detik) → default 30 hari.
  DateTime _qoderExpiry(Map<String, dynamic> map) {
    final expiresAt = map['expires_at'];
    if (expiresAt is num && expiresAt > 0) {
      return DateTime.fromMillisecondsSinceEpoch(expiresAt.toInt());
    }
    final raw = expiresAt?.toString().trim() ?? '';
    if (raw.isNotEmpty && RegExp(r'^\d+$').hasMatch(raw)) {
      final ms = int.tryParse(raw);
      if (ms != null && ms > 0) {
        return DateTime.fromMillisecondsSinceEpoch(ms);
      }
    }
    final expiresIn = _intFrom(map['expires_in']);
    if (expiresIn != null && expiresIn >= 0) {
      return DateTime.now().add(Duration(seconds: expiresIn));
    }
    return DateTime.now().add(const Duration(days: 30));
  }

  Future<_PollOutcome> _pollRfc8628(
    OAuthConfig config,
    DeviceAuthorization authorization,
  ) async {
    final response = await _postFormAllowingStatus(config.tokenUrl, {
      'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
      'device_code': authorization.deviceCode,
      'client_id': config.clientId,
      ...config.extraTokenParams,
    });
    final status = response.statusCode ?? 0;
    final data = response.data;
    final map = data is Map
        ? data.cast<String, dynamic>()
        : const <String, dynamic>{};

    if (status == 200) {
      return _PollSuccess(_parseTokenResponse(map));
    }
    switch (map['error']) {
      case 'authorization_pending':
        return const _PollPending();
      case 'slow_down':
        return const _PollSlowDown();
      case 'access_denied':
        return const _PollDenied('Akses ditolak oleh pengguna.');
      case 'expired_token':
        return const _PollDenied('Kode kedaluwarsa. Silakan coba lagi.');
    }
    final detail = _providerError(map);
    return _PollDenied(
      detail == null
          ? 'Server OAuth menolak (HTTP $status).'
          : 'Server OAuth menolak: $detail',
    );
  }

  /// Kilo Code: poll `GET {tokenUrl}/{deviceCode}`. 202 = menunggu,
  /// 403 = ditolak, 410 = kedaluwarsa; 200 + `status == "approved"` = sukses
  /// (token di field `token`).
  Future<_PollOutcome> _pollKilocode(
    OAuthConfig config,
    DeviceAuthorization authorization,
  ) async {
    final response = await _getAllowingStatus(
      '${config.tokenUrl}/${authorization.deviceCode}',
    );
    final status = response.statusCode ?? 0;
    final map = _asMap(response.data);

    switch (status) {
      case 202:
        return const _PollPending();
      case 403:
        return const _PollDenied('Akses ditolak oleh pengguna.');
      case 410:
        return const _PollDenied('Kode kedaluwarsa. Silakan coba lagi.');
    }

    if (status == 200) {
      final token = map['token'] as String?;
      if (map['status'] == 'approved' && token != null && token.isNotEmpty) {
        return _PollSuccess(
          OAuthTokenSet(
            accessToken: token,
            // Kilo Code tidak mengirim masa berlaku; pakai default panjang.
            expiresAt: DateTime.now().add(const Duration(days: 30)),
          ),
        );
      }
      return const _PollPending();
    }

    final detail = _providerError(map);
    return _PollDenied(
      detail == null
          ? 'Server Kilo Code menolak (HTTP $status).'
          : 'Server Kilo Code menolak: $detail',
    );
  }

  /// CodeBuddy: POST `{stateUrl}?platform=ide` (header khusus) → `{state,
  /// authUrl}`, lalu poll `GET {tokenUrl}?state=...`.
  Future<DeviceAuthorization> _startCodebuddyDeviceFlow(
    OAuthConfig config,
  ) async {
    final response = await _postJsonAllowingStatus(
      '${config.authorizationUrl}?platform=ide',
      const {},
      headers: _codebuddyHeaders(),
    );
    final map = _asMap(response.data);
    final status = response.statusCode ?? 0;
    final data = _asMap(map['data']);
    final authUrl = data['authUrl'] as String?;
    final state = data['state'] as String?;
    if (status != 200 || map['code'] != 0 || authUrl == null || state == null) {
      throw OAuthException(
        'Gagal memulai device flow CodeBuddy (HTTP $status'
        '${map['msg'] == null ? '' : ': ${map['msg']}'}).',
      );
    }
    return DeviceAuthorization(
      flow: OAuthFlow.deviceCode,
      style: DeviceFlowStyle.codebuddy,
      verificationUri: Uri.parse(authUrl),
      userCode: '',
      deviceCode: state,
      interval: const Duration(seconds: 5),
      expiresAt: DateTime.now().add(_flowTimeout),
    );
  }

  Future<_PollOutcome> _pollCodebuddy(
    OAuthConfig config,
    DeviceAuthorization authorization,
  ) async {
    final response = await _getAllowingStatus(
      '${config.tokenUrl}?state=${Uri.encodeComponent(authorization.deviceCode)}',
      headers: _codebuddyHeaders(includeEnterprise: true),
    );
    if ((response.statusCode ?? 0) != 200) return const _PollPending();
    final map = _asMap(response.data);
    final data = _asMap(map['data']);
    final token = data['accessToken'] as String?;
    if (map['code'] == 0 && token != null && token.isNotEmpty) {
      final refresh = data['refreshToken'] as String?;
      final expiresIn = _intFrom(data['expiresIn']) ?? 86400;
      return _PollSuccess(
        OAuthTokenSet(
          accessToken: token,
          refreshToken: (refresh == null || refresh.isEmpty) ? null : refresh,
          expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
        ),
      );
    }
    if (map['code'] == 11217) return const _PollPending();
    final detail = map['msg'] as String?;
    return _PollDenied(
      detail == null ? 'CodeBuddy menolak otorisasi.' : 'CodeBuddy: $detail',
    );
  }

  Map<String, String> _codebuddyHeaders({bool includeEnterprise = false}) => {
    'User-Agent': 'IDE/2.63.2 CodeBuddy/2.63.2',
    'X-Requested-With': 'XMLHttpRequest',
    'X-Domain': 'www.codebuddy.ai',
    'X-No-Authorization': 'true',
    'X-No-User-Id': 'true',
    if (includeEnterprise) 'X-No-Enterprise-Id': 'true',
    if (includeEnterprise) 'X-No-Department-Info': 'true',
    'X-Product': 'SaaS',
  };

  /// Zai GLM (ZCode CLI): POST `{cliInitUrl}` dengan Bearer poll-token →
  /// `{flow_id, authorize_url}`, lalu poll `GET {cliPollUrl}/{flow_id}`.
  Future<DeviceAuthorization> _startGlmDeviceFlow(OAuthConfig config) async {
    final pollToken = _randomHex(32);
    final response = await _postJsonAllowingStatus(
      config.authorizationUrl,
      const {'provider': 'zai'},
      headers: {'Authorization': 'Bearer $pollToken'},
    );
    final map = _asMap(response.data);
    final data = _asMap(map['data']);
    final flowId = data['flow_id'] as String?;
    final authorizeUrl = data['authorize_url'] as String?;
    if ((response.statusCode ?? 0) != 200 ||
        map['code'] != 0 ||
        flowId == null ||
        authorizeUrl == null) {
      final detail = map['msg'] as String?;
      throw OAuthException(
        detail == null
            ? 'Gagal memulai device flow Zai GLM (HTTP ${response.statusCode}).'
            : 'Gagal memulai device flow Zai GLM: $detail',
      );
    }
    final interval = _intFrom(data['poll_interval_sec']) ?? 3;
    return DeviceAuthorization(
      flow: OAuthFlow.deviceCode,
      style: DeviceFlowStyle.glm,
      verificationUri: Uri.parse(authorizeUrl),
      userCode: '',
      deviceCode: flowId,
      interval: Duration(seconds: interval),
      expiresAt: DateTime.now().add(_flowTimeout),
      extra: {'pollToken': pollToken},
    );
  }

  Future<_PollOutcome> _pollGlm(
    OAuthConfig config,
    DeviceAuthorization authorization,
  ) async {
    final pollToken = authorization.extra['pollToken'];
    if (pollToken == null) {
      return const _PollDenied('Poll token Zai GLM hilang; ulangi login.');
    }
    final response = await _getAllowingStatus(
      '${config.tokenUrl}/${Uri.encodeComponent(authorization.deviceCode)}',
      headers: {'Authorization': 'Bearer $pollToken'},
    );
    if ((response.statusCode ?? 0) != 200) {
      return const _PollPending();
    }
    final map = _asMap(response.data);
    if (map['code'] != 0) return const _PollPending();
    final data = _asMap(map['data']);
    switch (data['status']) {
      case 'pending':
        return const _PollPending();
      case 'failed':
        return const _PollDenied('Otorisasi Zai GLM gagal atau dibatalkan.');
      case 'ready':
        final providerData = _asMap(data['zai']);
        final token =
            (providerData['access_token'] ??
                providerData['accessToken'] ??
                data['accessToken'] ??
                data['access_token'])
            as String?;
        if (token == null || token.isEmpty) {
          return const _PollDenied('Respons token Zai GLM tidak memuat token.');
        }
        final refresh =
            (providerData['refresh_token'] ?? data['refreshToken']) as String?;
        return _PollSuccess(
          OAuthTokenSet(
            accessToken: token,
            refreshToken: (refresh == null || refresh.isEmpty) ? null : refresh,
            expiresAt: DateTime.now().add(const Duration(days: 30)),
          ),
        );
      default:
        return const _PollPending();
    }
  }

  /// Kiro (AWS SSO OIDC): register client → device_authorization → poll token.
  Future<DeviceAuthorization> _startKiroDeviceFlow(OAuthConfig config) async {
    final registerUrl =
        config.extraAuthParams['registerClientUrl'] ??
        'https://oidc.us-east-1.amazonaws.com/client/register';
    final startUrl =
        config.extraAuthParams['startUrl'] ??
        'https://view.awsapps.com/start';
    final clientName = config.extraAuthParams['clientName'] ?? 'kiro-oauth-client';

    final register = await _postJsonAllowingStatus(registerUrl, {
      'clientName': clientName,
      'clientType': 'public',
      'scopes': config.scopes,
      'grantTypes': [
        'urn:ietf:params:oauth:grant-type:device_code',
        'refresh_token',
      ],
      'issuerUrl':
          config.extraAuthParams['issuerUrl'] ??
          'https://identitycenter.amazonaws.com/ssoins-722374e8c3c8e6c6',
    });
    final clientInfo = _asMap(register.data);
    final clientId = clientInfo['clientId'] as String?;
    final clientSecret = clientInfo['clientSecret'] as String?;
    if ((register.statusCode ?? 0) != 200 ||
        clientId == null ||
        clientSecret == null) {
      throw OAuthException(
        'Gagal mendaftarkan klien Kiro (HTTP ${register.statusCode}).',
      );
    }

    final device = await _postJsonAllowingStatus(config.authorizationUrl, {
      'clientId': clientId,
      'clientSecret': clientSecret,
      'startUrl': startUrl,
    });
    final deviceData = _asMap(device.data);
    final deviceCode = deviceData['deviceCode'] as String?;
    final userCode = deviceData['userCode'] as String?;
    final verificationUri = deviceData['verificationUri'] as String?;
    if ((device.statusCode ?? 0) != 200 ||
        deviceCode == null ||
        userCode == null ||
        verificationUri == null) {
      throw OAuthException(
        'Gagal memulai device authorization Kiro '
        '(HTTP ${device.statusCode}).',
      );
    }
    final complete = deviceData['verificationUriComplete'] as String?;
    final expiresIn = _intFrom(deviceData['expiresIn']) ?? 900;
    final interval = _intFrom(deviceData['interval']) ?? 5;
    return DeviceAuthorization(
      flow: OAuthFlow.deviceCode,
      style: DeviceFlowStyle.kiro,
      verificationUri: Uri.parse(verificationUri),
      verificationUriComplete: complete == null ? null : Uri.tryParse(complete),
      userCode: userCode,
      deviceCode: deviceCode,
      interval: Duration(seconds: interval),
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      extra: {'clientId': clientId, 'clientSecret': clientSecret},
    );
  }

  Future<_PollOutcome> _pollKiro(
    OAuthConfig config,
    DeviceAuthorization authorization,
  ) async {
    final response = await _postJsonAllowingStatus(config.tokenUrl, {
      'clientId': authorization.extra['clientId'] ?? '',
      'clientSecret': authorization.extra['clientSecret'] ?? '',
      'deviceCode': authorization.deviceCode,
      'grantType': 'urn:ietf:params:oauth:grant-type:device_code',
    });
    final map = _asMap(response.data);
    final token = map['accessToken'] as String?;
    if ((response.statusCode ?? 0) == 200 && token != null && token.isNotEmpty) {
      final refresh = map['refreshToken'] as String?;
      final expiresIn = _intFrom(map['expiresIn']) ?? 3600;
      return _PollSuccess(
        OAuthTokenSet(
          accessToken: token,
          refreshToken: (refresh == null || refresh.isEmpty) ? null : refresh,
          expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
        ),
      );
    }
    switch (map['error']) {
      case 'authorization_pending':
        return const _PollPending();
      case 'slow_down':
        return const _PollSlowDown();
      case 'expired_token':
        return const _PollDenied('Kode kedaluwarsa. Silakan coba lagi.');
      case 'access_denied':
        return const _PollDenied('Akses ditolak oleh pengguna.');
    }
    final detail = _providerError(map);
    return _PollDenied(
      detail == null
          ? 'Server Kiro menolak (HTTP ${response.statusCode}).'
          : 'Server Kiro menolak: $detail',
    );
  }

  /// Tunggu [duration] atau sampai [cancel] complete. Mengembalikan true bila
  /// dibatalkan.
  Future<bool> _sleepOrCancel(Duration duration, Future<void> cancel) {
    final completer = Completer<bool>();
    final timer = Timer(duration, () {
      if (!completer.isCompleted) completer.complete(false);
    });
    cancel.then((_) {
      if (!completer.isCompleted) completer.complete(true);
    });
    return completer.future.whenComplete(timer.cancel);
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
      format: config.tokenBodyFormat,
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
    required String state,
  }) async {
    if (config.tokenExchange == TokenExchangeStyle.cline) {
      return _exchangeCline(config, code, redirectUri);
    }
    final response = await _postToken(
      config.tokenUrl,
      {
        'grant_type': 'authorization_code',
        'code': code,
        // Beberapa provider (mis. Claude) mengharapkan `state` dikirim ulang.
        'state': state,
        'redirect_uri': redirectUri.toString(),
        'client_id': config.clientId,
        'code_verifier': ?codeVerifier,
        ...config.extraTokenParams,
      },
      format: config.tokenBodyFormat,
    );
    return _parseTokenResponse(response);
  }

  /// Cline: `code` biasanya berisi data token base64; fallback ke POST token
  /// URL bila decode gagal.
  Future<OAuthTokenSet> _exchangeCline(
    OAuthConfig config,
    String code,
    Uri redirectUri,
  ) async {
    final decoded = _tryDecodeClineCode(code);
    if (decoded != null) return decoded;

    final response = await _postJsonAllowingStatus(config.tokenUrl, {
      'grant_type': 'authorization_code',
      'code': code,
      'client_type': 'extension',
      'redirect_uri': redirectUri.toString(),
    });
    final map = _asMap(response.data);
    final data = _asMap(map['data']);
    final access =
        (data['accessToken'] ?? map['accessToken'] ?? map['access_token'])
            as String?;
    if (access == null || access.isEmpty) {
      throw OAuthException('Cline tidak mengembalikan access token.');
    }
    final refresh = (data['refreshToken'] ?? map['refreshToken']) as String?;
    final expiresAt = (data['expiresAt'] ?? map['expiresAt']) as String?;
    return OAuthTokenSet(
      accessToken: access,
      refreshToken: (refresh == null || refresh.isEmpty) ? null : refresh,
      expiresAt: expiresAt == null
          ? DateTime.now().add(const Duration(hours: 1))
          : (DateTime.tryParse(expiresAt) ??
                DateTime.now().add(const Duration(hours: 1))),
    );
  }

  OAuthTokenSet? _tryDecodeClineCode(String code) {
    try {
      var base64 = code;
      final padding = 4 - (base64.length % 4);
      if (padding != 4) base64 += '=' * padding;
      final text = utf8.decode(base64Decode(base64));
      final end = text.lastIndexOf('}');
      if (end == -1) return null;
      final json = jsonDecode(text.substring(0, end + 1));
      if (json is! Map) return null;
      final access = json['accessToken'] as String?;
      if (access == null || access.isEmpty) return null;
      final refresh = json['refreshToken'] as String?;
      final expiresAt = json['expiresAt'] as String?;
      return OAuthTokenSet(
        accessToken: access,
        refreshToken: (refresh == null || refresh.isEmpty) ? null : refresh,
        expiresAt: expiresAt == null
            ? DateTime.now().add(const Duration(hours: 1))
            : (DateTime.tryParse(expiresAt) ??
                  DateTime.now().add(const Duration(hours: 1))),
      );
    } catch (_) {
      return null;
    }
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
    Map<String, String> body, {
    TokenBodyFormat format = TokenBodyFormat.form,
  }) async {
    try {
      final isJson = format == TokenBodyFormat.json;
      final response = await _dio.post<dynamic>(
        url,
        data: body,
        options: Options(
          contentType: isJson
              ? Headers.jsonContentType
              : Headers.formUrlEncodedContentType,
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

  /// Langkah tukar-token tambahan setelah token utama diperoleh.
  ///
  /// - [TokenExchangeStyle.none]: token dikembalikan apa adanya.
  /// - [TokenExchangeStyle.githubCopilot]: token GitHub ditukar menjadi token
  ///   Copilot (`POST https://api.github.com/copilot_internal/v2/token`).
  Future<OAuthTokenSet> _applyTokenExchange(
    OAuthConfig config,
    OAuthTokenSet tokens,
  ) async {
    switch (config.tokenExchange) {
      case TokenExchangeStyle.none:
        return tokens;
      case TokenExchangeStyle.githubCopilot:
        return _exchangeGithubCopilot(tokens);
      case TokenExchangeStyle.cline:
        // Cline mengembalikan token langsung di langkah exchange; tidak ada
        // langkah tambahan di sini.
        return tokens;
    }
  }

  Future<OAuthTokenSet> _exchangeGithubCopilot(OAuthTokenSet github) async {
    try {
      final response = await _dio.get<dynamic>(
        'https://api.github.com/copilot_internal/v2/token',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${github.accessToken}',
            'Accept': 'application/json',
            'Editor-Version': 'vscode/1.99.0',
            'Editor-Plugin-Version': 'copilot-chat/0.26.0',
            'User-Agent': 'GitHubCopilotChat/0.26.0',
          },
          responseType: ResponseType.json,
        ),
      );
      final data = response.data;
      final map = data is Map ? data.cast<String, dynamic>() : const <String, dynamic>{};
      final token = map['token'] as String?;
      if (token == null || token.isEmpty) {
        throw OAuthException('Token Copilot tidak diterima dari GitHub.');
      }
      final expiresAt = _intFrom(map['expires_at']);
      return OAuthTokenSet(
        accessToken: token,
        refreshToken: github.refreshToken,
        expiresAt: expiresAt == null
            ? DateTime.now().add(const Duration(minutes: 30))
            : DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000),
      );
    } on DioException catch (e) {
      throw OAuthException(_mapDioError(e));
    }
  }

  /// POST JSON tanpa body (atau body kosong) yang mengembalikan respons apa
  /// pun — dipakai device flow custom yang memakai status sebagai sinyal.
  Future<Response<dynamic>> _postJsonAllowingStatus(
    String url,
    Map<String, dynamic> body, {
    Map<String, String> headers = const {},
  }) async {
    try {
      return await _dio.post<dynamic>(
        url,
        data: body.isEmpty ? null : body,
        options: Options(
          contentType: Headers.jsonContentType,
          headers: {'Accept': 'application/json', ...headers},
          responseType: ResponseType.json,
          validateStatus: (_) => true,
        ),
      );
    } on DioException catch (e) {
      throw OAuthException(_mapDioError(e));
    }
  }

  /// GET yang mengembalikan respons apa pun (status non-2xx tidak dilempar).
  Future<Response<dynamic>> _getAllowingStatus(
    String url, {
    Map<String, String> headers = const {},
  }) async {
    try {
      return await _dio.get<dynamic>(
        url,
        options: Options(
          headers: {'Accept': 'application/json', ...headers},
          responseType: ResponseType.json,
          validateStatus: (_) => true,
        ),
      );
    } on DioException catch (e) {
      throw OAuthException(_mapDioError(e));
    }
  }

  Map<String, dynamic> _asMap(dynamic data) =>
      data is Map ? data.cast<String, dynamic>() : const <String, dynamic>{};

  /// POST form-urlencoded yang mengembalikan respons apa pun (status non-2xx
  /// tidak dilempar) — dipakai device flow yang memakai status 202/400 sebagai
  /// sinyal "masih menunggu".
  Future<Response<dynamic>> _postFormAllowingStatus(
    String url,
    Map<String, String> body,
  ) async {
    try {
      return await _dio.post<dynamic>(
        url,
        data: body,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'Accept': 'application/json'},
          responseType: ResponseType.json,
          validateStatus: (_) => true,
        ),
      );
    } on DioException catch (e) {
      throw OAuthException(_mapDioError(e));
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

/// Menyusun URL login device flow Qoder dengan parameter challenge/machine/nonce.
@visibleForTesting
Uri buildQoderLoginUrl(
  String base, {
  required String challenge,
  required String machineId,
  required String nonce,
}) {
  final uri = Uri.parse(base);
  return uri.replace(
    queryParameters: {
      ...uri.queryParameters,
      'challenge': challenge,
      'challenge_method': 'S256',
      'machine_id': machineId,
      'nonce': nonce,
    },
  );
}

/// Menurunkan kode singkat yang ditampilkan ke pengguna dari `nonce`.
///
/// Hipotesis: 8 karakter hex pertama dari UUID (tanpa tanda hubung),
/// uppercase — konsisten dengan bentuk kode yang ditampilkan 9router.
@visibleForTesting
String deriveUserCode(String nonce) {
  final hex = nonce.replaceAll('-', '');
  final code = hex.length >= 8 ? hex.substring(0, 8) : hex.padRight(8, '0');
  return code.toUpperCase();
}

int? _intFrom(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

/// Byte acak dalam heksadesimal (dipakai sebagai poll-token GLM).
String _randomHex(int bytes) {
  final rng = Random.secure();
  final buffer = StringBuffer();
  for (var i = 0; i < bytes; i++) {
    buffer.write(rng.nextInt(256).toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

/// Hasil satu putaran polling device flow.
sealed class _PollOutcome {
  const _PollOutcome();
}

class _PollPending extends _PollOutcome {
  const _PollPending();
}

class _PollSlowDown extends _PollOutcome {
  const _PollSlowDown();
}

class _PollSuccess extends _PollOutcome {
  const _PollSuccess(this.tokens);
  final OAuthTokenSet tokens;
}

class _PollDenied extends _PollOutcome {
  const _PollDenied(this.message);
  final String message;
}
