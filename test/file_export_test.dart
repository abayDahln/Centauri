import 'dart:convert';
import 'dart:typed_data';

import 'package:centauri/features/code_exporter/data/page_export_service.dart';
import 'package:centauri/features/history/data/mydesign_service.dart';
import 'package:centauri/features/history/domain/project.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart' as xml;

Project _sample() => Project(
  id: 'p1',
  title: 'Landing Page',
  messages: const [
    ProjectMessage(role: 'user', text: 'buatkan landing page', kind: 'chat'),
  ],
  pages: const [
    ProjectPage(
      id: 'page_0',
      name: 'Home',
      slug: 'home.html',
      html: '<!DOCTYPE html><html><body>Halo</body></html>',
    ),
  ],
  activePageId: 'page_0',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 2),
);

void main() {
  group('MydesignService (.mydesign)', () {
    final service = MydesignService();

    test('round-trips project through envelope JSON', () {
      final raw = service.buildMydesignJson(_sample());
      expect(raw, contains('"format": "mydesign"'));
      expect(raw, contains('"version": 2'));

      final restored = service.parseMydesign(raw);
      expect(restored.id, 'p1');
      expect(restored.title, 'Landing Page');
      expect(restored.pages.single.name, 'Home');
      expect(restored.pages.single.slug, 'home.html');
      expect(restored.pages.single.html, contains('Halo'));
      expect(restored.activePageId, 'page_0');
    });

    test('accepts raw project JSON without envelope', () {
      final restored = service.parseMydesign(
        '{"id":"x","pages":[{"id":"p","name":"T","slug":"t.html","html":"<p>hi</p>"}]}',
      );
      expect(restored.id, 'x');
      expect(restored.pages.single.html, contains('hi'));
    });

    test('migrates a v1 envelope (frames -> pages)', () {
      const v1 =
          '{"app":"centauri","format":"mydesign","version":1,'
          '"project":{"id":"x","frames":[{"id":"f","title":"Home","html":"<p>hi</p>"}]}}';
      final restored = service.parseMydesign(v1);
      expect(restored.pages.single.name, 'Home');
      expect(restored.pages.single.slug, 'home.html');
    });

    test('rejects non-JSON content', () {
      expect(
        () => service.parseMydesign('bukan json {{{'),
        throwsA(isA<MydesignException>()),
      );
    });

    test('rejects foreign envelope', () {
      expect(
        () => service.parseMydesign(
          '{"app":"other","format":"mydesign","version":2,"project":{"id":"x"}}',
        ),
        throwsA(isA<MydesignException>()),
      );
    });

    test('rejects newer version', () {
      expect(
        () => service.parseMydesign(
          '{"app":"centauri","format":"mydesign","version":99,"project":{"id":"x"}}',
        ),
        throwsA(isA<MydesignException>()),
      );
    });

    test('rejects empty project', () {
      expect(
        () => service.parseMydesign(
          '{"app":"centauri","format":"mydesign","version":2,"project":{"id":"x","pages":[],"messages":[]}}',
        ),
        throwsA(isA<MydesignException>()),
      );
    });
  });

  group('PageExportService.buildStandaloneSvg', () {
    final service = PageExportService();

    test('wraps html in svg foreignObject with dimensions', () {
      final svg = service.buildStandaloneSvg(
        html: '<p>Halo</p>',
        width: 390,
        height: 844,
      );
      expect(svg, contains('<svg'));
      expect(svg, contains('foreignObject'));
      expect(svg, contains('width="390"'));
      expect(svg, contains('height="844"'));
      expect(
        svg,
        contains(
          '<html xmlns="http://www.w3.org/1999/xhtml">'
          '<head></head><body><p>Halo</p></body></html>',
        ),
      );
    });

    test('strips script tags and escapes CDATA terminators', () {
      final svg = service.buildStandaloneSvg(
        html: '<p>a]]>b</p><script>alert(1)</script>',
        width: 100,
        height: 100,
      );
      expect(svg, isNot(contains('alert(1)')));
      expect(svg, isNot(contains(']]>')));
    });

    test('emits well-formed XML for messy HTML5 input', () {
      final svg = service.buildStandaloneSvg(
        html: '<!DOCTYPE html>'
            '<HTML><HEAD><meta charset=utf-8>'
            '<style>.a{content:">"}</style></HEAD><BODY>'
            '<!-- comment with <weird> & chars -->'
            '<div><h1>Title &amp; more</h1>'
            '<img src=a.png alt=x width=10><br><hr>'
            '<ul><li>one<li>two</ul>'
            '<svg viewBox="0 0 10 10"><path d="M0 0L10 10"/></svg>'
            '<script>var a = "</p>";</script>'
            '</div></BODY></HTML>',
        width: 390,
        height: 844,
      );
      final parsed = xml.XmlDocument.parse(svg);
      expect(parsed.findAllElements('foreignObject'), hasLength(1));
      expect(svg, contains('<img src="a.png" alt="x" width="10"/>'));
      expect(svg, contains('<br/>'));
      expect(svg, isNot(contains('<!--')));
      expect(svg, isNot(contains('alert')));
    });

    test('falls back to default size for invalid dimensions', () {
      final svg = service.buildStandaloneSvg(
        html: 'x',
        width: 0,
        height: -5,
      );
      expect(svg, contains('width="1440"'));
      expect(svg, contains('height="2000"'));
    });
  });

  group('PageExportService.buildPdfFromPng', () {
    test('produces a non-empty PDF from a 1x1 PNG', () async {
      final png = _tinyPng();
      final pdf = await PageExportService().buildPdfFromPng(png);
      expect(pdf, isNotEmpty);
      expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
    });
  });
}

/// PNG 1x1 (base64) agar test tidak butuh WebView.
Uint8List _tinyPng() => base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);
