/// Membaca halaman aktif untuk overlay "Memuat…" di preview.
/// Overlay hanya tampil saat berpindah halaman (id berubah), bukan saat HTML
/// halaman yang sama dimutasi (mis. inline edit) — supaya edit tidak berkedip.
class PageSwitchTracker {
  String? _current;

  /// Tandai mulai render untuk [pageId]. Return true hanya saat id berubah
  /// (berpindah halaman / render pertama), false untuk mutasi halaman sama.
  bool isSwitching(String? pageId) {
    if (pageId == null) return false;
    final switched = pageId != _current;
    _current = pageId;
    return switched;
  }
}
