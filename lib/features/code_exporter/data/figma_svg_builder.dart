/// Ubah payload `centauri-figma` (hasil serialisasi DOM halaman) menjadi SVG
/// murni yang bisa langsung ditempel di board Figma.
///
/// Berbeda dengan ekspor SVG bawaan (HTML dibungkus `foreignObject`, tidak
/// didukung Figma), SVG di sini hanya memakai primitif yang dipahami Figma:
///  - `<g>` per elemen → group/frame bersarang,
///  - `<rect>` → latar + border,
///  - `<text>` → text layer yang masih bisa diedit,
///  - `<image>` → gambar (disalin sebagai data URL agar mandiri).
library;

/// Warna CSS + alpha-nya.
class _Rgba {
  const _Rgba(this.hex, this.alpha);

  final String hex;
  final double alpha;
}

/// Membangun SVG dari payload DOM.
class FigmaSvgBuilder {
  const FigmaSvgBuilder();

  /// Bangun SVG lengkap untuk satu halaman.
  String build(Map<String, dynamic> payload) {
    final page = payload['page'] is Map
        ? Map<String, dynamic>.from(payload['page'] as Map)
        : const <String, dynamic>{};
    final width = _num(page['width'], 1440);
    final height = _num(page['height'], 2000);

    final out = StringBuffer();
    out.write(
      '<svg xmlns="http://www.w3.org/2000/svg" '
      'xmlns:xlink="http://www.w3.org/1999/xlink" '
      'width="${_n(width)}" height="${_n(height)}" '
      'viewBox="0 0 ${_n(width)} ${_n(height)}">',
    );

    final background = _color(page['background'] as String?);
    if (background != null) {
      out.write(
        '<rect x="0" y="0" width="${_n(width)}" height="${_n(height)}" '
        'fill="${background.hex}"/>',
      );
    }

    final nodes = payload['nodes'];
    if (nodes is List) {
      for (final node in nodes) {
        out.write(_node(node));
      }
    }

    out.write('</svg>');
    return out.toString();
  }

  String _node(dynamic raw) {
    if (raw is! Map) return '';
    final node = Map<String, dynamic>.from(raw);
    final styles = node['styles'] is Map
        ? Map<String, dynamic>.from(node['styles'] as Map)
        : const <String, dynamic>{};

    final display = (styles['display'] as String? ?? '').toLowerCase();
    if (display == 'none') return '';
    final visibility = (styles['visibility'] as String? ?? '').toLowerCase();
    if (visibility == 'hidden') return '';

    final rect = node['rect'] is Map
        ? Map<String, dynamic>.from(node['rect'] as Map)
        : const <String, dynamic>{};
    final x = _num(rect['x'], 0);
    final y = _num(rect['y'], 0);
    final w = _num(rect['w'], 0);
    final h = _num(rect['h'], 0);
    final opacity = _opacity(styles['opacity']);
    if (opacity <= 0) return '';

    final out = StringBuffer();
    final name = _escape((node['name'] as String? ?? 'layer').trim());
    out.write('<g data-name="$name"');
    if (opacity < 1) out.write(' opacity="${_n(opacity)}"');
    out.write('>');

    final radius = _radius(styles['borderRadius'] as String?);
    final background = _color(styles['backgroundColor'] as String?);
    if (background != null && w > 0 && h > 0) {
      out.write(
        '<rect x="${_n(x)}" y="${_n(y)}" width="${_n(w)}" height="${_n(h)}" '
        'fill="${background.hex}"',
      );
      if (background.alpha < 1) {
        out.write(' fill-opacity="${_n(background.alpha)}"');
      }
      if (radius > 0) out.write(' rx="${_n(radius)}" ry="${_n(radius)}"');
      out.write('/>');
    }

    final borderWidth = _px(styles['borderWidth'] as String?);
    final borderColor = _color(styles['borderColor'] as String?);
    final borderStyle = (styles['borderStyle'] as String? ?? 'solid')
        .toLowerCase();
    if (borderWidth != null &&
        borderWidth > 0 &&
        borderColor != null &&
        borderStyle != 'none' &&
        borderStyle != 'hidden' &&
        w > 0 &&
        h > 0) {
      out.write(
        '<rect x="${_n(x)}" y="${_n(y)}" width="${_n(w)}" height="${_n(h)}" '
        'fill="none" stroke="${borderColor.hex}" '
        'stroke-width="${_n(borderWidth)}"',
      );
      if (borderColor.alpha < 1) {
        out.write(' stroke-opacity="${_n(borderColor.alpha)}"');
      }
      if (radius > 0) out.write(' rx="${_n(radius)}" ry="${_n(radius)}"');
      out.write('/>');
    }

    // Bentuk dekoratif dari pseudo-element (`::before`/`::after`).
    final pseudos = node['pseudos'];
    if (pseudos is List) {
      for (final pseudo in pseudos) {
        if (pseudo is Map) {
          out.write(_pseudo(Map<String, dynamic>.from(pseudo)));
        }
      }
    }

    // Gambar latar (background-image).
    final bgImage = _url(styles['backgroundImage'] as String?);
    if (bgImage != null && w > 0 && h > 0) {
      out.write(
        '<image href="${_escape(bgImage)}" xlink:href="${_escape(bgImage)}" '
        'x="${_n(x)}" y="${_n(y)}" width="${_n(w)}" height="${_n(h)}" '
        'preserveAspectRatio="xMidYMid slice"/>',
      );
    }

    // Gambar <img>.
    final image = node['image'];
    if (image is Map && w > 0 && h > 0) {
      final src = image['src'] as String? ?? '';
      if (src.isNotEmpty) {
        final escaped = _escape(src);
        out.write(
          '<image href="$escaped" xlink:href="$escaped" '
          'x="${_n(x)}" y="${_n(y)}" width="${_n(w)}" height="${_n(h)}" '
          'preserveAspectRatio="${_fit(styles['objectFit'] as String?)}"/>',
        );
      }
    }

    // SVG inline (ikon) → disisipkan apa adanya, digeser ke posisinya.
    // `color` ikut dipasang supaya `currentColor` di dalam SVG ikon memakai
    // warna teks elemen aslinya; tanpa itu ikon jadi hitam di atas latar
    // gelap.
    final inlineSvg = node['svg'] as String? ?? '';
    if (inlineSvg.isNotEmpty) {
      final ink = _color(styles['color'] as String?);
      out.write(
        '<g transform="translate(${_n(x)},${_n(y)})"'
        '${ink != null ? ' color="${ink.hex}"' : ''}>$inlineSvg</g>',
      );
    }

    out.write(_text(node, styles));
    out.write(_field(node));

    final children = node['children'];
    if (children is List) {
      for (final child in children) {
        out.write(_node(child));
      }
    }

    out.write('</g>');
    return out.toString();
  }

  /// Layer teks: satu `<text>` per baris visual.
  String _text(Map<String, dynamic> node, Map<String, dynamic> styles) {
    final lines = node['textLines'];
    if (lines is! List || lines.isEmpty) return '';

    final size = _px(styles['fontSize'] as String?) ?? 16;
    final color =
        _color(styles['color'] as String?) ?? const _Rgba('#000000', 1);
    final weight = _weight(styles['fontWeight'] as String?);
    final family = _fontFamily(styles['fontFamily'] as String?);
    final align = (styles['textAlign'] as String? ?? 'left').toLowerCase();
    final spacing = _px(styles['letterSpacing'] as String?);

    final out = StringBuffer();
    for (final raw in lines) {
      if (raw is! Map) continue;
      final line = Map<String, dynamic>.from(raw);
      final content = (line['text'] as String? ?? '').trim();
      if (content.isEmpty) continue;

      final lx = _num(line['x'], 0);
      final lw = _num(line['w'], 0);
      final baseline = line['baseline'] != null
          ? _num(line['baseline'], 0)
          : _num(line['y'], 0) + size * 0.94;

      var anchor = 'start';
      var tx = lx;
      if (align == 'center') {
        anchor = 'middle';
        tx = lx + lw / 2;
      } else if (align == 'right' || align == 'end') {
        anchor = 'end';
        tx = lx + lw;
      }

      out.write(
        '<text x="${_n(tx)}" y="${_n(baseline)}" '
        'font-family="${_escape(family)}" font-size="${_n(size)}" '
        'font-weight="$weight" fill="${color.hex}"',
      );
      if (color.alpha < 1) {
        out.write(' fill-opacity="${_n(color.alpha)}"');
      }
      if (anchor != 'start') out.write(' text-anchor="$anchor"');
      if (spacing != null && spacing != 0) {
        out.write(' letter-spacing="${_n(spacing)}"');
      }
      out.write('>${_escape(content)}</text>');
    }
    return out.toString();
  }

  /// Bentuk dekoratif dari pseudo-element (bingkai lingkaran, garis, dsb.).
  String _pseudo(Map<String, dynamic> pseudo) {
    final x = _num(pseudo['x'], 0);
    final y = _num(pseudo['y'], 0);
    final w = _num(pseudo['w'], 0);
    final h = _num(pseudo['h'], 0);
    if (w <= 0 || h <= 0) return '';

    final radius = pseudo['radius'] as String? ?? '0px';
    final fill = _color(pseudo['fill'] as String?);
    final stroke = _color(pseudo['stroke'] as String?);
    final strokeWidth = _num(pseudo['strokeWidth'], 0);

    final out = StringBuffer();
    if (radius.contains('50%')) {
      out.write(
        '<ellipse cx="${_n(x + w / 2)}" cy="${_n(y + h / 2)}" '
        'rx="${_n(w / 2)}" ry="${_n(h / 2)}"',
      );
    } else {
      final r = _radius(radius);
      out.write(
        '<rect x="${_n(x)}" y="${_n(y)}" width="${_n(w)}" height="${_n(h)}"',
      );
      if (r > 0) out.write(' rx="${_n(r)}" ry="${_n(r)}"');
    }
    if (fill != null) {
      out.write(' fill="${fill.hex}"');
      if (fill.alpha < 1) out.write(' fill-opacity="${_n(fill.alpha)}"');
    } else {
      out.write(' fill="none"');
    }
    if (stroke != null && strokeWidth > 0) {
      out.write(' stroke="${stroke.hex}" stroke-width="${_n(strokeWidth)}"');
      if (stroke.alpha < 1) out.write(' stroke-opacity="${_n(stroke.alpha)}"');
    }
    out.write('/>');
    return out.toString();
  }

  /// Placeholder/nilai input → text layer (di Figma placeholder tidak ikut
  /// karena bukan text node).
  String _field(Map<String, dynamic> node) {
    final field = node['field'];
    if (field is! Map) return '';
    final data = Map<String, dynamic>.from(field);
    final text = (data['text'] as String? ?? '').trim();
    if (text.isEmpty) return '';

    final color = _color(data['color'] as String?) ?? const _Rgba('#000000', 1);
    final size = _num(data['fontSize'], 14);
    final weight = _weight(data['fontWeight'] as String?);
    final family = _fontFamily(data['fontFamily'] as String?);
    final x = _num(data['x'], 0);
    final baseline = _num(data['baseline'], 0);

    final out = StringBuffer();
    out.write(
      '<text x="${_n(x)}" y="${_n(baseline)}" '
      'font-family="${_escape(family)}" font-size="${_n(size)}" '
      'font-weight="$weight" fill="${color.hex}"',
    );
    if (color.alpha < 1) out.write(' fill-opacity="${_n(color.alpha)}"');
    out.write('>${_escape(text)}</text>');
    return out.toString();
  }

  // ------------------------------------------------------------- parsing --

  static double _num(Object? value, double fallback) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  static String _n(double value) {
    if (!value.isFinite) return '0';
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.01) return rounded.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  /// Ambil angka px pertama dari nilai CSS ("12px 8px" → 12).
  static double? _px(String? value) {
    if (value == null) return null;
    final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(value);
    if (match == null) return null;
    return double.tryParse(match.group(0)!);
  }

  static double _opacity(Object? value) {
    if (value is num) return value.toDouble().clamp(0.0, 1.0);
    if (value is String) {
      final parsed = double.tryParse(value.trim());
      if (parsed != null) return parsed.clamp(0.0, 1.0);
    }
    return 1;
  }

  /// Jari-jari border; sudut berbeda disederhanakan jadi nilai pertama.
  static double _radius(String? value) {
    if (value == null) return 0;
    final parts = value
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 0;
    final first = _px(parts.first);
    if (first == null) return 0;
    // Nilai berbeda per sudut: pakai yang terbesar agar tidak terpotong.
    var max = first;
    for (final part in parts) {
      final parsed = _px(part);
      if (parsed != null && parsed > max) max = parsed;
    }
    return max;
  }

  static String _weight(String? value) {
    final raw = (value ?? '400').trim().toLowerCase();
    if (raw == 'normal') return '400';
    if (raw == 'bold') return '700';
    final parsed = int.tryParse(raw);
    if (parsed != null) return parsed.toString();
    if (raw == 'lighter') return '300';
    if (raw == 'bolder') return '700';
    return '400';
  }

  /// Pemetaan `object-fit` ke `preserveAspectRatio` SVG.
  static String _fit(String? objectFit) {
    switch ((objectFit ?? '').toLowerCase()) {
      case 'contain':
      case 'scale-down':
        return 'xMidYMid meet';
      case 'fill':
      case 'none':
        return 'none';
      default:
        return 'xMidYMid slice';
    }
  }

  /// Nama keluarga font pertama; generic dipetakan ke Inter.
  static String _fontFamily(String? value) {
    if (value == null || value.trim().isEmpty) return 'Inter';
    final first = value
        .split(',')
        .first
        .trim()
        .replaceAll('"', '')
        .replaceAll("'", '');
    if (first.isEmpty) return 'Inter';
    const generics = {
      'sans-serif',
      'serif',
      'monospace',
      'cursive',
      'fantasy',
      'system-ui',
      'ui-sans-serif',
      'ui-serif',
    };
    if (generics.contains(first.toLowerCase())) return 'Inter';
    return first;
  }

  /// Ambil URL dari `url("...")`.
  static String? _url(String? value) {
    if (value == null || value.isEmpty) return null;
    final match = RegExp(
      r"""url\(\s*["']?([^"')]+)["']?\s*\)""",
      caseSensitive: false,
    ).firstMatch(value);
    if (match == null) return null;
    final url = match.group(1)!.trim();
    if (url.isEmpty || url == 'none') return null;
    return url;
  }

  /// Ubah warna CSS (rgb/rgba/hex/nama dasar) jadi hex + alpha.
  static _Rgba? _color(String? value) {
    if (value == null) return null;
    final raw = value.trim().toLowerCase();
    if (raw.isEmpty || raw == 'transparent' || raw == 'none') return null;

    final rgb = RegExp(
      r'rgba?\(\s*([\d.]+)[,\s]+([\d.]+)[,\s]+([\d.]+)(?:[,\s/]+([\d.%]+))?\s*\)',
    ).firstMatch(raw);
    if (rgb != null) {
      final r = _channel(rgb.group(1)!);
      final g = _channel(rgb.group(2)!);
      final b = _channel(rgb.group(3)!);
      final alphaRaw = rgb.group(4);
      final alpha = alphaRaw == null
          ? 1.0
          : alphaRaw.endsWith('%')
          ? double.tryParse(alphaRaw.substring(0, alphaRaw.length - 1))! / 100
          : (double.tryParse(alphaRaw) ?? 1);
      return _Rgba(_hex(r, g, b), alpha.clamp(0.0, 1.0));
    }

    if (raw.startsWith('#')) {
      final hex = raw.substring(1);
      if (hex.length == 3) {
        final r = hex[0], g = hex[1], b = hex[2];
        return _Rgba('#$r$r$g$g$b$b'.toUpperCase(), 1);
      }
      if (hex.length == 6 || hex.length == 8) {
        if (hex.length == 8) {
          final alpha = int.parse(hex.substring(6), radix: 16) / 255;
          return _Rgba('#${hex.substring(0, 6).toUpperCase()}', alpha);
        }
        return _Rgba('#${hex.toUpperCase()}', 1);
      }
      return null;
    }

    const named = <String, int>{
      'black': 0x000000,
      'white': 0xFFFFFF,
      'red': 0xFF0000,
      'green': 0x008000,
      'blue': 0x0000FF,
      'yellow': 0xFFFF00,
      'orange': 0xFFA500,
      'purple': 0x800080,
      'gray': 0x808080,
      'grey': 0x808080,
      'silver': 0xC0C0C0,
      'maroon': 0x800000,
      'olive': 0x808000,
      'lime': 0x00FF00,
      'aqua': 0x00FFFF,
      'cyan': 0x00FFFF,
      'teal': 0x008080,
      'navy': 0x000080,
      'fuchsia': 0xFF00FF,
      'magenta': 0xFF00FF,
    };
    final value32 = named[raw];
    if (value32 == null) return null;
    final r = (value32 >> 16) & 0xFF;
    final g = (value32 >> 8) & 0xFF;
    final b = value32 & 0xFF;
    return _Rgba(_hex(r, g, b), 1);
  }

  static int _channel(String value) {
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 0;
    return parsed.round().clamp(0, 255);
  }

  static String _hex(int r, int g, int b) =>
      '#${_pair(r)}${_pair(g)}${_pair(b)}';

  static String _pair(int value) =>
      value.toRadixString(16).padLeft(2, '0').toUpperCase();

  static String _escape(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      switch (rune) {
        case 0x26:
          buffer.write('&amp;');
        case 0x3C:
          buffer.write('&lt;');
        case 0x3E:
          buffer.write('&gt;');
        case 0x22:
          buffer.write('&quot;');
        case 0x27:
          buffer.write('&apos;');
        default:
          buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }
}
