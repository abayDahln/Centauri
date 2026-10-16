import '../../domain/entities/oauth_flow.dart';
import '../../domain/oauth/oauth_provider_preset.dart';

/// Registry preset OAuth bawaan.
///
/// Sebagian besar preset memakai jalur OAuth **resmi** (endpoint
/// terdokumentasi); preset "Custom" disediakan untuk provider lain. Preset
/// yang endpoint-nya reverse-engineered (mis. Qoder, Claude Code, Codex)
/// ditandai eksperimental dan di-opt-in secara eksplisit, sehingga tanggung
/// jawab kepatuhan ToS tetap di tangan pengguna.
///
/// Catatan: sebagian besar provider CLI/subscription di sini **token-only**
/// (chat belum didukung lewat jalur OpenAI-compatible Centauri), jadi
/// [OAuthProviderPreset.baseUrl] sengaja dikosongkan.
class OAuthProviderPresets {
  OAuthProviderPresets._();

  // ------------------------------------------------------------ resmi ------

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

  // ------------------------------------------------------- reverse-eng -----

  /// Claude Code — Authorization Code + PKCE (claude.ai), body JSON.
  static const OAuthProviderPreset claudeCode = OAuthProviderPreset(
    id: 'claude-code',
    label: 'Claude Code',
    description:
        'Hubungkan langganan Claude Code (Pro/Max). Token disimpan, tetapi '
        'chat belum didukung lewat jalur OpenAI-compatible Centauri.',
    baseUrl: '',
    authorizationUrl: 'https://claude.ai/oauth/authorize',
    tokenUrl: 'https://api.anthropic.com/v1/oauth/token',
    clientId: '9d1c250a-e61b-44d9-88ed-5944d1962f5e',
    scopes: ['org:create_api_key', 'user:profile', 'user:inference'],
    extraAuthParams: {'code': 'true'},
    tokenBodyFormat: TokenBodyFormat.json,
    isTokenOnly: true,
    isExperimental: true,
  );

  /// OpenAI Codex — Authorization Code + PKCE (auth.openai.com), port tetap.
  static const OAuthProviderPreset openaiCodex = OAuthProviderPreset(
    id: 'openai-codex',
    label: 'OpenAI Codex',
    description:
        'Hubungkan langganan ChatGPT/Codex. Memakai port redirect tetap 1455 '
        'dan path /auth/callback. Chat belum didukung.',
    baseUrl: '',
    authorizationUrl: 'https://auth.openai.com/oauth/authorize',
    tokenUrl: 'https://auth.openai.com/oauth/token',
    clientId: 'app_EMoamEEZ73f0CkXaXp7hrann',
    scopes: ['openid', 'profile', 'email', 'offline_access'],
    redirectPort: 1455,
    callbackPath: '/auth/callback',
    extraAuthParams: {
      'id_token_add_organizations': 'true',
      'codex_cli_simplified_flow': 'true',
      'originator': 'codex_cli_rs',
    },
    isTokenOnly: true,
    isExperimental: true,
  );

  /// Antigravity — Google OAuth (Authorization Code + PKCE).
  ///
  /// Sengaja TIDAK menyimpan Client ID / Client Secret bawaan di repo agar
  /// tidak memicu GitHub Push Protection. Pengguna mengisi Client ID OAuth
  /// miliknya sendiri (tipe Desktop) di UI — sama seperti preset Gemini.
  static const OAuthProviderPreset antigravity = OAuthProviderPreset(
    id: 'antigravity',
    label: 'Antigravity',
    description:
        'Hubungkan akun Google untuk Antigravity (cloud-platform scope). '
        'Isi Client ID OAuth dari project Google Cloud Anda (tipe Desktop). '
        'Chat belum didukung lewat jalur OpenAI-compatible Centauri.',
    baseUrl: '',
    authorizationUrl: 'https://accounts.google.com/o/oauth2/v2/auth',
    tokenUrl: 'https://oauth2.googleapis.com/token',
    clientId: '',
    scopes: [
      'https://www.googleapis.com/auth/cloud-platform',
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/userinfo.profile',
      'https://www.googleapis.com/auth/cclog',
      'https://www.googleapis.com/auth/experimentsandconfigs',
    ],
    extraAuthParams: {'access_type': 'offline', 'prompt': 'consent'},
    isTokenOnly: true,
    isExperimental: true,
  );

  /// GitHub Copilot — device flow GitHub + token exchange ke token Copilot.
  static const OAuthProviderPreset githubCopilot = OAuthProviderPreset(
    id: 'github-copilot',
    label: 'GitHub Copilot',
    description:
        'Login via GitHub device flow, lalu token ditukar menjadi token '
        'Copilot. Chat belum didukung lewat jalur OpenAI-compatible Centauri.',
    baseUrl: '',
    authorizationUrl: 'https://github.com/login/device/code',
    tokenUrl: 'https://github.com/login/oauth/access_token',
    clientId: 'Iv1.b507a08c87ecfe98',
    scopes: ['read:user'],
    flow: OAuthFlow.deviceCode,
    deviceFlowStyle: DeviceFlowStyle.rfc8628,
    tokenExchange: TokenExchangeStyle.githubCopilot,
    isTokenOnly: true,
    isExperimental: true,
  );

  /// Cursor IDE — impor token dari penyimpanan lokal Cursor (`state.vscdb`).
  static const OAuthProviderPreset cursor = OAuthProviderPreset(
    id: 'cursor',
    label: 'Cursor IDE',
    description:
        'Impor token dari instalasi Cursor lokal (cursorAuth/accessToken). '
        'Chat belum didukung lewat jalur OpenAI-compatible Centauri.',
    baseUrl: '',
    authorizationUrl: '',
    tokenUrl: '',
    flow: OAuthFlow.importToken,
    importSource: ImportSource.cursor,
    isTokenOnly: true,
    isExperimental: true,
  );

  /// Kilo Code — device flow custom (initiate + poll `/{code}`).
  static const OAuthProviderPreset kiloCode = OAuthProviderPreset(
    id: 'kilo-code',
    label: 'Kilo Code',
    description:
        'Hubungkan akun Kilo Code via device flow. Token disimpan, tetapi '
        'chat belum didukung lewat jalur OpenAI-compatible Centauri.',
    baseUrl: '',
    authorizationUrl: 'https://api.kilo.ai/api/device-auth/codes',
    tokenUrl: 'https://api.kilo.ai/api/device-auth/codes',
    flow: OAuthFlow.deviceCode,
    deviceFlowStyle: DeviceFlowStyle.kilocode,
    isTokenOnly: true,
    isExperimental: true,
  );

  /// Cline — Authorization Code (callback lokal) + exchange kode base64.
  static const OAuthProviderPreset cline = OAuthProviderPreset(
    id: 'cline',
    label: 'Cline',
    description:
        'Hubungkan akun Cline via callback lokal. Token disimpan, tetapi chat '
        'belum didukung lewat jalur OpenAI-compatible Centauri.',
    baseUrl: '',
    authorizationUrl: 'https://api.cline.bot/api/v1/auth/authorize',
    tokenUrl: 'https://api.cline.bot/api/v1/auth/token',
    extraAuthParams: {'client_type': 'extension'},
    tokenExchange: TokenExchangeStyle.cline,
    isTokenOnly: true,
    isExperimental: true,
  );

  /// CodeBuddy (International) — device flow custom (state + poll).
  static const OAuthProviderPreset codebuddy = OAuthProviderPreset(
    id: 'codebuddy',
    label: 'CodeBuddy',
    description:
        'Hubungkan akun CodeBuddy via device flow. Token disimpan, tetapi chat '
        'belum didukung lewat jalur OpenAI-compatible Centauri.',
    baseUrl: '',
    authorizationUrl: 'https://www.codebuddy.ai/v2/plugin/auth/state',
    tokenUrl: 'https://www.codebuddy.ai/v2/plugin/auth/token',
    flow: OAuthFlow.deviceCode,
    deviceFlowStyle: DeviceFlowStyle.codebuddy,
    isTokenOnly: true,
    isExperimental: true,
  );

  /// Zai GLM (ZCode CLI) — device flow custom (cli init + poll).
  static const OAuthProviderPreset zaiGlm = OAuthProviderPreset(
    id: 'zai-glm',
    label: 'Zai GLM',
    description:
        'Hubungkan langganan Z.ai (GLM Coding) via device flow. Token '
        'disimpan, tetapi chat belum didukung lewat jalur OpenAI-compatible.',
    baseUrl: '',
    authorizationUrl: 'https://zcode.z.ai/api/v1/oauth/cli/init',
    tokenUrl: 'https://zcode.z.ai/api/v1/oauth/cli/poll',
    flow: OAuthFlow.deviceCode,
    deviceFlowStyle: DeviceFlowStyle.glm,
    isTokenOnly: true,
    isExperimental: true,
  );

  /// Grok CLI — device flow standar (auth.x.ai).
  static const OAuthProviderPreset grokCli = OAuthProviderPreset(
    id: 'grok-cli',
    label: 'Grok CLI',
    description:
        'Hubungkan akun Grok (x.ai) via device flow. Token disimpan, tetapi '
        'chat belum didukung lewat jalur OpenAI-compatible Centauri.',
    baseUrl: '',
    authorizationUrl: 'https://auth.x.ai/oauth2/device/code',
    tokenUrl: 'https://auth.x.ai/oauth2/token',
    clientId: 'b1a00492-073a-47ea-816f-4c329264a828',
    scopes: [
      'openid',
      'profile',
      'email',
      'offline_access',
      'grok-cli:access',
      'api:access',
      'conversations:read',
      'conversations:write',
    ],
    flow: OAuthFlow.deviceCode,
    deviceFlowStyle: DeviceFlowStyle.rfc8628,
    isTokenOnly: true,
    isExperimental: true,
  );

  /// Kiro AI — device flow AWS SSO OIDC (register client + device + poll).
  static const OAuthProviderPreset kiro = OAuthProviderPreset(
    id: 'kiro',
    label: 'Kiro AI',
    description:
        'Hubungkan akun Kiro (AWS Builder ID) via device flow. Token disimpan, '
        'tetapi chat belum didukung lewat jalur OpenAI-compatible Centauri.',
    baseUrl: '',
    authorizationUrl: 'https://oidc.us-east-1.amazonaws.com/device_authorization',
    tokenUrl: 'https://oidc.us-east-1.amazonaws.com/token',
    scopes: [
      'codewhisperer:completions',
      'codewhisperer:analysis',
      'codewhisperer:conversations',
    ],
    extraAuthParams: {
      'registerClientUrl': 'https://oidc.us-east-1.amazonaws.com/client/register',
      'startUrl': 'https://view.awsapps.com/start',
      'clientName': 'kiro-oauth-client',
      'issuerUrl': 'https://identitycenter.amazonaws.com/ssoins-722374e8c3c8e6c6',
    },
    flow: OAuthFlow.deviceCode,
    deviceFlowStyle: DeviceFlowStyle.kiro,
    isTokenOnly: true,
    isExperimental: true,
  );
  /// Qoder — device flow custom (reverse-engineered, ala 9router).
  ///
  /// Token-only: API Qoder bukan OpenAI-compatible, jadi chat belum didukung;
  /// preset ini hanya untuk memperoleh token.
  static const OAuthProviderPreset qoder = OAuthProviderPreset(
    id: 'qoder',
    label: 'Qoder',
    description:
        'Hubungkan akun Qoder via device flow. Token disimpan, tetapi chat '
        'belum didukung (API Qoder bukan OpenAI-compatible).',
    baseUrl: '',
    authorizationUrl: 'https://qoder.com/device/selectAccounts',
    tokenUrl: 'https://openapi.qoder.sh/api/v1/deviceToken/poll',
    flow: OAuthFlow.deviceCode,
    deviceFlowStyle: DeviceFlowStyle.qoder,
    isTokenOnly: true,
    isExperimental: true,
  );

  static const List<OAuthProviderPreset> all = [
    googleGemini,
    claudeCode,
    antigravity,
    qoder,
    openaiCodex,
    githubCopilot,
    cursor,
    kiloCode,
    cline,
    codebuddy,
    zaiGlm,
    grokCli,
    kiro,
    custom,
  ];

  static OAuthProviderPreset? byId(String id) {
    for (final preset in all) {
      if (preset.id == id) return preset;
    }
    return null;
  }
}
