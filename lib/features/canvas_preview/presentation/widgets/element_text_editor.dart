import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/config/app_palette.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/l10n/l10n.dart';

/// Editor teks inline yang ditumpuk tepat di atas teks elemen di kanvas.
///
/// `webview_windows` tidak meneruskan keyboard ke DOM, jadi edit teks
/// dilakukan TextField Flutter: JS menyembunyikan teks asli (transparan)
/// selama editor terbuka, lalu host menulis ulang `textContent` saat Simpan.
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
  /// teks di editor terlihat sama dengan teks aslinya.
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
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
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
    final isCtrl =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    if (isCtrl && event.logicalKey == LogicalKeyboardKey.enter) {
      _save();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final size = _px(widget.styles['fontSize']) ?? 14;
    final height = _lineHeight(widget.styles['lineHeight'], size);

    return Focus(
      onKeyEvent: _onKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kotak edit digambar JS di dalam halaman (menempel persis pada
          // teks asli); di sini hanya caret + input yang tak terlihat.
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLines: null,
            cursorColor: palette.primary,
            cursorWidth: 2,
            textAlign: _textAlign(widget.styles['textAlign']),
            style: TextStyle(
              fontFamily: AppFonts.uiFamily,
              fontFamilyFallback: AppFonts.uiFallback,
              fontSize: size,
              height: height,
              fontWeight: _weight(widget.styles['fontWeight']),
              // Teks yang terlihat adalah teks asli di DOM (ikut reflow).
              // TextField hanya menyediakan caret + penanganan input.
              color: Colors.transparent,
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
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _EditorAction(
                icon: Icons.check_rounded,
                tooltip: l10n.commonSave,
                background: palette.primary,
                foreground: palette.onPrimary,
                onTap: _save,
              ),
              const SizedBox(width: 4),
              _EditorAction(
                icon: Icons.close_rounded,
                tooltip: l10n.commonCancel,
                background: palette.bgElevated,
                foreground: palette.textSecondary,
                onTap: widget.onCancel,
              ),
            ],
          ),
        ],
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
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(6),
              boxShadow: palette.shadowRaised,
            ),
            child: Icon(icon, size: 13, color: foreground),
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
