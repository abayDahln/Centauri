import 'package:centauri/features/history/domain/project.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Project serialization', () {
    Project sample() => Project(
      id: 'p1',
      title: 'Landing Page',
      messages: const [
        ProjectMessage(role: 'user', text: 'buatkan landing page', kind: 'chat'),
        ProjectMessage(role: 'assistant', text: '<!DOCTYPE html>', kind: 'ui'),
      ],
      frames: const [
        ProjectFrame(
          id: 'frame_0',
          title: 'Landing Page',
          html: '<html></html>',
          offset: Offset(80, 40),
          size: Size(390, 844),
        ),
      ],
      activeFrameId: 'frame_0',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 2),
    );

    test('round-trips through JSON', () {
      final original = sample();
      final restored = Project.fromJson(original.toJson());

      expect(restored.id, 'p1');
      expect(restored.title, 'Landing Page');
      expect(restored.messages.length, 2);
      expect(restored.messages[1].kind, 'ui');
      expect(restored.frames.single.offset, const Offset(80, 40));
      expect(restored.frames.single.size, const Size(390, 844));
      expect(restored.activeFrameId, 'frame_0');
      expect(restored.createdAt, DateTime(2026, 1, 1));
    });

    test('preview uses first user message', () {
      expect(sample().preview, contains('landing page'));
    });

    test('survives missing/empty fields', () {
      final restored = Project.fromJson({'id': 'x'});
      expect(restored.id, 'x');
      expect(restored.messages, isEmpty);
      expect(restored.frames, isEmpty);
      expect(restored.title, isNotEmpty);
    });

    test('copyWith updates title and keeps id', () {
      final renamed = sample().copyWith(title: 'Baru');
      expect(renamed.id, 'p1');
      expect(renamed.title, 'Baru');
      expect(renamed.frames.length, 1);
    });
  });
}
