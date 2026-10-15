import 'oauth_config.dart';
import 'oauth_token_set.dart';
import 'provider_auth_type.dart';

/// Metadata Custom API Provider (FR-01).
///
/// Catatan keamanan: [apiKey] dan [oauthToken] hanya hidup di Secure Storage
/// dan instance runtime; kedua field ini tidak pernah diserialisasi ke Hive
/// (NFR-01). [oauthConfig] aman diserialisasi karena hanya memuat data publik
/// klien PKCE (client id, endpoint, scope).
class ApiProvider {
  const ApiProvider({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.model,
    this.apiKey,
    this.authType = AuthType.apiKey,
    this.oauthConfig,
    this.oauthToken,
  });

  final String id;
  final String name;
  final String baseUrl;
  final String model;
  final String? apiKey;

  /// Metode autentikasi: API Key (BYOK) atau OAuth.
  final AuthType authType;

  /// Konfigurasi OAuth; wajib bila [authType] == [AuthType.oauth].
  final OAuthConfig? oauthConfig;

  /// Token OAuth runtime (tidak pernah dipersist ke Hive). Null berarti
  /// belum terhubung / token tidak tersedia.
  final OAuthTokenSet? oauthToken;

  /// Token yang dipakai untuk header `Authorization: Bearer`.
  /// OAuth menang bila ada; jika tidak, jatuh ke API Key.
  String? get bearerToken => oauthToken?.accessToken ?? apiKey;

  bool get usesOAuth => authType == AuthType.oauth;

  /// Base URL tanpa trailing slash agar aman digabung dengan path.
  String get normalizedBaseUrl {
    final trimmed = baseUrl.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  ApiProvider copyWith({
    String? name,
    String? baseUrl,
    String? model,
    String? apiKey,
    AuthType? authType,
    OAuthConfig? oauthConfig,
    OAuthTokenSet? oauthToken,
    bool clearOauthToken = false,
  }) {
    return ApiProvider(
      id: id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      apiKey: apiKey ?? this.apiKey,
      authType: authType ?? this.authType,
      oauthConfig: oauthConfig ?? this.oauthConfig,
      oauthToken: clearOauthToken ? null : (oauthToken ?? this.oauthToken),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'baseUrl': baseUrl,
    'model': model,
    'authType': authType.name,
    if (oauthConfig != null) 'oauthConfig': oauthConfig!.toJson(),
  };

  factory ApiProvider.fromJson(Map<String, dynamic> json) => ApiProvider(
    id: json['id'] as String,
    name: json['name'] as String,
    baseUrl: json['baseUrl'] as String,
    model: json['model'] as String,
    // Backward-compatible: provider lama di Hive tidak punya 'authType'.
    authType: _authTypeFromName(json['authType'] as String?),
    oauthConfig: json['oauthConfig'] == null
        ? null
        : OAuthConfig.fromJson(
            (json['oauthConfig'] as Map).cast<String, dynamic>(),
          ),
  );

  static AuthType _authTypeFromName(String? name) {
    return AuthType.values.firstWhere(
      (t) => t.name == name,
      orElse: () => AuthType.apiKey,
    );
  }
}
