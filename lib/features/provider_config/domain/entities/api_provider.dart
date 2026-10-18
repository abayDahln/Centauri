/// Id katalog untuk provider yang dikonfigurasi manual (bukan template).
const String kCustomCatalogId = 'custom-api';

/// Metadata Custom API Provider (FR-01).
///
/// Catatan keamanan: [apiKey] hanya hidup di Secure Storage dan instance
/// runtime; field ini tidak pernah diserialisasi ke Hive (NFR-01).
class ApiProvider {
  const ApiProvider({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.model,
    this.providerName = '',
    this.catalogId,
    this.apiKey,
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
  final String? apiKey;

  /// Model tambahan milik provider ini (di luar daftar template).
  final List<String> customModels;

  /// Model template yang disembunyikan khusus untuk provider ini. Disimpan
  /// sebagai daftar terpisah supaya penghapusan tidak mengubah provider lain
  /// maupun template bawaan.
  final List<String> removedModels;

  /// True bila provider memakai template katalog (bukan custom).
  bool get usesTemplate => catalogId != null && catalogId != kCustomCatalogId;

  /// Token yang dipakai untuk header `Authorization: Bearer`.
  String? get bearerToken => apiKey;

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
      customModels: customModels ?? this.customModels,
      removedModels: removedModels ?? this.removedModels,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'providerName': providerName,
    'catalogId': catalogId,
    'baseUrl': baseUrl,
    'model': model,
    'customModels': customModels,
    'removedModels': removedModels,
  };

  /// [providerName] dan [catalogId] opsional agar JSON provider lama (sebelum
  /// pemisahan nama label vs nama provider) tetap bisa dibaca.
  factory ApiProvider.fromJson(Map<String, dynamic> json) => ApiProvider(
    id: json['id'] as String,
    name: json['name'] as String,
    providerName: json['providerName'] as String? ?? json['name'] as String,
    catalogId: json['catalogId'] as String?,
    baseUrl: json['baseUrl'] as String,
    model: json['model'] as String,
    customModels: _stringList(json['customModels']),
    removedModels: _stringList(json['removedModels']),
  );

  /// Membaca daftar string dari JSON; provider lama belum punya field ini.
  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item,
    ];
  }
}
