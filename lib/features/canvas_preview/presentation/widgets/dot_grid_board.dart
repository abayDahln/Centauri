import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/theme.dart';
import '../provider/canvas_provider.dart';

/// Board besar (infinite-ish canvas) bergaya Figma/Stitch:
///  - latar abu dengan dot grid yang mengikuti pan/zoom,
///  - pan dengan drag (tool hand) atau drag area kosong,
///  - zoom dengan scroll wheel (fokus kursor) dan pinch,
///  - area board dibatasi (tidak tak terhingga) dan tumbuh otomatis.
class DotGridBoard extends ConsumerStatefulWidget {
  const DotGridBoard({super.key, required this.child});

  /// Konten board (frame-frame) dalam koordinat board.
  final Widget child;

  @override
  ConsumerState<DotGridBoard> createState() => _DotGridBoardState();
}

class _DotGridBoardState extends ConsumerState<DotGridBoard> {
  Offset? _lastFocal;

  static const double _dotSpacing = 28;
  static const double _dotRadius = 1.2;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(canvasProvider);
    final scale = state.scale;
    final pan = state.panOffset;
    final handTool = state.tool == BoardTool.hand;

    return ClipRRect(
      borderRadius: AppRadius.lg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Laporkan ukuran viewport ke notifier untuk clamping pan.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref
                .read(canvasProvider.notifier)
                .reportViewport(constraints.biggest);
          });

          return Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                final factor = event.scrollDelta.dy > 0 ? 0.92 : 1.08;
                ref
                    .read(canvasProvider.notifier)
                    .zoomAt(event.localPosition, factor);
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: (d) => _lastFocal = d.localFocalPoint,
              onScaleUpdate: (d) {
                final notifier = ref.read(canvasProvider.notifier);
                if (d.scale != 1.0) {
                  final previous = _lastFocal ?? d.localFocalPoint;
                  notifier.panBy(d.localFocalPoint - previous);
                  notifier.zoomAt(d.localFocalPoint, d.scale);
                  _lastFocal = d.localFocalPoint;
                  return;
                }
                if (handTool && d.focalPointDelta != Offset.zero) {
                  notifier.panBy(d.focalPointDelta);
                }
              },
              onScaleEnd: (_) => _lastFocal = null,
              onTap: () =>
                  ref.read(canvasProvider.notifier).selectFrame(null),
              onSecondaryTap: () =>
                  ref.read(canvasProvider.notifier).selectFrame(null),
              child: Stack(
                children: [
                  // Grid + batas board (statis di layar).
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _DotGridPainter(
                        pan: pan,
                        scale: scale,
                        spacing: _dotSpacing,
                        radius: _dotRadius,
                        showGrid: state.showGrid,
                      ),
                    ),
                  ),
                  // Konten board yang di-transform.
                  Positioned.fill(
                    child: Transform(
                      transform: Matrix4.identity()
                        ..translateByDouble(pan.dx, pan.dy, 0, 1)
                        ..scaleByDouble(scale, scale, 1, 1),
                      child: widget.child,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  _DotGridPainter({
    required this.pan,
    required this.scale,
    required this.spacing,
    required this.radius,
    required this.showGrid,
  });

  final Offset pan;
  final double scale;
  final double spacing;
  final double radius;
  final bool showGrid;

  @override
  void paint(Canvas canvas, Size size) {
    // Latar board (infinite): satu warna, dot grid mengikuti pan/zoom.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEDEFF3),
    );

    if (!showGrid) return;

    final step = spacing * scale;
    if (step < 8) return; // terlalu rapat: lewati agar tidak ramai.

    final paint = Paint()..color = const Color(0xFFC7CBD3);
    final dotRadius = radius * scale.clamp(0.6, 2.2);

    final startX = pan.dx % step;
    final startY = pan.dy % step;
    for (var x = startX; x < size.width; x += step) {
      for (var y = startY; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter old) =>
      old.pan != pan ||
      old.scale != scale ||
      old.showGrid != showGrid ||
      old.spacing != spacing;
}
