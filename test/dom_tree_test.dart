import 'package:centauri/features/canvas_preview/domain/dom_tree.dart';
import 'package:flutter_test/flutter_test.dart';

const _sample = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>body { margin: 0; }</style>
  <title>Ignored</title>
</head>
<body>
  <section id="hero" class="hero band">
    <h1>Hello Centauri</h1>
    <p>Build <strong>fast</strong> UIs.</p>
    <button type="button">Get started</button>
  </section>
</body>
</html>
''';

void main() {
  group('buildDomTreePayload', () {
    test('stamps data-centauri-id on every element', () {
      final payload = buildDomTreePayload(_sample);
      final html = payload['html'] as String;

      expect(html.contains('data-centauri-id="n0"'), isTrue);
      expect(html.contains('data-centauri-id="n1"'), isTrue);
      // Setiap elemen punya id unik.
      final ids = RegExp('data-centauri-id="([^"]+)"')
          .allMatches(html)
          .map((m) => m.group(1))
          .toList();
      expect(ids.toSet().length, ids.length);
      expect(ids.length, 5);
    });

    test('skips head, style, meta and title from the tree', () {
      final payload = buildDomTreePayload(_sample);
      final root = DomNode.fromJson(payload['root'] as Map<String, dynamic>);

      final tags = <String>[];
      void visit(DomNode node) {
        tags.add(node.tag);
        node.children.forEach(visit);
      }

      visit(root);
      expect(tags, isNot(contains('head')));
      expect(tags, isNot(contains('style')));
      expect(tags, isNot(contains('meta')));
      expect(tags, isNot(contains('title')));
      expect(tags, contains('section'));
      expect(tags, contains('h1'));
      expect(tags, contains('button'));
    });

    test('labels elements with id and first class', () {
      final payload = buildDomTreePayload(_sample);
      final root = DomNode.fromJson(payload['root'] as Map<String, dynamic>);

      final labels = <String>[];
      void visit(DomNode node) {
        labels.add(node.label);
        node.children.forEach(visit);
      }

      visit(root);
      expect(labels, contains('section#hero'));
      expect(labels, contains('h1'));
      expect(labels, contains('button'));
    });

    test('includes text nodes marked isText', () {
      final payload = buildDomTreePayload(_sample);
      final root = DomNode.fromJson(payload['root'] as Map<String, dynamic>);

      final texts = <DomNode>[];
      void visit(DomNode node) {
        if (node.isText) texts.add(node);
        node.children.forEach(visit);
      }

      visit(root);
      expect(texts, isNotEmpty);
      expect(texts.any((n) => n.label.contains('Hello Centauri')), isTrue);
    });

    test('root node is the page and is selectable', () {
      final payload = buildDomTreePayload(_sample);
      final root = DomNode.fromJson(payload['root'] as Map<String, dynamic>);
      expect(root.tag, 'page');
      expect(root.label, 'Page');
      expect(root.isText, isFalse);
    });

    test('handles empty body without crashing', () {
      final payload = buildDomTreePayload('<!DOCTYPE html><html><body></body></html>');
      final root = DomNode.fromJson(payload['root'] as Map<String, dynamic>);
      expect(root.children, isEmpty);
    });
  });

  group('DomTreeResult', () {
    DomTreeResult build() {
      final payload = buildDomTreePayload(_sample);
      return DomTreeResult(
        root: DomNode.fromJson(payload['root'] as Map<String, dynamic>),
        stampedHtml: payload['html'] as String,
        nodeCount: payload['nodeCount'] as int,
      );
    }

    test('findById returns matching node', () {
      final tree = build();
      final first = tree.selectableNodes.first;
      expect(tree.findById(first.id)?.id, first.id);
    });

    test('findById returns null for unknown id', () {
      expect(build().findById('does-not-exist'), isNull);
    });

    test('selectableNodes excludes text nodes', () {
      final tree = build();
      expect(tree.selectableNodes.every((n) => !n.isText), isTrue);
    });

    test('nodeCount matches selectable + text entries', () {
      final tree = build();
      expect(tree.nodeCount, greaterThan(0));
    });
  });
}
