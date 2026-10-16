import '../entities/oauth_config.dart';
import '../entities/oauth_flow.dart';

/// Preset provider OAuth. Menyediakan endpoint otorisasi/token, scope, dan
/// default Base URL + model agar pengguna tidak perlu mengetik manual.
///
/// [clientId] boleh kosong. Bila kosong, pengguna wajib mengisi Client ID
/// miliknya sendiri (mis. dari project Google Cloud mereka) — pola BYOK untuk
/// OAuth, konsisten dengan arsitektur local-first Centauri.
class OAuthProviderPreset {
  const OAuthProviderPreset({
    required this.id,
    required this.label,
    required this.authorizationUrl,
    required this.tokenUrl,
    required this.baseUrl,
    this.description = '',
    this.scopes = const [],
    this.defaultModel,
    this.revocationUrl,
    this.audience,
    this.clientId = '',
    this.extraAuthParams = const {},
    this.extraTokenParams = const {},
    this.isExperimental = false,
    this.isCustom = false,
    this.flow = OAuthFlow.authorizationCode,
    this.deviceFlowStyle = DeviceFlowStyle.rfc8628,
    this.tokenExchange = TokenExchangeStyle.none,
    this.tokenBodyFormat = TokenBodyFormat.form,
    this.redirectPort,
    this.callbackPath,
    this.importSource,
    this.usePkce = true,
    this.isTokenOnly = false,
    this.modelsUrl = '',
  });

  final String id;
  final String label;
  final String description;

  /// Endpoint API (OpenAI-compatible) yang dipakai setelah login berhasil.
  final String baseUrl;
  final String? defaultModel;

  final String authorizationUrl;
  final String tokenUrl;
  final List<String> scopes;
  final String? revocationUrl;
  final String? audience;

  /// Client id bawaan preset. Kosong = pengguna harus mengisi sendiri.
  final String clientId;

  final Map<String, String> extraAuthParams;
  final Map<String, String> extraTokenParams;

  /// Flow tidak resmi (reverse-engineered) — tampilkan peringatan ToS.
  final bool isExperimental;

  /// Preset "Custom": pengguna mengisi semua endpoint sendiri. Ini jalur untuk
  /// provider yang tidak disertakan bawaan, termasuk flow subscription.
  final bool isCustom;

  /// Alur OAuth yang dipakai preset ini.
  final OAuthFlow flow;
  /// Dialek device flow (hanya relevan bila [flow] == [OAuthFlow.deviceCode]).
  final DeviceFlowStyle deviceFlowStyle;

  /// Langkah tukar-token tambahan setelah token utama diperoleh.
  final TokenExchangeStyle tokenExchange;

  /// Format body saat menukar token (form-urlencoded atau JSON).
  final TokenBodyFormat tokenBodyFormat;

  /// Port loopback tetap untuk redirect (mis. Codex memakai 1455).
  final int? redirectPort;

  /// Path callback loopback khusus (mis. `/auth/callback`).
  final String? callbackPath;

  /// Sumber impor token lokal (mis. Cursor). Lihat [OAuthFlow.importToken].
  final ImportSource? importSource;

  /// Aktifkan PKCE (S256). Default true.
  final bool usePkce;

  /// Provider yang hanya untuk memperoleh token (chat belum didukung). Base URL
  /// / model tidak wajib diisi.
  final bool isTokenOnly;

  /// Endpoint daftar model khusus preset ini (URL penuh atau root).
  ///
  /// Dipakai bila daftar live `GET /models` tidak bisa diambil dari Base URL
  /// chat — mis. preset token-only yang API-nya punya endpoint model
  /// terpisah (contoh: GitHub Copilot memakai
  /// `https://api.githubcopilot.com/v1/models` dengan token hasil exchange).
  /// Kosong = ikut Base URL efektif seperti biasa.
  final String modelsUrl;

  bool get requiresUserClientId => clientId.isEmpty;

  OAuthConfig toOAuthConfig({String? clientIdOverride}) {
    final effectiveClientId = (clientIdOverride ?? clientId).trim();
    return OAuthConfig(
      authorizationUrl: authorizationUrl,
      tokenUrl: tokenUrl,
      clientId: effectiveClientId,
      scopes: scopes,
      revocationUrl: revocationUrl,
      audience: audience,
      redirectPort: redirectPort,
      extraAuthParams: extraAuthParams,
      extraTokenParams: extraTokenParams,
      usePkce: usePkce,
      isExperimental: isExperimental,
      flow: flow,
      deviceFlowStyle: deviceFlowStyle,
      tokenExchange: tokenExchange,
      tokenBodyFormat: tokenBodyFormat,
      callbackPath: callbackPath,
      importSource: importSource,
      isTokenOnly: isTokenOnly,
    );
  }
}
