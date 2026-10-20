import 'package:centauri/app/config/app_palette.dart';
import 'package:centauri/app/config/theme_provider.dart';
import 'package:centauri/app/l10n/app_language.dart';
import 'package:centauri/app/widgets/appearance_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

/// Host kecil yang menampilkan state tema sebagai teks supaya test bisa
/// memastikan provider benar-benar berubah.
Widget _host() {
  return Consumer(
    builder: (context, ref, _) {
      final selection = ref.watch(appThemeProvider);
      return Scaffold(
        body: Column(
          children: [
            Text(
              'mode:${selection.mode.id} primary:${selection.primary.id} '
              'secondary:${selection.secondary.id}',
            ),
            const AppearanceMenuButton(),
          ],
        ),
      );
    },
  );
}

Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Appearance'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tombol membuka dialog dengan mode dan dua baris swatch', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        themeFromProvider: true,
        localeFromProvider: true,
        overrides: languageOverride(AppLanguage.english),
        home: _host(),
      ),
    );

    await _openDialog(tester);

    expect(find.byType(AppearanceDialog), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Primary color'), findsOneWidget);
    expect(find.text('AI color'), findsOneWidget);

    // 8 preset untuk primary + 8 untuk secondary.
    expect(find.byTooltip('Blue'), findsNWidgets(2));
    expect(find.byTooltip('Slate'), findsNWidgets(2));
  });

  testWidgets('pilih mode gelap mengubah provider dan palet dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        themeFromProvider: true,
        localeFromProvider: true,
        overrides: languageOverride(AppLanguage.english),
        home: _host(),
      ),
    );

    await _openDialog(tester);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(find.text('mode:dark primary:blue secondary:blue'), findsOneWidget);

    final dialog = tester.widget<Dialog>(find.byType(Dialog));
    expect(dialog.backgroundColor, AppPalette.dark().bgElevated);
  });

  testWidgets('pilih warna primary dan secondary', (tester) async {
    await tester.pumpWidget(
      testApp(
        themeFromProvider: true,
        localeFromProvider: true,
        overrides: languageOverride(AppLanguage.english),
        home: _host(),
      ),
    );

    await _openDialog(tester);

    // Swatch pertama pada baris primary (biru) sudah aktif; pilih violet.
    await tester.tap(find.byTooltip('Violet').first);
    await tester.pumpAndSettle();
    expect(
      find.text('mode:light primary:violet secondary:blue'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Teal').last);
    await tester.pumpAndSettle();
    expect(
      find.text('mode:light primary:violet secondary:teal'),
      findsOneWidget,
    );
  });

  testWidgets('reset mengembalikan mode dan warna ke default', (tester) async {
    await tester.pumpWidget(
      testApp(
        themeFromProvider: true,
        localeFromProvider: true,
        overrides: languageOverride(AppLanguage.english),
        home: _host(),
      ),
    );

    await _openDialog(tester);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Rose').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(find.text('mode:light primary:blue secondary:blue'), findsOneWidget);
  });
}
