import 'package:centauri/features/provider_config/presentation/provider_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Perilaku kartu setelan provider: alur pilih provider lewat dialog, kunci
/// Base URL untuk template, dan syarat field Nama Provider untuk Custom.
void main() {
  Future<void> pumpPage(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1000, 2400)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ProviderDetailPage())),
    );
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
}
