/// Kumpulan token OAuth (access + refresh) beserta masa berlakunya.
///
/// Catatan keamanan: objek ini HANYA boleh dipersist ke secure storage
/// (DPAPI/Keystore), tidak pernah ke Hive (NFR-01).
class OAuthTokenSet {
  const OAuthTokenSet({
    required this.accessToken,
    required this.expiresAt,
    this.refreshToken,
    this.tokenType = 'Bearer',
    this.scope,
  });

  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;
  final String tokenType;
  final String? scope;

  /// Buffer 5 menit agar refresh terjadi sebelum token benar-benar kedaluwarsa.
  static const Duration refreshSkew = Duration(minutes: 5);

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get needsRefresh =>
      DateTime.now().isAfter(expiresAt.subtract(refreshSkew));

  bool get canRefresh => refreshToken != null && refreshToken!.isNotEmpty;

  OAuthTokenSet copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? tokenType,
    String? scope,
  }) {
    return OAuthTokenSet(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      tokenType: tokenType ?? this.tokenType,
      scope: scope ?? this.scope,
    );
  }

  /// Hanya untuk secure storage (memuat token rahasia).
  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    if (refreshToken != null) 'refreshToken': refreshToken,
    'expiresAt': expiresAt.toIso8601String(),
    'tokenType': tokenType,
    if (scope != null) 'scope': scope,
  };

  factory OAuthTokenSet.fromJson(Map<String, dynamic> json) => OAuthTokenSet(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String?,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
    tokenType: json['tokenType'] as String? ?? 'Bearer',
    scope: json['scope'] as String?,
  );

  /// Membangun token set dari respons token endpoint (RFC 6749 §5.1).
  ///
  /// Bila [previous] diberikan dan respons tidak memuat `refresh_token`
  /// (umum pada refresh grant), refresh token lama dipertahankan.
  factory OAuthTokenSet.fromTokenResponse(
    Map<String, dynamic> response, {
    OAuthTokenSet? previous,
  }) {
    final accessToken = response['access_token'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw const FormatException('Respons token tidak memuat access_token.');
    }
    final expiresIn = response['expires_in'];
    final seconds = expiresIn is int
        ? expiresIn
        : int.tryParse(expiresIn?.toString() ?? '') ?? 3600;
    final refresh = response['refresh_token'] as String?;
    return OAuthTokenSet(
      accessToken: accessToken,
      refreshToken: (refresh == null || refresh.isEmpty)
          ? previous?.refreshToken
          : refresh,
      expiresAt: DateTime.now().add(Duration(seconds: seconds)),
      tokenType: response['token_type'] as String? ?? 'Bearer',
      scope: response['scope'] as String? ?? previous?.scope,
    );
  }
}
