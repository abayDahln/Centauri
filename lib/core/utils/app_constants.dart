class AppConstants {
  AppConstants._();

  static const String appName = 'Centauri';
  static const String appVersion = '0.1.0';

  /// Identitas aplikasi untuk header atribusi OpenRouter. Sebagian model di
  /// sana hanya terbuka untuk app yang dikenal lewat header ini.
  static const String appReferer = 'https://github.com/abayDahln/Centauri';

  // Secure storage: API key disimpan per-provider, tidak pernah di Hive.
  static const String apiKeyPrefix = 'centauri_provider_api_key_';

  // Hive boxes.
  static const String providersBoxName = 'centauri_providers';
  static const String metaBoxName = 'centauri_meta';
  static const String projectsBoxName = 'centauri_projects';
  static const String activeProviderIdKey = 'active_provider_id';
  static const String activeProjectIdKey = 'active_project_id';

  // Network defaults.
  static const Duration connectTimeout = Duration(seconds: 30);

  /// Batas tunggu antar-chunk saat generate. Dio memperlakukan ini sebagai
  /// timeout inaktivitas (jarak antar event data), bukan total durasi, saat
  /// memakai [ResponseType.stream]. Nilai longgar karena model lokal bisa
  /// lambat pada token pertama.
  static const Duration receiveTimeout = Duration(minutes: 5);

  /// Batas aman total untuk satu kali generate (streaming).
  static const Duration generationTimeout = Duration(minutes: 10);

  /// Timeout khusus validasi kredensial (GET /models) agar feedback cepat.
  static const Duration testConnectionTimeout = Duration(seconds: 20);

  // Endpoint OpenAI-compatible untuk validasi kredensial.
  static const String testConnectionPath = '/models';
  static const String chatCompletionsPath = '/chat/completions';

  // Parameter generasi UI. Temperature lebih tinggi dari chat agar model
  // berani berkreasi desain (bukan output dasar yang seragam).
  //
  // `max_tokens` sengaja TIDAK dikirim: nilainya ikut dihitung terhadap context
  // window (OpenRouter menolak request bila input + max_tokens melewati batas
  // model), sementara batas output tiap provider berbeda-beda. Tanpa parameter
  // ini provider memakai batas maksimum modelnya sendiri, jadi output panjang
  // tetap utuh dan tidak ada request yang ditolak karena anggaran token.
  static const double designTemperature = 0.7;
}
