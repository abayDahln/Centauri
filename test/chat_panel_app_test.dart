import 'dart:io';

import 'package:centauri/app/app.dart';
import 'package:centauri/app/l10n/app_language.dart';
import 'package:centauri/core/storage/local_storage_service.dart';
import 'package:centauri/features/canvas_preview/presentation/provider/layout_provider.dart';
import 'package:centauri/features/canvas_preview/presentation/provider/workspace_provider.dart';
import 'package:centauri/features/prompt_editor/presentation/prompt_chat_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/hive_teardown.dart';
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

/// Mulai langsung di mode fokus chat (kanvas pratinjau disembunyikan).
class _HiddenCanvas extends CanvasVisibleNotifier {
  @override
  bool build() => false;
}

void main() {
  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('centauri_chat_layout');
    // Root sesi ikut diisolasi supaya daftar riwayat tidak membaca folder sesi
    // pengguna sungguhan.
    await LocalStorageService().init(
      path: dir.path,
      sessionsPath: '${dir.path}${Platform.pathSeparator}sessions',
    );
  });

  tearDownAll(closeHiveForTests);

  testWidgets('Mode fokus chat: scrollbar di tepi kanan, isi tetap di tengah', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(4320, 2700)
      ..devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workspaceProvider.overrideWith(_ChatWorkspace.new),
          canvasVisibleProvider.overrideWith(_HiddenCanvas.new),
          ...languageOverride(AppLanguage.byCode('id')),
        ],
        child: const CentauriApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Tombol top bar kini milik riwayat.
    expect(find.byTooltip('Sembunyikan riwayat'), findsOneWidget);
    expect(find.byTooltip('Tampilkan chat'), findsNothing);

    // Daftar pesan membentang dari tepi kanan sidebar sampai tepi kanan
    // jendela (1440), jadi scrollbar-nya ada di pojok kanan.
    final list = tester.getRect(
      find.descendant(
        of: find.byType(PromptChatPanel),
        matching: find.byType(ListView),
      ),
    );
    expect(list.right, 1440);
    expect(list.left, 280); // 20% dari 1440, dibatasi maksimum 280

    // Isi percakapan tidak ikut membentang: kolomnya dipusatkan.
    final bubble = tester.getRect(
      find.descendant(
        of: find.byType(PromptChatPanel),
        matching: find.text('Halo'),
      ),
    );
    expect(list.right - bubble.right, greaterThan(200));
  });
}
