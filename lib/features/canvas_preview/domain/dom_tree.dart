import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

/// Satu node pada layers tree ala Figma. Node dibangun dari DOM hasil AI
/// sehingga tree dan canvas memakai id yang sama (`data-centauri-id`).
@immutable
class DomNode {
  const DomNode({
    required this.id,
    required this.tag,
    required this.depth,
    required this.label,
    required this.children,
    this.isText = false,
  });

  /// Id stabil hasil stamping, dipakai untuk sinkronisasi tree <-> canvas.
  final String id;

  /// Nama tag (lowercase) atau `#text` untuk node teks.
  final String tag;

  /// Kedalaman relatif untuk indentasi/materialisasi tree (0 = root).
  final int depth;

  /// Label pendek untuk ditampilkan (mis. `div.card`, `#app`, `"Hello"`).
  final String label;

  /// Node teks tidak bisa di-pilih sebagai container, hanya ditampilkan.
  final bool isText;

  final List<DomNode> children;

  bool get hasChildren => children.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'id': id,
    'tag': tag,
    'depth': depth,
    'label': label,
    'isText': isText,
    'children': children.map((c) => c.toJson()).toList(),
  };

  static DomNode fromJson(Map<String, dynamic> json) => DomNode(
    id: json['id'] as String,
    tag: json['tag'] as String,
    depth: json['depth'] as int,
    label: json['label'] as String,
    isText: json['isText'] as bool? ?? false,
    children: (json['children'] as List<dynamic>)
        .map((c) => DomNode.fromJson(c as Map<String, dynamic>))
        .toList(),
  );
}

/// Hasil parsing: tree untuk panel + HTML yang sudah di-stamp id
/// (dipakai untuk render canvas dan selectors JS).
@immutable
class DomTreeResult {
  const DomTreeResult({
    required this.root,
    required this.stampedHtml,
    required this.nodeCount,
  });

  final DomNode root;
  final String stampedHtml;
  final int nodeCount;

  /// Cari node berdasarkan id (DFS). Null bila tidak ditemukan.
  DomNode? findById(String id) {
    DomNode? visit(DomNode node) {
      if (node.id == id) return node;
      for (final child in node.children) {
        final found = visit(child);
        if (found != null) return found;
      }
      return null;
    }

    return visit(root);
  }

  /// Semua node yang bisa dipilih (non-teks), urut pre-order.
  List<DomNode> get selectableNodes {
    final out = <DomNode>[];
    void visit(DomNode node) {
      if (!node.isText) out.add(node);
      for (final child in node.children) {
        visit(child);
      }
    }

    visit(root);
    return out;
  }
}

const _nodeIdAttribute = 'data-centauri-id';

const _skippedTags = {
  'script',
  'style',
  'meta',
  'link',
  'noscript',
  'template',
  'title',
  'head',
  'base',
};

/// Tag yang secara visual tidak berguna di layers panel.
bool _isPresentational(String tag) => const {
  'br',
  'wbr',
  'svg',
  'path',
  'circle',
  'rect',
  'line',
  'polygon',
  'polyline',
  'g',
  'defs',
  'use',
}.contains(tag);

/// Entry isolate-friendly: mengembalikan payload JSON yang aman
/// dilewatkan via `compute` (NFR-02).
Map<String, dynamic> buildDomTreePayload(String htmlSource) {
  final document = html_parser.parse(htmlSource);
  final body = document.body;

  var counter = 0;
  String nextId() => 'n${counter++}';

  DomNode buildElement(dom.Element element, int depth) {
    final id = nextId();
    element.attributes[_nodeIdAttribute] = id;

    final tag = (element.localName ?? 'element').toLowerCase();
    final children = <DomNode>[];

    for (final node in element.nodes) {
      if (node is dom.Element) {
        final childTag = (node.localName ?? '').toLowerCase();
        if (_skippedTags.contains(childTag) || _isPresentational(childTag)) {
          continue;
        }
        children.add(buildElement(node, depth + 1));
      } else if (node is dom.Text) {
        final text = node.data.replaceAll(RegExp(r'\s+'), ' ').trim();
        if (text.isEmpty) continue;
        children.add(
          DomNode(
            id: nextId(),
            tag: '#text',
            depth: depth + 1,
            label: text.length > 42 ? '${text.substring(0, 42)}...' : text,
            isText: true,
            children: const [],
          ),
        );
      }
    }

    return DomNode(
      id: id,
      tag: tag,
      depth: depth,
      label: _labelFor(element, tag),
      children: children,
    );
  }

  final rootChildren = <DomNode>[];
  if (body != null) {
    for (final node in body.nodes) {
      if (node is dom.Element) {
        final childTag = (node.localName ?? '').toLowerCase();
        if (_skippedTags.contains(childTag) || _isPresentational(childTag)) {
          continue;
        }
        rootChildren.add(buildElement(node, 0));
      }
    }
  }

  final root = DomNode(
    id: 'root',
    tag: 'page',
    depth: 0,
    label: 'Page',
    children: rootChildren,
  );

  return {
    'root': root.toJson(),
    'html': document.outerHtml,
    'nodeCount': counter,
  };
}

/// Versi isolate dari [buildDomTreePayload].
Future<DomTreeResult> buildDomTreeInIsolate(String htmlSource) async {
  final payload = await compute(buildDomTreePayload, htmlSource);
  return DomTreeResult(
    root: DomNode.fromJson(payload['root'] as Map<String, dynamic>),
    stampedHtml: payload['html'] as String,
    nodeCount: payload['nodeCount'] as int,
  );
}

String _labelFor(dom.Element element, String tag) {
  final id = element.id;
  if (id.isNotEmpty) return '$tag#$id';

  final classes = element.className.trim();
  if (classes.isNotEmpty) {
    final first = classes.split(RegExp(r'\s+')).first;
    return '$tag.$first';
  }
  return tag;
}
