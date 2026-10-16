import 'package:centauri/features/provider_config/domain/catalog/catalog_selection.dart';
import 'package:centauri/features/provider_config/presentation/widgets/provider_card.dart';
import 'package:centauri/features/provider_config/presentation/widgets/provider_catalog_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<CatalogSelection?> pumpPanel(
    WidgetTester tester, {
    required void Function(CatalogSelection) onSelected,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProviderCatalogPanel(onSelected: onSelected),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return null;
  }

  testWidgets('menampilkan header section + 22 kartu', (tester) async {
    CatalogSelection? captured;
    await pumpPanel(tester, onSelected: (s) => captured = s);

    expect(find.text('OAuth'), findsOneWidget);
    expect(find.text('Free Tier'), findsOneWidget);
    expect(find.text('API Key'), findsOneWidget);
    expect(find.text('Claude Code'), findsOneWidget);
    expect(find.text('Kiro AI'), findsOneWidget);
    expect(find.byType(ProviderCard), findsNWidgets(22));
    expect(captured, isNull);
  });

  testWidgets('tap kartu mengembalikan OAuthSelection', (tester) async {
    CatalogSelection? captured;
    await pumpPanel(tester, onSelected: (s) => captured = s);

    await tester.tap(find.text('Claude Code'));
    await tester.pumpAndSettle();

    expect(captured, isA<OAuthSelection>());
    expect((captured! as OAuthSelection).preset.id, 'claude-code');
  });

  testWidgets('tap kartu API key mengembalikan ApiKeySelection', (
    tester,
  ) async {
    CatalogSelection? captured;
    await pumpPanel(tester, onSelected: (s) => captured = s);

    await tester.ensureVisible(find.text('Kiro AI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kiro AI'));
    await tester.pumpAndSettle();

    expect(captured, isA<ApiKeySelection>());
    expect((captured! as ApiKeySelection).entry.id, 'kiro-ai');
  });
}
