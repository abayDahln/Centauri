import '../entities/api_provider.dart';
import '../entities/oauth_token_set.dart';

/// Kegagalan alur OAuth dengan pesan yang aman ditampilkan ke pengguna.
/// Tidak pernah memuat token/secret (NFR-01).
class OAuthException implements Exception {
  OAuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Mesin OAuth 2.0 Authorization Code + PKCE.
abstract class OAuthService {
  /// Jalankan alur penuh: buka browser, tangkap callback, tukar code → token.
  Future<OAuthTokenSet> authorize(ApiProvider provider);

  /// Perbarui access token memakai refresh token.
  Future<OAuthTokenSet> refresh(ApiProvider provider, OAuthTokenSet current);

  /// Cabut token (best-effort). No-op bila provider tidak punya revocation URL.
  Future<void> revoke(ApiProvider provider, OAuthTokenSet tokens);
}
