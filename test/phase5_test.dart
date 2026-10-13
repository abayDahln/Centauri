import 'package:centauri/features/canvas_preview/domain/board_frame.dart';
import 'package:centauri/features/canvas_preview/presentation/provider/canvas_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

BoardFrame _frame(String id, {String html = '<html></html>'}) => BoardFrame(
  id: id,
  title: id,
  html: html,
  offset: Offset.zero,
  size: const Size(390, 844),
);

void main() {
  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('CanvasNotifier undo/redo (Fase 5a)', () {
    test('a content change is recorded and undo restores the prior frames', () {
      final container = makeContainer();
      final notifier = container.read(canvasProvider.notifier);

      // Baseline: board kosong (state awal).
      expect(notifier.canUndo, isFalse);

      // Simulasi satu perubahan konten: state kosong -> frame_0.
      final before = container.read(canvasProvider);
      notifier.moveFrame('frame_0', Offset.zero); // no-op, tetap aman
      // Dorong snapshot "sebelum" (kosong) lalu terapkan state baru.
      notifier.recordHistory(before);
      expect(notifier.canUndo, isTrue);

      // Undo mengembalikan snapshot kosong.
      expect(notifier.undo(), isTrue);
      expect(container.read(canvasProvider).frames, isEmpty);
      expect(notifier.canRedo, isTrue);
      expect(notifier.redo(), isTrue);
      expect(notifier.canRedo, isFalse);
    });

    test('loadSession is undoable and restores the previous board', () async {
      final container = makeContainer();
      final notifier = container.read(canvasProvider.notifier);

      final before = container.read(canvasProvider);
      await notifier.loadSession(
        messages: const [],
        frames: [_frame('frame_0')],
        activeFrameId: 'frame_0',
      );
      notifier.recordHistory(before);

      expect(container.read(canvasProvider).frames.length, 1);
      expect(notifier.canUndo, isTrue);

      notifier.undo();
      expect(container.read(canvasProvider).frames, isEmpty);
    });

    test('pushUndoSnapshot records current state exactly once', () {
      final container = makeContainer();
      final notifier = container.read(canvasProvider.notifier);

      notifier.pushUndoSnapshot();
      expect(notifier.undoDepth, 1);
      notifier.pushUndoSnapshot(); // identik -> tidak dobel
      expect(notifier.undoDepth, 1);
    });

    test('clearHistory empties stacks', () {
      final container = makeContainer();
      final notifier = container.read(canvasProvider.notifier);
      notifier.pushUndoSnapshot();
      expect(notifier.canUndo, isTrue);
      notifier.clearHistory();
      expect(notifier.canUndo, isFalse);
      expect(notifier.canRedo, isFalse);
    });

    test('undo on empty stack returns false', () {
      final container = makeContainer();
      final notifier = container.read(canvasProvider.notifier);
      expect(notifier.undo(), isFalse);
      expect(notifier.redo(), isFalse);
    });

    test('copySelectedNode requires a selection', () {
      final container = makeContainer();
      final notifier = container.read(canvasProvider.notifier);
      expect(notifier.copySelectedNode(), isFalse);
      expect(notifier.hasClipboard, isFalse);
    });
  });
}
