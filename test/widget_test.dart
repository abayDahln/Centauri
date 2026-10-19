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

    expect(find.text('Mulai dengan pesan'), findsOneWidget);
    expect(find.text('Belum ada halaman'), findsNothing);
    expect(find.text('Tulis pesan…'), findsOneWidget);

    addTearDown(tester.view.reset);
  });

  testWidgets('Top bar keeps the history toggle on the left, settings right', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(4320, 2700)
      ..devicePixelRatio = 3.0;
    await tester.pumpWidget(const ProviderScope(child: CentauriApp()));
    await tester.pump();

    final panel = find.byIcon(Icons.view_sidebar_outlined);
    final settings = find.byIcon(Icons.settings_outlined);
    expect(panel, findsOneWidget);
    expect(settings, findsOneWidget);
    expect(
      tester.getCenter(settings).dx,
      greaterThan(tester.getCenter(panel).dx),
    );

    // Tanpa halaman: belum ada ekspor, pemilih mode, maupun undo/redo.
    expect(find.text('Desain'), findsNothing);
    expect(find.text('Kode'), findsNothing);
    expect(find.text('Ekspor'), findsNothing);
    expect(find.text('Tulis pesan…'), findsOneWidget);

    addTearDown(() async => tester.binding.setSurfaceSize(null));
  });

  testWidgets('Preview closes so the chat fills the window', (tester) async {
    tester.view
      ..physicalSize = const Size(4320, 2700)
      ..devicePixelRatio = 3.0;
    await tester.pumpWidget(const ProviderScope(child: CentauriApp()));
    await tester.pump();

    // Kanvas terbuka: tombol tutup pratinjau ada, panel chat masih tertutup.
    expect(find.byIcon(Icons.close_fullscreen_outlined), findsOneWidget);
    expect(find.text('Belum ada percakapan'), findsNothing);

    await tester.tap(find.byIcon(Icons.close_fullscreen_outlined));
    await tester.pumpAndSettle();

    // Mode fokus chat: percakapan tampil penuh, tombol berubah jadi buka.
    expect(find.byIcon(Icons.open_in_full_outlined), findsOneWidget);
    expect(find.text('Belum ada percakapan'), findsOneWidget);
    expect(find.text('Tulis pesan…'), findsOneWidget);
    // Sidebar riwayat tetap ada; tombol riwayat tetap di top bar walau kanvas
    // sedang disembunyikan.
    expect(find.text('Chat baru'), findsOneWidget);
    expect(find.byIcon(Icons.view_sidebar_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.open_in_full_outlined));
    await tester.pumpAndSettle();

    // Kanvas kembali, panel chat tetap terbuka.
    expect(find.byIcon(Icons.view_sidebar_outlined), findsOneWidget);
    expect(find.text('Belum ada percakapan'), findsOneWidget);

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

  testWidgets('Tombol sidebar menyembunyikan lalu menampilkan riwayat', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(4320, 2700)
      ..devicePixelRatio = 3.0;
    await tester.pumpWidget(const ProviderScope(child: CentauriApp()));
    await tester.pump();

    // Riwayat tampil di sidebar kiri.
    expect(find.text('Chat baru'), findsOneWidget);
    expect(find.text('Riwayat'), findsNothing);

    // Sembunyikan riwayat.
    await tester.tap(find.byIcon(Icons.view_sidebar_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Chat baru'), findsNothing);

    // Tampilkan kembali.
    await tester.tap(find.byIcon(Icons.view_sidebar_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Chat baru'), findsOneWidget);

    addTearDown(() async => tester.binding.setSurfaceSize(null));
  });
}
