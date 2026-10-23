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
    test('undo/redo availability is mirrored in state', () async {
      final container = makeContainer();
      final notifier = container.read(workspaceProvider.notifier);

      expect(notifier.canUndo, isFalse);
      expect(container.read(workspaceProvider).canUndo, isFalse);

      await notifier.loadSession(
        messages: const [],
        pages: [_page('page_0')],
        activePageId: 'page_0',
      );
      notifier.pushUndoSnapshot();
      expect(notifier.canUndo, isTrue);
      expect(container.read(workspaceProvider).undoDepth, 1);

      expect(notifier.undo(), isTrue);
      expect(notifier.canRedo, isTrue);
      expect(container.read(workspaceProvider).canRedo, isTrue);

      expect(notifier.redo(), isTrue);
      expect(notifier.canRedo, isFalse);
      expect(container.read(workspaceProvider).canRedo, isFalse);
    });

    test('loadSession clears history from the previous session', () async {
      final container = makeContainer();
      final notifier = container.read(workspaceProvider.notifier);

      await notifier.loadSession(
        messages: const [],
        pages: [_page('page_0')],
        activePageId: 'page_0',
      );
      notifier.pushUndoSnapshot();
      expect(notifier.canUndo, isTrue);

      await notifier.loadSession(
        messages: const [],
        pages: [_page('page_1')],
        activePageId: 'page_1',
      );
      expect(notifier.canUndo, isFalse);
      expect(notifier.canRedo, isFalse);
    });

    test('clearHistory empties stacks', () async {
      final container = makeContainer();
      final notifier = container.read(workspaceProvider.notifier);
      await notifier.loadSession(
        messages: const [],
        pages: [_page('page_0')],
        activePageId: 'page_0',
      );
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
