import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/theme.dart';
import '../provider/canvas_provider.dart';
import 'canvas_stage.dart';
import 'dot_grid_board.dart';

/// Permukaan board: dot-grid + semua frame UI yang sudah digenerate.
class BoardSurface extends ConsumerWidget {
  const BoardSurface({super.key});

  /// Key global ke ukuran viewport board (dipakai untuk "fit to frames").
  static final GlobalKey boardViewportKey = GlobalKey();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(canvasProvider);

    return KeyedSubtree(
      key: boardViewportKey,
      child: DotGridBoard(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (state.frames.isEmpty)
              const Positioned(
                left: 80,
                top: 120,
                child: _BoardHint(),
              ),
            for (final frame in state.frames)
              BoardFrameView(
                key: ValueKey(frame.id),
                frame: frame,
                scale: state.scale,
              ),
          ],
        ),
      ),
    );
  }
}

class _BoardHint extends StatelessWidget {
  const _BoardHint();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.dashboard_customize_outlined,
            size: 30,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 12),
          Text(
            'Board masih kosong',
            style: TextStyle(
              fontFamily: AppFonts.uiFamily,
              fontFamilyFallback: AppFonts.uiFallback,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tulis prompt di bawah untuk membuat frame UI. '
            'Setiap hasil muncul sebagai kartu di board ini.',
            style: AppText.caption,
          ),
        ],
      ),
    );
  }
}
