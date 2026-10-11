class AppConstants {
  AppConstants._();

  static const String appName = 'Centauri';
  static const String appVersion = '0.1.0';

  // Secure storage: API key disimpan per-provider, tidak pernah di Hive.
  static const String apiKeyPrefix = 'centauri_provider_api_key_';

  // Hive boxes.
  static const String providersBoxName = 'centauri_providers';
  static const String metaBoxName = 'centauri_meta';
  static const String activeProviderIdKey = 'active_provider_id';

  // Network defaults.
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // Endpoint OpenAI-compatible untuk validasi kredensial.
  static const String testConnectionPath = '/models';
  static const String chatCompletionsPath = '/chat/completions';

  // Preset endpoint umum untuk helper di UI.
  static const Map<String, String> knownProviderPresets = {
    'OpenAI': 'https://api.openai.com/v1',
    'Groq': 'https://api.groq.com/openai/v1',
    'Ollama (local)': 'http://localhost:11434/v1',
  };
}
