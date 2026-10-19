import 'dart:io';

import 'package:centauri/app/app.dart';
import 'package:centauri/app/l10n/app_language.dart';
import 'package:centauri/core/storage/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'helpers/pump_app.dart';

/// Regresi: halaman konfigurasi provider tidak boleh menjadi jalan buntu —
/// harus selalu ada tombol kembali yang mengembalikan ke canvas.
void main() {
  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('centauri_nav_test');
    await LocalStorageService().init(path: dir.path);
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('Provider settings bisa dibuka lalu ditutup', (tester) async {
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
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    // Halaman daftar provider tampil, lengkap dengan tombol kembali.
    expect(find.text('Bring Your Own Key (BYOK)'), findsOneWidget);
    expect(find.byType(BackButton), findsWidgets);

    await tester.tap(find.byType(BackButton).first);
    await tester.pumpAndSettle();

    // Kembali ke canvas.
    expect(find.text('Tulis pesan…'), findsOneWidget);
  });
}
