import 'dart:convert';

import 'package:centauri/features/canvas_preview/data/services/canvas_webview_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CanvasSelectEvent.tryParse', () {
    test('parses a JSON string (mobile JS channel)', () {
      final event = CanvasSelectEvent.tryParse(
        jsonEncode({'type': 'resize', 'height': 1200}),
      );
      expect(event, isNotNull);
      expect(event!.type, 'resize');
      expect(event.contentHeight, 1200);
    });

    test('parses a decoded Map (webview_windows webMessage)', () {
      // Plugin webview_windows men-decode JSON sebelum ke Dart, sehingga
      // listener menerima Map, bukan String. Ini regression test untuk bug
      // canvas putih + inspector stuck di Windows.
      final event = CanvasSelectEvent.tryParse({
        'type': 'resize',
        'height': 2400,
      });
      expect(event, isNotNull);
      expect(event!.type, 'resize');
      expect(event.contentHeight, 2400);
    });

    test('parses geometry Map with node id', () {
      final event = CanvasSelectEvent.tryParse({
        'type': 'geometry',
        'id': 'n3',
        'tag': 'section',
        'rect': {'x': 0, 'y': 10, 'w': 390, 'h': 200},
        'styles': {'display': 'block'},
      });
      expect(event, isNotNull);
      expect(event!.id, 'n3');
      expect(event.geometry, isNotNull);
      expect(event.geometry!.width, 390);
    });

    test('returns null for empty or invalid payloads', () {
      expect(CanvasSelectEvent.tryParse(''), isNull);
      expect(CanvasSelectEvent.tryParse('   '), isNull);
      expect(CanvasSelectEvent.tryParse('bukan json'), isNull);
      expect(CanvasSelectEvent.tryParse({'nope': 1}), isNull);
      expect(CanvasSelectEvent.tryParse(null), isNull);
      expect(CanvasSelectEvent.tryParse(42), isNull);
    });
  });
}
