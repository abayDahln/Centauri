import 'dart:io';

import 'package:centauri/app/app.dart';
import 'package:centauri/core/storage/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('centauri_test');
    await LocalStorageService().init(path: dir.path);
  });

  tearDownAll(() async {
    await Hive.close();
  });
  testWidgets('Empty workspace shows chat landing (not a preview)', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1200, 2400)
      ..devicePixelRatio = 3.0;
    await tester.pumpWidget(const ProviderScope(child: CentauriApp()));
    await tester.pump();

    expect(find.text('Mulai dengan sebuah prompt'), findsOneWidget);
    expect(find.text('Belum ada halaman'), findsNothing);
    expect(
      find.text('What would you like to change or create?'),
      findsOneWidget,
    );

    addTearDown(tester.view.reset);
  });

  testWidgets('Top-left exposes menu and provider settings', (tester) async {
    tester.view
      ..physicalSize = const Size(4320, 2700)
      ..devicePixelRatio = 3.0;
    await tester.pumpWidget(const ProviderScope(child: CentauriApp()));
    await tester.pump();

    // Tombol menu panel + konfigurasi provider selalu ada di kiri atas.
    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    // Provider pill juga tersedia.
    expect(find.text('Pilih provider'), findsOneWidget);
    expect(
      find.text('What would you like to change or create?'),
      findsOneWidget,
    );

    addTearDown(() async => tester.binding.setSurfaceSize(null));
  });

  testWidgets('Workspace controls hidden until a page exists', (tester) async {
    tester.view
      ..physicalSize = const Size(4320, 2700)
      ..devicePixelRatio = 3.0;
    await tester.pumpWidget(const ProviderScope(child: CentauriApp()));
    await tester.pump();

    // Prompt bar (input + kirim) tetap ada; kontrol workspace lain
    // (mode link, ekspor, undo/redo, bersihkan) hanya saat ada halaman.
    expect(find.byIcon(Icons.touch_app_outlined), findsNothing);
    expect(find.byIcon(Icons.undo), findsNothing);
    expect(find.byIcon(Icons.redo), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);

    addTearDown(() async => tester.binding.setSurfaceSize(null));
  });

  testWidgets('Side panel with Chat/History opens when workspace empty', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(4320, 2700)
      ..devicePixelRatio = 3.0;
    await tester.pumpWidget(const ProviderScope(child: CentauriApp()));
    await tester.pump();

    // Panel tertutup: belum ada tab "History" di panel samping.
    expect(find.text('History'), findsNothing);

    // Klik tombol menu di kiri atas.
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    // Panel samping muncul dengan dua tab: Chat, History.
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);

    // Buka tab History -> tombol "Chat baru" tampil.
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Chat baru'), findsOneWidget);

    addTearDown(() async => tester.binding.setSurfaceSize(null));
  });
}
