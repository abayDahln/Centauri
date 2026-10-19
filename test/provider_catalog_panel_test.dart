import 'package:centauri/features/provider_config/domain/catalog/provider_catalog_entry.dart';
import 'package:centauri/features/provider_config/presentation/widgets/provider_card.dart';
import 'package:centauri/features/provider_config/presentation/widgets/provider_catalog_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

void main() {
  Future<void> pumpPanel(
    WidgetTester tester, {
    required void Function(ProviderCatalogEntry) onSelected,
  }) async {
    await tester.pumpWidget(
      testApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProviderCatalogPanel(onSelected: onSelected),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('menampilkan header section + 12 kartu', (tester) async {
    ProviderCatalogEntry? captured;
    await pumpPanel(tester, onSelected: (e) => captured = e);

    expect(find.text('Custom API Key'), findsOneWidget);
    expect(find.text('Free Tier'), findsOneWidget);
    expect(find.text('API Key'), findsOneWidget);
    expect(find.text('Kiro AI'), findsOneWidget);
    expect(find.byType(ProviderCard), findsNWidgets(12));
    expect(captured, isNull);
  });

  testWidgets('Custom API Key tampil paling atas', (tester) async {
    await pumpPanel(tester, onSelected: (_) {});

    final customY = tester.getTopLeft(find.text('Custom API Key')).dy;
    final freeTierY = tester.getTopLeft(find.text('Free Tier')).dy;
    expect(customY, lessThan(freeTierY));
  });

  testWidgets('tap kartu API key mengembalikan entri katalog', (tester) async {
    ProviderCatalogEntry? captured;
    await pumpPanel(tester, onSelected: (e) => captured = e);

    await tester.ensureVisible(find.text('Kiro AI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kiro AI'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.id, 'kiro-ai');
  });

  testWidgets('tap Custom API Key mengembalikan entri custom', (tester) async {
    ProviderCatalogEntry? captured;
    await pumpPanel(tester, onSelected: (e) => captured = e);

    await tester.tap(find.text('Custom API Key'));
    await tester.pumpAndSettle();

    expect(captured?.id, 'custom-api');
  });
}
