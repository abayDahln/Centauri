import '../../domain/oauth/oauth_provider_preset.dart';

/// Registry preset OAuth bawaan.
///
/// Sengaja hanya memuat provider dengan jalur OAuth **resmi** (endpoint
/// terdokumentasi) dan satu preset "Custom" untuk provider lain — termasuk
/// flow subscription yang endpoint-nya tidak resmi. Endpoint reverse-engineered
/// (mis. Claude/Copilot) TIDAK di-hardcode di sini; pengguna yang ingin
/// memakainya mengisi sendiri lewat preset Custom, sehingga tanggung jawab
/// kepatuhan ToS tetap di tangan pengguna.
class OAuthProviderPresets {
  OAuthProviderPresets._();

  static const OAuthProviderPreset googleGemini = OAuthProviderPreset(
    id: 'google-gemini',
    label: 'Google Gemini',
    description:
        'Login dengan akun Google. Perlu Client ID OAuth dari project '
        'Google Cloud Anda (tipe Desktop).',
    baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
    defaultModel: 'gemini-2.0-flash',
    authorizationUrl: 'https://accounts.google.com/o/oauth2/v2/auth',
    tokenUrl: 'https://oauth2.googleapis.com/token',
    revocationUrl: 'https://oauth2.googleapis.com/revoke',
    scopes: ['https://www.googleapis.com/auth/generative-language.retriever'],
    // Wajib agar Google mengirim refresh_token.
    extraAuthParams: {
      'access_type': 'offline',
      'prompt': 'consent',
      'include_granted_scopes': 'true',
    },
  );

  static const OAuthProviderPreset custom = OAuthProviderPreset(
    id: 'custom-oauth',
    label: 'Custom OAuth',
    description:
        'Konfigurasikan endpoint OAuth, Client ID, Base URL, dan model sendiri. '
        'Jalur ini dapat dipakai untuk provider apa pun — termasuk flow '
        'subscription. Pastikan Anda mematuhi ketentuan layanan provider.',
    baseUrl: '',
    authorizationUrl: '',
    tokenUrl: '',
    isExperimental: true,
    isCustom: true,
  );

  static const List<OAuthProviderPreset> all = [googleGemini, custom];

  static OAuthProviderPreset? byId(String id) {
    for (final preset in all) {
      if (preset.id == id) return preset;
    }
    return null;
  }
}
