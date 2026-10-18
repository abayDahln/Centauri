import 'dart:typed_data';

import 'package:centauri/features/canvas_preview/data/services/canvas_webview_service.dart';
import 'package:centauri/features/canvas_preview/domain/dom_tree.dart';
import 'package:centauri/features/canvas_preview/domain/page.dart';
import 'package:centauri/features/canvas_preview/domain/prompt_mention.dart';
import 'package:centauri/features/canvas_preview/presentation/provider/workspace_provider.dart';
import 'package:centauri/features/prompt_editor/domain/attachment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

AppPage _page(String id, String name, {String slug = '', String html = ''}) =>
    AppPage(
      id: id,
      name: name,
      slug: slug.isEmpty ? '$id.html' : slug,
      html: html,
    );

Attachment _attachment(String id, String name, {int size = 10}) => Attachment(
  id: id,
  name: name,
  mimeType: 'image/png',
  bytes: Uint8List.fromList(List.filled(size, 1)),
);

DomTreeResult _tree(String html) {
  final payload = buildDomTreePayload(html);
  return DomTreeResult(
    root: DomNode.fromJson(payload['root'] as Map<String, dynamic>),
    stampedHtml: payload['html'] as String,
    nodeCount: payload['nodeCount'] as int,
  );
}

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  WorkspaceNotifier notifier() => container.read(workspaceProvider.notifier);
  WorkspaceState state() => container.read(workspaceProvider);

  group('initial state', () {
    test('starts empty in design mode with selection mode off', () {
      expect(state().pages, isEmpty);
      expect(state().activePageId, isNull);
      expect(state().activePage, isNull);
      expect(state().hasPages, isFalse);
      expect(state().outputMode, OutputMode.design);
      expect(state().selectionMode, isFalse);
      expect(state().mentions, isEmpty);
    });
  });

  group('page selection', () {
    test('setActivePage selects and clears selection', () async {
      final n = notifier();
      await n.loadSession(
        messages: const [],
        pages: [_page('page_0', 'Home'), _page('page_1', 'Pricing')],
        activePageId: 'page_0',
      );
      n.selectNode('n0');

      n.setActivePage('page_1');
      expect(state().activePageId, 'page_1');
      expect(state().activePage?.name, 'Pricing');
      expect(state().selectedNodeId, isNull);

      n.setActivePage(null);
      expect(state().activePageId, isNull);
      expect(state().activePage, isNull);
    });
  });

  group('deletePage', () {
    test('removes the page and moves active to the first remaining', () async {
      final n = notifier();
      await n.loadSession(
        messages: const [],
        pages: [
          _page('page_0', 'Home'),
          _page('page_1', 'Pricing'),
          _page('page_2', 'About'),
        ],
        activePageId: 'page_1',
      );

      n.deletePage('page_1');
      expect(state().pages.map((p) => p.id), ['page_0', 'page_2']);
      expect(state().activePageId, 'page_0');
    });

    test('clears active page when the last page is deleted', () async {
      final n = notifier();
      await n.loadSession(
        messages: const [],
        pages: [_page('page_0', 'Home')],
        activePageId: 'page_0',
      );
      n.deletePage('page_0');
      expect(state().pages, isEmpty);
      expect(state().activePageId, isNull);
    });

    test('deleting a non-active page keeps the active one', () async {
      final n = notifier();
      await n.loadSession(
        messages: const [],
        pages: [_page('page_0', 'Home'), _page('page_1', 'Pricing')],
        activePageId: 'page_1',
      );
      n.deletePage('page_0');
      expect(state().activePageId, 'page_1');
    });
  });

  group('renamePage', () {
    test('trims and applies the new name', () async {
      final n = notifier();
      await n.loadSession(
        messages: const [],
        pages: [_page('page_0', 'Home')],
        activePageId: 'page_0',
      );
      n.renamePage('page_0', '  Landing  ');
      expect(state().pages.single.name, 'Landing');
    });

    test('ignores an empty name', () async {
      final n = notifier();
      await n.loadSession(
        messages: const [],
        pages: [_page('page_0', 'Home')],
        activePageId: 'page_0',
      );
      n.renamePage('page_0', '   ');
      expect(state().pages.single.name, 'Home');
    });
  });

  group('updatePageHtml', () {
    test('replaces html + tree and drops stale selection', () async {
      final n = notifier();
      await n.loadSession(
        messages: const [],
        pages: [_page('page_0', 'Home')],
        activePageId: 'page_0',
      );
      n.selectNode('node-that-does-not-exist');

      final tree = _tree('<div id="x">Hello</div>');
      n.updatePageHtml(
        pageId: 'page_0',
        stampedHtml: tree.stampedHtml,
        tree: tree,
      );

      expect(state().activePage!.html, contains('data-centauri-id'));
      expect(state().activePage!.domTree, isNotNull);
      // Node lama tidak ada di tree baru -> seleksi dibuang.
      expect(state().selectedNodeId, isNull);
    });

    test('keeps selection when the node still exists', () async {
      final n = notifier();
      await n.loadSession(
        messages: const [],
        pages: [_page('page_0', 'Home')],
        activePageId: 'page_0',
      );
      final tree = _tree('<div id="x">Hello</div>');
      final existingId = tree.selectableNodes.first.id;
      n.selectNode(existingId);

      n.updatePageHtml(
        pageId: 'page_0',
        stampedHtml: tree.stampedHtml,
        tree: tree,
      );
      expect(state().selectedNodeId, existingId);
    });
  });

  group('clearWorkspace', () {
    test('resets pages, messages and generation flags', () async {
      final n = notifier();
      await n.loadSession(
        messages: const [CanvasMessage(role: ChatRole.user, text: 'hi')],
        pages: [_page('page_0', 'Home')],
        activePageId: 'page_0',
      );
      n.clearWorkspace();
      expect(state().pages, isEmpty);
      expect(state().messages, isEmpty);
      expect(state().activePageId, isNull);
      expect(state().isGenerating, isFalse);
    });
  });

  group('selection + hover', () {
    test('selectNode null clears, non-null sets', () {
      final n = notifier();
      n.selectNode('n1');
      expect(state().selectedNodeId, 'n1');
      n.selectNode(null);
      expect(state().selectedNodeId, isNull);
    });

    test('updateNodeGeometry ignores mismatched id', () {
      final n = notifier();
      n.selectNode('n1');
      n.updateNodeGeometry(
        const NodeGeometry(
          id: 'other',
          tag: 'div',
          x: 0,
          y: 0,
          width: 1,
          height: 1,
        ),
      );
      expect(state().selectedNodeGeometry, isNull);

      n.updateNodeGeometry(
        const NodeGeometry(
          id: 'n1',
          tag: 'div',
          x: 1,
          y: 2,
          width: 3,
          height: 4,
        ),
      );
      expect(state().selectedNodeGeometry!.width, 3);
    });

    test('hoverNode guards duplicate values', () {
      final n = notifier();
      n.hoverNode('n1');
      expect(state().hoveredNodeId, 'n1');
      n.hoverNode('n1');
      expect(state().hoveredNodeId, 'n1');
      n.hoverNode(null);
      expect(state().hoveredNodeId, isNull);
    });
  });

  group('output mode + link intercept', () {
    test('setOutputMode switches between design and dev', () {
      final n = notifier();
      n.setOutputMode(OutputMode.dev);
      expect(state().outputMode, OutputMode.dev);
      n.setOutputMode(OutputMode.dev); // no-op
      expect(state().outputMode, OutputMode.dev);
    });

    test('toggleSelectionMode flips the flag', () {
      final n = notifier();
      expect(state().selectionMode, isFalse);
      n.toggleSelectionMode();
      expect(state().selectionMode, isTrue);
      n.toggleSelectionMode();
      expect(state().selectionMode, isFalse);
    });
  });

  group('attachments', () {
    test('adds unique attachments and rejects duplicates silently', () {
      final n = notifier();
      expect(n.addAttachment(_attachment('a1', 'ref.png')), isNull);
      expect(n.addAttachment(_attachment('a1', 'ref.png')), isNull);
      expect(state().attachments.length, 1);
    });

    test('enforces a maximum of 6 attachments', () {
      final n = notifier();
      for (var i = 0; i < 6; i++) {
        expect(n.addAttachment(_attachment('a$i', 'f$i.png')), isNull);
      }
      expect(state().attachments.length, 6);
      expect(n.addAttachment(_attachment('a9', 'extra.png')), isNotNull);
    });

    test('removeAttachment and clearAttachments work', () {
      final n = notifier();
      n.addAttachment(_attachment('a1', 'a.png'));
      n.addAttachment(_attachment('a2', 'b.png'));
      n.removeAttachment('a1');
      expect(state().attachments.map((a) => a.id), ['a2']);
      n.clearAttachments();
      expect(state().attachments, isEmpty);
    });
  });

  group('prompt mentions', () {
    test('element mention replaces the previous element', () async {
      final n = notifier();
      await n.loadSession(
        messages: const [],
        pages: [_page('page_0', 'Beranda')],
        activePageId: 'page_0',
      );
      n.addElementMention(nodeId: 'n1', label: 'button · Kirim');
      expect(state().mentions.length, 1);
      expect(state().mentions.first.kind, PromptMentionKind.element);
      expect(state().mentions.first.pageName, 'Beranda');
      n.addElementMention(nodeId: 'n2', label: 'input · Email');
      expect(state().mentions.length, 1);
      expect(state().mentions.first.nodeId, 'n2');
    });

    test('page and all-pages mentions dedupe and can be removed', () async {
      final n = notifier();
      await n.loadSession(
        messages: const [],
        pages: [_page('page_0', 'Beranda'), _page('page_1', 'Harga')],
        activePageId: 'page_0',
      );
      n.addPageMention(state().pages.first);
      n.addPageMention(state().pages.first);
      n.addAllPagesMention();
      n.addAllPagesMention();
      expect(state().mentions.length, 2);
      n.removeMention(state().mentions.last);
      expect(state().mentions.length, 1);
      expect(state().mentions.single.kind, PromptMentionKind.page);
    });
  });

  group('undo / redo', () {
    test('recordHistory + undo/redo round-trip', () async {
      final n = notifier();
      expect(n.canUndo, isFalse);

      final before = state();
      await n.loadSession(
        messages: const [],
        pages: [_page('page_0', 'Home')],
        activePageId: 'page_0',
      );
      n.recordHistory(before);

      expect(n.canUndo, isTrue);
      expect(n.undo(), isTrue);
      expect(state().pages, isEmpty);
      expect(n.canRedo, isTrue);

      expect(n.redo(), isTrue);
      expect(state().pages.length, 1);
      expect(n.canRedo, isFalse);
    });

    test('pushUndoSnapshot records exactly once', () {
      final n = notifier();
      n.pushUndoSnapshot();
      expect(n.undoDepth, 1);
      n.pushUndoSnapshot(); // identik -> tidak dobel
      expect(n.undoDepth, 1);
    });

    test('clearHistory empties both stacks', () {
      final n = notifier();
      n.pushUndoSnapshot();
      expect(n.canUndo, isTrue);
      n.clearHistory();
      expect(n.canUndo, isFalse);
      expect(n.canRedo, isFalse);
    });

    test('undo/redo on empty stacks return false', () {
      final n = notifier();
      expect(n.undo(), isFalse);
      expect(n.redo(), isFalse);
    });
  });

  group('loadSession', () {
    test('rebuilds pages with stamped html via isolate', () async {
      final n = notifier();
      await n.loadSession(
        messages: const [],
        pages: [
          _page(
            'page_0',
            'Home',
            html: '<!DOCTYPE html><html><body><div>Hi</div></body></html>',
          ),
        ],
        activePageId: 'page_0',
      );
      final page = state().activePage!;
      expect(page.domTree, isNotNull);
      expect(page.html, contains('data-centauri-id'));
    });

    test('keeps empty-html pages untouched', () async {
      final n = notifier();
      await n.loadSession(
        messages: const [],
        pages: [_page('page_0', 'Home')],
        activePageId: 'page_0',
      );
      expect(state().activePage!.html, isEmpty);
      expect(state().activePage!.domTree, isNull);
    });
  });

  group('submitPrompt guard', () {
    test('blank prompt is ignored', () async {
      final n = notifier();
      await n.submitPrompt('   ');
      expect(state().isGenerating, isFalse);
      expect(state().messages, isEmpty);
    });
  });
}
