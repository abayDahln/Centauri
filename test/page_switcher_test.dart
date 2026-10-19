import 'package:centauri/app/config/theme.dart';
import 'package:centauri/features/canvas_preview/domain/page.dart';
import 'package:centauri/features/canvas_preview/presentation/provider/workspace_provider.dart';
import 'package:centauri/features/canvas_preview/presentation/widgets/page_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

/// State awal yang bisa dipreset tiap test (workspaceProvider juga singleton
/// state di antara test dalam satu isolate).
WorkspaceState _preset = const WorkspaceState();

class _PresetWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => _preset;
}

void main() {
  testWidgets('highlight tab mengikuti page aktif seketika', (tester) async {
    const pages = [
      AppPage(id: 'page_1', name: 'Home', slug: 'home.html', html: 'h'),
      AppPage(id: 'page_2', name: 'Login', slug: 'login.html', html: 'l'),
    ];
    _preset = const WorkspaceState(pages: pages, activePageId: 'page_1');
    final container = ProviderContainer(
      overrides: [workspaceProvider.overrideWith(_PresetWorkspaceNotifier.new)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: testApp(home: const Scaffold(body: PageSwitcherBar())),
      ),
    );
    await tester.pump();

    Color tabUnderline(String label) {
      final box = tester.widget<Container>(
        find
            .ancestor(of: find.text(label), matching: find.byType(Container))
            .first,
      );
      final border = (box.decoration as BoxDecoration).border! as Border;
      return border.bottom.color;
    }

    expect(tabUnderline('Home'), AppColors.accentPrimary);
    expect(tabUnderline('Login'), Colors.transparent);

    // Pindah halaman via state (mis. dari navigasi link HTML) — tab harus
    // ikut berganti highlight TANPA render ulang apapun di sisi tab.
    container.read(workspaceProvider.notifier).setActivePage('page_2');
    await tester.pump();

    expect(tabUnderline('Login'), AppColors.accentPrimary);
    expect(tabUnderline('Home'), Colors.transparent);
  });

  testWidgets('tab aktif di luar layar men-scroll ke posisi terlihat', (
    tester,
  ) async {
    final pages = [
      for (var i = 1; i <= 12; i++)
        AppPage(
          id: 'page_$i',
          name: 'Halaman Urutan $i',
          slug: 'page-$i.html',
          html: 'h',
        ),
    ];
    _preset = WorkspaceState(pages: pages, activePageId: 'page_1');
    final container = ProviderContainer(
      overrides: [workspaceProvider.overrideWith(_PresetWorkspaceNotifier.new)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: testApp(
          home: const Scaffold(
            body: SizedBox(width: 240, child: PageSwitcherBar()),
          ),
        ),
      ),
    );
    await tester.pump();

    final scrollable = tester.widget<Scrollable>(
      find.descendant(
        of: find.byType(PageSwitcherBar),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.controller, isNotNull);

    // Aktifkan tab terjauh yang belum terlihat layar.
    container.read(workspaceProvider.notifier).setActivePage('page_12');
    await tester.pumpAndSettle();

    expect(scrollable.controller!.position.pixels, greaterThan(0));
  });
}
