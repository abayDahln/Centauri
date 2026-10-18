import 'package:centauri/features/canvas_preview/presentation/provider/workspace_provider.dart';
import 'package:centauri/features/provider_config/data/datasources/ai_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('Cancel generate (regression UX)', () {
    test('cancelGeneration on idle is a no-op', () {
      final container = makeContainer();
      final notifier = container.read(workspaceProvider.notifier);
      expect(container.read(workspaceProvider).isGenerating, isFalse);
      notifier.cancelGeneration();
      expect(container.read(workspaceProvider).isGenerating, isFalse);
      expect(container.read(workspaceProvider).messages, isEmpty);
    });

    test('cancelGeneration is idempotent when nothing is running', () {
      final container = makeContainer();
      final notifier = container.read(workspaceProvider.notifier);
      AiApiService.cancelAll();
      AiApiService.cancelAll();
      notifier.cancelGeneration();
      expect(container.read(workspaceProvider).isGenerating, isFalse);
    });

    test('cancelAll is safe with no active requests', () {
      expect(AiApiService.cancelAll, returnsNormally);
    });
  });

  group('isUiRequestPrompt (MODE GATE)', () {
    test('greetings stay chat', () {
      expect(isUiRequestPrompt('hello'), isFalse);
      expect(isUiRequestPrompt('halo!'), isFalse);
      expect(isUiRequestPrompt('selamat pagi'), isFalse);
    });

    test('UI verbs and nouns trigger generation', () {
      expect(isUiRequestPrompt('buatkan landing page'), isTrue);
      expect(isUiRequestPrompt('create a pricing page'), isTrue);
      expect(isUiRequestPrompt('edit the navbar'), isTrue);
      expect(isUiRequestPrompt('tampilkan dashboard'), isTrue);
    });

    test('short chatter without UI signal stays chat', () {
      expect(isUiRequestPrompt('apa kabar'), isFalse);
      expect(isUiRequestPrompt('terima kasih'), isFalse);
    });

    test('attachment-only or node-only requests stay chat', () {
      expect(isUiRequestPrompt('lihat ini', hasAttachments: true), isFalse);
      expect(isUiRequestPrompt('ini apa', hasSelectedNode: true), isFalse);
    });
  });

  group('Submit guard', () {
    test('empty prompt does nothing', () async {
      final container = makeContainer();
      final notifier = container.read(workspaceProvider.notifier);
      await notifier.submitPrompt('   ');
      expect(container.read(workspaceProvider).isGenerating, isFalse);
      expect(container.read(workspaceProvider).messages, isEmpty);
    });
  });

  group('retryLastPrompt (UX: coba lagi tanpa ketik ulang)', () {
    CanvasMessage userMsg(String text) =>
        CanvasMessage(role: ChatRole.user, text: text, displayText: text);
    const errMsg = CanvasMessage(
      role: ChatRole.error,
      text: 'Tidak dapat terhubung ke endpoint.',
    );

    test('no-op when there is nothing to retry', () async {
      final container = makeContainer();
      final notifier = container.read(workspaceProvider.notifier);
      await notifier.retryLastPrompt();
      expect(container.read(workspaceProvider).messages, isEmpty);
    });

    test('dangling error without user prompt is left intact', () async {
      final container = makeContainer();
      final notifier = container.read(workspaceProvider.notifier);
      await notifier.loadSession(
        messages: const [errMsg],
        pages: const [],
        activePageId: null,
      );
      await notifier.retryLastPrompt();
      final messages = container.read(workspaceProvider).messages;
      expect(messages.length, 1);
      expect(messages.single.role, ChatRole.error);
    });

    test('reuses last user prompt without duplicating bubbles', () async {
      final container = makeContainer();
      final notifier = container.read(workspaceProvider.notifier);
      await notifier.loadSession(
        messages: [userMsg('buatkan landing page'), errMsg],
        pages: const [],
        activePageId: null,
      );
      await notifier.retryLastPrompt();
      // Tanpa provider aktif, submit ulang gagal lagi — yang penting hanya
      // ada tepat 1 pesan error baru, tanpa duplikasi bubble user.
      final messages = container.read(workspaceProvider).messages;
      expect(messages.length, 1);
      expect(messages.single.role, ChatRole.error);
    });
  });
}
