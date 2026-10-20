import 'package:flutter/painting.dart';
import 'package:highlight/highlight.dart';

/// Hasil sorot sintaks: span siap render beserta jumlah baris logisnya.
class CodeHighlight {
  const CodeHighlight({required this.span, required this.lineCount});

  final TextSpan span;
  final int lineCount;
}

/// Palet atom-one-dark dengan tambahan `tag` (bawaan tema tidak punya),
/// supaya kurung siku HTML ikut berwarna, bukan abu-abu polos.
const Map<String, Color> _syntaxColors = {
  'root': Color(0xFFD4D7DD),
  'comment': Color(0xFF6B7280),
  'quote': Color(0xFF6B7280),
  'doctag': Color(0xFFC678DD),
  'keyword': Color(0xFFC678DD),
  'formula': Color(0xFFC678DD),
  'section': Color(0xFFE06C75),
  'name': Color(0xFFE06C75),
  'tag': Color(0xFFE06C75),
  'selector-tag': Color(0xFFE06C75),
  'deletion': Color(0xFFE06C75),
  'subst': Color(0xFFE06C75),
  'literal': Color(0xFF56B6C2),
  'string': Color(0xFF98C379),
  'regexp': Color(0xFF98C379),
  'addition': Color(0xFF98C379),
  'attribute': Color(0xFFD19A66),
  'attr': Color(0xFFD19A66),
  'meta-string': Color(0xFF98C379),
  'built_in': Color(0xFFE5C07B),
  'variable': Color(0xFFD19A66),
  'template-variable': Color(0xFFD19A66),
  'number': Color(0xFFD19A66),
  'symbol': Color(0xFF56B6C2),
  'bullet': Color(0xFFD19A66),
  'meta': Color(0xFF61AFEF),
  'meta-keyword': Color(0xFFC678DD),
  'title': Color(0xFF61AFEF),
  'function': Color(0xFF61AFEF),
  'class': Color(0xFFE5C07B),
  'type': Color(0xFFE5C07B),
  'selector-class': Color(0xFFE5C07B),
  'selector-id': Color(0xFF61AFEF),
  'selector-pseudo': Color(0xFF56B6C2),
  'property': Color(0xFFE06C75),
  'params': Color(0xFFD4D7DD),
  'link': Color(0xFF61AFEF),
};

const Set<String> _italicClasses = {'comment', 'quote'};

TextStyle? _styleFor(String? className) {
  if (className == null) return null;
  final color = _syntaxColors[className];
  if (color == null) return null;
  return TextStyle(
    color: color,
    fontStyle: _italicClasses.contains(className) ? FontStyle.italic : null,
  );
}

/// Menyorot satu potongan kode dengan bahasa tertentu.
List<TextSpan> _spansFor(String code, String language) {
  if (code.isEmpty) return const [];
  try {
    final nodes = highlight.parse(code, language: language).nodes;
    if (nodes == null) return [TextSpan(text: code)];
    final spans = <TextSpan>[];
    for (final node in nodes) {
      _appendNode(node, spans);
    }
    return spans;
  } catch (_) {
    // Bahasa tidak dikenal / parser gagal: tetap tampilkan teks aslinya.
    return [TextSpan(text: code)];
  }
}

void _appendNode(Node node, List<TextSpan> out) {
  final value = node.value;
  if (value != null) {
    out.add(TextSpan(text: value, style: _styleFor(node.className)));
    return;
  }
  final children = node.children;
  if (children == null || children.isEmpty) return;
  final nested = <TextSpan>[];
  for (final child in children) {
    _appendNode(child, nested);
  }
  out.add(TextSpan(style: _styleFor(node.className), children: nested));
}

/// Menyorot dokumen HTML, termasuk isi `<style>` (CSS) dan `<script>` (JS).
///
/// Normalisasi CRLF/tab hanya untuk tampilan; teks asli untuk copy/simpan
/// tidak diubah.
CodeHighlight highlightHtmlDocument(String source) {
  final code = source
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll('\t', '  ');
  final lineCount = code.isEmpty ? 1 : '\n'.allMatches(code).length + 1;

  final embedded = RegExp(
    r'(<(style|script)\b[^>]*>)([\s\S]*?)(</\2\s*>)',
    caseSensitive: false,
  );

  final spans = <TextSpan>[];
  var cursor = 0;

  for (final match in embedded.allMatches(code)) {
    if (match.start > cursor) {
      spans.addAll(_spansFor(code.substring(cursor, match.start), 'html'));
    }

    final openTag = match.group(1)!;
    final tagName = match.group(2)!.toLowerCase();
    final inner = match.group(3)!;
    final closeTag = match.group(4)!;

    spans.addAll(_spansFor(openTag, 'html'));
    if (inner.isNotEmpty) {
      spans.addAll(_spansFor(inner, tagName == 'style' ? 'css' : 'javascript'));
    }
    spans.addAll(_spansFor(closeTag, 'html'));

    cursor = match.end;
  }

  if (cursor < code.length) {
    spans.addAll(_spansFor(code.substring(cursor), 'html'));
  }

  return CodeHighlight(
    span: TextSpan(children: spans),
    lineCount: lineCount,
  );
}
