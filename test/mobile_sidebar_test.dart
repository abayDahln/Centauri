import 'dart:io';

import 'package:centauri/app/app.dart';
import 'package:centauri/app/l10n/app_language.dart';
import 'package:centauri/core/storage/local_storage_service.dart';
import 'package:centauri/features/history/presentation/history_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/hive_teardown.dart';
import 'helpers/pump_app.dart';

/// Layar ponsel: lebar logis 400 px (< ambang desktop 900 px).
void _usePonsel(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1200, 2400)
    ..devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  addTearDown(() async => tester.binding.setSurfaceSize(null));
}

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...languageOverride(AppLanguage.byCode('id'))],
      child: const CentauriApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('centauri_mobile_shell');
    await LocalStorageService().init(
      path: dir.path,
      sessionsPath: '${dir.path}${Platform.pathSeparator}sessions',
    );
  });

  tearDownAll(closeHiveForTests);

  testWidgets('Mobile: tanpa logo/nama app, tombol riwayat di kiri', (
    tester,
  ) async {
    _usePonsel(tester);
    await _pumpApp(tester);

    // Branding "C" dan "Centauri" tidak lagi tampil di app bar.
    expect(find.text('Centauri'), findsNothing);

    // Tanpa UI, chat sudah menjadi layar utama, jadi tombol kiri membuka
    // riwayat — bukan chat.
    final historyButton = find.byIcon(Icons.history);
    expect(historyButton, findsOneWidget);
    expect(tester.getCenter(historyButton).dx, lessThan(200));
  });

  testWidgets('Mobile: riwayat dibuka sebagai sidebar, bukan bottom sheet', (
    tester,
  ) async {
    _usePonsel(tester);
    await _pumpApp(tester);

    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();

    final drawer = find.byType(Drawer);
    expect(drawer, findsOneWidget);
    // Menempel di tepi kiri layar seperti panel chat desktop.
    expect(tester.getRect(drawer).left, 0);
    // Tanpa halaman, drawer berisi riwayat saja (chat sudah jadi layar utama).
    expect(
      find.descendant(of: drawer, matching: find.byType(HistoryPanel)),
      findsOneWidget,
    );
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('Mobile: menu History membuka sidebar di tab riwayat', (
    tester,
  ) async {
    _usePonsel(tester);
    await _pumpApp(tester);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Riwayat').last);
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsOneWidget);
    expect(find.byType(HistoryPanel), findsOneWidget);
  });
}
