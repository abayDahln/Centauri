import '../entities/api_provider.dart';
import '../entities/device_authorization.dart';
import '../entities/oauth_token_set.dart';

/// Kegagalan alur OAuth dengan pesan yang aman ditampilkan ke pengguna.
/// Tidak pernah memuat token/secret (NFR-01).
class OAuthException implements Exception {
  OAuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Mesin OAuth 2.0 (Authorization Code + PKCE dan Device Authorization Grant).
abstract class OAuthService {
  /// Jalankan alur penuh: buka browser, tangkap callback, tukar code → token.
  Future<OAuthTokenSet> authorize(ApiProvider provider);

  /// Mulai device flow dan kembalikan info yang harus ditampilkan UI
  /// (URL login + kode). TIDAK membuka browser dan tidak melakukan polling.
  Future<DeviceAuthorization> startDeviceFlow(ApiProvider provider);

  /// Poll token device sampai sukses / ditolak / kedaluwarsa / dibatalkan.
  /// [cancel] yang complete akan menghentikan polling.
  Future<OAuthTokenSet> pollDeviceFlow(
    ApiProvider provider,
    DeviceAuthorization authorization, {
    required Future<void> cancel,
  });

  /// Perbarui access token memakai refresh token.
  Future<OAuthTokenSet> refresh(ApiProvider provider, OAuthTokenSet current);

  /// Cabut token (best-effort). No-op bila provider tidak punya revocation URL.
  Future<void> revoke(ApiProvider provider, OAuthTokenSet tokens);
}
