/// Mengambil dokumen HTML yang masih setengah jadi dari teks streaming.
///
/// Saat generate, model menulis beberapa blok ```html berurutan. Blok yang
/// belum ditutup adalah halaman yang sedang ditulis, jadi isinya dipakai
/// untuk pratinjau live. Sanitasi memakai operasi string murni (bukan parser
/// HTML) supaya cukup murah untuk dijalankan tiap beberapa ratus milidetik.
library;

/// Di bawah ini dianggap belum ada yang layak ditampilkan.
const int _minLength = 320;

/// Batas aman payload `executeScript` WebView2.
const int _maxLength = 600000;

/// Dokumen parsial siap tampil, atau null bila belum ada.
String? extractPartialHtml(String raw) {
  if (raw.length < _minLength) return null;

  final String body;
  // Fence berpasangan: 0 buka, 1 tutup, 2 buka, ... Fence terakhir tanpa
  // pasangan adalah halaman yang sedang ditulis; kalau semua sudah tertutup,
  // dipakai pasangan terakhir (halaman terakhir yang selesai).
  final ticks = RegExp('```').allMatches(raw).toList();
  if (ticks.isNotEmpty) {
    final openIndex = ticks.length.isOdd ? ticks.length - 1 : ticks.length - 2;
    final open = ticks[openIndex];
    final closeIndex = openIndex + 1;
    final closeAt = closeIndex < ticks.length
        ? ticks[closeIndex].start
        : raw.length;
    var start = open.end;
    // Lewati nama bahasa sampai akhir baris pembuka.
    while (start < raw.length && raw[start] != '\n') {
      start++;
    }
    if (start < raw.length) start++;
    body = raw.substring(
      start.clamp(0, raw.length),
      closeAt.clamp(0, raw.length),
    );
  } else {
    final lower = raw.toLowerCase();
    final doctype = lower.lastIndexOf('<!doctype');
    final htmlTag = lower.lastIndexOf('<html');
    final start = doctype >= 0 ? doctype : htmlTag;
    if (start < 0) return null;
    body = raw.substring(start);
  }

  if (!body.toLowerCase().contains('<body')) return null;

  var out = _truncateUnsafeTail(body);
  // Pemotongan bisa membuang <body> (mis. <style> di head belum ditutup).
  if (!out.toLowerCase().contains('<body')) return null;
  if (out.length < _minLength) return null;

  out = _closeStructure(out);
  if (out.length > _maxLength) return null;
  return out;
}

/// Slug halaman dari `<meta name="centauri-page" content="...">`, bila ada.
String? slugOfPartial(String html) {
  final meta = RegExp(
    r'''<meta[^>]+name=["']centauri-page["'][^>]*>''',
    caseSensitive: false,
  ).firstMatch(html);
  if (meta == null) return null;
  final content = RegExp(
    r'''content=["']([^"']+)["']''',
    caseSensitive: false,
  ).firstMatch(meta.group(0)!);
  final slug = content?.group(1)?.trim();
  return (slug == null || slug.isEmpty) ? null : slug;
}

/// Buang ekor dokumen yang merusak render.
String _truncateUnsafeTail(String html) {
  var out = html;

  // <script>/<style> yang belum ditutup menelan seluruh sisa dokumen.
  for (final tag in const ['script', 'style']) {
    final lower = out.toLowerCase();
    final open = lower.lastIndexOf('<$tag');
    if (open < 0) continue;
    if (lower.indexOf('</$tag>', open) < 0) out = out.substring(0, open);
  }

  // Tag terakhir yang belum selesai, mis. `<div class="ca`.
  final lt = out.lastIndexOf('<');
  if (lt > out.lastIndexOf('>')) out = out.substring(0, lt);

  // Komentar yang belum ditutup.
  final comment = out.lastIndexOf('<!--');
  if (comment >= 0 && out.indexOf('-->', comment) < 0) {
    out = out.substring(0, comment);
  }

  // Entity setengah jadi, mis. `&am`.
  final amp = out.lastIndexOf('&');
  if (amp >= 0 && out.indexOf(';', amp) < 0 && out.length - amp < 8) {
    out = out.substring(0, amp);
  }

  return out;
}

/// Tutup struktur supaya browser tidak menganggap dokumen masih berjalan.
String _closeStructure(String html) {
  var out = html;
  final lower = out.toLowerCase();
  final bodyAt = lower.indexOf('<body');
  final headAt = lower.indexOf('<head');
  final headClose = lower.indexOf('</head>');

  // <head> masih terbuka tepat sebelum <body>.
  if (headAt >= 0 && (headClose < 0 || headClose > bodyAt)) {
    out = '${out.substring(0, bodyAt)}</head>${out.substring(bodyAt)}';
  }

  final afterHead = out.toLowerCase();
  if (!afterHead.contains('</body>')) out = '$out</body>';
  if (!out.toLowerCase().contains('</html>')) out = '$out</html>';
  return out;
}

/// Teks penjelasan di luar blok kode berpagar, untuk bubble chat live.
///
/// Blok ```...``` (HTML halaman) dibuang supaya chat tidak dibanjiri kode;
/// kalimat sebelum/sesudah blok tetap tampil. Teks yang belum selesai
/// ditulis tetap dikembalikan apa adanya agar terasa mengalir.
String streamProse(String raw) {
  final buffer = StringBuffer();
  var inFence = false;
  for (final line in raw.split('\n')) {
    if (line.trimLeft().startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (!inFence) buffer.writeln(line);
  }
  return buffer.toString().trim();
}
