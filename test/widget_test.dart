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
    Hive.init(dir.path);
    await LocalStorageService().init();
  });

  tearDownAll(() async {
    await Hive.close();
  });
  testWidgets('Empty board shows chat landing (not the board)', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1200, 2400)
      ..devicePixelRatio = 3.0;
    await tester.pumpWidget(const ProviderScope(child: CentauriApp()));
    await tester.pump();

    expect(find.text('Mulai dengan sebuah prompt'), findsOneWidget);
    expect(find.text('Board masih kosong'), findsNothing);
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

  testWidgets('Board controls hidden until a UI exists', (tester) async {
    tester.view
      ..physicalSize = const Size(4320, 2700)
      ..devicePixelRatio = 3.0;
    await tester.pumpWidget(const ProviderScope(child: CentauriApp()));
    await tester.pump();

    // Zoom chip + viewport toggle (di prompt bar) tetap ada; kontrol board
    // lain (grid/fit/clear) hanya saat board aktif.
    expect(find.byIcon(Icons.grid_4x4), findsNothing);
    expect(find.byIcon(Icons.fit_screen_outlined), findsNothing);

    addTearDown(() async => tester.binding.setSurfaceSize(null));
  });

  testWidgets('Side panel with Chat/History/Layers opens when board empty', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(4320, 2700)
      ..devicePixelRatio = 3.0;
    await tester.pumpWidget(const ProviderScope(child: CentauriApp()));
    await tester.pump();

    // Panel tertutup: belum ada tab "History"/"Layers" di panel samping.
    expect(find.text('History'), findsNothing);
    expect(find.text('Layers'), findsNothing);

    // Klik tombol menu di kiri atas.
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    // Panel samping muncul dengan tiga tab: Chat, History, Layers.
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Layers'), findsOneWidget);

    // Buka tab History -> tombol "Chat baru" tampil.
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Chat baru'), findsOneWidget);

    // Buka tab Layers -> tampil placeholder saat belum ada frame aktif.
    await tester.tap(find.text('Layers'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Klik komponen di canvas'),
      findsOneWidget,
    );

    addTearDown(() async => tester.binding.setSurfaceSize(null));
  });
}
