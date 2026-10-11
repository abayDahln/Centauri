import 'package:html/parser.dart' as html;

/// Transformasi heuristik HTML (output AI) menjadi komponen React JSX.
/// Tidak menjamin 1:1 sempurna; hasil difungsikan sebagai starting point
/// yang bisa langsung diedit pengguna.
class HtmlToReactTransformer {
  static const _voidElements = [
    'area',
    'base',
    'br',
    'col',
    'embed',
    'hr',
    'img',
    'input',
    'link',
    'meta',
    'param',
    'source',
    'track',
    'wbr',
  ];

  String transform(String htmlSource) {
    final document = html.parse(htmlSource);
    final body = document.body;
    final bodyHtml = body?.innerHtml ?? '';

    final jsx = _transformAttributes(bodyHtml);

    return '''
// Dihasilkan otomatis oleh Centauri.
// Catatan: pindahkan isi tag <style> dokumen HTML asli ke file CSS
// terpisah (generated-ui.css) - class mengacu ke CSS hand-written.
export default function GeneratedUI() {
  return (
    <div className="min-h-screen bg-[#09090B] text-zinc-50">
$jsx
    </div>
  );
}
''';
  }

  String _transformAttributes(String source) {
    var out = source;

    // class -> className, for -> htmlFor
    out = out.replaceAll(RegExp(r'\sclass\s*=\s*"'), ' className="');
    out = out.replaceAll(RegExp(r"\sclass\s*=\s*'"), " className='");
    out = out.replaceAll(RegExp(r'\sfor\s*=\s*"'), ' htmlFor="');
    out = out.replaceAll(RegExp(r"\sfor\s*=\s*'"), " htmlFor='");

    // style="a:b;c:d" -> style={{a: 'b', c: 'd'}}
    out = out.replaceAllMapped(
      RegExp(r'style\s*=\s*"([^"]*)"'),
      (m) => 'style={{${_cssToJsx(m.group(1) ?? '')}}}',
    );
    out = out.replaceAllMapped(
      RegExp(r"style\s*=\s*'([^']*)'"),
      (m) => 'style={{${_cssToJsx(m.group(1) ?? '')}}}',
    );

    // Self-close void elements.
    for (final tag in _voidElements) {
      out = out.replaceAllMapped(
        RegExp('<$tag\\b([^>]*?)(/?)>', caseSensitive: false),
        (m) => m.group(2) == '/'
            ? m.group(0)!
            : '<$tag${m.group(1)} />',
      );
    }

    return out;
  }

  String _cssToJsx(String css) {
    final declarations = css
        .split(';')
        .map((d) => d.trim())
        .where((d) => d.contains(':'))
        .toList();

    return declarations.map((declaration) {
      final separator = declaration.indexOf(':');
      final key = _camelCase(declaration.substring(0, separator).trim());
      final rawValue = declaration.substring(separator + 1).trim();

      if (key == 'custom-properties') return '';

      final numeric = rawValue.endsWith('px')
          ? double.tryParse(rawValue.substring(0, rawValue.length - 2))
          : null;
      if (numeric != null) {
        final isWhole = numeric == numeric.roundToDouble();
        return '$key: ${isWhole ? numeric.round() : numeric}';
      }
      if (key == 'opacity' || key == 'zIndex' || key == 'fontWeight') {
        if (double.tryParse(rawValue) != null) return '$key: $rawValue';
      }
      return "$key: '${rawValue.replaceAll("'", r"\'")}'";
    }).join(', ');
  }

  String _camelCase(String kebab) {
    final parts = kebab.split('-');
    if (parts.length == 1) return kebab;
    final buffer = StringBuffer(parts.first);
    for (var i = 1; i < parts.length; i++) {
      final part = parts[i];
      if (part.isEmpty) continue;
      buffer.write(part[0].toUpperCase() + part.substring(1));
    }
    return buffer.toString();
  }
}
