import '../entities/oauth_config.dart';

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
      extraAuthParams: extraAuthParams,
      extraTokenParams: extraTokenParams,
      isExperimental: isExperimental,
    );
  }
}
