import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html;

/// Transformasi heuristik HTML (output AI) menjadi widget tree Flutter.
///
/// Batasan yang diketahui (sengaja, fase awal):
/// - Class CSS di <style> tidak dipetakan; hanya inline style yang diterjemahkan.
/// - Hasil adalah starting point, bukan drop-in replacement 1:1.
class HtmlToFlutterTransformer {
  static const _headingSizes = {
    'h1': 30,
    'h2': 26,
    'h3': 22,
    'h4': 20,
    'h5': 18,
    'h6': 16,
  };

  static const _skippedTags = {
    'script',
    'style',
    'title',
    'head',
    'meta',
    'link',
    'noscript',
    'template',
  };

  static const _textTags = {
    'p',
    'span',
    'label',
    'strong',
    'em',
    'small',
    'code',
    'pre',
    'b',
    'i',
    'u',
    'figcaption',
    'blockquote',
    'th',
    'td',
    'li',
    'option',
  };

  String transform(String htmlSource) {
    final document = html.parse(htmlSource);
    final body = document.body;
    final children = body == null ? '' : _buildChildren(body.nodes, 4);

    return '''
import 'package:flutter/material.dart';

// Dihasilkan otomatis oleh Centauri dari output AI (HTML -> Flutter).
// Catatan: class CSS tidak dipetakan ke widget; hanya inline style
// yang diterjemahkan. Periksa dan sesuaikan sebelum dipakai di produksi.
class GeneratedUIScreen extends StatelessWidget {
  const GeneratedUIScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
$children
            ],
          ),
        ),
      ),
    );
  }
}
''';
  }

  String _buildChildren(List<html_dom.Node> nodes, int indent) {
    final lines = <String>[];
    for (final node in nodes) {
      final code = _buildNode(node, indent);
      if (code != null && code.isNotEmpty) lines.add(code);
    }
    return lines.join('\n');
  }

  String? _buildNode(html_dom.Node node, int indent) {
    if (node is html_dom.Text) {
      final text = _collapseWhitespace(node.text);
      if (text.isEmpty) return null;
      return '${_indent(indent)}Text(${_dartString(text)}),';
    }
    if (node is html_dom.Element) {
      return _buildElement(node, indent);
    }
    return null;
  }

  String? _buildElement(html_dom.Element el, int indent) {
    final tag = (el.localName ?? '').toLowerCase();

    if (_skippedTags.contains(tag)) return null;

    switch (tag) {
      case 'br':
        return '${_indent(indent)}const SizedBox(height: 8),';
      case 'hr':
        return '${_indent(indent)}const Divider(color: Color(0xFF27272A), height: 24),';
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        return _headingWidget(el, indent, _headingSizes[tag] ?? 16);
      case 'a':
        return _anchorWidget(el, indent);
      case 'button':
        return _buttonWidget(el, indent);
      case 'img':
        return _imageWidget(el, indent);
      case 'input':
      case 'textarea':
        return _inputWidget(el, indent);
      case 'ul':
      case 'ol':
        return _listWidget(el, indent, tag == 'ol');
      case 'table':
        return _tableWidget(el, indent);
      case 'tr':
        return _tableRowWidget(el, indent);
      default:
        if (_textTags.contains(tag) && el.children.isEmpty) {
          return _textWidget(el, indent);
        }
        return _containerWidget(el, indent);
    }
  }

  String _textWidget(html_dom.Element el, int indent) {
    final text = _collapseWhitespace(el.text);
    if (text.isEmpty) return '${_indent(indent)}const SizedBox.shrink(),';

    final centered = _parseInlineStyle(el)['text-align'] == 'center';
    final styleSegments = _textStyle(el);
    final styleArg = styleSegments.isEmpty
        ? null
        : 'style: TextStyle(\n${_indent(indent + 3)}${styleSegments.join(',\n${_indent(indent + 3)}')},\n${_indent(indent + 2)})';

    final args = <String>[?styleArg];
    if (centered) args.add('textAlign: TextAlign.center');

    if (args.isEmpty) {
      return '${_indent(indent)}Text(${_dartString(text)}),';
    }
    return _multilineWidget('Text', indent, [_dartString(text), ...args]);
  }

  String _headingWidget(html_dom.Element el, int indent, int size) {
    final text = _collapseWhitespace(el.text);
    if (text.isEmpty) return '${_indent(indent)}const SizedBox.shrink(),';
    final style = _textStyle(el, defaultColor: true);
    final styleLines = <String>[
      'fontSize: $size',
      'fontWeight: FontWeight.w700',
      ...style,
    ];
    return _multilineWidget('Text', indent, [
      _dartString(text),
      'style: TextStyle(\n${_indent(indent + 3)}${styleLines.join(',\n${_indent(indent + 3)}')},\n${_indent(indent + 2)})',
    ]);
  }

  String _anchorWidget(html_dom.Element el, int indent) {
    final text = _collapseWhitespace(el.text);
    if (text.isEmpty) return '${_indent(indent)}const SizedBox.shrink(),';
    return '${_indent(indent)}TextButton(\n'
        '${_indent(indent + 1)}onPressed: () {},\n'
        '${_indent(indent + 1)}child: Text(${_dartString(text)}),\n'
        '${_indent(indent)}),';
  }

  String _buttonWidget(html_dom.Element el, int indent) {
    final text = _collapseWhitespace(el.text);
    if (text.isEmpty) {
      return '${_indent(indent)}ElevatedButton(\n'
          '${_indent(indent + 1)}onPressed: () {},\n'
          '${_indent(indent + 1)}child: const Text("Aksi"),\n'
          '${_indent(indent)}),';
    }
    return '${_indent(indent)}ElevatedButton(\n'
        '${_indent(indent + 1)}onPressed: () {},\n'
        '${_indent(indent + 1)}child: Text(${_dartString(text)}),\n'
        '${_indent(indent)}),';
  }

  String _imageWidget(html_dom.Element el, int indent) {
    final src = el.attributes['src'] ?? '';
    if (src.isEmpty) {
      return '${_indent(indent)}const SizedBox(height: 120),';
    }
    return '${_indent(indent)}ClipRRect(\n'
        '${_indent(indent + 1)}borderRadius: BorderRadius.circular(8),\n'
        '${_indent(indent + 1)}child: Image.network(\n'
        '${_indent(indent + 2)}${_dartString(src)},\n'
        '${_indent(indent + 2)}fit: BoxFit.cover,\n'
        '${_indent(indent + 2)}errorBuilder: (context, error, stack) =>\n'
        '${_indent(indent + 3)}const SizedBox(height: 120),\n'
        '${_indent(indent + 1)}),\n'
        '${_indent(indent)}),';
  }

  String _inputWidget(html_dom.Element el, int indent) {
    final placeholder = el.attributes['placeholder'] ?? '';
    final isPassword = (el.attributes['type'] ?? '') == 'password';
    return '${_indent(indent)}TextField(\n'
        '${_indent(indent + 1)}obscureText: $isPassword,\n'
        '${_indent(indent + 1)}decoration: InputDecoration(\n'
        '${_indent(indent + 2)}hintText: ${_dartString(placeholder)},\n'
        '${_indent(indent + 2)}border: const OutlineInputBorder(),\n'
        '${_indent(indent + 1)}),\n'
        '${_indent(indent)}),';
  }

  String _listWidget(html_dom.Element el, int indent, bool ordered) {
    final children = _buildChildren(el.children, indent + 2);
    if (children.isEmpty) return '${_indent(indent)}const SizedBox.shrink(),';
    return '${_indent(indent)}Column(\n'
        '${_indent(indent + 1)}crossAxisAlignment: CrossAxisAlignment.start,\n'
        '${_indent(indent + 1)}children: [\n'
        '$children\n'
        '${_indent(indent + 1)}],\n'
        '${_indent(indent)}),';
  }

  String _tableWidget(html_dom.Element el, int indent) {
    final rows = el.querySelectorAll('tr');
    final children = _buildChildren(rows, indent + 2);
    if (children.isEmpty) return '${_indent(indent)}const SizedBox.shrink(),';
    return '${_indent(indent)}Column(\n'
        '${_indent(indent + 1)}crossAxisAlignment: CrossAxisAlignment.stretch,\n'
        '${_indent(indent + 1)}children: [\n'
        '$children\n'
        '${_indent(indent + 1)}],\n'
        '${_indent(indent)}),';
  }

  String _tableRowWidget(html_dom.Element el, int indent) {
    final children = _buildChildren(el.children, indent + 2);
    if (children.isEmpty) return '${_indent(indent)}const SizedBox.shrink(),';
    return '${_indent(indent)}Row(\n'
        '${_indent(indent + 1)}crossAxisAlignment: CrossAxisAlignment.start,\n'
        '${_indent(indent + 1)}children: [\n'
        '$children\n'
        '${_indent(indent + 1)}],\n'
        '${_indent(indent)}),';
  }

  String? _containerWidget(html_dom.Element el, int indent) {
    final children = _buildChildren(el.nodes, indent + 2);
    final style = _parseInlineStyle(el);
    final color = _color(style['background-color']);
    final padding = _edgeInsets(style['padding']);
    final radius = _borderRadius(style['border-radius']);

    final fields = <String>[];
    if (padding != null) fields.add('padding: $padding');
      if (color != null) {
      final decorationParts = <String>['color: $color'];
      if (radius != null) decorationParts.add('borderRadius: $radius');
      fields.add('decoration: BoxDecoration(${decorationParts.join(', ')})');
    } else if (radius != null) {
      fields.add('decoration: BoxDecoration(borderRadius: $radius)');
    }

    if (children.isEmpty) {
      if (fields.isEmpty) return null;
      return '${_indent(indent)}Container(\n'
          '${_indent(indent + 1)}height: 4,\n'
          '${_indent(indent + 1)}${fields.map((f) => '$f,\n${_indent(indent + 1)}').join()}'
          '${_indent(indent)}),';
    }

    final childrenColumn = 'Column(\n'
        '${_indent(indent + 2)}crossAxisAlignment: CrossAxisAlignment.start,\n'
        '${_indent(indent + 2)}children: [\n'
        '$children\n'
        '${_indent(indent + 2)}],\n'
        '${_indent(indent + 1)})';

    final fieldLines = fields.map((f) => '${_indent(indent + 1)}$f,\n').join();

    return '${_indent(indent)}Container(\n'
        '$fieldLines'
        '${_indent(indent + 1)}child: $childrenColumn,\n'
        '${_indent(indent)}),';
  }

  /// Segment style untuk [TextStyle]; list of `key: value` pairs.
  List<String> _textStyle(html_dom.Element el, {bool defaultColor = false}) {
    final style = _parseInlineStyle(el);
    final segments = <String>[];

    final colorValue = _color(style['color']);
    if (colorValue != null) {
      segments.add('color: $colorValue');
    } else if (defaultColor) {
      segments.add('color: const Color(0xFFFAFAFA)');
    }

    if (style.containsKey('font-size')) {
      final size = _parsePx(style['font-size']);
      if (size != null) segments.add('fontSize: $size');
    }

    final weight = style['font-weight'];
    if (weight != null) {
      final numeric = int.tryParse(weight);
      if (weight == 'bold' || (numeric != null && numeric >= 600)) {
        segments.add('fontWeight: FontWeight.w700');
      } else if (weight == 'normal' || (numeric != null && numeric < 600)) {
        segments.add('fontWeight: FontWeight.w400');
      }
    }

    if (style['text-align'] == 'center') {
      segments.add('height: 1.5');
    }

    return segments;
  }

  String _multilineWidget(
    String constructor,
    int indent,
    List<String> positionalArgs,
  ) {
    final args = positionalArgs.map((a) => '${_indent(indent + 2)}$a,\n').join();
    return '${_indent(indent)}$constructor(\n'
        '$args'
        '${_indent(indent)}),';
  }

  Map<String, String> _parseInlineStyle(html_dom.Element el) {
    final raw = el.attributes['style'];
    if (raw == null || raw.isEmpty) return const {};
    final map = <String, String>{};
    for (final declaration in raw.split(';')) {
      final separator = declaration.indexOf(':');
      if (separator < 0) continue;
      map[declaration.substring(0, separator).trim().toLowerCase()] =
          declaration.substring(separator + 1).trim();
    }
    return map;
  }

  double? _parsePx(String? value) {
    if (value == null) return null;
    return double.tryParse(value.replaceAll('px', '').trim());
  }

  String? _edgeInsets(String? padding) {
    if (padding == null) return null;
    final parts = padding.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final values = parts.map((p) => _parsePx(p)?.round()).toList();
    if (values.isEmpty || values.any((v) => v == null)) return null;
    final v = values.cast<int>();
    switch (v.length) {
      case 1:
        return v[0] == 0 ? null : 'const EdgeInsets.all(${v[0]})';
      case 2:
        return 'const EdgeInsets.symmetric(vertical: ${v[0]}, horizontal: ${v[1]})';
      case 3:
        return 'const EdgeInsets.fromLTRB(${v[1]}, ${v[0]}, ${v[1]}, ${v[2]})';
      case 4:
        return 'const EdgeInsets.fromLTRB(${v[0]}, ${v[1]}, ${v[2]}, ${v[3]})';
      default:
        return null;
    }
  }

  String? _borderRadius(String? radius) {
    if (radius == null) return null;
    final value = _parsePx(radius)?.round();
    if (value == null || value == 0) return null;
    return 'BorderRadius.circular($value)';
  }

  String? _color(String? raw) {
    if (raw == null) return null;
    var value = raw.trim().toLowerCase();
    if (value.isEmpty || value == 'transparent' || value == 'inherit') {
      return null;
    }

    if (value.startsWith('var(')) {
      final varName = value.substring(4).replaceAll(')', '');
      value = _tailwindAlias(varName.trim()) ?? '';
      if (value.isEmpty) return null;
    }

    if (value.startsWith('#')) {
      final hex = value.substring(1);
      if (hex.length == 3) {
        return 'const Color(0xFF${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]})';
      }
      if (hex.length == 6) {
        return 'const Color(0xFF${hex.toUpperCase()})';
      }
      return null;
    }

    final rgbMatch = RegExp(r'rgba?\(([^)]+)\)').firstMatch(value);
    if (rgbMatch != null) {
      final parts = rgbMatch.group(1)!.split(',').map((p) => p.trim()).toList();
      final r = int.tryParse(parts[0]);
      final g = parts.length > 1 ? int.tryParse(parts[1]) : r;
      final b = parts.length > 2 ? int.tryParse(parts[2]) : r;
      if (r == null || g == null || b == null) return null;
      return 'const Color(0xFF${_hex8(r)}${_hex8(g)}${_hex8(b)})';
    }

    const named = <String, String>{
      'white': 'FFFFFF',
      'black': '000000',
      'red': 'EF4444',
      'blue': '3B82F6',
      'green': '10B981',
      'yellow': 'F59E0B',
      'orange': 'F97316',
      'purple': '8B5CF6',
      'violet': '8B5CF6',
      'pink': 'EC4899',
      'gray': 'A1A1AA',
      'grey': 'A1A1AA',
      'slate': '64748B',
      'amber': 'F59E0B',
      'emerald': '10B981',
      'cyan': '22D3EE',
      'teal': '14B8A6',
      'indigo': '6366F1',
      'rose': 'F43F5E',
      'zinc': 'A1A1AA',
    };
    final namedValue = named[value];
    if (namedValue == null) return null;
    return 'const Color(0xFF$namedValue)';
  }

  String? _tailwindAlias(String varName) {
    const aliases = {
      '--background': '#09090b',
      '--foreground': '#fafafa',
      '--primary': '#3b82f6',
      '--secondary': '#27272a',
      '--muted': '#a1a1aa',
      '--accent': '#8b5cf6',
      '--card': '#18181b',
      '--border': '#27272a',
    };
    return aliases[varName];
  }

  String _hex8(int value) => value.toRadixString(16).padLeft(2, '0');

  String _dartString(String text) {
    final escaped = text
        .replaceAll(r'\', r'\\')
        .replaceAll("'", r"\'")
        .replaceAll('\n', r'\n')
        .replaceAll(r'$', r'\$');
    return "'$escaped'";
  }

  String _collapseWhitespace(String text) =>
      text.replaceAll(RegExp(r'\s+'), ' ').trim();

  String _indent(int level) => '  ' * level;
}
