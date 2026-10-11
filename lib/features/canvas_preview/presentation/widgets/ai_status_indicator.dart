import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/theme.dart';
import '../provider/canvas_provider.dart';

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

  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _shimmer.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(canvasProvider.select((s) => s.status));
    final startedAt = ref.watch(
      canvasProvider.select((s) => s.generationStartedAt),
    );

    if (status == AiStatus.idle) return const SizedBox.shrink();

    final label = status.label.isEmpty ? 'Memproses' : status.label;
    final elapsed = _formatElapsed(startedAt);

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) {
        final t = _shimmer.value;
        // Sorot bergerak dari kiri ke kanan.
        final highlight = 0.35 + 0.65 * (1 - (2 * t - 1).abs());
        final color = Color.lerp(
          AppColors.textSecondary,
          AppColors.accentPrimary,
          highlight,
        )!;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: widget.compact ? 14 : 15,
              height: widget.compact ? 14 : 15,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accentPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.uiFamily,
                fontFamilyFallback: AppFonts.uiFallback,
                fontSize: widget.compact ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            _Dots(animation: _shimmer, color: color),
            if (elapsed != null) ...[
              const SizedBox(width: 8),
              Text(
                elapsed,
                style: TextStyle(
                  fontFamily: AppFonts.monoFamily,
                  fontFamilyFallback: AppFonts.monoFallback,
                  fontSize: widget.compact ? 11 : 12,
                  color: AppColors.textDisabled,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  String? _formatElapsed(DateTime? startedAt) {
    if (startedAt == null) return null;
    final seconds = DateTime.now().difference(startedAt).inSeconds;
    if (seconds <= 0) return null;
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return minutes > 0
        ? '$minutes:${rest.toString().padLeft(2, '0')}'
        : '${rest}s';
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
          padding: const EdgeInsets.only(left: 2),
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
