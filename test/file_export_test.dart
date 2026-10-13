import 'dart:convert';
import 'dart:typed_data';

import 'package:centauri/features/code_exporter/data/frame_export_service.dart';
import 'package:centauri/features/history/data/mydesign_service.dart';
import 'package:centauri/features/history/domain/project.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Project _sample() => Project(
  id: 'p1',
  title: 'Landing Page',
  messages: const [
    ProjectMessage(role: 'user', text: 'buatkan landing page', kind: 'chat'),
  ],
  frames: const [
    ProjectFrame(
      id: 'frame_0',
      title: 'Landing Page',
      html: '<!DOCTYPE html><html><body>Halo</body></html>',
      offset: Offset(80, 40),
      size: Size(390, 844),
    ),
  ],
  activeFrameId: 'frame_0',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 2),
);

void main() {
  group('MydesignService (.mydesign)', () {
    final service = MydesignService();

    test('round-trips project through envelope JSON', () {
      final raw = service.buildMydesignJson(_sample());
      expect(raw, contains('"format": "mydesign"'));
      expect(raw, contains('"version": 1'));

      final restored = service.parseMydesign(raw);
      expect(restored.id, 'p1');
      expect(restored.title, 'Landing Page');
      expect(restored.frames.single.offset, const Offset(80, 40));
      expect(restored.frames.single.size, const Size(390, 844));
      expect(restored.frames.single.html, contains('Halo'));
      expect(restored.activeFrameId, 'frame_0');
    });

    test('accepts raw project JSON without envelope', () {
      final restored = service.parseMydesign(
        '{"id":"x","frames":[{"id":"f","title":"T","html":"<p>hi</p>"}]}',
      );
      expect(restored.id, 'x');
      expect(restored.frames.single.html, contains('hi'));
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
          '{"app":"other","format":"mydesign","version":1,"project":{"id":"x"}}',
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
          '{"app":"centauri","format":"mydesign","version":1,"project":{"id":"x","frames":[],"messages":[]}}',
        ),
        throwsA(isA<MydesignException>()),
      );
    });
  });

  group('FrameExportService.buildStandaloneSvg', () {
    final service = FrameExportService();

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
      // HTML mentah tidak boleh bocor sebagai markup aktif.
      expect(svg, isNot(contains('<p>Halo</p>')));
    });

    test('falls back to default size for invalid dimensions', () {
      final svg = service.buildStandaloneSvg(
        html: 'x',
        width: 0,
        height: -5,
      );
      expect(svg, contains('width="390"'));
    });
  });

  group('FrameExportService.buildPdfFromPng', () {
    test('produces a non-empty PDF from a 1x1 PNG', () async {
      // PNG 1x1 transparan.
      final png = _tinyPng();
      final pdf = await FrameExportService().buildPdfFromPng(png);
      expect(pdf, isNotEmpty);
      // Header PDF.
      expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
    });
  });
}

/// PNG 1x1 (base64) agar test tidak butuh WebView.
Uint8List _tinyPng() => base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);
