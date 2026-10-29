import 'oauth_session.dart';

/// Id katalog untuk provider yang dikonfigurasi manual (bukan template).
const String kCustomCatalogId = 'custom-api';

/// Id katalog provider yang memakai login akun (OAuth), bukan API key.
const String kClineOAuthCatalogId = 'cline';

/// Metadata Custom API Provider (FR-01).
///
/// Catatan keamanan: [apiKey] hanya hidup di Secure Storage dan instance
/// runtime; field ini tidak pernah diserialisasi ke Hive (NFR-01). Hal yang
/// sama berlaku untuk [oauthSession].
class ApiProvider {
  const ApiProvider({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.model,
    this.providerName = '',
    this.catalogId,
    this.authType = AuthType.apiKey,
    this.oauthProvider,
    this.apiKey,
    this.oauthSession,
    this.customModels = const [],
    this.removedModels = const [],
  });

  final String id;

  /// Label pilihan pengguna untuk entri ini, mis. "Groq Kerja".
  final String name;

  /// Nama provider yang dipakai, mis. "Groq" (dari template) atau nama bebas
  /// untuk provider custom.
  final String providerName;

  /// Id entri katalog template, atau [kCustomCatalogId] untuk provider yang
  /// dikonfigurasi sendiri. Null hanya pada data lama sebelum dinormalkan.
  final String? catalogId;

  final String baseUrl;
  final String model;

  /// Jenis kredensial. [AuthType.oauth] hanya untuk provider yang mendukung
  /// masuk dengan akun (saat ini Cline).
  final AuthType authType;

  /// Penanda provider OAuth, mis. `cline`. Disimpan di Hive supaya pembersih
  /// data lama bisa membedakan provider baru dari entri OAuth generasi pertama
  /// (yang tidak punya penanda ini). Null untuk provider API key.
  final String? oauthProvider;

  final String? apiKey;

  /// Sesi OAuth runtime; null untuk provider API key atau saat sesi belum ada.
  /// Tidak pernah ikut `toJson`.
  final OAuthSession? oauthSession;

  /// Model tambahan milik provider ini (di luar daftar template).
  final List<String> customModels;

  /// Model template yang disembunyikan khusus untuk provider ini. Disimpan
  /// sebagai daftar terpisah supaya penghapusan tidak mengubah provider lain
  /// maupun template bawaan.
  final List<String> removedModels;

  /// True bila provider memakai template katalog (bukan custom).
  bool get usesTemplate => catalogId != null && catalogId != kCustomCatalogId;

  /// True bila provider diautentikasi dengan sesi akun, bukan API key.
  bool get usesOAuth => authType == AuthType.oauth;

  /// Token yang dipakai untuk header `Authorization: Bearer`.
  ///
  /// Untuk provider OAuth, sesi menang atas [apiKey]; sesi null berarti
  /// pengguna belum masuk (atau sudah keluar) sehingga tidak ada bearer.
  String? get bearerToken {
    if (usesOAuth) return oauthSession?.accessToken;
    return apiKey;
  }

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
    String? providerName,
    String? baseUrl,
    String? model,
    String? apiKey,
    String? catalogId,
    AuthType? authType,
    String? oauthProvider,
    OAuthSession? oauthSession,
    bool clearOAuthSession = false,
    List<String>? customModels,
    List<String>? removedModels,
  }) {
    return ApiProvider(
      id: id,
      name: name ?? this.name,
      providerName: providerName ?? this.providerName,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      apiKey: apiKey ?? this.apiKey,
      catalogId: catalogId ?? this.catalogId,
      authType: authType ?? this.authType,
      oauthProvider: oauthProvider ?? this.oauthProvider,
      oauthSession: clearOAuthSession
          ? null
          : (oauthSession ?? this.oauthSession),
      customModels: customModels ?? this.customModels,
      removedModels: removedModels ?? this.removedModels,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'providerName': providerName,
    'catalogId': catalogId,
    'authType': authType.name,
    if (oauthProvider != null) 'oauthProvider': oauthProvider,
    'baseUrl': baseUrl,
    'model': model,
    'customModels': customModels,
    'removedModels': removedModels,
  };

  /// [providerName] dan [catalogId] opsional agar JSON provider lama (sebelum
  /// pemisahan nama label vs nama provider) tetap bisa dibaca.
  factory ApiProvider.fromJson(Map<String, dynamic> json) {
    // Provider OAuth generasi pertama (sebelum fitur dihapus) memakai bentuk
    // `oauthConfig`; entri seperti itu dibaca sebagai API key agar tidak
    // dianggap sesi baru yang belum punya token.
    final legacyOAuthShape = json.containsKey('oauthConfig');
    return ApiProvider(
      id: json['id'] as String,
      name: json['name'] as String,
      providerName: json['providerName'] as String? ?? json['name'] as String,
      catalogId: json['catalogId'] as String?,
      authType: legacyOAuthShape
          ? AuthType.apiKey
          : _authType(json['authType'] as String?),
      oauthProvider: legacyOAuthShape ? null : json['oauthProvider'] as String?,
      baseUrl: json['baseUrl'] as String,
      model: json['model'] as String,
      customModels: _stringList(json['customModels']),
      removedModels: _stringList(json['removedModels']),
    );
  }

  /// Membaca nama [AuthType] dari JSON; nilai tak dikenal jatuh ke API key.
  static AuthType _authType(String? name) {
    for (final value in AuthType.values) {
      if (value.name == name) return value;
    }
    return AuthType.apiKey;
  }

  /// Membaca daftar string dari JSON; provider lama belum punya field ini.
  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item,
    ];
  }
}
