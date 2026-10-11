/// Metadata Custom API Provider (FR-01).
/// Catatan keamanan: [apiKey] hanya hidup di Secure Storage dan instance
/// runtime; field ini tidak pernah diserialisasi ke Hive (NFR-01).
class ApiProvider {
  const ApiProvider({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.model,
    this.apiKey,
  });

  final String id;
  final String name;
  final String baseUrl;
  final String model;
  final String? apiKey;

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
  }) {
    return ApiProvider(
      id: id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      apiKey: apiKey ?? this.apiKey,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'baseUrl': baseUrl,
    'model': model,
  };

  factory ApiProvider.fromJson(Map<String, dynamic> json) => ApiProvider(
    id: json['id'] as String,
    name: json['name'] as String,
    baseUrl: json['baseUrl'] as String,
    model: json['model'] as String,
  );
}
