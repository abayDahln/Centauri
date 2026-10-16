/// Jenis alur OAuth yang dipakai sebuah provider.
enum OAuthFlow {
  /// Authorization Code (+ PKCE) via redirect loopback — alur default.
  authorizationCode,

  /// Device Authorization Grant (RFC 8628) — pengguna membuka URL + kode.
  deviceCode,

  /// Impor token dari penyimpanan lokal aplikasi lain (mis. Cursor IDE).
  /// Tidak ada browser/OAuth; token dibaca dari state lokal provider.
  importToken,
}

/// Dialek device flow. Hanya relevan bila [OAuthFlow.deviceCode].
enum DeviceFlowStyle {
  /// RFC 8628 standar: kode device/user diterbitkan server.
  rfc8628,

  /// Device flow custom Qoder: kode device di-generate lokal dan endpoint
  /// polling memakai semantik status non-standar (202/404 = menunggu).
  qoder,

  /// Device flow custom Kilo Code: POST JSON tanpa body untuk meminta kode,
  /// lalu poll `GET {pollUrlBase}/{code}` (202/403/410 = status khusus).
  kilocode,

  /// Device flow custom CodeBuddy: POST `{stateUrl}?platform=ide` (header
  /// khusus) → `{state, authUrl}`, lalu poll `GET {tokenUrl}?state=...`.
  codebuddy,

  /// Device flow custom Zai GLM (ZCode CLI): POST `{cliInitUrl}` dengan
  /// Bearer poll-token → `{flow_id, authorize_url}`, lalu poll
  /// `GET {cliPollUrl}/{flow_id}` sampai status `ready`.
  glm,

  /// Device flow AWS SSO OIDC (Kiro): register client → device_authorization →
  /// poll token. Semua body JSON dengan field camelCase.
  kiro,
}

/// Sumber impor token lokal. Hanya relevan bila [OAuthFlow.importToken].
enum ImportSource {
  /// Cursor IDE: baca `cursorAuth/accessToken` dari `state.vscdb` lokal.
  cursor,
}

/// Format body request saat menukar token.
enum TokenBodyFormat {
  /// `application/x-www-form-urlencoded` (default, RFC 6749).
  form,

  /// `application/json` (dipakai sebagian provider, mis. Claude Code).
  json,
}

/// Langkah tambahan setelah token utama diperoleh.
enum TokenExchangeStyle {
  /// Tanpa langkah tambahan.
  none,

  /// GitHub Copilot: tukar token GitHub menjadi token Copilot.
  githubCopilot,

  /// Cline: `code` berisi data token base64 (fallback: POST ke token URL).
  cline,
}
