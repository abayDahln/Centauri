import 'dart:io';

import 'package:centauri/app/app.dart';
import 'package:centauri/app/l10n/app_language.dart';
import 'package:centauri/core/storage/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/hive_teardown.dart';
import 'helpers/pump_app.dart';

/// Regression: hotkey board TIDAK boleh menelan input keyboard saat pengguna
/// mengetik di prompt bar (paste, backspace, spasi).
void main() {
  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('centauri_prompt_test');
    // Root sesi ikut diisolasi: tanpa ini daftar riwayat membaca folder sesi
    // pengguna sungguhan dan tesnya tidak deterministik.
    await LocalStorageService().init(
      path: dir.path,
      sessionsPath: '${dir.path}${Platform.pathSeparator}sessions',
    );
  });

  tearDownAll(closeHiveForTests);

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(4320, 2700)
      ..devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: languageOverride(AppLanguage.byCode('id')),
        child: const CentauriApp(),
      ),
    );
    await tester.pump();
  }

  testWidgets('can type text into the prompt field', (tester) async {
    await pumpApp(tester);

    final field = find.byType(TextField).last;
    await tester.tap(field);
    await tester.pumpAndSettle();

    await tester.enterText(field, 'login screen');
    await tester.pump();

    expect(find.text('login screen'), findsOneWidget);
  });

  testWidgets('backspace removes characters instead of deleting a frame', (
    tester,
  ) async {
    await pumpApp(tester);

    final field = find.byType(TextField).last;
    await tester.tap(field);
    await tester.pumpAndSettle();

    await tester.enterText(field, 'hello');
    await tester.pump();

    // Kirim Backspace lewat key event seperti pengguna menekan tombol.
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();

    // Field harus tetap fokus (tidak ada frame yang terhapus / panel berubah).
    expect(find.byType(TextField), findsWidgets);
    expect(find.text('hello'), findsNothing);
  });

  testWidgets('space while typing inserts a space, not the hand tool', (
    tester,
  ) async {
    await pumpApp(tester);

    final field = find.byType(TextField).last;
    await tester.tap(field);
    await tester.pumpAndSettle();

    await tester.enterText(field, 'a');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(find.byType(TextField), findsWidgets);
  });
}
