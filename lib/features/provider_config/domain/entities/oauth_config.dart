/// Konfigurasi OAuth 2.0 (Authorization Code + PKCE) untuk sebuah provider.
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
  });

  /// Endpoint otorisasi (tempat browser diarahkan).
  final String authorizationUrl;

  /// Endpoint tukar token (code → access/refresh token).
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
  );
}
