import 'package:centauri/features/canvas_preview/domain/viewport_mode.dart';
import 'package:centauri/features/canvas_preview/presentation/provider/canvas_provider.dart';
import 'package:centauri/features/prompt_editor/domain/prompt_templates.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('design token selection is shared state', () {
    final notifier = container.read(canvasProvider.notifier);

    expect(container.read(canvasProvider).selectedToken, isNull);

    final electric = designTokenPresets.firstWhere((t) => t.id == 'electric');
    notifier.setSelectedToken(electric);
    expect(container.read(canvasProvider).selectedToken?.id, 'electric');

    notifier.setSelectedToken(null);
    expect(container.read(canvasProvider).selectedToken, isNull);
  });

  test('viewport mode updates', () {
    final notifier = container.read(canvasProvider.notifier);

    expect(container.read(canvasProvider).viewport, ViewportMode.desktop);

    notifier.setViewport(ViewportMode.tablet);
    expect(container.read(canvasProvider).viewport, ViewportMode.tablet);
  });

  test('clearCanvas resets content but keeps token selection', () {
    final notifier = container.read(canvasProvider.notifier);
    final current = designTokenPresets.first;
    notifier.setSelectedToken(current);

    notifier.clearCanvas();

    final state = container.read(canvasProvider);
    expect(state.generatedHtml, isNull);
    expect(state.messages, isEmpty);
    expect(state.selectedToken?.id, current.id);
  });
}
