import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/theme.dart';
import '../provider/canvas_provider.dart';

/// Board besar (infinite-ish canvas) bergaya Figma/Stitch.
///
/// Interaksi:
///  - **Mouse / trackpad drag** (tool hand, tahan Space, atau tombol tengah):
///    menggeser board (pan).
///  - **Roda mouse**: zoom di titik kursor (default kanvas). `Shift+scroll`
///    untuk pan horizontal.
///  - **Trackpad dua jari (PointerPanZoom)**: geser = pan, cubit = zoom ke
///    titik jari — ditangani native, bukan fallback scroll.
///  - **Trackpad pinch via sinyal**: `Ctrl+scroll` & pinch lama juga zoom.
///  - **Pinch** (PointerScaleEvent) tetap didukung sebagai fallback.
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

  /// Mouse / trackpad click-drag: pointer yang sedang dipakai untuk pan.
  bool _dragging = false;
  int? _panPointerId;

  /// Gestur trackpad (PointerPanZoom) sedang berjalan.
  bool _panZoomActive = false;

  /// Nilai kumulatif terakhir dari gesture trackpad, untuk menghitung delta.
  Offset _lastPanZoomPan = Offset.zero;
  double _lastPanZoomScale = 1.0;

  /// Posisi kursor terakhir yang diketahui di atas board (koordinat lokal
  /// Listener — ruang yang sama dengan `panOffset`).
  ///
  /// Dipakai sebagai jangkar zoom pinch trackpad. Alasan: posisi yang dibawa
  /// `PointerPanZoomUpdateEvent` dari OS gesture sering TIDAK akurat (dapat
  /// berupa origin), sehingga zoom selalu terjangkar ke pojok. Posisi kursor
  /// dari hover/move/signal selalu benar — sama seperti jalur Ctrl+scroll
  /// yang sudah terjangkar ke kursor dengan tepat.
  Offset? _cursorLocal;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(canvasProvider);
    final scale = state.scale;
    final pan = state.panOffset;
    final handTool = state.tool == BoardTool.hand;

    // Cursor board: default (di area kosong). Hand saat bisa menggeser board
    // (tool hand / Space), grabbing saat benar-benar menggeser.
    // Cursor `move` (panah 4 arah) TIDAK dipasang di sini — itu milik kartu
    // frame (lihat `_FrameCard`), agar hanya muncul saat kursor di atas frame,
    // bukan di area kosong board.
    final spaceHeld = HardwareKeyboard.instance.isLogicalKeyPressed(
      LogicalKeyboardKey.space,
    );
    final canPanBoard = handTool || spaceHeld;
    final cursor = _dragging
        ? SystemMouseCursors.grabbing
        : (canPanBoard ? SystemMouseCursors.grab : MouseCursor.defer);

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

          return MouseRegion(
            cursor: cursor,
            opaque: false,
            child: Listener(
              // Lacak kursor: jangkar zoom pinch yang akurat.
              onPointerHover: (event) {
                _cursorLocal = event.localPosition;
              },
              // ============================================================
              // A. Gestur TRACKPAD native (PointerPanZoom).
              //
              // Di Windows/macOS, cukup banyak trackpad presisi mengirim gestur
              // sebagai PointerPanZoom (BUKAN PointerScrollEvent). Satu gestur
              // membawa: pan dua-jari, pinch (scale), dan rotasi. Kita pakai:
              //   - panDelta  -> geser board (pan)
              //   - scale     -> zoom ke titik jari (kumulatif)
              // ============================================================
              onPointerPanZoomStart: (event) {
                _panZoomActive = true;
                // Nilai kumulatif gesture dimulai dari nol.
                _lastPanZoomPan = Offset.zero;
                _lastPanZoomScale = 1.0;
                // Jangan timpa posisi kursor yang sudah diketahui akurat —
                // posisi event gesture dari OS tidak bisa diandalkan.
                _cursorLocal ??= event.localPosition;
              },
              onPointerPanZoomUpdate: (event) {
                if (!_panZoomActive) return;
                final notifier = ref.read(canvasProvider.notifier);

                // Delta pan sejak event sebelumnya (px layar).
                final panDelta = event.pan - _lastPanZoomPan;

                // `event.scale` kumulatif; ambil faktor relatif terhadap
                // pembacaan sebelumnya agar zoom tidak "melompat".
                var factor = _lastPanZoomScale == 0
                    ? 1.0
                    : event.scale / _lastPanZoomScale;

                // Deadzone: trackpad sering menghasilkan noise scale sangat kecil
                // saat pan dua-jari. Abaikan agar pan tidak mengubah zoom.
                const scaleDeadzone = 0.005; // 0.5%
                if ((factor - 1.0).abs() < scaleDeadzone) factor = 1.0;

                _lastPanZoomPan = event.pan;
                _lastPanZoomScale = event.scale;

                // Jangkar ke kursor (bukan event.localPosition yang tak akurat).
                // Satu update state: pan + zoom sekaligus (anti-getar).
                notifier.panAndZoomAt(
                  _cursorLocal ?? event.localPosition,
                  panDelta: panDelta,
                  scaleFactor: factor,
                );
              },
              onPointerPanZoomEnd: (event) {
                _panZoomActive = false;
                _lastPanZoomPan = Offset.zero;
                _lastPanZoomScale = 1.0;
              },

              // ============================================================
              // B. Pointer signal: roda mouse & trackpad yang mengirim sinyal.
              //
              // - PointerScaleEvent  : pinch dari trackpad lama/OS tertentu.
              // - PointerScrollEvent : roda mouse, atau trackpad non-precision
              //   (Windows hanya mengirim pan-zoom bila driver mendukung).
              // ============================================================
              onPointerSignal: (event) {
                // Pinch lama -> zoom langsung di titik jari (jangkar kursor).
                if (event is PointerScaleEvent) {
                  ref
                      .read(canvasProvider.notifier)
                      .zoomAt(
                        _cursorLocal ?? event.localPosition,
                        event.scale,
                      );
                  return;
                }

                if (event is! PointerScrollEvent) return;

                // Catat posisi kursor dari sinyal scroll (selalu akurat).
                _cursorLocal = event.localPosition;

                final notifier = ref.read(canvasProvider.notifier);
                final keys = HardwareKeyboard.instance;
                final dy = event.scrollDelta.dy;
                final sdx = event.scrollDelta.dx;

                // Pemetaan roda mouse:
                //  - scroll biasa       -> geser board atas/bawah (pan vertikal)
                //  - Shift + scroll     -> geser board kanan/kiri (pan horizontal)
                //  - Ctrl/Cmd + scroll  -> zoom in/out ke arah kursor
                if (event.kind == PointerDeviceKind.trackpad) {
                  // Trackpad = pan dua-jari natural (jalur PointerPanZoom biasanya),
                  // fallback di sini: pan mengikuti delta, ctrl = zoom.
                  if (keys.isControlPressed || keys.isMetaPressed) {
                    if (dy != 0) {
                      notifier.zoomAt(
                        event.localPosition,
                        math.exp(-dy * 0.0015),
                      );
                    }
                    return;
                  }
                  if (sdx == 0 && dy == 0) return;
                  notifier.panBy(Offset(-sdx, -dy));
                  return;
                }

                if (keys.isControlPressed || keys.isMetaPressed) {
                  // Zoom ke arah kursor.
                  if (dy == 0) return;
                  final factor = math.exp(-dy * 0.0015);
                  notifier.zoomAt(event.localPosition, factor);
                  return;
                }

                if (keys.isShiftPressed) {
                  // Shift + scroll = geser board kanan/kiri.
                  if (dy == 0 && sdx == 0) return;
                  final h = dy != 0 ? dy : sdx;
                  notifier.panBy(Offset(-h, 0));
                  return;
                }

                // Default: scroll biasa menggeser board atas/bawah.
                if (dy == 0 && sdx == 0) return;
                final v = dy != 0 ? dy : sdx;
                notifier.panBy(Offset(0, -v));
              },

              // ============================================================
              // C. Drag pan (mouse & trackpad click-drag).
              // ============================================================
              onPointerDown: (event) {
                // Pan dengan drag bila: tool hand, spasi ditahan, atau tombol
                // tengah mouse. Trackpad klik-drag juga mengirim PointerDown
                // lalu PointerMove.
                final spaceNow = HardwareKeyboard.instance.isLogicalKeyPressed(
                  LogicalKeyboardKey.space,
                );
                final middleButton = event.buttons & kMiddleMouseButton != 0;
                final wantsPan = handTool || spaceNow || middleButton;
                if (!wantsPan) return;
                setState(() {
                  _dragging = true;
                  _panPointerId = event.pointer;
                  _lastFocal = event.localPosition;
                });
              },
              onPointerMove: (event) {
                _cursorLocal = event.localPosition;
                if (!_dragging || event.pointer != _panPointerId) return;
                final previous = _lastFocal ?? event.localPosition;
                final delta = event.localPosition - previous;
                _lastFocal = event.localPosition;
                ref.read(canvasProvider.notifier).panBy(delta);
              },
              onPointerUp: (event) {
                if (event.pointer == _panPointerId) {
                  setState(() {
                    _dragging = false;
                    _panPointerId = null;
                    _lastFocal = null;
                  });
                }
              },
              onPointerCancel: (event) {
                if (event.pointer == _panPointerId) {
                  setState(() {
                    _dragging = false;
                    _panPointerId = null;
                    _lastFocal = null;
                  });
                }
              },

              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
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
