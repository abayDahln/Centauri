/// Metode autentikasi provider.
///
/// [apiKey] adalah default BYOK (key ditempel manual). [oauth] memakai
/// OAuth 2.0 Authorization Code + PKCE sehingga pengguna tidak perlu
/// menempel key sendiri.
enum AuthType { apiKey, oauth }
