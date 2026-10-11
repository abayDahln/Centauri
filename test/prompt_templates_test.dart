import 'package:centauri/features/prompt_editor/domain/prompt_templates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('uiSystemPrompt', () {
    test('requires a single self-contained HTML document', () {
      expect(uiSystemPrompt, contains('ONE complete, fully self-contained'));
      expect(uiSystemPrompt, contains('<!DOCTYPE html>'));
      expect(uiSystemPrompt, contains('viewport'));
    });

    test('forbids external assets, CDN and CSS frameworks', () {
      final lower = uiSystemPrompt.toLowerCase();
      expect(lower, contains('forbidden: external stylesheets'));
      expect(lower, contains('no tailwind cdn'));
      expect(lower, contains('web fonts'));
    });

    test('requires all CSS inside a single style tag', () {
      final lower = uiSystemPrompt.toLowerCase();
      expect(lower, contains('all css'));
      expect(lower, contains('<style> tag'));
    });

    test('allows and encourages inline vanilla JS', () {
      final lower = uiSystemPrompt.toLowerCase();
      expect(lower, contains('javascript is allowed and encouraged'));
      expect(lower, contains('vanilla js'));
      expect(uiSystemPrompt, contains('<script>'));
    });

    test('does not instruct Tailwind CDN usage', () {
      expect(
        uiSystemPrompt.contains('cdn.tailwindcss.com'),
        isFalse,
        reason: 'Tailwind CDN butuh internet; Centauri harus offline-first.',
      );
    });
  });

  group('designTokenPresets', () {
    test('every fragment asks for hand-written CSS', () {
      for (final preset in designTokenPresets) {
        expect(preset.id, isNotEmpty);
        expect(preset.label, isNotEmpty);
        expect(
          preset.promptFragment.toLowerCase(),
          contains('design tokens'),
          reason: 'Preset ${preset.id} harus menyebut design token.',
        );
      }
    });

    test('presets have unique ids', () {
      final ids = designTokenPresets.map((p) => p.id).toSet();
      expect(ids.length, designTokenPresets.length);
    });
  });
}
