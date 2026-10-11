import 'package:centauri/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Mobile shell shows canvas, hint, and bottom nav', (
    tester,
  ) async {
    // tester.view.physicalSize memakai physical pixels; DPR 3.0 di tester.
    tester.view
      ..physicalSize = const Size(1200, 2400)
      ..devicePixelRatio = 3.0;
    await tester.pumpWidget(const ProviderScope(child: CentauriApp()));
    await tester.pump();

    expect(find.text('Centauri - Canvas'), findsOneWidget);
    expect(
      find.text('Buka panel Prompt, lalu ketik deskripsi UI untuk mulai.'),
      findsOneWidget,
    );
    expect(find.text('Canvas kosong'), findsOneWidget);
    expect(find.text('Layers'), findsOneWidget);
    expect(find.text('Prompt'), findsOneWidget);
    expect(find.text('Code'), findsOneWidget);

    addTearDown(tester.view.reset);
  });

  testWidgets('Desktop shell shows activity bar, sidebar, tabs, status bar', (
    tester,
  ) async {
    // 4320x2700 physical => 1440x900 logical (DPR 3.0).
    tester.view
      ..physicalSize = const Size(4320, 2700)
      ..devicePixelRatio = 3.0;
    await tester.pumpWidget(const ProviderScope(child: CentauriApp()));
    await tester.pump();

    expect(find.text('Canvas Preview'), findsOneWidget);
    expect(find.text('index.html'), findsOneWidget);
    expect(find.text('Design'), findsOneWidget);
    expect(find.text('Dev'), findsOneWidget);
    expect(find.text('canvas / belum ada konten'), findsOneWidget);
    expect(find.text('PROVIDER'), findsOneWidget);
    expect(find.text('LAYERS'), findsOneWidget);
    expect(find.text('DESIGN TOKENS'), findsOneWidget);
    expect(find.text('Width: 100%'), findsOneWidget);
    expect(find.text('No provider'), findsWidgets);

    addTearDown(() async => tester.binding.setSurfaceSize(null));
  });
}
