import 'dart:collection';

/// Cache LRU kecil untuk WebView per halaman.
///
/// Setiap halaman yang sudah dibuka punya WebView sendiri; halaman yang masih
/// tersimpan di sini tetap hidup (dokumen, skrip, dan posisi gulirnya) walau
/// tidak sedang tampil. Berpindah kembali ke halaman itu jadi seketika karena
/// tidak ada dokumen yang perlu dimuat ulang.
///
/// Urutan map = urutan pemakaian: entri paling awal paling lama dipakai dan
/// dibuang lebih dulu saat melebihi [maxEntries].
class PageViewCache<T> {
  PageViewCache({this.maxEntries = 3}) : assert(maxEntries >= 1);

  final int maxEntries;
  final LinkedHashMap<String, T> _entries = LinkedHashMap<String, T>();

  int get length => _entries.length;
  bool contains(String id) => _entries.containsKey(id);
  T? operator [](String id) => _entries[id];
  List<String> get ids => List<String>.unmodifiable(_entries.keys);

  /// Ambil [id] dan tandai sebagai paling baru dipakai.
  T? touch(String id) {
    final value = _entries.remove(id);
    if (value != null) _entries[id] = value;
    return value;
  }

  /// Simpan [value] sebagai entri terbaru, lalu kembalikan entri yang tergusur.
  ///
  /// [keep] dilindungi dari penggusuran — halaman yang sedang ditampilkan dan
  /// halaman tujuan tidak boleh dibuang walau cache penuh.
  List<T> store(String id, T value, {Iterable<String> keep = const []}) {
    _entries.remove(id);
    _entries[id] = value;
    final evicted = <T>[];
    for (final key in _entries.keys.toList(growable: false)) {
      if (_entries.length <= maxEntries) break;
      if (key == id || keep.contains(key)) continue;
      evicted.add(_entries.remove(key) as T);
    }
    return evicted;
  }

  /// Buang satu entri (mis. halaman dihapus dari proyek).
  T? remove(String id) => _entries.remove(id);

  /// Kosongkan cache; pemanggil bertanggung jawab men-dispose isinya.
  List<T> clear() {
    final values = _entries.values.toList(growable: false);
    _entries.clear();
    return values;
  }
}
