import 'package:centauri/app/l10n/app_language.dart';
import 'package:centauri/app/l10n/l10n.dart';
import 'package:centauri/app/widgets/language_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

/// Regresi i18n: pemilih bahasa mengubah seluruh teks UI seketika, daftar
/// bahasa memuat semua bahasa yang punya ARB, dan memilih Arab membalik arah
/// tata letak (RTL).
void main() {
  Future<void> pumpSwitcher(WidgetTester tester) async {
    // Viewport cukup tinggi agar dialog (max 480px) tampil penuh tanpa gulir
    // untuk bahasa-bahasa awal; daftar terpanjang tetap diuji dengan gulir.
    tester.view
      ..physicalSize = const Size(1400, 1200)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      testApp(
        localeFromProvider: true,
        overrides: languageOverride(AppLanguage.indonesian),
        home: Builder(
          builder: (context) => Scaffold(
            appBar: AppBar(actions: const [LanguageMenuButton()]),
            body: Center(child: Text(context.l10n.commonSave)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('teks UI mengikuti bahasa aktif dari provider', (tester) async {
    await pumpSwitcher(tester);

    expect(find.text('Simpan'), findsOneWidget);
    expect(find.text('Save'), findsNothing);
  });

  testWidgets('daftar bahasa memuat semua bahasa yang punya ARB', (
    tester,
  ) async {
    await pumpSwitcher(tester);

    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();

    expect(find.text('Bahasa'), findsOneWidget); // judul dialog
    // "English" dan "Filipino" muncul dua kali: nama asli + nama Inggris.
    expect(find.text('English'), findsNWidgets(2));
    expect(find.text('Bahasa Indonesia'), findsOneWidget);

    // Jumlah baris = jumlah bahasa yang punya ARB.
    final list = tester.widget<ListView>(
      find.descendant(
        of: find.byType(LanguageDialog),
        matching: find.byType(ListView),
      ),
    );
    final delegate = list.childrenDelegate as SliverChildBuilderDelegate;
    expect(delegate.childCount, AppLanguage.all.length);

    // Bahasa di bawah lipatan tetap bisa dicapai dengan menggulir.
    await tester.scrollUntilVisible(
      find.text('ไทย'),
      120,
      scrollable: find
          .descendant(
            of: find.byType(LanguageDialog),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('ไทย'), findsOneWidget);
  });

  testWidgets('memilih Arab mengganti teks dan membalik arah (RTL)', (
    tester,
  ) async {
    await pumpSwitcher(tester);

    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();

    final arabic = find.text('العربية');
    await tester.ensureVisible(arabic);
    await tester.pumpAndSettle();
    await tester.tap(arabic);
    await tester.pumpAndSettle();

    expect(find.text('حفظ'), findsOneWidget);
    expect(find.text('Simpan'), findsNothing);

    // Buka lagi: judul dialog kini Arab, dan arah tata letak sudah RTL.
    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();

    expect(find.text('اللغة'), findsOneWidget);
    final direction = tester.widget<Directionality>(
      find
          .ancestor(
            of: find.text('اللغة'),
            matching: find.byType(Directionality),
          )
          .first,
    );
    expect(direction.textDirection, TextDirection.rtl);
  });
}
