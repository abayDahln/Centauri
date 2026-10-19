import 'package:centauri/features/canvas_preview/presentation/provider/workspace_provider.dart';
import 'package:centauri/features/prompt_editor/presentation/prompt_chat_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

/// Workspace berisi percakapan, agar daftar pesan benar-benar dirender.
class _ChatWorkspace extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState(
    messages: [
      CanvasMessage(role: ChatRole.user, text: 'Halo'),
      CanvasMessage(
        role: ChatRole.assistant,
        text: 'Hai, ada yang bisa dibantu?',
      ),
    ],
  );
}

/// Lebar panel mode fokus chat pada pengujian ini.
const double _paneWidth = 1090;

Future<void> _pumpPanel(WidgetTester tester, {double? contentMaxWidth}) async {
  tester.view
    ..physicalSize = const Size(2400, 1600)
    ..devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  addTearDown(() async => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    testApp(
      overrides: [workspaceProvider.overrideWith(_ChatWorkspace.new)],
      home: Center(
        child: SizedBox(
          width: _paneWidth,
          height: 800,
          child: PromptChatPanel(contentMaxWidth: contentMaxWidth),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Mode fokus chat: daftar selebar panel, isi tidak rata tepi', (
    tester,
  ) async {
    await _pumpPanel(tester, contentMaxWidth: 760);

    // Daftar memakai seluruh lebar panel, jadi scrollbar ada di tepi kanan
    // panel — bukan di tengah jendela.
    final list = tester.getRect(find.byType(ListView));
    expect(list.width, _paneWidth);

    // Isi percakapan tetap dipusatkan, tidak membentang sampai tepi kanan.
    final bubble = tester.getRect(find.text('Halo'));
    expect(list.right - bubble.right, greaterThan(150));
  });

  testWidgets('Tanpa batas lebar: isi mengisi panel sampai tepi', (
    tester,
  ) async {
    await _pumpPanel(tester);

    final list = tester.getRect(find.byType(ListView));
    final bubble = tester.getRect(find.text('Halo'));
    expect(list.width, _paneWidth);
    // Hanya sisa padding daftar (16 px) + padding bubble (14 px) — perilaku
    // panel samping, bukan kolom yang dipusatkan.
    expect(list.right - bubble.right, lessThan(40));
  });
}
