/// Jenis kredensial yang dipakai sebuah provider.
///
/// [apiKey] adalah jalur lama (kunci disimpan lewat `SecureStorageService`).
/// [oauth] dipakai provider yang mendukung masuk dengan akun; tokennya tetap
/// disimpan di secure storage, hanya bentuk sesinya yang berbeda.
enum AuthType { apiKey, oauth }

/// Sesi OAuth satu provider (runtime + secure storage).
///
/// Tidak pernah ikut diserialisasi ke Hive: metadata provider hanya menyimpan
/// [AuthType], sedangkan token hidup di `flutter_secure_storage` (NFR-01).
class OAuthSession {
  const OAuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    this.userId,
    this.email,
    this.displayName,
  });

  final String accessToken;
  final String refreshToken;

  /// Waktu kedaluwarsa access token (UTC).
  final DateTime expiresAt;

  /// Identitas akun, diisi setelah `GET /users/me` berhasil.
  final String? userId;
  final String? email;
  final String? displayName;

  /// Perpanjang sesi sedikit lebih awal supaya generate tidak gagal di tengah
  /// jalan karena token kedaluwarsa saat request sedang berlangsung.
  static const Duration refreshMargin = Duration(minutes: 5);

  bool get isExpiringSoon =>
      DateTime.now().toUtc().isAfter(expiresAt.toUtc().subtract(refreshMargin));

  OAuthSession copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? userId,
    String? email,
    String? displayName,
  }) {
    return OAuthSession(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    if (userId != null) 'userId': userId,
    if (email != null) 'email': email,
    if (displayName != null) 'displayName': displayName,
  };

  /// Sesi rusak (mis. `expiresAt` hilang) tetap dibaca agar token tidak hilang;
  /// waktu kedaluwarsa jatuh ke epoch sehingga sesi langsung di-refresh.
  factory OAuthSession.fromJson(Map<String, dynamic> json) {
    final rawExpiry = json['expiresAt'];
    return OAuthSession(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      expiresAt:
          (rawExpiry is String ? DateTime.tryParse(rawExpiry) : null)
              ?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      userId: json['userId'] as String?,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
    );
  }
}
