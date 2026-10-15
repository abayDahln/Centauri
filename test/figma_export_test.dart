import 'dart:convert';

import 'package:centauri/features/canvas_preview/data/services/canvas_webview_service.dart';
import 'package:centauri/features/code_exporter/data/figma_export_service.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _payload() => {
  'app': 'centauri',
  'format': 'centauri-figma',
  'version': 1,
  'page': {'name': 'Home', 'slug': 'home.html', 'width': 1440, 'height': 2400},
  'nodes': [
    {
      'id': 'n0',
      'tag': 'section',
      'name': 'section#hero',
      'rect': {'x': 0, 'y': 0, 'w': 1440, 'h': 600},
      'styles': {'backgroundColor': 'rgb(255, 255, 255)'},
      'text': '',
      'children': [
        {
          'id': 'n1',
          'tag': 'h1',
          'name': 'h1',
          'rect': {'x': 40, 'y': 80, 'w': 600, 'h': 60},
          'styles': {'fontSize': '48px', 'color': 'rgb(17, 24, 39)'},
          'text': 'Hello Centauri',
          'children': <dynamic>[],
        },
      ],
    },
  ],
};

void main() {
  group('CanvasSelectEvent figma payload', () {
    test('parses a figma event with payload map', () {
      final event = CanvasSelectEvent.tryParse({
        'type': 'figma',
        'payload': _payload(),
      });
      expect(event, isNotNull);
      expect(event!.type, 'figma');
      expect(event.payload, isNotNull);
      expect(event.payload!['format'], 'centauri-figma');
    });

    test('parses a figmaError event', () {
      final event = CanvasSelectEvent.tryParse({
        'type': 'figmaError',
        'message': 'Dokumen belum siap.',
      });
      expect(event!.type, 'figmaError');
      expect(event.errorMessage, 'Dokumen belum siap.');
      expect(event.payload, isNull);
    });
  });

  group('FigmaExportService.buildFigmaJson', () {
    final service = FigmaExportService();

    test('wraps payload with envelope metadata', () {
      final json = service.buildFigmaJson(_payload());
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded['app'], 'centauri');
      expect(decoded['format'], 'centauri-figma');
      expect(decoded['version'], FigmaExportService.currentVersion);
      expect(decoded['exportedAt'], isA<String>());
      expect(decoded['page'], isA<Map>());
      expect((decoded['nodes'] as List).length, 1);
    });

    test('throws when there are no nodes', () {
      expect(
        () => service.buildFigmaJson({'page': {}, 'nodes': <dynamic>[]}),
        throwsA(isA<FigmaExportException>()),
      );
      expect(
        () => service.buildFigmaJson({'page': {}}),
        throwsA(isA<FigmaExportException>()),
      );
    });
  });

  group('FigmaExportService.countNodes', () {
    test('counts nodes recursively', () {
      expect(FigmaExportService().countNodes(_payload()), 2);
    });

    test('returns 0 when nodes is missing or empty', () {
      expect(FigmaExportService().countNodes(const {}), 0);
      expect(FigmaExportService().countNodes({'nodes': <dynamic>[]}), 0);
    });
  });
}
