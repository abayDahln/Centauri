import 'page.dart';

/// Ubah nama halaman menjadi slug nama-file: lowercase, hyphen, berakhiran
/// `.html`. Contoh: "Landing Page" -> "landing-page.html".
String slugify(String name) {
  final cleaned = name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (cleaned.isEmpty) return 'page.html';
  return '$cleaned.html';
}

/// Nama-file tanpa ekstensi `.html` (lowercase).
String slugStem(String slug) {
  final lower = slug.toLowerCase();
  return lower.endsWith('.html') ? lower.substring(0, lower.length - 5) : lower;
}

/// Pastikan [base] unik di antara [existing] (append `-2`, `-3`, ...).
String uniqueSlug(String base, Iterable<String> existing) {
  final normalized = base.toLowerCase().endsWith('.html')
      ? base.toLowerCase()
      : '${base.toLowerCase()}.html';
  final taken = existing.map((s) => s.toLowerCase()).toSet();
  if (!taken.contains(normalized)) return normalized;
  final stem = slugStem(normalized);
  var i = 2;
  while (true) {
    final candidate = '$stem-$i.html';
    if (!taken.contains(candidate)) return candidate;
    i++;
  }
}

/// Jenis sebuah href saat dipetakan ke halaman yang ada.
enum LinkKind {
  /// Link ke halaman lain yang sudah di-generate.
  internal,

  /// Link keluar (http/https/mailto/tel).
  external,

  /// Anchor dalam halaman yang sama (#...) — dibiarkan apa adanya.
  anchor,

  /// Target internal yang tidak cocok halaman mana pun.
  unknown,
}

/// Hasil resolusi link. [pageId] hanya terisi bila [kind] == internal.
class ResolvedLink {
  const ResolvedLink(this.kind, [this.pageId]);

  final LinkKind kind;
  final String? pageId;
}

/// Petakan [href] ke halaman yang cocok.
///
/// Aturan:
/// - kosong / `#...` -> anchor (dibiarkan, biar browser scroll sendiri).
/// - `http(s)://`, `//`, `mailto:`, `tel:` -> external.
/// - selain itu internal: ambil basename (buang query/fragment), cocokkan
///   dengan `slug` halaman atau slug dari `name` halaman.
ResolvedLink resolveLink(String href, List<AppPage> pages) {
  final raw = href.trim();
  if (raw.isEmpty || raw.startsWith('#')) {
    return const ResolvedLink(LinkKind.anchor);
  }
  final lower = raw.toLowerCase();
  if (lower.startsWith('http://') ||
      lower.startsWith('https://') ||
      lower.startsWith('//') ||
      lower.startsWith('mailto:') ||
      lower.startsWith('tel:') ||
      lower.startsWith('data:') ||
      lower.startsWith('javascript:')) {
    return const ResolvedLink(LinkKind.external);
  }

  var path = raw.split('#').first.split('?').first.replaceAll('\\', '/');
  final segments = path.split('/');
  var base = segments.isEmpty ? path : segments.last;
  base = base.replaceAll(RegExp(r'^\./'), '').toLowerCase();
  if (base.isEmpty) return const ResolvedLink(LinkKind.anchor);

  final stem = slugStem(base);
  for (final page in pages) {
    if (base == page.slug.toLowerCase() ||
        stem == slugStem(page.slug) ||
        stem == slugStem(slugify(page.name))) {
      return ResolvedLink(LinkKind.internal, page.id);
    }
  }
  return const ResolvedLink(LinkKind.unknown);
}
