import 'package:flutter/material.dart';

import '../../../../app/config/app_palette.dart';
import '../../../../app/config/theme.dart';

/// Skeleton block yang berdenyut halus untuk menggantikan spinner generik
/// pada state loading (Pre-Flight: hindari circular spinner default).
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = AppRadius.sm,
  });

  final double width;
  final double height;
  final BorderRadius radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = reduceMotion ? 0.5 : _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(
              context.palette.bgSunken,
              context.palette.borderSubtle,
              t,
            ),
            borderRadius: widget.radius,
          ),
        );
      },
    );
  }
}

/// Baris skeleton untuk list provider pada state loading.
class SkeletonListRow extends StatelessWidget {
  const SkeletonListRow({super.key, this.lines = 2});

  final int lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 160, height: 11),
          if (lines > 1) ...[
            const SizedBox(height: 6),
            const SkeletonBox(width: 96, height: 9),
          ],
        ],
      ),
    );
  }
}
