import 'dart:typed_data';

import 'package:centauri/features/canvas_preview/domain/page.dart';
import 'package:centauri/features/canvas_preview/presentation/provider/workspace_provider.dart';
import 'package:centauri/features/history/domain/project.dart';
import 'package:centauri/features/prompt_editor/domain/attachment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Project serialization (schema v2)', () {
    Project sample() => Project(
      id: 'p1',
      title: 'Landing Page',
      messages: const [
        ProjectMessage(
          role: 'user',
          text: 'buatkan landing page',
          kind: 'chat',
        ),
        ProjectMessage(role: 'assistant', text: '<!DOCTYPE html>', kind: 'ui'),
      ],
      pages: const [
        ProjectPage(
          id: 'page_0',
          name: 'Home',
          slug: 'home.html',
          html: '<html></html>',
        ),
      ],
      activePageId: 'page_0',
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
      expect(restored.pages.single.name, 'Home');
      expect(restored.pages.single.slug, 'home.html');
      expect(restored.activePageId, 'page_0');
      expect(restored.createdAt, DateTime(2026, 1, 1));
    });

    test('writes the current schema version', () {
      expect(sample().toJson()['schemaVersion'], kProjectSchemaVersion);
      expect(kProjectSchemaVersion, 2);
    });

    test('preview uses first user message', () {
      expect(sample().preview, contains('landing page'));
    });

    test('survives missing/empty fields', () {
      final restored = Project.fromJson({'id': 'x'});
      expect(restored.id, 'x');
      expect(restored.messages, isEmpty);
      expect(restored.pages, isEmpty);
      expect(restored.title, isNotEmpty);
    });

    test('copyWith updates title and keeps id', () {
      final renamed = sample().copyWith(title: 'Baru');
      expect(renamed.id, 'p1');
      expect(renamed.title, 'Baru');
      expect(renamed.pages.length, 1);
    });

    test('round-trips message attachments', () {
      final project = Project(
        id: 'p2',
        title: 'With image',
        messages: [
          ProjectMessage(
            role: 'user',
            text: 'buat ulang design ini',
            kind: 'chat',
            attachmentNames: const ['ref.png'],
            attachments: [
              Attachment(
                id: 'a1',
                name: 'ref.png',
                mimeType: 'image/png',
                bytes: Uint8List.fromList([1, 2, 3, 4]),
              ),
            ],
          ),
        ],
        pages: const [],
        activePageId: null,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final restored = Project.fromJson(project.toJson());
      final message = restored.messages.single;
      expect(message.attachmentNames, ['ref.png']);
      expect(message.attachments.length, 1);
      expect(message.attachments.first.name, 'ref.png');
      expect(message.attachments.first.bytes, [1, 2, 3, 4]);
      expect(message.attachments.first.mimeType, 'image/png');
    });
  });

  group('Project v1 -> v2 migration', () {
    test('maps legacy frames to pages and drops coordinates', () {
      final legacy = <String, dynamic>{
        'id': 'legacy',
        'title': 'Old board',
        'messages': <dynamic>[],
        'frames': <dynamic>[
          {
            'id': 'frame_0',
            'title': 'Landing Page',
            'html': '<html><body>old</body></html>',
            'offset': {'dx': 80, 'dy': 40},
            'size': {'width': 390, 'height': 844},
          },
          {
            'id': 'frame_1',
            'title': 'Pricing',
            'html': '<html><body>price</body></html>',
          },
        ],
        'activeFrameId': 'frame_0',
      };

      final project = Project.fromJson(legacy);
      expect(project.pages.length, 2);
      expect(project.pages.first.id, 'frame_0');
      expect(project.pages.first.name, 'Landing Page');
      expect(project.pages.first.slug, 'landing-page.html');
      expect(project.pages.first.html, contains('old'));
      expect(project.pages[1].slug, 'pricing.html');
      // activeFrameId dipetakan ke activePageId.
      expect(project.activePageId, 'frame_0');
    });

    test('deduplicates slugs during migration', () {
      final legacy = <String, dynamic>{
        'id': 'legacy',
        'frames': <dynamic>[
          {'id': 'f0', 'title': 'Home', 'html': ''},
          {'id': 'f1', 'title': 'Home', 'html': ''},
        ],
      };
      final project = Project.fromJson(legacy);
      expect(project.pages.map((p) => p.slug), ['home.html', 'home-2.html']);
    });

    test('migration yields empty pages when no frames present', () {
      final project = Project.fromJson({'id': 'x'});
      expect(project.pages, isEmpty);
    });
  });

  group('Project.fromCanvas', () {
    test('snapshots workspace pages and messages', () {
      // Tidak butuh ProviderContainer: bikin state langsung.
      final state = WorkspaceState(
        pages: const [
          AppPage(id: 'page_0', name: 'Home', slug: 'home.html', html: 'x'),
        ],
        activePageId: 'page_0',
        messages: const [
          CanvasMessage(role: ChatRole.user, text: 'hi', displayText: 'hi'),
        ],
      );
      final project = Project.fromCanvas(
        id: 'p',
        title: 'T',
        state: state,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(project.pages.single.slug, 'home.html');
      expect(project.activePageId, 'page_0');
      expect(project.messages.single.text, 'hi');
    });
  });
}
