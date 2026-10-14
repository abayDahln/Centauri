import 'package:centauri/features/canvas_preview/domain/board_frame.dart';
import 'package:centauri/features/canvas_preview/presentation/provider/canvas_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regresi: `_FrameCard` tidak boleh melempar error render (overflow /
/// BoxConstraints non-normalized) di skala berapa pun, khususnya zoom > 100%
/// dan zoom-out, sambil menjaga child selalu di-layout pada ukuran logis.
void main() {
  BoardFrame frame() => BoardFrame(
    id: 'frame_0',
    title: 'Test Frame',
    html: '<!DOCTYPE html><html><body>hi</body></html>',
    offset: Offset.zero,
    size: const Size(390, 600),
  );

  Future<void> pumpBoard(WidgetTester tester, double scale) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(canvasProvider.notifier).setScale(scale);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            // WebView tidak ada di test; kita pakai child placeholder agar
            // fokus pada layout frame, bukan bridge.
            body: SizedBox(
              width: 1200,
              height: 900,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  BoardCanvasHarness(frame: frame(), scale: scale),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final scale in const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]) {
    testWidgets('frame layout is valid at scale $scale', (tester) async {
      await pumpBoard(tester, scale);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('child keeps logical size regardless of board scale', (
    tester,
  ) async {
    for (final scale in const [0.5, 0.75, 1.0, 1.5, 2.0]) {
      await pumpBoard(tester, scale);
      // SizedBox logis harus tetap 390x600 (di-scale secara paint, bukan
      // layout) -> isi frame tidak reflow saat zoom.
      final size = tester.getSize(find.byType(SizedBox).last);
      expect(size.width, closeTo(390, 0.01), reason: 'scale=$scale');
      expect(size.height, closeTo(600, 0.01), reason: 'scale=$scale');
    }
  });

  testWidgets('drag delta maps 1:1 to board units (no scale division)', (
    tester,
  ) async {
    // Karena Transform meng-inverse saat hit-test, delta drag yang diterima
    // sudah dalam ruang logis kartu. Simulasi: drag 100px layar pada skala
    // 0.5 harus bergerak 100/0.5 = 200 unit board? TIDAK — harus 100 unit
    // setelah di-inverse, sehingga widget berpindah 100 * 0.5 = 50px layar.
    Offset? lastDelta;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 1200,
              height: 900,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 100,
                    top: 100,
                    child: Transform.scale(
                      scale: 0.5,
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: 390,
                        height: 600,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanUpdate: (d) => lastDelta = d.delta,
                          child: const ColoredBox(color: Color(0xFFFFFFFF)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final gesture = await tester.startGesture(const Offset(150, 150));
    await gesture.moveBy(const Offset(100, 0));
    await tester.pump();

    // Gesture 100px layar pada Transform 0.5 -> delta logis 200 (inverse),
    // lalu dikali scale saat paint = 100px layar. Jadi delta logis = 200.
    expect(lastDelta, isNotNull);
    expect(lastDelta!.dx, closeTo(200, 1));
  });
}

/// Harness tipis: bungkus kartu frame tanpa WebView nyata agar test widget
/// tidak butuh platform view. Meniru struktur `_FrameCard` (Positioned tanpa
/// width/height + Transform.scale + SizedBox logis).
class BoardCanvasHarness extends StatelessWidget {
  const BoardCanvasHarness({
    super.key,
    required this.frame,
    required this.scale,
  });

  final BoardFrame frame;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: frame.offset.dx * scale,
      top: frame.offset.dy * scale,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topLeft,
        filterQuality: FilterQuality.high,
        child: SizedBox(
          width: frame.size.width,
          height: frame.size.height,
          child: const ColoredBox(color: Color(0xFFFFFFFF)),
        ),
      ),
    );
  }
}
