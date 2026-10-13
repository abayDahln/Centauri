import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/theme.dart';
import '../../data/services/canvas_service_registry.dart';
import '../provider/canvas_provider.dart';

/// Inspector Panel native (Fase 2).
/// Baca: `NodeGeometry.styles` (computed + inline) dari JS bridge.
/// Tulis: `applyNodeStyle` → inline style di DOM. HTML tetap source of truth.
class InspectorPanel extends ConsumerWidget {
  const InspectorPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFrameId = ref.watch(
      canvasProvider.select((s) => s.activeFrameId),
    );
    final nodeId = ref.watch(
      canvasProvider.select((s) => s.selectedNodeId),
    );
    final geometry = ref.watch(
      canvasProvider.select((s) => s.selectedNodeGeometry),
    );

    if (activeFrameId == null || nodeId == null) {
      return const _InspectorEmpty(
        text: 'Pilih elemen di canvas atau layers untuk mengedit gayanya.',
      );
    }
    if (geometry == null) {
      return const _InspectorEmpty(text: 'Membaca gaya elemen…');
    }

    Future<void> apply(Map<String, String> patch) async {
      final service = CanvasServiceRegistry.forFrame(activeFrameId);
      if (service == null) return;
      await service.applyNodeStyle(nodeId, patch);
      // Minta geometri terbaru agar overlay + inspector sinkron.
      await service.requestNodeGeometry(nodeId);
    }

    final styles = geometry.styles;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      children: [
        _Header(geometryTag: geometry.tag, nodeId: nodeId),
        _SizeReadout(geometry: geometry),
        _OpacitySection(
          value: _parseOpacity(styles['opacity']),
          onChanged: (v) => apply({'opacity': v.toStringAsFixed(2)}),
        ),
        _FillSection(
          background: styles['backgroundColor'] ?? '',
          color: styles['color'] ?? '',
          onApply: apply,
        ),
        _TypographySection(
          fontSize: _parsePx(styles['fontSize'], fallback: 14),
          fontWeight: styles['fontWeight'] ?? '',
          textAlign: styles['textAlign'] ?? '',
          onApply: apply,
        ),
        _BorderSection(
          radius: _parsePx(styles['borderRadius'], fallback: 0),
          borderWidth: _parsePx(styles['borderWidth'], fallback: 0),
          borderColor: styles['borderColor'] ?? '',
          onApply: apply,
        ),
        _SpacingSection(
          padding: _parsePx(styles['paddingTop'], fallback: 0),
          onApply: apply,
        ),
        _SizeEditorSection(
          width: geometry.width,
          height: geometry.height,
          onApply: (w, h) async {
            final service = CanvasServiceRegistry.forFrame(activeFrameId);
            if (service == null) return;
            await service.moveResizeNode(
              nodeId,
              width: w,
              height: h,
            );
            await service.requestNodeGeometry(nodeId);
          },
        ),
      ],
    );
  }
}

class _InspectorEmpty extends StatelessWidget {
  const _InspectorEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Text(text, style: AppText.caption),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.geometryTag, required this.nodeId});

  final String geometryTag;
  final String nodeId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Inspector', style: AppText.sectionTitle),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                geometryTag.isEmpty ? 'node' : geometryTag,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentPrimary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                nodeId,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _SizeReadout extends StatelessWidget {
  const _SizeReadout({required this.geometry});

  final dynamic geometry;

  @override
  Widget build(BuildContext context) {
    final w = (geometry.width as double).toStringAsFixed(0);
    final h = (geometry.height as double).toStringAsFixed(0);
    final x = (geometry.x as double).toStringAsFixed(0);
    final y = (geometry.y as double).toStringAsFixed(0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        '$w × $h  •  x:$x y:$y (CSS px)',
        style: AppText.caption,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _OpacitySection extends StatefulWidget {
  const _OpacitySection({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  State<_OpacitySection> createState() => _OpacitySectionState();
}

class _OpacitySectionState extends State<_OpacitySection> {
  late double _v;

  @override
  void initState() {
    super.initState();
    _v = widget.value;
  }

  @override
  void didUpdateWidget(covariant _OpacitySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.value - widget.value).abs() > 0.001) _v = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('OPACITY'),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _v.clamp(0.0, 1.0),
                min: 0,
                max: 1,
                divisions: 20,
                label: '${(_v * 100).round()}%',
                onChanged: (v) => setState(() => _v = v),
                onChangeEnd: widget.onChanged,
              ),
            ),
            SizedBox(
              width: 48,
              child: Text(
                '${(_v * 100).round()}%',
                textAlign: TextAlign.right,
                style: AppText.uiSmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FillSection extends StatelessWidget {
  const _FillSection({
    required this.background,
    required this.color,
    required this.onApply,
  });

  final String background;
  final String color;
  final Future<void> Function(Map<String, String>) onApply;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('FILL & TEXT'),
        _ColorRow(
          label: 'Background',
          cssValue: background,
          onPick: (hex) => onApply({'backgroundColor': hex}),
        ),
        _ColorRow(
          label: 'Text',
          cssValue: color,
          onPick: (hex) => onApply({'color': hex}),
        ),
      ],
    );
  }
}

class _TypographySection extends StatelessWidget {
  const _TypographySection({
    required this.fontSize,
    required this.fontWeight,
    required this.textAlign,
    required this.onApply,
  });

  final double fontSize;
  final String fontWeight;
  final String textAlign;
  final Future<void> Function(Map<String, String>) onApply;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('TYPOGRAPHY'),
        Row(
          children: [
            Expanded(
              child: Text('Size  ${fontSize.toStringAsFixed(0)}px',
                  style: AppText.uiSmall),
            ),
          ],
        ),
        Slider(
          value: fontSize.clamp(10.0, 48.0),
          min: 10,
          max: 48,
          divisions: 38,
          label: '${fontSize.round()}px',
          onChangeEnd: (v) => onApply({'fontSize': '${v.round()}px'}),
          onChanged: (_) {},
        ),
        Row(
          children: [
            Expanded(
              child: _MiniDropdown(
                value: _normalizeWeight(fontWeight),
                items: const ['400', '500', '600', '700'],
                onChanged: (v) => onApply({'fontWeight': v}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniDropdown(
                value: _normalizeAlign(textAlign),
                items: const ['left', 'center', 'right'],
                onChanged: (v) => onApply({'textAlign': v}),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BorderSection extends StatelessWidget {
  const _BorderSection({
    required this.radius,
    required this.borderWidth,
    required this.borderColor,
    required this.onApply,
  });

  final double radius;
  final double borderWidth;
  final String borderColor;
  final Future<void> Function(Map<String, String>) onApply;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('BORDER'),
        Text('Radius  ${radius.toStringAsFixed(0)}px', style: AppText.uiSmall),
        Slider(
          value: radius.clamp(0.0, 32.0),
          min: 0,
          max: 32,
          divisions: 32,
          label: '${radius.round()}px',
          onChangeEnd: (v) => onApply({'borderRadius': '${v.round()}px'}),
          onChanged: (_) {},
        ),
        Text('Width  ${borderWidth.toStringAsFixed(0)}px',
            style: AppText.uiSmall),
        Slider(
          value: borderWidth.clamp(0.0, 8.0),
          min: 0,
          max: 8,
          divisions: 8,
          label: '${borderWidth.round()}px',
          onChangeEnd: (v) => onApply({
            'borderWidth': '${v.round()}px',
            if (v > 0) 'borderStyle': 'solid',
          }),
          onChanged: (_) {},
        ),
        _ColorRow(
          label: 'Border',
          cssValue: borderColor,
          onPick: (hex) => onApply({'borderColor': hex}),
        ),
      ],
    );
  }
}

class _SpacingSection extends StatelessWidget {
  const _SpacingSection({required this.padding, required this.onApply});

  final double padding;
  final Future<void> Function(Map<String, String>) onApply;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('SPACING'),
        Text('Padding  ${padding.toStringAsFixed(0)}px',
            style: AppText.uiSmall),
        Slider(
          value: padding.clamp(0.0, 48.0),
          min: 0,
          max: 48,
          divisions: 24,
          label: '${padding.round()}px',
          onChangeEnd: (v) => onApply({'padding': '${v.round()}px'}),
          onChanged: (_) {},
        ),
      ],
    );
  }
}

class _SizeEditorSection extends StatefulWidget {
  const _SizeEditorSection({
    required this.width,
    required this.height,
    required this.onApply,
  });

  final double width;
  final double height;
  final Future<void> Function(double?, double?) onApply;

  @override
  State<_SizeEditorSection> createState() => _SizeEditorSectionState();
}

class _SizeEditorSectionState extends State<_SizeEditorSection> {
  late final TextEditingController _w;
  late final TextEditingController _h;

  @override
  void initState() {
    super.initState();
    _w = TextEditingController(text: widget.width.toStringAsFixed(0));
    _h = TextEditingController(text: widget.height.toStringAsFixed(0));
  }

  @override
  void didUpdateWidget(covariant _SizeEditorSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.width - widget.width).abs() > 0.5) {
      _w.text = widget.width.toStringAsFixed(0);
    }
    if ((oldWidget.height - widget.height).abs() > 0.5) {
      _h.text = widget.height.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _w.dispose();
    _h.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('SIZE'),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _w,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'W (px)',
                  isDense: true,
                ),
                onSubmitted: (v) {
                  final w = double.tryParse(v);
                  if (w != null && w >= 24 && w <= 4000) {
                    widget.onApply(w, null);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _h,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'H (px)',
                  isDense: true,
                ),
                onSubmitted: (v) {
                  final h = double.tryParse(v);
                  if (h != null && h >= 16 && h <= 6000) {
                    widget.onApply(null, h);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.label,
    required this.cssValue,
    required this.onPick,
  });

  final String label;
  final String cssValue;
  final ValueChanged<String> onPick;

  static const _swatches = [
    '#3B82F6',
    '#8B5CF6',
    '#22D3EE',
    '#10B981',
    '#F59E0B',
    '#EF4444',
    '#18181B',
    '#FAFAFA',
    'transparent',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 88, child: Text(label, style: AppText.uiSmall)),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: _cssToColor(cssValue),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.borderSubtle),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final hex in _swatches)
                  InkWell(
                    onTap: () => onPick(hex),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _cssToColor(hex),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniDropdown extends StatelessWidget {
  const _MiniDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = items.contains(value) ? value : items.first;
    return DropdownButtonFormField<String>(
      initialValue: current,
      isDense: true,
      items: [
        for (final item in items)
          DropdownMenuItem(value: item, child: Text(item)),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

// --- parsing helpers (CSS → Dart) ---

double _parsePx(String? raw, {required double fallback}) {
  if (raw == null || raw.isEmpty) return fallback;
  final match = RegExp(r'-?\d+(\.\d+)?').firstMatch(raw);
  if (match == null) return fallback;
  return double.tryParse(match.group(0)!) ?? fallback;
}

double _parseOpacity(String? raw) {
  if (raw == null || raw.isEmpty) return 1.0;
  return double.tryParse(raw.trim())?.clamp(0.0, 1.0) ?? 1.0;
}

String _normalizeWeight(String raw) {
  final lower = raw.toLowerCase();
  if (lower.contains('700') || lower.contains('bold')) return '700';
  if (lower.contains('600') || lower.contains('semibold')) return '600';
  if (lower.contains('500') || lower.contains('medium')) return '500';
  return '400';
}

String _normalizeAlign(String raw) {
  final lower = raw.toLowerCase();
  if (lower.contains('center')) return 'center';
  if (lower.contains('right')) return 'right';
  return 'left';
}

Color _cssToColor(String css) {
  final value = css.trim().toLowerCase();
  if (value.isEmpty || value == 'transparent') return Colors.transparent;
  final rgba = RegExp(
    r'rgba?\((\d+)[,\s]+(\d+)[,\s]+(\d+)(?:[,\s/]+([\d.]+))?\)',
  ).firstMatch(value);
  if (rgba != null) {
    final r = int.tryParse(rgba.group(1)!) ?? 0;
    final g = int.tryParse(rgba.group(2)!) ?? 0;
    final b = int.tryParse(rgba.group(3)!) ?? 0;
    final a = double.tryParse(rgba.group(4) ?? '1') ?? 1.0;
    return Color.fromRGBO(r, g, b, a.clamp(0.0, 1.0));
  }
  final hex = RegExp(r'#([0-9a-f]{3,8})').firstMatch(value);
  if (hex != null) {
    var h = hex.group(1)!;
    if (h.length == 3) h = h.split('').map((c) => '$c$c').join();
    if (h.length == 6) h = 'ff$h';
    final intVal = int.tryParse(h, radix: 16);
    if (intVal != null) return Color(intVal);
  }
  return Colors.grey;
}
