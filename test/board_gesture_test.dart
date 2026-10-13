import 'package:centauri/features/canvas_preview/presentation/provider/canvas_provider.dart';
import 'package:centauri/features/canvas_preview/presentation/widgets/dot_grid_board.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test gestur board terisolasi (tanpa WebView). Memverifikasi pemisahan
/// jelas antara roda mouse (zoom default), trackpad (pan), dan Cmd/Ctrl+scroll
/// (zoom paksa) — inti bug interaksi sebelumnya.
void main() {
  ProviderContainer? container;

  Future<void> pumpBoard(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 600,
                height: 400,
                child: DotGridBoard(child: SizedBox.expand()),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(DotGridBoard)),
    );
  }

  tearDown(() => container = null);

  CanvasState state() => container!.read(canvasProvider);
  CanvasNotifier notifier() => container!.read(canvasProvider.notifier);

  testWidgets('mouse wheel zooms by default (Figma-like canvas)', (
    tester,
  ) async {
    await pumpBoard(tester);
    notifier().setScale(1.0);

    final center = tester.getCenter(find.byType(DotGridBoard));
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    pointer.hover(center);

    // Roda mouse: delta sumbu Y positif (scroll turun) -> zoom OUT.
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 60)));
    await tester.pump();

    expect(state().scale, lessThan(1.0));
  });

  testWidgets('shift + wheel pans horizontally instead of zooming', (
    tester,
  ) async {
    await pumpBoard(tester);
    notifier().reportViewport(const Size(600, 400));
    notifier().setScale(1.0);

    final center = tester.getCenter(find.byType(DotGridBoard));
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    pointer.hover(center);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 40)));
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);

    // Scale tidak berubah; board bergeser horizontal (dx != 0).
    expect(state().scale, 1.0);
    expect(state().panOffset.dx, isNot(0));
  });

  testWidgets('trackpad two-finger scroll pans, does not zoom', (
    tester,
  ) async {
    await pumpBoard(tester);
    notifier().reportViewport(const Size(600, 400));
    notifier().setScale(1.0);

    final center = tester.getCenter(find.byType(DotGridBoard));
    final pointer = TestPointer(1, PointerDeviceKind.trackpad);
    pointer.hover(center);

    // Sinyal scroll dengan kind == trackpad harus diperlakukan sebagai pan.
    await tester.sendEventToBinding(pointer.scroll(const Offset(20, 30)));
    await tester.pump();

    expect(state().scale, 1.0);
    expect(state().panOffset, isNot(Offset.zero));
  });

  testWidgets('ctrl + wheel zooms even from a trackpad signal', (
    tester,
  ) async {
    await pumpBoard(tester);
    notifier().setScale(1.0);

    final center = tester.getCenter(find.byType(DotGridBoard));
    final pointer = TestPointer(1, PointerDeviceKind.trackpad);
    pointer.hover(center);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 40)));
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

    expect(state().scale, lessThan(1.0));
  });

  testWidgets('pointer pan-zoom pinch zooms around the fingers', (
    tester,
  ) async {
    await pumpBoard(tester);
    notifier().setScale(1.0);

    final center = tester.getCenter(find.byType(DotGridBoard));
    final pointer = TestPointer(1, PointerDeviceKind.trackpad);

    await tester.sendEventToBinding(pointer.panZoomStart(center));
    // Pinch membuka (scale kumulatif 1.5) -> zoom in.
    await tester.sendEventToBinding(
      pointer.panZoomUpdate(center, scale: 1.5),
    );
    await tester.pump();
    await tester.sendEventToBinding(pointer.panZoomEnd());

    expect(state().scale, greaterThan(1.0));
  });

  testWidgets('pointer pan-zoom pure pan does not change zoom', (
    tester,
  ) async {
    await pumpBoard(tester);
    notifier().reportViewport(const Size(600, 400));
    notifier().setScale(1.0);

    final center = tester.getCenter(find.byType(DotGridBoard));
    final pointer = TestPointer(1, PointerDeviceKind.trackpad);

    await tester.sendEventToBinding(pointer.panZoomStart(center));
    // Geser dua jari tanpa pinch; scale noise di bawah deadzone diabaikan.
    await tester.sendEventToBinding(
      pointer.panZoomUpdate(center, pan: const Offset(25, -15), scale: 1.001),
    );
    await tester.pump();
    await tester.sendEventToBinding(pointer.panZoomEnd());

    expect(state().scale, 1.0);
    expect(state().panOffset, isNot(Offset.zero));
  });
}
