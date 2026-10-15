import 'package:url_launcher/url_launcher.dart';

/// Pembuka browser sistem. Dibungkus sebagai kelas agar mudah di-fake di test
/// dan agar [OAuthService] tidak bergantung langsung pada plugin `url_launcher`.
class BrowserLauncher {
  const BrowserLauncher();

  /// Buka [url] di browser eksternal. Mengembalikan false bila gagal.
  Future<bool> open(Uri url) {
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
