import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/app_palette.dart';
import '../provider/workspace_provider.dart';

/// Indikator live status AI (ala Claude/Gemini/ChatGPT): label status yang
/// berdenyut, titik bergerak, dan penghitung waktu berjalan.
///
/// [compact] = versi kecil untuk toolbar/board.
class AiStatusIndicator extends ConsumerStatefulWidget {
  const AiStatusIndicator({super.key, this.compact = false});

  final bool compact;

  @override
  ConsumerState<AiStatusIndicator> createState() => _AiStatusIndicatorState();
}

class _AiStatusIndicatorState extends ConsumerState<AiStatusIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(workspaceProvider.select((s) => s.status));

    if (status == AiStatus.idle) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: widget.compact ? 14 : 16,
              height: widget.compact ? 14 : 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.palette.secondary,
              ),
            ),
            SizedBox(width: widget.compact ? 8 : 10),
            _Dots(animation: _shimmer, color: context.palette.secondary),
          ],
        );
      },
    );
  }
}

/// Tiga titik yang muncul bergantian (seperti sedang menulis).
class _Dots extends StatelessWidget {
  const _Dots({required this.animation, required this.color});

  final Animation<double> animation;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final phase = (animation.value * 3).floor() % 3;
        return Padding(
          padding: const EdgeInsetsDirectional.only(start: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final active = i == phase;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    color: active ? color : color.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
