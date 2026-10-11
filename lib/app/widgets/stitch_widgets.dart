import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Kartu/panel mengambang bergaya Stitch: permukaan putih, sudut membulat
/// besar, border sangat tipis, shadow lembut.
class SoftPanel extends StatelessWidget {
  const SoftPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppRadius.lg,
    this.showBorder = true,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius radius;
  final bool showBorder;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: radius,
        border: showBorder
            ? Border.all(color: AppColors.borderSubtle)
            : null,
        boxShadow: AppColors.shadowSoft,
      ),
      child: child,
    );
  }
}

/// Tombol ikon bulat lembut dengan hover.
class SoftIconButton extends StatefulWidget {
  const SoftIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 36,
    this.iconSize = 18,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final bool active;

  @override
  State<SoftIconButton> createState() => _SoftIconButtonState();
}

class _SoftIconButtonState extends State<SoftIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final background = widget.active
        ? AppColors.accentSoft
        : _hovered && enabled
        ? AppColors.hoverBg
        : Colors.transparent;
    final color = !enabled
        ? AppColors.textDisabled
        : widget.active
        ? AppColors.accentPrimary
        : AppColors.textSecondary;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: background,
              borderRadius: AppRadius.sm,
            ),
            child: Icon(widget.icon, size: widget.iconSize, color: color),
          ),
        ),
      ),
    );
  }
}

/// Sakelar tersegmentasi bergaya pill (Design / Dev, viewport, dsb).
class SoftSegmented<T> extends StatelessWidget {
  const SoftSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<SoftSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.bgSunken,
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: segments.map((segment) {
          final active = segment.value == selected;
          return GestureDetector(
            onTap: () => onChanged(segment.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: active ? AppColors.bgSurface : Colors.transparent,
                borderRadius: AppRadius.pill,
                boxShadow: active ? AppColors.shadowSoft : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (segment.icon != null) ...[
                    Icon(
                      segment.icon,
                      size: 15,
                      color: active
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    segment.label,
                    style: TextStyle(
                      fontFamily: AppFonts.uiFamily,
                      fontFamilyFallback: AppFonts.uiFallback,
                      fontSize: 12.5,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      color: active
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class SoftSegment<T> {
  const SoftSegment({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}
