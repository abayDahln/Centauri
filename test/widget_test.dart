import 'dart:io';

import 'package:centauri/app/app.dart';
import 'package:centauri/app/l10n/app_language.dart';
import 'package:centauri/app/widgets/animated_side_panel.dart';
import 'package:centauri/core/storage/local_storage_service.dart';
import 'package:centauri/features/prompt_editor/presentation/prompt_chat_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/hive_teardown.dart';
import 'helpers/pump_app.dart';

/// Panel chat desktop (kolom yang lebarnya dianimasikan).
Finder _chatPanel() => find
    .ancestor(
      of: find.byType(PromptChatPanel),
      matching: find.byType(AnimatedContainer),
    )
    .first;

/// Lebar panel chat yang benar-benar tampil; 0 berarti tersembunyi.
///
/// Panel tetap ter-mount saat disembunyikan (lebarnya dianimasikan ke nol),
/// jadi `find.text` saja tidak cukup untuk memeriksa visibilitas.
double _chatPanelWidth(WidgetTester tester) =>
    tester.getSize(_chatPanel()).width;

double _historyPanelWidth(WidgetTester tester) => tester
    .getSize(
      find.byWidgetPredicate(
        (widget) =>
            widget is AnimatedSidePanel &&
            widget.alignment == AlignmentDirectional.centerStart,
      ),
    )
    .width;

void main() {
  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('centauri_test');
    await LocalStorageService().init(path: dir.path);
  });

  tearDownAll(closeHiveForTests);
  testWidgets('Empty workspace shows chat landing (not a preview)', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1200, 2400)
      ..devicePixelRatio = 3.0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: languageOverride(AppLanguage.byCode('id')),
        child: const CentauriApp(),
      ),
    );
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
    await tester.pumpWidget(
      ProviderScope(
        overrides: languageOverride(AppLanguage.byCode('id')),
        child: const CentauriApp(),
      ),
    );
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
    await tester.pumpWidget(
      ProviderScope(
        overrides: languageOverride(AppLanguage.byCode('id')),
        child: const CentauriApp(),
      ),
    );
    await tester.pump();

    // Kanvas terbuka: tombol tutup pratinjau ada, panel chat tersembunyi.
    expect(find.byIcon(Icons.close_fullscreen_outlined), findsOneWidget);
    expect(_chatPanelWidth(tester), 0);

    await tester.tap(find.byIcon(Icons.close_fullscreen_outlined));
    await tester.pumpAndSettle();

    // Mode fokus chat: percakapan mengisi sisa lebar jendela, tombol berubah
    // jadi buka.
    expect(find.byIcon(Icons.open_in_full_outlined), findsOneWidget);
    expect(find.text('Belum ada percakapan'), findsOneWidget);
    // Kolom pesan di dalam panel chat (bukan prompt bar pratinjau yang tetap
    // ter-mount walau kanvas disembunyikan).
    expect(
      find.descendant(of: _chatPanel(), matching: find.text('Tulis pesan…')),
      findsOneWidget,
    );
    expect(
      _chatPanelWidth(tester),
      closeTo(1440 - _historyPanelWidth(tester), 0.5),
    );
    // Sidebar riwayat tetap ada; tombol riwayat tetap di top bar walau kanvas
    // sedang disembunyikan.
    expect(find.text('Chat baru'), findsOneWidget);
    expect(find.byIcon(Icons.view_sidebar_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.open_in_full_outlined));
    await tester.pumpAndSettle();

    // Kanvas kembali, panel chat tetap terbuka.
    expect(find.byIcon(Icons.view_sidebar_outlined), findsOneWidget);
    expect(find.text('Belum ada percakapan'), findsOneWidget);
    expect(_chatPanelWidth(tester), greaterThan(0));

    addTearDown(() async => tester.binding.setSurfaceSize(null));
  });

  testWidgets('Workspace controls hidden until a page exists', (tester) async {
    tester.view
      ..physicalSize = const Size(4320, 2700)
      ..devicePixelRatio = 3.0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: languageOverride(AppLanguage.byCode('id')),
        child: const CentauriApp(),
      ),
    );
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
    await tester.pumpWidget(
      ProviderScope(
        overrides: languageOverride(AppLanguage.byCode('id')),
        child: const CentauriApp(),
      ),
    );
    await tester.pump();

    // Riwayat tampil di sidebar kiri.
    expect(find.text('Chat baru'), findsOneWidget);
    expect(find.text('Riwayat'), findsNothing);
    expect(_historyPanelWidth(tester), greaterThan(0));

    // Sembunyikan riwayat. Panel tetap ter-mount, jadi lebarnya yang diperiksa.
    await tester.tap(find.byIcon(Icons.view_sidebar_outlined));
    await tester.pumpAndSettle();
    expect(_historyPanelWidth(tester), 0);

    // Tampilkan kembali.
    await tester.tap(find.byIcon(Icons.view_sidebar_outlined));
    await tester.pumpAndSettle();
    expect(_historyPanelWidth(tester), greaterThan(0));
    expect(find.text('Chat baru'), findsOneWidget);

    addTearDown(() async => tester.binding.setSurfaceSize(null));
  });
}
