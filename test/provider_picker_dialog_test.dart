import 'package:centauri/features/provider_config/domain/catalog/provider_catalog_entry.dart';
import 'package:centauri/features/provider_config/presentation/widgets/provider_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> open(
    WidgetTester tester, {
    required void Function(ProviderCatalogEntry?) onResult,
    String? selectedId,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final entry = await showProviderPickerDialog(
                  context,
                  selectedId: selectedId,
                );
                onResult(entry);
              },
              child: const Text('buka'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
  }

  testWidgets('Custom API Key tampil paling atas', (tester) async {
    await open(tester, onResult: (_) {});

    expect(find.text('Pilih Provider'), findsOneWidget);
    expect(find.text('Custom API Key'), findsOneWidget);

    final customY = tester.getTopLeft(find.text('Custom API Key')).dy;
    final freeTierY = tester.getTopLeft(find.text('Free Tier')).dy;
    expect(customY, lessThan(freeTierY));
  });

  testWidgets('memilih template mengembalikan entri katalog', (tester) async {
    ProviderCatalogEntry? picked;
    await open(tester, onResult: (e) => picked = e);

    await tester.ensureVisible(find.text('Kiro AI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kiro AI'));
    await tester.pumpAndSettle();

    expect(picked?.id, 'kiro-ai');
  });

  testWidgets('memilih Custom API Key mengembalikan entri custom', (
    tester,
  ) async {
    ProviderCatalogEntry? picked;
    await open(tester, onResult: (e) => picked = e);

    await tester.tap(find.text('Custom API Key'));
    await tester.pumpAndSettle();

    expect(picked?.id, 'custom-api');
  });

  testWidgets('Batal mengembalikan null', (tester) async {
    var called = false;
    ProviderCatalogEntry? picked;
    await open(
      tester,
      onResult: (e) {
        called = true;
        picked = e;
      },
    );

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(picked, isNull);
  });
}
