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

    test('does not greet or introduce itself on every reply', () {
      final lower = uiSystemPrompt.toLowerCase();
      expect(lower, contains('never greet twice'));
      expect(lower, contains('never open a reply with'));
      expect(lower, isNot(contains('always introduce and identify yourself')));
    });

    test(
      'tells the model to edit existing pages instead of duplicating them',
      () {
        final lower = uiSystemPrompt.toLowerCase();
        expect(lower, contains('edit, never duplicate'));
        expect(lower, contains('home-2.html'));
        expect(lower, contains('new page only when asked'));
      },
    );

    test('does not instruct Tailwind CDN usage', () {
      expect(
        uiSystemPrompt.contains('cdn.tailwindcss.com'),
        isFalse,
        reason: 'Tailwind CDN butuh internet; Centauri harus offline-first.',
      );
    });
  });
}
