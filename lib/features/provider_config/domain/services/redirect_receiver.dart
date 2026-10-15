/// Hasil callback OAuth yang diterima dari redirect URI.
class OAuthRedirectResult {
  const OAuthRedirectResult({
    this.code,
    this.state,
    this.error,
    this.errorDescription,
  });

  final String? code;
  final String? state;
  final String? error;
  final String? errorDescription;

  bool get isSuccess => code != null && code!.isNotEmpty;
}

/// Penerima redirect OAuth.
///
/// Abstraksi ini memisahkan alur OAuth dari mekanisme penangkapan callback,
/// sehingga bisa diuji dengan fake dan memudahkan penambahan jalur Android
/// (custom URI scheme) di masa depan tanpa mengubah [OAuthService].
abstract class RedirectReceiver {
  /// Mulai menerima callback dan kembalikan redirect URI yang harus dipakai
  /// pada authorization request. [port] null = ephemeral (port acak).
  Future<Uri> start({int? port});

  /// Tunggu sampai callback diterima atau [timeout] tercapai.
  Future<OAuthRedirectResult> waitForCallback({required Duration timeout});

  /// Hentikan penerima dan bebaskan resource.
  Future<void> stop();
}
