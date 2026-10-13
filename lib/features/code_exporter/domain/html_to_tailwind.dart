import 'package:html/parser.dart' as html;

/// Transformasi heuristik HTML (output AI) menjadi snippet HTML ber-Tailwind.
/// Setiap deklarasi inline `style="prop: value"` dipetakan menjadi
/// arbitrary property Tailwind `[prop:value]` (butuh Tailwind v3.2+;
/// underscore `_` dibaca sebagai spasi). Class yang sudah ada dipertahankan.
/// Isi tag `<style>` TIDAK diterjemahkan — pindahkan ke file CSS seperti
/// pada konverter React. Hasil adalah starting point, periksa sebelum produksi.
class HtmlToTailwindTransformer {
  String transform(String htmlSource) {
    final document = html.parse(htmlSource);
    final body = document.body;
    if (body == null) {
      return '<!-- Centauri: dokumen kosong, tidak ada yang dikonversi. -->\n';
    }

    for (final element in body.querySelectorAll('*')) {
      final style = element.attributes['style'];
      if (style == null || style.trim().isEmpty) continue;
      final utilities = cssToTailwind(style);
      if (utilities.isEmpty) continue;
      final existing = element.attributes['class']?.trim() ?? '';
      element.attributes['class'] = existing.isEmpty
          ? utilities
          : '$existing $utilities';
      element.attributes.remove('style');
    }

    return '''
<!-- Dihasilkan otomatis oleh Centauri (heuristik, periksa sebelum produksi).
     - Setiap inline style diubah menjadi arbitrary property Tailwind
       ([prop:value], underscore = spasi). Butuh Tailwind CSS v3.2+.
     - Class asli dipertahankan apa adanya.
     - Pindahkan isi tag <style> dokumen HTML asli ke file CSS terpisah. -->
${body.innerHtml}
''';
  }
}

/// Konversi blok deklarasi CSS menjadi kelas arbitrary property Tailwind.
/// Top-level agar bisa diuji langsung.
String cssToTailwind(String css) {
  final out = <String>[];
  for (final declaration in css.split(';')) {
    final trimmed = declaration.trim();
    if (trimmed.isEmpty || !trimmed.contains(':')) continue;
    final separator = trimmed.indexOf(':');
    final prop = trimmed.substring(0, separator).trim().toLowerCase();
    var value = trimmed.substring(separator + 1).trim();
    if (prop.isEmpty || value.isEmpty) continue;

    // !important → modifier prefix Tailwind.
    var important = '';
    if (value.contains('!important')) {
      important = '!';
      value = value.replaceAll('!important', '').trim();
      if (value.isEmpty) continue;
    }

    // Di dalam arbitrary value: spasi → underscore, kutip ganda → tunggal.
    final safeValue = value
        .replaceAll('"', "'")
        .replaceAll(RegExp(r'\s+'), '_');
    out.add('$important[$prop:$safeValue]');
  }
  return out.join(' ');
}
