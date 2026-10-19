import 'package:centauri/features/provider_config/domain/entities/api_provider.dart';
import 'package:centauri/features/provider_config/domain/repositories/api_provider_repository.dart';
import 'package:centauri/features/provider_config/presentation/provider_detail_page.dart';
import 'package:centauri/features/provider_config/presentation/providers/provider_config_provider.dart';
import 'package:centauri/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers/pump_app.dart';

/// Perilaku kartu setelan provider: alur pilih provider lewat dialog, kunci
/// Base URL untuk template, dan syarat field Nama Provider untuk Custom.
void main() {
  Future<void> pumpPage(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1000, 2400)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(home: const ProviderDetailPage()));
    await tester.pumpAndSettle();
  }

  Future<void> pickFromDialog(WidgetTester tester, String label) async {
    await tester.tap(find.byKey(const ValueKey('picker-provider')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  bool baseUrlEnabled(WidgetTester tester) {
    final field = tester.widget<TextFormField>(
      find.byKey(const ValueKey('field-baseUrl')),
    );
    return field.enabled;
  }

  testWidgets('kondisi awal: provider belum dipilih, Base URL nonaktif', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Pilih provider'), findsOneWidget);
    expect(find.text('Pilih provider dulu'), findsOneWidget);
    expect(baseUrlEnabled(tester), isFalse);
    expect(find.byKey(const ValueKey('field-providerName')), findsNothing);
  });

  testWidgets('pilih template: Base URL terkunci, model terisi', (
    tester,
  ) async {
    await pumpPage(tester);
    await pickFromDialog(tester, 'Kiro AI');

    expect(find.text('Kiro AI'), findsOneWidget);
    // Nama Provider hanya muncul untuk Custom.
    expect(find.byKey(const ValueKey('field-providerName')), findsNothing);
    expect(baseUrlEnabled(tester), isFalse);
    // Model terisi otomatis dari saran template.
    expect(find.text('Pilih model'), findsNothing);
  });

  testWidgets('pilih Custom API Key: Nama Provider muncul, Base URL bebas', (
    tester,
  ) async {
    await pumpPage(tester);
    await pickFromDialog(tester, 'Custom API Key');

    expect(find.byKey(const ValueKey('field-providerName')), findsOneWidget);
    expect(baseUrlEnabled(tester), isTrue);
    expect(find.text('Pilih model'), findsOneWidget);
  });

  testWidgets('Model nonaktif sampai provider dipilih', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const ValueKey('picker-model')));
    await tester.pumpAndSettle();
    expect(find.text('Pilih Model'), findsNothing);

    await pickFromDialog(tester, 'Kiro AI');
    await tester.tap(find.byKey(const ValueKey('picker-model')));
    await tester.pumpAndSettle();
    expect(find.text('Pilih Model'), findsOneWidget);
  });

  group('Reset API Key', () {
    Future<_FakeProviderRepository> pumpEdit(WidgetTester tester) async {
      final repository = _FakeProviderRepository(
        const ApiProvider(
          id: 'p1',
          name: 'OpenRouter',
          providerName: 'OpenRouter',
          catalogId: 'openrouter',
          baseUrl: 'https://openrouter.ai/api/v1',
          model: 'openai/gpt-5.4',
          apiKey: 'sk-lama',
        ),
      );

      tester.view
        ..physicalSize = const Size(1000, 2400)
        ..devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final router = GoRouter(
        initialLocation: '/edit',
        routes: [
          GoRoute(
            path: '/providers',
            builder: (_, _) => const Scaffold(body: Text('daftar provider')),
          ),
          GoRoute(
            path: '/edit',
            builder: (_, _) => const ProviderDetailPage(providerId: 'p1'),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiProviderRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp.router(
            locale: testLocaleId,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Muat state provider lebih dulu, seperti daftar provider yang menjadi
      // pintu masuk halaman ini di aplikasi.
      final context = tester.element(find.byType(ProviderDetailPage));
      await ProviderScope.containerOf(
        context,
        listen: false,
      ).read(providerConfigProvider.future);
      await tester.pumpAndSettle();
      return repository;
    }

    TextFormField keyField(WidgetTester tester) => tester.widget<TextFormField>(
      find.byKey(const ValueKey('field-apiKey')),
    );

    testWidgets('field terkunci dan tombol Reset tampil saat key tersimpan', (
      tester,
    ) async {
      await pumpEdit(tester);

      expect(keyField(tester).enabled, isFalse);
      expect(find.byKey(const ValueKey('button-reset-apiKey')), findsOneWidget);
    });

    testWidgets('Reset membuka field tanpa langsung menghapus key', (
      tester,
    ) async {
      final repository = await pumpEdit(tester);

      await tester.tap(find.byKey(const ValueKey('button-reset-apiKey')));
      await tester.pumpAndSettle();

      expect(keyField(tester).enabled, isTrue);
      expect(repository.clearCalls, 0);
      expect(find.text('API Key dihapus saat disimpan.'), findsOneWidget);
    });

    testWidgets('Batal setelah Reset tidak menghapus key tersimpan', (
      tester,
    ) async {
      final repository = await pumpEdit(tester);

      await tester.tap(find.byKey(const ValueKey('button-reset-apiKey')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('button-cancel')));
      await tester.pumpAndSettle();

      expect(repository.clearCalls, 0);
      expect(repository.saved, isNull);
      expect(find.text('daftar provider'), findsOneWidget);
    });

    testWidgets('Simpan setelah Reset menghapus key tersimpan', (tester) async {
      final repository = await pumpEdit(tester);

      await tester.tap(find.byKey(const ValueKey('button-reset-apiKey')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('button-save')));
      await tester.pumpAndSettle();

      expect(repository.clearCalls, 1);
      expect(repository.saved?.apiKey, isNull);
    });
  });
}

/// Repository palsu: menyimpan satu provider dengan key, tanpa Hive/secure
/// storage, dan mencatat pemanggilan clearApiKey.
class _FakeProviderRepository implements ApiProviderRepository {
  _FakeProviderRepository(this.provider);

  final ApiProvider provider;
  int clearCalls = 0;
  ApiProvider? saved;

  /// Seperti repository asli: daftar provider tidak membawa API Key.
  ApiProvider get _withoutKey => ApiProvider(
    id: provider.id,
    name: provider.name,
    providerName: provider.providerName,
    catalogId: provider.catalogId,
    baseUrl: provider.baseUrl,
    model: provider.model,
  );

  @override
  Future<List<ApiProvider>> getProviders() async => [_withoutKey];

  @override
  Future<ApiProvider?> getActiveProvider() async => provider;

  @override
  Future<ApiProvider?> getProviderById(String id) async =>
      provider.id == id ? provider : null;

  @override
  Future<void> saveProvider(ApiProvider provider) async {
    saved = provider;
  }

  @override
  Future<void> clearApiKey(String id) async {
    clearCalls++;
  }

  @override
  Future<void> deleteProvider(String id) async {}

  @override
  Future<void> setActiveProvider(String id) async {}
}
