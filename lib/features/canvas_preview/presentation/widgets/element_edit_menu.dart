import 'package:flutter/material.dart';

import '../../../../app/config/app_palette.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/l10n/l10n.dart';
import '../../data/services/canvas_webview_service.dart';

/// Menu "Edit Element" bergaya editor visual, dirender native di atas WebView
/// agar ikut palet tema dan i18n aplikasi.
///
/// Breadcrumb di kepala menu adalah satu-satunya cara berpindah antara induk
/// dan anak: setiap crumb bisa diketuk untuk memilih elemen itu.
class ElementEditMenu extends StatelessWidget {
  const ElementEditMenu({
    super.key,
    required this.chain,
    required this.selectedId,
    required this.canEditText,
    required this.onEditText,
    required this.onEditWithAi,
    required this.onDelete,
    required this.onSelectAncestor,
    required this.onClose,
  });

  /// Rantai paling luar → elemen terpilih.
  final List<NodeAncestor> chain;
  final String selectedId;
  final bool canEditText;
  final VoidCallback onEditText;
  final VoidCallback onEditWithAi;
  final VoidCallback onDelete;
  final ValueChanged<String> onSelectAncestor;
  final VoidCallback onClose;

  static const double width = 264;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: palette.bgElevated,
          borderRadius: AppRadius.md,
          border: Border.all(color: palette.borderSubtle),
          boxShadow: palette.shadowRaised,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BreadcrumbBar(
              chain: chain,
              selectedId: selectedId,
              onSelect: onSelectAncestor,
              onClose: onClose,
              closeTooltip: l10n.commonClose,
            ),
            Container(height: 1, color: palette.borderSubtle),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (canEditText)
                    _MenuItem(
                      icon: Icons.text_fields_rounded,
                      label: l10n.previewEditText,
                      onTap: onEditText,
                    ),
                  _MenuItem(
                    icon: Icons.auto_awesome_outlined,
                    label: l10n.previewEditWithAi,
                    onTap: onEditWithAi,
                  ),
                  _MenuItem(
                    icon: Icons.delete_outline_rounded,
                    label: l10n.commonDelete,
                    color: palette.statusError,
                    onTap: onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreadcrumbBar extends StatelessWidget {
  const _BreadcrumbBar({
    required this.chain,
    required this.selectedId,
    required this.onSelect,
    required this.onClose,
    required this.closeTooltip,
  });

  final List<NodeAncestor> chain;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onClose;
  final String closeTooltip;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 4, 4),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: Directionality.of(context) == TextDirection.rtl,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < chain.length; i++) ...[
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 12,
                          color: palette.textDisabled,
                        ),
                      ),
                    _Crumb(
                      label: chain[i].label,
                      selected: chain[i].id == selectedId,
                      onTap: () => onSelect(chain[i].id),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _IconHit(
            icon: Icons.close_rounded,
            tooltip: closeTooltip,
            onTap: onClose,
          ),
        ],
      ),
    );
  }
}

class _Crumb extends StatefulWidget {
  const _Crumb({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_Crumb> createState() => _CrumbState();
}

class _CrumbState extends State<_Crumb> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = widget.selected
        ? palette.primary
        : (_hovered ? palette.textPrimary : palette.textSecondary);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          decoration: BoxDecoration(
            color: _hovered ? palette.hoverBg : Colors.transparent,
            borderRadius: AppRadius.sm,
          ),
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.monoFamily,
              fontFamilyFallback: AppFonts.monoFallback,
              fontSize: 10.5,
              height: 1.2,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatefulWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = widget.color ?? palette.textPrimary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 34,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _hovered ? palette.hoverBg : Colors.transparent,
            borderRadius: AppRadius.sm,
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 16, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontFamily: AppFonts.uiFamily,
                    fontFamilyFallback: AppFonts.uiFallback,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: color,
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

class _IconHit extends StatefulWidget {
  const _IconHit({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_IconHit> createState() => _IconHitState();
}

class _IconHitState extends State<_IconHit> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: _hovered ? palette.hoverBg : Colors.transparent,
              borderRadius: AppRadius.sm,
            ),
            child: Icon(
              widget.icon,
              size: 14,
              color: _hovered ? palette.textPrimary : palette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
