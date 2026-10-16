import 'oauth_flow.dart';

/// Hasil langkah awal device flow: informasi yang ditampilkan ke pengguna
/// (URL login + kode) beserta kredensial untuk polling.
///
/// Catatan keamanan: [codeVerifier] bersifat rahasia dan objek ini hanya
/// hidup di memori selama satu alur — TIDAK pernah dipersist (NFR-01).
class DeviceAuthorization {
  const DeviceAuthorization({
    required this.flow,
    required this.style,
    required this.verificationUri,
    required this.userCode,
    required this.deviceCode,
    required this.interval,
    required this.expiresAt,
    this.verificationUriComplete,
    this.codeVerifier,
    this.extra = const {},
  });

  final OAuthFlow flow;
  final DeviceFlowStyle style;

  /// URL yang dibuka pengguna untuk berotorisasi.
  final Uri verificationUri;

  /// URL lengkap yang sudah memuat kode (RFC 8628), bila provider mendukung.
  final Uri? verificationUriComplete;

  /// Kode singkat yang ditampilkan ke pengguna ("Your Code").
  final String userCode;

  /// Kredensial polling: `device_code` (RFC 8628) atau `nonce` (Qoder).
  final String deviceCode;

  /// PKCE `code_verifier` (khusus Qoder). Null untuk RFC 8628.
  final String? codeVerifier;

  /// Data khusus dialek yang perlu dibawa dari langkah awal ke polling
  /// (mis. `clientId`/`clientSecret` Kiro, poll-token GLM). Hanya di memori.
  final Map<String, String> extra;

  /// Jeda antar-poll.
  final Duration interval;

  /// Batas waktu; setelah lewat, flow dianggap gagal.
  final DateTime expiresAt;

  /// URL yang sebaiknya dibuka browser: versi lengkap bila ada.
  Uri get openUri => verificationUriComplete ?? verificationUri;
}
