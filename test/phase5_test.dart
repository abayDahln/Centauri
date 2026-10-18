import 'package:centauri/features/canvas_preview/domain/page.dart';
import 'package:centauri/features/canvas_preview/presentation/provider/workspace_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AppPage _page(String id, {String html = ''}) =>
    AppPage(id: id, name: id, slug: '$id.html', html: html);

void main() {
  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('WorkspaceNotifier undo/redo (Fase 5a)', () {
    test(
      'a content change is recorded and undo restores prior pages',
      () async {
        final container = makeContainer();
        final notifier = container.read(workspaceProvider.notifier);

        expect(notifier.canUndo, isFalse);

        // Simulasi satu perubahan konten: state kosong -> 1 halaman.
        final before = container.read(workspaceProvider);
        await notifier.loadSession(
          messages: const [],
          pages: [_page('page_0')],
          activePageId: 'page_0',
        );
        notifier.recordHistory(before);
        expect(notifier.canUndo, isTrue);

        expect(notifier.undo(), isTrue);
        expect(container.read(workspaceProvider).pages, isEmpty);
        expect(notifier.canRedo, isTrue);
        expect(notifier.redo(), isTrue);
        expect(notifier.canRedo, isFalse);
      },
    );

    test(
      'loadSession is undoable and restores the previous workspace',
      () async {
        final container = makeContainer();
        final notifier = container.read(workspaceProvider.notifier);

        final before = container.read(workspaceProvider);
        await notifier.loadSession(
          messages: const [],
          pages: [_page('page_0')],
          activePageId: 'page_0',
        );
        notifier.recordHistory(before);

        expect(container.read(workspaceProvider).pages.length, 1);
        expect(notifier.canUndo, isTrue);

        notifier.undo();
        expect(container.read(workspaceProvider).pages, isEmpty);
      },
    );

    test('pushUndoSnapshot records current state exactly once', () {
      final container = makeContainer();
      final notifier = container.read(workspaceProvider.notifier);

      notifier.pushUndoSnapshot();
      expect(notifier.undoDepth, 1);
      notifier.pushUndoSnapshot(); // identik -> tidak dobel
      expect(notifier.undoDepth, 1);
    });

    test('clearHistory empties stacks', () {
      final container = makeContainer();
      final notifier = container.read(workspaceProvider.notifier);
      notifier.pushUndoSnapshot();
      expect(notifier.canUndo, isTrue);
      notifier.clearHistory();
      expect(notifier.canUndo, isFalse);
      expect(notifier.canRedo, isFalse);
    });

    test('undo on empty stack returns false', () {
      final container = makeContainer();
      final notifier = container.read(workspaceProvider.notifier);
      expect(notifier.undo(), isFalse);
      expect(notifier.redo(), isFalse);
    });
  });
}
