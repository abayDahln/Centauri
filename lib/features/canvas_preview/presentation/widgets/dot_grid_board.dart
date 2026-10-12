import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/theme.dart';
import '../provider/canvas_provider.dart';

/// Board besar (infinite-ish canvas) bergaya Figma/Stitch:
///  - latar abu dengan dot grid yang mengikuti pan/zoom,
///  - pan dengan drag (tool hand) atau drag area kosong,
///  - zoom dengan scroll wheel (fokus kursor) dan pinch.
///
/// Catatan: grid digambar di ruang layar, sedangkan frame diposisikan sendiri
/// oleh [BoardSurface] memakai `panOffset` + `scale` (tanpa Transform). Ini
/// menjaga WebView tetap tajam pada semua tingkat zoom.
class DotGridBoard extends ConsumerStatefulWidget {
  const DotGridBoard({super.key, required this.child});

  /// Konten board (frame-frame) dalam koordinat layar.
  final Widget child;

  @override
  ConsumerState<DotGridBoard> createState() => _DotGridBoardState();
}

class _DotGridBoardState extends ConsumerState<DotGridBoard> {
  Offset? _lastFocal;

  static const double _dotSpacing = 28;
  static const double _dotRadius = 1.2;

  /// Akumulasi delta wheel agar zoom tidak "kebablasan" pada mouse dengan
  /// scroll cepat (akselerasi OS). Zoom hanya diterapkan per ambang tertentu.
  double _wheelAccum = 0;
  static const double _wheelThreshold = 60;

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
              if (event is! PointerScrollEvent) return;
              // Ctrl + scroll = zoom (pola Figma). Scroll biasa = pan vertikal.
              final isZoom =
                  HardwareKeyboard.instance.isControlPressed ||
                  HardwareKeyboard.instance.isMetaPressed;

              if (isZoom) {
                _wheelAccum += event.scrollDelta.dy;
                if (_wheelAccum.abs() < _wheelThreshold) return;
                final direction = _wheelAccum.sign;
                _wheelAccum = 0;
                // Satu langkah per ambang, konsisten di semua perangkat.
                final factor = direction > 0 ? 0.9 : 1.1;
                ref
                    .read(canvasProvider.notifier)
                    .zoomAt(event.localPosition, factor);
                return;
              }

              // Scroll biasa: pan vertikal. Shift+scroll: pan horizontal.
              final delta = HardwareKeyboard.instance.isShiftPressed
                  ? Offset(-event.scrollDelta.dy, 0)
                  : Offset(0, -event.scrollDelta.dy);
              ref.read(canvasProvider.notifier).panBy(delta);
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
                clipBehavior: Clip.none,
                children: [
                  // Grid statis di layar.
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
                  widget.child,
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
