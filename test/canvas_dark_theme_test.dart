import 'package:centauri/app/config/app_palette.dart';
import 'package:centauri/app/config/theme.dart';
import 'package:centauri/features/canvas_preview/presentation/provider/workspace_provider.dart';
import 'package:centauri/features/canvas_preview/presentation/widgets/ai_status_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

/// Status AI selain idle supaya indikator benar-benar tampil.
WorkspaceState _busyStatus = const WorkspaceState(status: AiStatus.thinking);

class _BusyWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => _busyStatus;
}

void main() {
  testWidgets('indikator AI memakai aksen primary', (tester) async {
    _busyStatus = const WorkspaceState(status: AiStatus.thinking);
    final palette = AppPalette.dark(primary: AppAccentPreset.violet.seedColor);

    await tester.pumpWidget(
      testApp(
        palette: palette,
        brightness: Brightness.dark,
        overrides: [workspaceProvider.overrideWith(_BusyWorkspaceNotifier.new)],
        home: const Scaffold(body: AiStatusIndicator()),
      ),
    );
    await tester.pump();

    final spinner = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(spinner.color, palette.primary);
  });

  testWidgets('warna permukaan widget ikut palet gelap', (tester) async {
    await tester.pumpWidget(
      testApp(
        palette: AppPalette.dark(),
        brightness: Brightness.dark,
        home: Builder(
          builder: (context) => Scaffold(
            backgroundColor: context.palette.bgBase,
            body: Text('x', style: context.text.ui),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('x'));
    expect(text.style?.color, AppPalette.dark().textPrimary);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, const Color(0xFF09090B));
  });
}
