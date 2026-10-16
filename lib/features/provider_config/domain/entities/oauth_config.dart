import 'oauth_flow.dart';

/// Konfigurasi OAuth 2.0 untuk sebuah provider.
///
/// Mendukung dua alur ([flow]):
///  - [OAuthFlow.authorizationCode] (default): Authorization Code + PKCE via
///    redirect loopback.
///  - [OAuthFlow.deviceCode]: Device Authorization Grant (RFC 8628) atau
///    dialek custom ([deviceFlowStyle]).
///
/// Untuk device flow, [authorizationUrl] dipakai sebagai:
///  - RFC 8628: endpoint `device_authorization` (di-POST untuk minta kode);
///  - Qoder: base login URL (parameter challenge/machine_id/nonce ditambah
///    lokal oleh klien).
/// [tokenUrl] menjadi endpoint polling token pada kedua dialek.
///
/// Catatan keamanan: [clientId] untuk klien publik PKCE bersifat non-rahasia,
/// jadi aman diserialisasi ke Hive. [clientSecret] (bila ada) TIDAK disimpan
/// di sini — ia hidup di secure storage, sama seperti API Key (NFR-01).
class OAuthConfig {
  const OAuthConfig({
    required this.authorizationUrl,
    required this.tokenUrl,
    required this.clientId,
    this.scopes = const [],
    this.revocationUrl,
    this.audience,
    this.redirectPort,
    this.extraAuthParams = const {},
    this.extraTokenParams = const {},
    this.usePkce = true,
    this.isExperimental = false,
    this.flow = OAuthFlow.authorizationCode,
    this.deviceFlowStyle = DeviceFlowStyle.rfc8628,
    this.tokenExchange = TokenExchangeStyle.none,
    this.tokenBodyFormat = TokenBodyFormat.form,
    this.callbackPath,
    this.importSource,
    this.isTokenOnly = false,
  });

  /// Endpoint otorisasi (Authorization Code) / device_authorization (RFC 8628)
  /// / base login URL (Qoder). Lihat catatan kelas.
  final String authorizationUrl;

  /// Endpoint tukar token (code → access/refresh token) atau endpoint polling
  /// device token.
  final String tokenUrl;

  /// Client id publik PKCE.
  final String clientId;

  /// Scope yang diminta.
  final List<String> scopes;

  /// Endpoint revoke token (opsional, best-effort saat disconnect).
  final String? revocationUrl;

  /// Parameter `audience` (dipakai sebagian provider, mis. Auth0).
  final String? audience;

  /// Port tetap untuk loopback redirect. Null = ephemeral (port acak).
  /// Sebagian provider mem-pin port redirect sehingga wajib tetap.
  final int? redirectPort;

  /// Parameter tambahan pada authorization request.
  final Map<String, String> extraAuthParams;

  /// Parameter tambahan pada token request.
  final Map<String, String> extraTokenParams;

  /// Aktifkan PKCE (S256). Default true.
  final bool usePkce;

  /// Menandai preset flow "subscription" yang endpoint-nya tidak resmi
  /// (reverse-engineered). Berisiko berubah sewaktu-waktu / melanggar ToS,
  /// sehingga UI wajib menampilkan peringatan.
  final bool isExperimental;

  /// Alur OAuth yang dipakai. Default [OAuthFlow.authorizationCode].
  final OAuthFlow flow;

  /// Dialek device flow. Hanya relevan bila [flow] == [OAuthFlow.deviceCode].
  final DeviceFlowStyle deviceFlowStyle;

  /// Langkah tukar-token tambahan setelah token utama diperoleh.
  final TokenExchangeStyle tokenExchange;

  /// Format body saat menukar token (form-urlencoded atau JSON).
  final TokenBodyFormat tokenBodyFormat;

  /// Path callback loopback khusus (mis. `/auth/callback`). Null = default
  /// (`AppConstants.oauthRedirectPath`).
  final String? callbackPath;

  /// Sumber impor token lokal (hanya relevan bila [flow] ==
  /// [OAuthFlow.importToken]).
  final ImportSource? importSource;

  /// Provider yang hanya dipakai untuk memperoleh token (tidak untuk chat).
  /// Base URL / model tidak wajib. Contoh: Qoder (API-nya bukan
  /// OpenAI-compatible sehingga chat belum didukung).
  final bool isTokenOnly;

  OAuthConfig copyWith({
    String? authorizationUrl,
    String? tokenUrl,
    String? clientId,
    List<String>? scopes,
    String? revocationUrl,
    String? audience,
    int? redirectPort,
    Map<String, String>? extraAuthParams,
    Map<String, String>? extraTokenParams,
    bool? usePkce,
    bool? isExperimental,
    OAuthFlow? flow,
    DeviceFlowStyle? deviceFlowStyle,
    TokenExchangeStyle? tokenExchange,
    TokenBodyFormat? tokenBodyFormat,
    String? callbackPath,
    ImportSource? importSource,
    bool? isTokenOnly,
  }) {
    return OAuthConfig(
      authorizationUrl: authorizationUrl ?? this.authorizationUrl,
      tokenUrl: tokenUrl ?? this.tokenUrl,
      clientId: clientId ?? this.clientId,
      scopes: scopes ?? this.scopes,
      revocationUrl: revocationUrl ?? this.revocationUrl,
      audience: audience ?? this.audience,
      redirectPort: redirectPort ?? this.redirectPort,
      extraAuthParams: extraAuthParams ?? this.extraAuthParams,
      extraTokenParams: extraTokenParams ?? this.extraTokenParams,
      usePkce: usePkce ?? this.usePkce,
      isExperimental: isExperimental ?? this.isExperimental,
      flow: flow ?? this.flow,
      deviceFlowStyle: deviceFlowStyle ?? this.deviceFlowStyle,
      tokenExchange: tokenExchange ?? this.tokenExchange,
      tokenBodyFormat: tokenBodyFormat ?? this.tokenBodyFormat,
      callbackPath: callbackPath ?? this.callbackPath,
      importSource: importSource ?? this.importSource,
      isTokenOnly: isTokenOnly ?? this.isTokenOnly,
    );
  }

  Map<String, dynamic> toJson() => {
    'authorizationUrl': authorizationUrl,
    'tokenUrl': tokenUrl,
    'clientId': clientId,
    'scopes': scopes,
    if (revocationUrl != null) 'revocationUrl': revocationUrl,
    if (audience != null) 'audience': audience,
    if (redirectPort != null) 'redirectPort': redirectPort,
    if (extraAuthParams.isNotEmpty) 'extraAuthParams': extraAuthParams,
    if (extraTokenParams.isNotEmpty) 'extraTokenParams': extraTokenParams,
    'usePkce': usePkce,
    'isExperimental': isExperimental,
    'flow': flow.name,
    'deviceFlowStyle': deviceFlowStyle.name,
    'tokenExchange': tokenExchange.name,
    'tokenBodyFormat': tokenBodyFormat.name,
    if (callbackPath != null) 'callbackPath': callbackPath,
    if (importSource != null) 'importSource': importSource!.name,
    'isTokenOnly': isTokenOnly,
  };

  factory OAuthConfig.fromJson(Map<String, dynamic> json) => OAuthConfig(
    authorizationUrl: json['authorizationUrl'] as String,
    tokenUrl: json['tokenUrl'] as String,
    clientId: json['clientId'] as String,
    scopes:
        (json['scopes'] as List?)?.map((e) => e.toString()).toList() ??
        const [],
    revocationUrl: json['revocationUrl'] as String?,
    audience: json['audience'] as String?,
    redirectPort: json['redirectPort'] as int?,
    extraAuthParams:
        (json['extraAuthParams'] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        ) ??
        const {},
    extraTokenParams:
        (json['extraTokenParams'] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        ) ??
        const {},
    usePkce: json['usePkce'] as bool? ?? true,
    isExperimental: json['isExperimental'] as bool? ?? false,
    flow: _flowFromName(json['flow'] as String?),
    deviceFlowStyle: _deviceFlowStyleFromName(
      json['deviceFlowStyle'] as String?,
    ),
    tokenExchange: _tokenExchangeFromName(json['tokenExchange'] as String?),
    tokenBodyFormat: _tokenBodyFormatFromName(
      json['tokenBodyFormat'] as String?,
    ),
    callbackPath: json['callbackPath'] as String?,
    importSource: _importSourceFromName(json['importSource'] as String?),
    isTokenOnly: json['isTokenOnly'] as bool? ?? false,
  );

  static OAuthFlow _flowFromName(String? name) => OAuthFlow.values.firstWhere(
    (f) => f.name == name,
    orElse: () => OAuthFlow.authorizationCode,
  );

  static DeviceFlowStyle _deviceFlowStyleFromName(String? name) =>
      DeviceFlowStyle.values.firstWhere(
        (s) => s.name == name,
        orElse: () => DeviceFlowStyle.rfc8628,
      );

  static TokenExchangeStyle _tokenExchangeFromName(String? name) =>
      TokenExchangeStyle.values.firstWhere(
        (s) => s.name == name,
        orElse: () => TokenExchangeStyle.none,
      );

  static TokenBodyFormat _tokenBodyFormatFromName(String? name) =>
      TokenBodyFormat.values.firstWhere(
        (s) => s.name == name,
        orElse: () => TokenBodyFormat.form,
      );

  static ImportSource? _importSourceFromName(String? name) {
    if (name == null) return null;
    for (final source in ImportSource.values) {
      if (source.name == name) return source;
    }
    return null;
  }
}
