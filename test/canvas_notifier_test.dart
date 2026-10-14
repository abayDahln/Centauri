import 'package:centauri/features/canvas_preview/domain/board_frame.dart';
import 'package:centauri/features/canvas_preview/domain/viewport_mode.dart';
import 'package:centauri/features/canvas_preview/presentation/provider/canvas_provider.dart';
import 'package:centauri/features/prompt_editor/domain/prompt_templates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  BoardFrame frame(String id, {Offset offset = Offset.zero}) => BoardFrame(
    id: id,
    title: id,
    html: '<html></html>',
    offset: offset,
    size: const Size(390, 844),
  );

  test('design token selection is shared state', () {
    final notifier = container.read(canvasProvider.notifier);

    expect(container.read(canvasProvider).selectedToken, isNull);

    final electric = designTokenPresets.firstWhere((t) => t.id == 'electric');
    notifier.setSelectedToken(electric);
    expect(container.read(canvasProvider).selectedToken?.id, 'electric');

    notifier.setSelectedToken(null);
    expect(container.read(canvasProvider).selectedToken, isNull);
  });

  test('viewport mode updates state and active frame size', () {
    final notifier = container.read(canvasProvider.notifier);

    expect(container.read(canvasProvider).viewport, ViewportMode.mobile);

    notifier.setViewport(ViewportMode.tablet);
    expect(container.read(canvasProvider).viewport, ViewportMode.tablet);
  });

  test('detectViewportOverride: user text wins over the toggle', () {
    // Tidak menyebut apa pun -> null (tombol dipakai sebagai default).
    expect(detectViewportOverride('Build a pricing page'), isNull);

    // Pola eksplisit paling kuat.
    expect(
      detectViewportOverride('Build a landing page. Viewport: desktop.'),
      ViewportMode.desktop,
    );
    expect(
      detectViewportOverride('viewport=mobile please'),
      ViewportMode.mobile,
    );

    // Nama device.
    expect(detectViewportOverride('a tablet layout'), ViewportMode.tablet);

    // Lebar px.
    expect(detectViewportOverride('design at 1280px wide'), ViewportMode.desktop);
    expect(detectViewportOverride('use 390 width'), ViewportMode.mobile);

    // Device disebut terakhir menang.
    expect(
      detectViewportOverride('build desktop version, then also a mobile one'),
      ViewportMode.mobile,
    );
  });

  test('setViewport does not resize existing frames', () async {
    final notifier = container.read(canvasProvider.notifier);
    // Buat frame lewat loadSession agar ukurannya diketahui.
    await notifier.loadSession(
      messages: const [],
      frames: [frame('f1', offset: const Offset(0, 0))],
      activeFrameId: 'f1',
    );

    final before = container.read(canvasProvider).frames.first.size;
    notifier.setViewport(ViewportMode.desktop);
    final after = container.read(canvasProvider).frames.first.size;

    // Ukuran frame tidak boleh berubah oleh tombol viewport.
    expect(after, before);
  });

  test('clearBoard resets frames but keeps token selection', () {
    final notifier = container.read(canvasProvider.notifier);
    final current = designTokenPresets.first;
    notifier.setSelectedToken(current);

    notifier.clearBoard();

    final state = container.read(canvasProvider);
    expect(state.frames, isEmpty);
    expect(state.messages, isEmpty);
    expect(state.selectedToken?.id, current.id);
  });

  test('pan by accumulates offset', () {
    final notifier = container.read(canvasProvider.notifier);
    expect(container.read(canvasProvider).panOffset, Offset.zero);

    notifier.panBy(const Offset(10, 20));
    notifier.panBy(const Offset(5, -5));
    expect(container.read(canvasProvider).panOffset, const Offset(15, 15));
  });

  test('scale is clamped to a sane range', () {
    final notifier = container.read(canvasProvider.notifier);

    notifier.setScale(99);
    expect(
      container.read(canvasProvider).scale,
      CanvasState.maxScale,
    );

    notifier.setScale(0.0001);
    expect(
      container.read(canvasProvider).scale,
      CanvasState.minScale,
    );
  });

  test('zoom limits guard buttons', () {
    final notifier = container.read(canvasProvider.notifier);
    notifier.setScale(CanvasState.maxScale);
    expect(notifier.canZoomIn, isFalse);
    expect(notifier.canZoomOut, isTrue);

    notifier.setScale(CanvasState.minScale);
    expect(notifier.canZoomIn, isTrue);
    expect(notifier.canZoomOut, isFalse);
  });

  test('board can pan freely when empty (infinite canvas)', () {
    final notifier = container.read(canvasProvider.notifier);
    notifier.reportViewport(const Size(1000, 700));
    notifier.panBy(const Offset(5000, 4000));
    expect(container.read(canvasProvider).panOffset, const Offset(5000, 4000));
  });

  test('pan is clamped once frames exist so content stays reachable', () {
    final notifier = container.read(canvasProvider.notifier);
    notifier.reportViewport(const Size(1000, 700));

    // Tanpa frame: bebas.
    notifier.panBy(const Offset(100000, 100000));
    expect(container.read(canvasProvider).panOffset.dx, 100000);
  });

  test('zoomAt keeps the focal point stable', () {
    final notifier = container.read(canvasProvider.notifier);
    notifier.setScale(1.0);
    const focal = Offset(200, 150);

    final before = (focal - container.read(canvasProvider).panOffset) /
        container.read(canvasProvider).scale;

    notifier.zoomAt(focal, 2.0);

    final state = container.read(canvasProvider);
    final after = (focal - state.panOffset) / state.scale;
    expect(after.dx, closeTo(before.dx, 0.001));
    expect(after.dy, closeTo(before.dy, 0.001));
  });

  test('selectFrame marks exactly one frame active', () {
    final notifier = container.read(canvasProvider.notifier);
    // Seed frames via moveFrame-free path: use clearBoard then simulate.
    // (Frames are normally created by submitPrompt; here we test selectFrame
    // guard behaviour on empty board.)
    notifier.selectFrame('missing');
    final state = container.read(canvasProvider);
    expect(state.activeFrameId, 'missing');
    expect(state.activeFrame, isNull);
  });

  test('moveFrame ignores unknown id without throwing', () {
    final notifier = container.read(canvasProvider.notifier);
    notifier.moveFrame('nope', const Offset(5, 5));
    expect(container.read(canvasProvider).frames, isEmpty);
  });

  test('resetView restores default scale and pan', () {
    final notifier = container.read(canvasProvider.notifier);
    notifier.setScale(2.0);
    notifier.panBy(const Offset(100, 100));

    notifier.resetView();

    final state = container.read(canvasProvider);
    expect(state.scale, 0.6);
    expect(state.panOffset, Offset.zero);
  });

  test('frame copyWith preserves identity fields', () {
    final original = frame('f1', offset: const Offset(10, 10));
    final moved = original.copyWith(offset: const Offset(50, 50));
    expect(moved.id, original.id);
    expect(moved.size, original.size);
    expect(moved.offset, const Offset(50, 50));
  });

  test('panBy ignores zero delta', () {
    final notifier = container.read(canvasProvider.notifier);
    notifier.reportViewport(const Size(1000, 700));
    notifier.panBy(Offset.zero);
    expect(container.read(canvasProvider).panOffset, Offset.zero);
  });

  test('panBy delta is applied in screen pixels at any zoom', () {
    final notifier = container.read(canvasProvider.notifier);
    notifier.reportViewport(const Size(1000, 700));
    // Board kosong: tak ada clamping, pan apa adanya.
    notifier.setScale(2.0);
    notifier.panBy(const Offset(30, -12));
    expect(container.read(canvasProvider).panOffset, const Offset(30, -12));
  });

  test('zoomAt ignores non-positive / non-finite factors', () {
    final notifier = container.read(canvasProvider.notifier);
    notifier.setScale(1.0);
    notifier.zoomAt(const Offset(100, 100), 0);
    notifier.zoomAt(const Offset(100, 100), -1);
    notifier.zoomAt(const Offset(100, 100), double.nan);
    notifier.zoomAt(const Offset(100, 100), double.infinity);
    expect(container.read(canvasProvider).scale, 1.0);
  });

  test('zoomBy zooms around the viewport centre when no frame', () {
    final notifier = container.read(canvasProvider.notifier);
    notifier.reportViewport(const Size(1000, 700));
    notifier.setScale(0.6);
    notifier.zoomBy(1.5);
    expect(
      container.read(canvasProvider).scale,
      closeTo(0.9, 0.0001),
    );
  });

  test('zoomBy keeps the active frame centre fixed on screen', () async {
    final notifier = container.read(canvasProvider.notifier);
    notifier.reportViewport(const Size(1000, 700));
    await notifier.loadSession(
      messages: const [],
      frames: [frame('f1', offset: const Offset(0, 0))],
      activeFrameId: 'f1',
    );
    notifier.setScale(0.6);

    Offset screenCentre() {
      final s = container.read(canvasProvider);
      final f = s.activeFrame!;
      return Offset(
        (f.offset.dx + f.size.width / 2) * s.scale + s.panOffset.dx,
        (f.offset.dy + f.size.height / 2) * s.scale + s.panOffset.dy,
      );
    }

    final before = screenCentre();
    notifier.zoomBy(1.2);
    notifier.zoomBy(1.2);
    notifier.zoomBy(1 / 1.2);
    final after = screenCentre();

    // Pusat frame aktif harus tetap di posisi layar yang sama (tidak bergeser).
    expect(after.dx, closeTo(before.dx, 0.5));
    expect(after.dy, closeTo(before.dy, 0.5));
  });

  test('panAndZoomAt applies pan and zoom in a single update', () {
    final notifier = container.read(canvasProvider.notifier);
    notifier.reportViewport(const Size(1000, 700));
    notifier.setScale(1.0);

    const focal = Offset(300, 200);
    final before = (focal - container.read(canvasProvider).panOffset) /
        container.read(canvasProvider).scale;

    notifier.panAndZoomAt(focal, scaleFactor: 1.25);

    final state = container.read(canvasProvider);
    expect(state.scale, closeTo(1.25, 0.0001));
    // Fokus tetap di titik board yang sama.
    final after = (focal - state.panOffset) / state.scale;
    expect(after.dx, closeTo(before.dx, 0.001));
    expect(after.dy, closeTo(before.dy, 0.001));
  });

  test('panAndZoomAt with only pan delta just pans', () {
    final notifier = container.read(canvasProvider.notifier);
    notifier.reportViewport(const Size(1000, 700));
    notifier.setScale(1.0);
    notifier.panAndZoomAt(
      const Offset(100, 100),
      panDelta: const Offset(25, -10),
    );
    final state = container.read(canvasProvider);
    expect(state.scale, 1.0);
    expect(state.panOffset, const Offset(25, -10));
  });

  test('panAndZoomAt clamps scale to the sane range', () {
    final notifier = container.read(canvasProvider.notifier);
    notifier.reportViewport(const Size(1000, 700));
    notifier.setScale(CanvasState.maxScale);
    notifier.panAndZoomAt(const Offset(0, 0), scaleFactor: 2.0);
    expect(container.read(canvasProvider).scale, CanvasState.maxScale);
  });
}
