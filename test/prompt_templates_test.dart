import 'package:centauri/features/prompt_editor/domain/prompt_templates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('uiSystemPrompt', () {
    test('requires a single self-contained HTML document', () {
      expect(uiSystemPrompt, contains('self-contained'));
      expect(uiSystemPrompt, contains('<!DOCTYPE html>'));
      expect(uiSystemPrompt, contains('viewport'));
    });

    test('forbids external code but allows open-source images', () {
      final lower = uiSystemPrompt.toLowerCase();
      expect(lower, contains('forbidden'));
      expect(lower, contains('cdn'));
      expect(lower, contains('web fonts'));
      expect(lower, contains('no css frameworks'));
      // Gambar dari sumber open-source diizinkan & didorong.
      expect(lower, contains('images are allowed and encouraged'));
      expect(lower, contains('picsum.photos'));
      expect(lower, contains('dicebear'));
    });

    test('requires all CSS inside a single style tag', () {
      final lower = uiSystemPrompt.toLowerCase();
      expect(lower, contains('css'));
      expect(lower, contains('<style>'));
      expect(lower, contains('one <style> tag'));
    });

    test('requires real interactivity via inline vanilla JS', () {
      final lower = uiSystemPrompt.toLowerCase();
      expect(lower, contains('interactivity is mandatory'));
      expect(lower, contains('<script>'));
      expect(lower, contains('vanilla js'));
    });

    test('demands design quality and bans AI slop', () {
      final lower = uiSystemPrompt.toLowerCase();
      expect(lower, contains('ai slop'));
      expect(lower, contains('lorem ipsum'));
      expect(lower, contains('emoji'));
      expect(lower, contains('design system'));
      expect(lower, contains('light and dark'));
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
    test('every fragment defines a design direction', () {
      for (final preset in designTokenPresets) {
        expect(preset.id, isNotEmpty);
        expect(preset.label, isNotEmpty);
        expect(
          preset.promptFragment.toLowerCase(),
          contains('design direction'),
          reason: 'Preset ${preset.id} harus mendefinisikan arah desain.',
        );
      }
    });

    test('presets have unique ids', () {
      final ids = designTokenPresets.map((p) => p.id).toSet();
      expect(ids.length, designTokenPresets.length);
    });
  });
}
