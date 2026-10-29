import 'package:centauri/features/canvas_preview/domain/partial_html.dart';
import 'package:centauri/features/canvas_preview/presentation/provider/generation_stream_provider.dart';
import 'package:centauri/features/canvas_preview/presentation/widgets/chat_stream_bubble.dart';
import 'package:centauri/features/canvas_preview/presentation/widgets/chat_typing_bubble.dart';
import 'package:centauri/features/canvas_preview/presentation/widgets/markdown_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

void main() {
  group('streamProse', () {
    test('membuang blok kode HTML, menyisakan kalimat penjelasan', () {
      const raw =
          'Saya buatkan halaman login.\n'
          '```html\n'
          '<!DOCTYPE html><html><body>Halo</body></html>\n'
          '```\n'
          'Halaman ini memakai satu kolom.';

      expect(
        streamProse(raw),
        'Saya buatkan halaman login.\n\nHalaman ini memakai satu kolom.',
      );
    });

    test('fence yang belum ditutup ikut disembunyikan', () {
      const raw = 'Menyiapkan.\n```html\n<div class="hero">';
      expect(streamProse(raw), 'Menyiapkan.');
    });

    test('balasan chat tanpa fence tampil utuh', () {
      expect(
        streamProse('Halo, ada yang bisa dibantu?'),
        'Halo, ada yang bisa dibantu?',
      );
    });
  });

  group('ChatStreamBubble', () {
    Future<ProviderContainer> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        testApp(home: const Scaffold(body: ChatStreamBubble())),
      );
      return ProviderScope.containerOf(
        tester.element(find.byType(ChatStreamBubble)),
      );
    }

    testWidgets('menampilkan token live untuk balasan chat', (tester) async {
      final container = await pump(tester);
      final stream = container.read(generationStreamProvider.notifier)
        ..begin(uiRequest: false);

      stream.onDelta('Halo, saya ');
      await tester.pump(const Duration(milliseconds: 120));
      stream.onDelta('sedang menulis.');
      await tester.pump(const Duration(milliseconds: 120));

      final markdown = tester.widget<MarkdownMessage>(
        find.byType(MarkdownMessage),
      );
      expect(markdown.text, 'Halo, saya sedang menulis.');
      // Tidak ada status halaman untuk percakapan biasa.
      expect(find.textContaining('halaman'), findsNothing);
    });

    testWidgets('permintaan UI menyembunyikan HTML dan menampilkan status', (
      tester,
    ) async {
      final container = await pump(tester);
      final stream = container.read(generationStreamProvider.notifier)
        ..begin(uiRequest: true, knownScreenCount: 3);

      stream.onDelta(
        'Membuat halaman login.\n```html\n<div>isi halaman</div>\n```',
      );
      await tester.pump(const Duration(milliseconds: 120));

      final markdown = tester.widget<MarkdownMessage>(
        find.byType(MarkdownMessage),
      );
      expect(markdown.text, 'Membuat halaman login.');
      expect(find.text('Menulis halaman 1 dari 3…'), findsOneWidget);
    });

    testWidgets('sebelum token pertama tampil titik tunggu', (tester) async {
      final container = await pump(tester);
      container.read(generationStreamProvider.notifier)
        ..begin(uiRequest: false);

      await tester.pump();
      expect(find.byType(ChatTypingBubble), findsOneWidget);
      expect(find.byType(MarkdownMessage), findsNothing);
    });

    testWidgets('tidak merender apa pun saat idle', (tester) async {
      await pump(tester);
      expect(find.byType(MarkdownMessage), findsNothing);
      expect(find.byType(ChatTypingBubble), findsNothing);
    });
  });
}
