import 'package:flutter/material.dart';

import '../config/app_palette.dart';
import '../config/theme.dart';

/// Panel dasar: permukaan putih, garis 1 px, sudut 10.
///
/// Tanpa bayangan — kedalaman di design system datang dari garis dan kanvas,
/// bukan shadow.
class SoftPanel extends StatelessWidget {
  const SoftPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppRadius.md,
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
        color: context.palette.bgSurface,
        borderRadius: radius,
        border: showBorder
            ? Border.all(color: context.palette.borderSubtle)
            : null,
      ),
      child: child,
    );
  }
}

/// Pil status: titik warna + teks. Status selalu disertai teks, tidak pernah
/// titik sendirian.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, this.color, this.onTap});

  final String label;

  /// Warna titik status; `null` = hijau sukses dari palet aktif.
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dotColor = color ?? context.palette.statusSuccess;
    final content = Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.palette.bgSurface,
        borderRadius: AppRadius.pill,
        border: Border.all(color: context.palette.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: context.text.caption),
        ],
      ),
    );

    if (onTap == null) return content;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: content),
    );
  }
}

/// Tombol ikon persegi 36 px, radius 6. Hover netral, aktif memakai aksen
/// lembut.
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
    final hovered = _hovered && enabled;
    // Mulai dari warna hover yang transparan, bukan `Colors.transparent`
    // (hitam transparan) agar fade pertama tidak terlihat gelap.
    final idle = context.palette.hoverBg.withValues(alpha: 0);
    final background = widget.active
        ? context.palette.primarySoft
        : hovered
        ? context.palette.hoverBg
        : idle;
    final color = !enabled
        ? context.palette.textDisabled
        : widget.active
        ? context.palette.primary
        : context.palette.textSecondary;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            // Keluar langsung, masuk tetap halus. Dengan begitu tombol
            // sebelumnya tidak ikut terlihat hover saat kursor pindah.
            duration: hovered
                ? const Duration(milliseconds: 120)
                : Duration.zero,
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

/// Sakelar tersegmentasi: bingkai 1 px, radius 6, segmen aktif aksen lembut.
class SoftSegmented<T> extends StatelessWidget {
  const SoftSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.height = 32,
  });

  final List<SoftSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: context.palette.bgSurface,
        borderRadius: AppRadius.sm,
        border: Border.all(color: context.palette.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            if (i > 0)
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: context.palette.borderSubtle,
              ),
            _segment(context, segments[i]),
          ],
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, SoftSegment<T> segment) {
    final active = segment.value == selected;
    return GestureDetector(
      onTap: () => onChanged(segment.value),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          color: active ? context.palette.primarySoft : Colors.transparent,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (segment.icon != null) ...[
                Icon(
                  segment.icon,
                  size: 15,
                  color: active
                      ? context.palette.primary
                      : context.palette.textSecondary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                segment.label,
                style: context.text.button.copyWith(
                  color: active
                      ? context.palette.primary
                      : context.palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SoftSegment<T> {
  const SoftSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Tab garis bawah: tinggi 40, aktif ditandai garis aksen 2 px.
class AppTab extends StatelessWidget {
  const AppTab({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? context.palette.textPrimary
        : context.palette.textSecondary;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: AppMetrics.toolbarHeight,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? context.palette.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: context.text.button.copyWith(
                color: color,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
