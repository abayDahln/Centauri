/// Kode kesalahan lintas lapisan.
///
/// Lapisan `data` tidak menyimpan teks yang terlihat pengguna: ia melempar kode
/// ini lewat [AppErrorDetails], lalu lapisan UI/state menerjemahkannya dengan
/// `localizedAppError` di `lib/app/l10n/error_messages.dart`. Dengan begitu
/// pesan error ikut bahasa UI tanpa membuat data layer bergantung pada
/// `BuildContext`.
enum AppErrorCode {
  /// Generate dibatalkan pengguna — biasanya tidak perlu ditampilkan.
  cancelled,

  // ---------------------------------------------------------- provider AI --
  apiTimeout,
  apiUnreachable,
  apiUnauthorized,
  apiRateLimited,
  apiNotFound,
  apiRejected,
  apiCertificate,
  apiSendFailed,
  apiBadResponse,
  apiNoChatEndpoint,
  apiModelUnavailable,
  apiConnectionBroken,

  /// Provider mengirim pesannya sendiri (mis. "model not found: gpt-99").
  apiProviderReported,

  generationTimeout,

  // --------------------------------------------------------------- ekspor --
  exportNotReady,
  exportTimeout,
  exportNoElements,
  exportEmptyResult,
  exportWriteFailed,

  /// Ekspor gagal tanpa sebab yang lebih spesifik (detail masuk log).
  exportFailed,

  // ------------------------------------------------- impor berkas proyek --
  importInvalidFile,
  importNotProject,
  importNewerVersion,
  importEmpty,
  importUnusable,

  // ------------------------------------------------------------- lampiran --
  attachmentEmpty,
  attachmentTooLarge,
  attachmentUnsupported,

  // ------------------------------------------------------------ penyimpanan --
  storageFailed,

  // ---------------------------------------------------------- konversi kode --
  transformNoCode,

  /// Konversi ke format target gagal (detail parser masuk log).
  transformFailed,

  /// Tidak ada kode yang lebih spesifik.
  unknown,
}

/// Kode error plus data yang dibutuhkan untuk menyusun pesannya di UI.
///
/// Semua exception lapisan data/domain mewarisi ini, jadi satu mapper
/// ([AppErrorDetails] → String) cukup untuk semuanya.
class AppErrorDetails {
  const AppErrorDetails(
    this.code, {
    this.detail,
    this.name,
    this.version,
    this.maxMb,
    this.formats,
  });

  final AppErrorCode code;

  /// Rincian teknis (status HTTP, URL, pesan asli provider) untuk log. TIDAK
  /// ditampilkan ke pengguna — kecuali pada [AppErrorCode.apiProviderReported],
  /// yang justru pesannya berasal dari provider.
  final String? detail;

  /// Nama berkas/pemicu, mis. nama lampiran yang ditolak.
  final String? name;

  /// Versi berkas yang lebih baru dari aplikasi.
  final String? version;

  /// Batas ukuran (MB) untuk pesan "terlalu besar".
  final int? maxMb;

  /// Daftar format yang didukung untuk pesan "format tidak didukung".
  final String? formats;

  /// Label aman untuk log: kode + detail, tanpa kredensial.
  String get debugLabel => appErrorDebugLabel(code, detail: detail);
}

/// Label debug yang aman ditulis ke log: kode + detail teknis, tanpa kredensial.
String appErrorDebugLabel(AppErrorCode code, {String? detail}) {
  final trimmed = detail?.trim();
  return trimmed == null || trimmed.isEmpty
      ? 'AppErrorCode.${code.name}'
      : 'AppErrorCode.${code.name}: $trimmed';
}
