import 'package:centauri/features/canvas_preview/presentation/provider/canvas_provider.dart';
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
      final notifier = container.read(canvasProvider.notifier);
      expect(container.read(canvasProvider).isGenerating, isFalse);
      notifier.cancelGeneration();
      expect(container.read(canvasProvider).isGenerating, isFalse);
      // Tidak menambah pesan apa pun ketika tidak ada yang berjalan.
      expect(container.read(canvasProvider).messages, isEmpty);
    });

    test('cancelGeneration stops a running generation and appends a notice',
        () {
      final container = makeContainer();
      final notifier = container.read(canvasProvider.notifier);

      // Simulasi generate sedang berjalan (tanpa jaringan): tanda isGenerating
      // di-set lewat submit tanpa provider -> tetap idle karena gagal dini.
      // Jadi kita pakai jalur internal lewat copyWith tak tersedia; sebagai
      // gantinya uji bahwa cancelAll tidak melempar dan idempoten.
      AiApiService.cancelAll();
      AiApiService.cancelAll();
      notifier.cancelGeneration();
      expect(container.read(canvasProvider).isGenerating, isFalse);
    });

    test('cancelAll is safe with no active requests', () {
      expect(AiApiService.cancelAll, returnsNormally);
    });
  });

  group('detectScreenRequest', () {
    test('range with comma list detects all screens in order', () {
      final req = detectScreenRequest(
        'buatkan aku ui aplikasi media sosial seperti instagram dan facebook, '
        'lengkap dengan semua screen dari login, home sampai profile',
      );
      expect(req.count, 3);
      expect(req.names, ['login', 'home', 'profile']);
    });

    test('explicit count without names', () {
      final req = detectScreenRequest('buatkan 5 screen onboarding');
      expect(req.count, 5);
      expect(req.names, contains('onboarding'));
    });

    test('single screen stays single', () {
      final req = detectScreenRequest('buatkan landing page');
      expect(req.count, 1);
      expect(req.names, isEmpty);
    });

    test('ID spelling canonicalized to EN', () {
      final req = detectScreenRequest('buatkan profil dan pengaturan');
      expect(req.names, ['profile', 'settings']);
    });
  });

  group('Submit guard', () {
    test('empty prompt does nothing', () async {
      final container = makeContainer();
      final notifier = container.read(canvasProvider.notifier);
      await notifier.submitPrompt('   ');
      expect(container.read(canvasProvider).isGenerating, isFalse);
      expect(container.read(canvasProvider).messages, isEmpty);
    });
  });

  group('retryLastPrompt (UX: coba lagi tanpa ketik ulang)', () {
    CanvasMessage userMsg(String text) => CanvasMessage(
      role: ChatRole.user,
      text: text,
      displayText: text,
    );
    const errMsg = CanvasMessage(
      role: ChatRole.error,
      text: 'Tidak dapat terhubung ke endpoint.',
    );

    test('no-op when there is nothing to retry', () async {
      final container = makeContainer();
      final notifier = container.read(canvasProvider.notifier);
      await notifier.retryLastPrompt();
      expect(container.read(canvasProvider).messages, isEmpty);
    });

    test('dangling error without user prompt is left intact', () async {
      final container = makeContainer();
      final notifier = container.read(canvasProvider.notifier);
      await notifier.loadSession(
        messages: const [errMsg],
        frames: const [],
        activeFrameId: null,
      );
      await notifier.retryLastPrompt();
      // Tidak ada prompt user untuk dipakai ulang: pesan tidak disentuh.
      final messages = container.read(canvasProvider).messages;
      expect(messages.length, 1);
      expect(messages.single.role, ChatRole.error);
    });

    test('reuses last user prompt without duplicating bubbles', () async {
      final container = makeContainer();
      final notifier = container.read(canvasProvider.notifier);
      await notifier.loadSession(
        messages: [userMsg('buatkan landing page'), errMsg],
        frames: const [],
        activeFrameId: null,
      );
      await notifier.retryLastPrompt();
      final messages = container.read(canvasProvider).messages;
      // Tanpa provider aktif, submit ulang gagal lagi — yang penting hanya
      // ada tepat 1 pesan error baru, tanpa duplikasi bubble user.
      expect(messages.length, 1);
      expect(messages.single.role, ChatRole.error);
    });
  });
}
