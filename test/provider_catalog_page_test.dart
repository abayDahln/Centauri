import 'package:centauri/features/provider_config/domain/catalog/catalog_selection.dart';
import 'package:centauri/features/provider_config/presentation/provider_catalog_page.dart';
import 'package:centauri/features/provider_config/presentation/widgets/provider_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  late CatalogSelection? captured;

  Future<void> pumpApp(WidgetTester tester) async {
    captured = null;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  captured = await context.push<CatalogSelection>('/catalog');
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/catalog',
          builder: (_, _) => const ProviderCatalogPage(),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  }

  Future<void> openCatalog(WidgetTester tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('menampilkan header section + 22 kartu', (tester) async {
    await openCatalog(tester);

    expect(find.text('OAuth'), findsOneWidget);
    expect(find.text('Free Tier'), findsOneWidget);
    expect(find.text('API Key'), findsOneWidget);
    expect(find.text('Claude Code'), findsOneWidget);
    expect(find.text('Custom API'), findsOneWidget);
    expect(find.byType(ProviderCard), findsNWidgets(22));
  });

  testWidgets('pencarian memfilter kartu', (tester) async {
    await openCatalog(tester);

    await tester.enterText(find.byType(TextField), 'claude');
    await tester.pumpAndSettle();

    expect(find.byType(ProviderCard), findsOneWidget);
    expect(find.text('Claude Code'), findsOneWidget);
  });

  testWidgets('pencarian tanpa hasil menampilkan empty state', (tester) async {
    await openCatalog(tester);

    await tester.enterText(find.byType(TextField), 'zzzzzz');
    await tester.pumpAndSettle();

    expect(find.byType(ProviderCard), findsNothing);
    expect(find.text('Tidak ada provider yang cocok.'), findsOneWidget);
  });

  testWidgets('tap kartu mengembalikan OAuthSelection', (tester) async {
    await openCatalog(tester);

    await tester.tap(find.text('Claude Code'));
    await tester.pumpAndSettle();

    expect(captured, isA<OAuthSelection>());
    expect((captured! as OAuthSelection).preset.id, 'claude-code');
  });

  testWidgets('tap kartu API key mengembalikan ApiKeySelection', (
    tester,
  ) async {
    await openCatalog(tester);

    await tester.ensureVisible(find.text('Custom API'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom API'));
    await tester.pumpAndSettle();

    expect(captured, isA<ApiKeySelection>());
    expect((captured! as ApiKeySelection).entry.id, 'custom-api');
  });
}
