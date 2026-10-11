import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/theme.dart';
import '../../domain/dom_tree.dart';
import '../provider/canvas_provider.dart';

/// Layers panel ala Figma: tree DOM hasil generate, hover/klik sinkron
/// dengan canvas lewat [CanvasNotifier].
class LayersPanel extends ConsumerStatefulWidget {
  const LayersPanel({super.key});

  @override
  ConsumerState<LayersPanel> createState() => _LayersPanelState();
}

class _LayersPanelState extends ConsumerState<LayersPanel> {
  final _expanded = <String>{'root'};
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  static const double _rowHeight = 22;

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      if (!_expanded.add(id)) _expanded.remove(id);
    });
  }

  void _select(DomNode node) {
    ref.read(canvasProvider.notifier).selectNode(node.id);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final tree = ref.watch(canvasProvider.select((s) => s.domTree));
    final selectedId = ref.watch(canvasProvider.select((s) => s.selectedNodeId));
    final hoveredId = ref.watch(canvasProvider.select((s) => s.hoveredNodeId));

    if (tree == null) {
      return const _LayersEmptyState();
    }

    // Naikkan (auto-expand) ancestor node terpilih agar selalu terlihat.
    if (selectedId != null) {
      for (final node in tree.selectableNodes) {
        if (_containsAncestor(node, selectedId)) _expanded.add(node.id);
      }
    }

    final flat = _flatten(tree.root);

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) => _handleKey(event, flat, selectedId),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LayersHeader(nodeCount: tree.nodeCount),
          Expanded(
            child: flat.isEmpty
                ? const _LayersEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    itemCount: flat.length,
                    itemExtent: _rowHeight,
                    itemBuilder: (context, index) {
                      final entry = flat[index];
                      return _LayerRow(
                        entry: entry,
                        selected: entry.node.id == selectedId,
                        hovered: entry.node.id == hoveredId,
                        expanded: _expanded.contains(entry.node.id),
                        onTap: () => _select(entry.node),
                        onToggle: () => _toggle(entry.node.id),
                        onHover: (value) => ref
                            .read(canvasProvider.notifier)
                            .hoverNode(value ? entry.node.id : null),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  bool _containsAncestor(DomNode node, String targetId) {
    for (final child in node.children) {
      if (child.id == targetId) return true;
      if (_containsAncestor(child, targetId)) return true;
    }
    return false;
  }

  List<_FlatEntry> _flatten(DomNode root) {
    final out = <_FlatEntry>[];
    void visit(DomNode node, int indent) {
      out.add(_FlatEntry(node: node, indent: indent));
      if (_expanded.contains(node.id)) {
        for (final child in node.children) {
          visit(child, indent + 1);
        }
      }
    }

    visit(root, 0);
    return out;
  }

  /// Keyboard nav ala Figma/VS Code: panah atas/bawah pindah baris,
  /// kanan buka node, kiri tutup node, Esc lepas pilihan.
  KeyEventResult _handleKey(
    KeyEvent event,
    List<_FlatEntry> flat,
    String? selectedId,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final notifier = ref.read(canvasProvider.notifier);

    if (key == LogicalKeyboardKey.escape) {
      notifier.selectNode(null);
      return KeyEventResult.handled;
    }
    if (flat.isEmpty) return KeyEventResult.ignored;

    final index = flat.indexWhere((e) => e.node.id == selectedId);
    final currentIndex = index < 0 ? 0 : index;
    final current = flat[currentIndex];

    if (key == LogicalKeyboardKey.arrowDown) {
      final next = flat[(currentIndex + 1).clamp(0, flat.length - 1)];
      notifier.selectNode(next.node.id);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      final prev = flat[(currentIndex - 1).clamp(0, flat.length - 1)];
      notifier.selectNode(prev.node.id);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      if (current.node.hasChildren && !_expanded.contains(current.node.id)) {
        _toggle(current.node.id);
      } else if (current.node.hasChildren) {
        notifier.selectNode(current.node.children.first.id);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      if (_expanded.contains(current.node.id) && current.node.hasChildren) {
        _toggle(current.node.id);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}

class _FlatEntry {
  const _FlatEntry({required this.node, required this.indent});

  final DomNode node;
  final int indent;
}

class _LayersHeader extends StatelessWidget {
  const _LayersHeader({required this.nodeCount});

  final int nodeCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.only(left: 12, right: 8),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          const Expanded(child: Text('LAYERS', style: AppText.sectionHeader)),
          Text('$nodeCount', style: AppText.caption),
        ],
      ),
    );
  }
}

class _LayersEmptyState extends StatelessWidget {
  const _LayersEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Text(
        'Belum ada layer.\nGenerate UI untuk melihat struktur elemennya di sini.',
        style: AppText.caption,
      ),
    );
  }
}

class _LayerRow extends StatefulWidget {
  const _LayerRow({
    required this.entry,
    required this.selected,
    required this.hovered,
    required this.expanded,
    required this.onTap,
    required this.onToggle,
    required this.onHover,
  });

  final _FlatEntry entry;
  final bool selected;
  final bool hovered;
  final bool expanded;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final ValueChanged<bool> onHover;

  @override
  State<_LayerRow> createState() => _LayerRowState();
}

class _LayerRowState extends State<_LayerRow> {
  @override
  Widget build(BuildContext context) {
    final node = widget.entry.node;
    final background = widget.selected
        ? AppColors.selectionBg
        : widget.hovered
        ? AppColors.hoverBg
        : Colors.transparent;

    final foreground = widget.selected
        ? Colors.white
        : node.isText
        ? AppColors.textDisabled
        : AppColors.textPrimary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => widget.onHover(true),
      onExit: (_) => widget.onHover(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          color: background,
          padding: EdgeInsets.only(
            left: 8 + widget.entry.indent * 12,
            right: 8,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 14,
                height: 22,
                child: node.hasChildren
                    ? InkWell(
                        onTap: widget.onToggle,
                        child: Icon(
                          widget.expanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                          size: 14,
                          color: foreground,
                        ),
                      )
                    : null,
              ),
              Icon(_iconFor(node), size: 12, color: foreground),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  node.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: node.isText
                        ? AppFonts.monoFamily
                        : AppFonts.uiFamily,
                    fontFamilyFallback: node.isText
                        ? AppFonts.monoFallback
                        : AppFonts.uiFallback,
                    fontSize: 11,
                    fontStyle: node.isText ? FontStyle.italic : FontStyle.normal,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ikon per tag, mirip glyph layers Figma untuk mempermudah scan visual.
IconData _iconFor(DomNode node) {
  if (node.isText) return Icons.text_fields;
  switch (node.tag) {
    case 'frame':
    case 'html':
    case 'body':
      return Icons.crop_square;
    case 'div':
    case 'section':
    case 'main':
    case 'article':
    case 'aside':
    case 'header':
    case 'footer':
    case 'nav':
      return Icons.crop_square_outlined;
    case 'h1':
    case 'h2':
    case 'h3':
    case 'h4':
    case 'h5':
    case 'h6':
      return Icons.title;
    case 'p':
    case 'span':
    case 'label':
    case 'strong':
    case 'em':
    case 'small':
      return Icons.notes;
    case 'a':
      return Icons.link;
    case 'button':
      return Icons.smart_button_outlined;
    case 'input':
    case 'textarea':
    case 'select':
    case 'form':
      return Icons.input;
    case 'img':
    case 'picture':
    case 'figure':
      return Icons.image_outlined;
    case 'ul':
    case 'ol':
      return Icons.format_list_bulleted;
    case 'li':
      return Icons.chevron_right;
    case 'table':
    case 'thead':
    case 'tbody':
    case 'tr':
      return Icons.grid_on;
    case 'td':
    case 'th':
      return Icons.crop_16_9;
    default:
      return Icons.crop_square_outlined;
  }
}
