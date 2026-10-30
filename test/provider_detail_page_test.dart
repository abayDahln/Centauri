import 'package:centauri/features/provider_config/data/datasources/cline_oauth_service.dart';
import 'package:centauri/features/provider_config/domain/entities/api_provider.dart';
import 'package:centauri/features/provider_config/domain/entities/oauth_session.dart';
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

  group('Cline', () {
    Future<_FakeProviderRepository> pumpCline(WidgetTester tester) async {
      final repository = _FakeProviderRepository();

      tester.view
        ..physicalSize = const Size(1000, 2400)
        ..devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        testApp(
          home: const ProviderDetailPage(),
          overrides: [
            apiProviderRepositoryProvider.overrideWithValue(repository),
            clineOAuthServiceProvider.overrideWithValue(_FakeClineOAuth()),
            // Test tidak membuka socket loopback: langsung ke tempel tautan.
            clineLoopbackProvider.overrideWithValue(() async => null),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // State provider dimuat seperti saat halaman dibuka dari daftar.
      final context = tester.element(find.byType(ProviderDetailPage));
      await ProviderScope.containerOf(
        context,
        listen: false,
      ).read(providerConfigProvider.future);
      await tester.pumpAndSettle();
      return repository;
    }

    /// Nama sengaja tidak diisi: connect tidak boleh meminta nama.
    Future<void> connect(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('button-oauth-connect')));
      // Tombol menampilkan spinner selama proses hubungkan, jadi jangan
      // pumpAndSettle (animasinya tidak pernah berhenti).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(
        find.byKey(const ValueKey('field-cline-link')),
        'vscode://saoudrizwan.claude-dev/auth?code=abc',
      );
      await tester.tap(find.byKey(const ValueKey('button-cline-submit')));
      await tester.pumpAndSettle();
    }

    testWidgets('kartu masuk akun tampil, field API Key hilang', (
      tester,
    ) async {
      await pumpCline(tester);
      await pickFromDialog(tester, 'Cline');

      expect(find.byKey(const ValueKey('oauth-login-card')), findsOneWidget);
      expect(find.byKey(const ValueKey('field-apiKey')), findsNothing);
      expect(
        find.byKey(const ValueKey('button-oauth-connect')),
        findsOneWidget,
      );
    });

    testWidgets('hubungkan menampilkan nama akun, email, dan saldo', (
      tester,
    ) async {
      final repository = await pumpCline(tester);
      await pickFromDialog(tester, 'Cline');
      await connect(tester);

      // Nama provider terisi otomatis supaya hasil connect bisa disimpan.
      final nameField = tester.widget<TextFormField>(
        find.byKey(const ValueKey('field-nama')),
      );
      expect(nameField.controller?.text, 'Cline');
      expect(find.text('Masuk sebagai Orang'), findsOneWidget);
      expect(find.text('o***@contoh.com'), findsOneWidget);
      expect(find.textContaining('0,01'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('button-oauth-disconnect')),
        findsOneWidget,
      );
      // Provider tersimpan sebagai provider akun, bukan API key.
      expect(repository.saved?.authType, AuthType.oauth);
      expect(repository.saved?.oauthProvider, kClineOAuthCatalogId);
      expect(repository.saved?.oauthSession?.accessToken, 'acc-token');
    });

    testWidgets('Keluar menghapus sesi dan kembali ke keadaan belum masuk', (
      tester,
    ) async {
      final repository = await pumpCline(tester);
      await pickFromDialog(tester, 'Cline');
      await connect(tester);

      await tester.tap(find.byKey(const ValueKey('button-oauth-disconnect')));
      await tester.pumpAndSettle();

      expect(repository.clearSessionCalls, 1);
      expect(
        find.byKey(const ValueKey('button-oauth-connect')),
        findsOneWidget,
      );
      expect(find.text('Masuk sebagai Orang'), findsNothing);
    });

    testWidgets('tautan kosong tidak dikirim ke penyimpanan', (tester) async {
      final repository = await pumpCline(tester);
      await pickFromDialog(tester, 'Cline');

      await tester.tap(find.byKey(const ValueKey('button-oauth-connect')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // Tombol Hubungkan di dialog tidak menutup dialog saat field kosong.
      await tester.tap(find.byKey(const ValueKey('button-cline-submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const ValueKey('field-cline-link')), findsOneWidget);
      expect(repository.saved, isNull);
    });
  });
}

/// Repository palsu: menyimpan provider di memori (tanpa Hive/secure storage)
/// dan mencatat pemanggilan yang diperiksa test.
class _FakeProviderRepository implements ApiProviderRepository {
  _FakeProviderRepository([ApiProvider? provider]) : _providers = [?provider];

  final List<ApiProvider> _providers;

  int clearCalls = 0;
  int clearSessionCalls = 0;
  ApiProvider? saved;

  /// Seperti repository asli: daftar provider tidak membawa kredensial.
  ApiProvider _withoutCredentials(ApiProvider p) => ApiProvider(
    id: p.id,
    name: p.name,
    providerName: p.providerName,
    catalogId: p.catalogId,
    baseUrl: p.baseUrl,
    model: p.model,
    authType: p.authType,
    oauthProvider: p.oauthProvider,
  );

  @override
  Future<List<ApiProvider>> getProviders() async => [
    for (final p in _providers) _withoutCredentials(p),
  ];

  @override
  Future<ApiProvider?> getActiveProvider() async =>
      saved ?? _providers.firstOrNull;

  @override
  Future<ApiProvider?> getProviderById(String id) async =>
      _providers.where((p) => p.id == id).firstOrNull;

  @override
  Future<void> saveProvider(ApiProvider provider) async {
    saved = provider;
    _providers
      ..removeWhere((p) => p.id == provider.id)
      ..add(provider);
  }

  @override
  Future<void> clearApiKey(String id) async {
    clearCalls++;
  }

  @override
  Future<void> clearOAuthSession(String id) async {
    clearSessionCalls++;
  }

  @override
  Future<void> deleteProvider(String id) async {
    _providers.removeWhere((p) => p.id == id);
  }

  @override
  Future<void> setActiveProvider(String id) async {}
}

/// Pengganti [ClineOAuthService] tanpa jaringan.
class _FakeClineOAuth extends ClineOAuthService {
  _FakeClineOAuth({OAuthSession? session}) : _session = session ?? _default;

  static final _default = OAuthSession(
    accessToken: 'acc-token',
    refreshToken: 'ref-token',
    expiresAt: DateTime.utc(2026, 12, 1),
    userId: 'user-1',
    email: 'orang@contoh.com',
    displayName: 'Orang',
  );

  final OAuthSession _session;
  String? lastLink;
  int balanceCalls = 0;

  @override
  Future<OAuthSession> connect(String pasted) async {
    lastLink = pasted;
    return _session;
  }

  @override
  Future<double> fetchBalance(OAuthSession session) async {
    balanceCalls++;
    return -0.01;
  }
}
