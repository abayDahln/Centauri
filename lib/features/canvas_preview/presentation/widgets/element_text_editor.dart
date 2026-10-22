import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/config/app_palette.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/l10n/l10n.dart';

/// Kartu edit teks yang mengambang tepat di atas elemen kanvas.
///
/// `webview_windows` tidak meneruskan keyboard ke DOM, jadi input ditangani
/// TextField Flutter di dalam kartu ini. Setiap ketikan tetap ditulis ke DOM
/// lewat [onChanged] supaya ukuran dan layout komponen ikut berubah live.
class ElementTextEditor extends StatefulWidget {
  const ElementTextEditor({
    super.key,
    required this.initialText,
    required this.styles,
    required this.onSave,
    required this.onCancel,
    this.onChanged,
  });

  final String initialText;

  /// Subset `getComputedStyle` elemen (fontSize, fontWeight, color, ...) agar
  /// teks di kartu terlihat sama dengan teks aslinya.
  final Map<String, String> styles;

  final ValueChanged<String> onSave;
  final VoidCallback onCancel;

  /// Dipanggil setiap ketikan: host menulisnya ke DOM agar ukuran/layout
  /// komponen ikut berubah real-time.
  final ValueChanged<String>? onChanged;

  @override
  State<ElementTextEditor> createState() => _ElementTextEditorState();
}

class _ElementTextEditorState extends State<ElementTextEditor> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );
  final FocusNode _focusNode = FocusNode();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Karet di akhir teks, bukan select-all.
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _save() {
    if (_saving) return;
    _saving = true;
    widget.onSave(_controller.text.trim());
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onCancel();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      // Shift+Enter menyisipkan baris baru untuk teks multi-baris.
      if (HardwareKeyboard.instance.isShiftPressed) {
        return KeyEventResult.ignored;
      }
      _save();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final size = _px(widget.styles['fontSize']) ?? 14.0;
    final height = _lineHeight(widget.styles['lineHeight'], size);
    final weight = _weight(widget.styles['fontWeight']);
    final textAlign = _textAlign(widget.styles['textAlign']);
    final family = _fontFamily(widget.styles['fontFamily']);
    final color = _cssColor(widget.styles['color']) ?? palette.textPrimary;

    return Focus(
      onKeyEvent: _onKey,
      child: Container(
        decoration: BoxDecoration(
          color: palette.bgElevated,
          borderRadius: AppRadius.md,
          border: Border.all(color: palette.borderSubtle),
          boxShadow: palette.shadowRaised,
        ),
        padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              minLines: 1,
              maxLines: 5,
              cursorColor: palette.primary,
              cursorWidth: 2,
              textAlign: textAlign,
              style: TextStyle(
                fontFamily: family,
                fontFamilyFallback: AppFonts.uiFallback,
                fontSize: size,
                height: height,
                fontWeight: weight,
                color: color,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                filled: false,
              ),
              onTapOutside: (_) {},
              onChanged: widget.onChanged,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _EditorAction(
                  icon: Icons.close_rounded,
                  tooltip: l10n.commonCancel,
                  background: palette.bgSurface,
                  foreground: palette.textSecondary,
                  onTap: widget.onCancel,
                ),
                const SizedBox(width: 6),
                _EditorAction(
                  icon: Icons.check_rounded,
                  tooltip: l10n.commonSave,
                  background: palette.primary,
                  foreground: palette.onPrimary,
                  onTap: _save,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorAction extends StatelessWidget {
  const _EditorAction({
    required this.icon,
    required this.tooltip,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: background,
              borderRadius: AppRadius.sm,
              border: Border.all(color: palette.borderSubtle),
            ),
            child: Icon(icon, size: 14, color: foreground),
          ),
        ),
      ),
    );
  }
}

double? _px(String? raw) {
  if (raw == null) return null;
  final value = double.tryParse(raw.replaceAll('px', '').trim());
  if (value == null || value <= 0) return null;
  return value.clamp(8, 96);
}

/// Nama font pertama dari `getComputedStyle().fontFamily`.
String _fontFamily(String? raw) {
  if (raw == null || raw.isEmpty) return AppFonts.uiFamily;
  final first = raw
      .split(',')
      .first
      .trim()
      .replaceAll('"', '')
      .replaceAll("'", '');
  if (first.isEmpty || first == 'inherit' || first == 'initial') {
    return AppFonts.uiFamily;
  }
  return first;
}

/// `rgb(r, g, b)` / `rgba(r, g, b, a)` / `#RRGGBB` → [Color].
Color? _cssColor(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final value = raw.trim();
  if (value.startsWith('#')) {
    final hex = value.substring(1);
    if (hex.length != 6) return null;
    final parsed = int.tryParse(hex, radix: 16);
    return parsed == null ? null : Color(0xFF000000 | parsed);
  }
  final match = RegExp(r'rgba?\(([\d.]+)[,\s]+([\d.]+)[,\s]+([\d.]+)')
      .firstMatch(value);
  if (match == null) return null;
  int channel(String raw) => double.tryParse(raw)?.round().clamp(0, 255) ?? 0;
  return Color.fromARGB(
    255,
    channel(match.group(1)!),
    channel(match.group(2)!),
    channel(match.group(3)!),
  );
}

double _lineHeight(String? raw, double fontSize) {
  if (raw == null || raw.isEmpty || raw == 'normal') return 1.25;
  final value = double.tryParse(raw.replaceAll('px', '').trim());
  if (value == null || value <= 0) return 1.25;
  return (value / fontSize).clamp(0.9, 2.4);
}

FontWeight _weight(String? raw) {
  final value = int.tryParse(raw ?? '');
  if (value == null) return FontWeight.w400;
  return switch (value) {
    <= 300 => FontWeight.w300,
    <= 400 => FontWeight.w400,
    <= 500 => FontWeight.w500,
    <= 600 => FontWeight.w600,
    <= 700 => FontWeight.w700,
    <= 800 => FontWeight.w800,
    _ => FontWeight.w900,
  };
}

TextAlign _textAlign(String? raw) {
  return switch (raw) {
    'center' => TextAlign.center,
    'right' || 'end' => TextAlign.end,
    _ => TextAlign.start,
  };
}
