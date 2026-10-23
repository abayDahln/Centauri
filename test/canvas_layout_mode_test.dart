import 'package:centauri/app/widgets/stitch_widgets.dart';
import 'package:centauri/features/canvas_preview/domain/page.dart';
import 'package:centauri/features/canvas_preview/presentation/canvas_preview_page.dart';
import 'package:centauri/features/canvas_preview/presentation/provider/layout_provider.dart';
import 'package:centauri/features/canvas_preview/presentation/provider/workspace_provider.dart';
import 'package:centauri/features/canvas_preview/presentation/widgets/page_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

class _PresetWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState(
    pages: [
      AppPage(
        id: 'p1',
        name: 'Home',
        slug: 'home.html',
        html: '<div>Home</div>',
      ),
    ],
    activePageId: 'p1',
  );
}

void main() {
  group('CanvasLayoutMode', () {
    test('defaultCanvasLayoutMode returns desktop for desktop platforms and mobile for mobile', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(defaultCanvasLayoutMode, CanvasLayoutMode.desktop);

      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      expect(defaultCanvasLayoutMode, CanvasLayoutMode.desktop);

      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(defaultCanvasLayoutMode, CanvasLayoutMode.desktop);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(defaultCanvasLayoutMode, CanvasLayoutMode.mobile);

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(defaultCanvasLayoutMode, CanvasLayoutMode.mobile);

      debugDefaultTargetPlatformOverride = null;
    });

    test('CanvasLayoutModeNotifier builds with platform default and allows set and toggle', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(canvasLayoutModeProvider),
        CanvasLayoutMode.desktop,
      );

      container
          .read(canvasLayoutModeProvider.notifier)
          .set(CanvasLayoutMode.mobile);
      expect(container.read(canvasLayoutModeProvider), CanvasLayoutMode.mobile);

      container.read(canvasLayoutModeProvider.notifier).toggle();
      expect(
        container.read(canvasLayoutModeProvider),
        CanvasLayoutMode.desktop,
      );

      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('Preview Toolbar & Frame Widget Tests', () {
    testWidgets(
      'renders Desktop and Mobile icon buttons in toolbar and switches layout',
      (tester) async {
        tester.view
          ..physicalSize = const Size(1200, 800)
          ..devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final container = ProviderContainer(
          overrides: [
            workspaceProvider.overrideWith(_PresetWorkspaceNotifier.new),
            canvasLayoutModeProvider.overrideWith(CanvasLayoutModeNotifier.new),
          ],
        );
        addTearDown(container.dispose);

        // Force Windows target platform for initial desktop default
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: testApp(
              locale: testLocaleId,
              home: const Scaffold(body: CanvasPreviewPage()),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Find icon buttons
        final desktopButtonFinder = find.byWidgetPredicate(
          (widget) =>
              widget is SoftIconButton &&
              widget.icon == Icons.desktop_windows_outlined,
        );
        final mobileButtonFinder = find.byWidgetPredicate(
          (widget) =>
              widget is SoftIconButton &&
              widget.icon == Icons.phone_android_outlined,
        );

        expect(desktopButtonFinder, findsOneWidget);
        expect(mobileButtonFinder, findsOneWidget);

        // Check active states
        expect(
          tester.widget<SoftIconButton>(desktopButtonFinder).active,
          isTrue,
        );
        expect(
          tester.widget<SoftIconButton>(mobileButtonFinder).active,
          isFalse,
        );

        expect(find.text('100%'), findsOneWidget);

        // Initial state is desktop
        expect(
          container.read(canvasLayoutModeProvider),
          CanvasLayoutMode.desktop,
        );

        // Tap mobile icon button
        await tester.tap(mobileButtonFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          container.read(canvasLayoutModeProvider),
          CanvasLayoutMode.mobile,
        );
        expect(
          tester.widget<SoftIconButton>(mobileButtonFinder).active,
          isTrue,
        );
        expect(
          tester.widget<SoftIconButton>(desktopButtonFinder).active,
          isFalse,
        );

        // Tap desktop icon button
        await tester.tap(desktopButtonFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          container.read(canvasLayoutModeProvider),
          CanvasLayoutMode.desktop,
        );
        expect(
          tester.widget<SoftIconButton>(desktopButtonFinder).active,
          isTrue,
        );
        expect(
          tester.widget<SoftIconButton>(mobileButtonFinder).active,
          isFalse,
        );

        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets('defaults to mobile on Android platform', (tester) async {
      tester.view
        ..physicalSize = const Size(1200, 800)
        ..devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final container = ProviderContainer(
        overrides: [
          workspaceProvider.overrideWith(_PresetWorkspaceNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(canvasLayoutModeProvider), CanvasLayoutMode.mobile);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: testApp(
            locale: testLocaleId,
            home: const Scaffold(body: CanvasPreviewPage()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final mobileButtonFinder = find.byWidgetPredicate(
        (widget) =>
            widget is SoftIconButton &&
            widget.icon == Icons.phone_android_outlined,
      );
      expect(tester.widget<SoftIconButton>(mobileButtonFinder).active, isTrue);

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets(
      'preview frame width adapts between desktop (full width) and mobile (390px)',
      (tester) async {
        tester.view
          ..physicalSize = const Size(1200, 800)
          ..devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final container = ProviderContainer(
          overrides: [
            workspaceProvider.overrideWith(_PresetWorkspaceNotifier.new),
            canvasLayoutModeProvider.overrideWith(CanvasLayoutModeNotifier.new),
          ],
        );
        addTearDown(container.dispose);

        debugDefaultTargetPlatformOverride = TargetPlatform.windows;

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: testApp(
              locale: testLocaleId,
              home: const Scaffold(body: CanvasPreviewPage()),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // In desktop mode, preview frame is wide (> 500)
        final desktopSize = tester.getSize(find.byType(PagePreview));
        expect(desktopSize.width, greaterThan(500));

        // Switch to mobile mode
        container
            .read(canvasLayoutModeProvider.notifier)
            .set(CanvasLayoutMode.mobile);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // In mobile mode, preview frame width is constrained to 390 (PagePreview is 388 due to 1px border)
        final mobileSize = tester.getSize(find.byType(PagePreview));
        expect(mobileSize.width, equals(388.0));

        debugDefaultTargetPlatformOverride = null;
      },
    );
  });
}
