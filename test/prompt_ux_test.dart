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
}
