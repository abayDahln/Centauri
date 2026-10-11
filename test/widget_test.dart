import 'package:centauri/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  testWidgets('Top-left exposes history and provider settings', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(4320, 2700)
      ..devicePixelRatio = 3.0;
    await tester.pumpWidget(const ProviderScope(child: CentauriApp()));
    await tester.pump();

    // Tombol riwayat + konfigurasi provider selalu ada di kiri atas.
    expect(find.byIcon(Icons.history), findsOneWidget);
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
}
