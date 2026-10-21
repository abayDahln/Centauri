import 'package:centauri/app/l10n/app_language.dart';
import 'package:centauri/features/mcp/presentation/mcp_guide_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

/// Panduan MCP harus terbaca di 12 bahasa dan di lebar sempit, karena isinya
/// teks panjang (Jerman/Prancis/Rusia) dan arah RTL (Arab).
void main() {
  Future<void> pumpGuide(
    WidgetTester tester, {
    required Locale locale,
    required Size size,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      testApp(
        locale: locale,
        themeFromProvider: true,
        home: const Scaffold(
          body: McpGuideView(endpoint: 'http://127.0.0.1:8765/mcp'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tampil di semua bahasa tanpa overflow', (tester) async {
    for (final size in const [Size(900, 900), Size(360, 720)]) {
      for (final language in AppLanguage.all) {
        await pumpGuide(tester, locale: language.locale, size: size);
        expect(
          tester.takeException(),
          isNull,
          reason: '${language.code} @ $size',
        );
      }
    }
  });

  testWidgets('memilih agent mengganti contoh JSON', (tester) async {
    await pumpGuide(tester, locale: testLocaleEn, size: const Size(900, 900));

    expect(find.text('File: .mcp.json'), findsOneWidget);

    await tester.tap(find.text('OpenCode'));
    await tester.pumpAndSettle();

    expect(find.text('File: opencode.jsonc'), findsOneWidget);
    expect(find.text('File: .mcp.json'), findsNothing);
  });

  testWidgets('daftar tool mengikuti skema server', (tester) async {
    await pumpGuide(tester, locale: testLocaleEn, size: const Size(900, 1600));

    for (final name in const [
      'list_sessions',
      'get_session',
      'get_page_html',
      'write_page',
      'delete_page',
      'post_to_chat',
    ]) {
      expect(find.text(name), findsOneWidget);
    }
  });
}
