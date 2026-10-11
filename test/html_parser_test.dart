import 'package:centauri/features/prompt_editor/domain/html_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('extractHtmlFromResponse', () {
    test('extracts content from ```html fenced block', () {
      const raw =
          'Here you go:\n'
          '```html\n'
          '<!DOCTYPE html>\n<html><body><h1>Hi</h1></body></html>\n'
          '```\n'
          'Let me know if you need changes.';

      final result = extractHtmlFromResponse(raw);

      expect(result, contains('<h1>Hi</h1>'));
      expect(result.contains('```'), isFalse);
      expect(result.contains('Let me know'), isFalse);
    });

    test('extracts content from plain fenced block', () {
      const raw = '```\n<html><body><div>Test</div></body></html>\n```';
      final result = extractHtmlFromResponse(raw);

      expect(result, contains('<div>Test</div>'));
    });

    test('extracts html value from JSON response', () {
      const raw = '{"html": "<html><body><p>From JSON</p></body></html>"}';
      final result = extractHtmlFromResponse(raw);

      expect(result, contains('<p>From JSON</p>'));
      expect(result, startsWith('<!DOCTYPE html>'));
    });

    test('strips prose around a full HTML document', () {
      const raw =
          'Sure! Creating your page now.\n\n'
          '<html><head></head><body><main>Content</main></body></html>\n\n'
          'Done.';

      final result = extractHtmlFromResponse(raw);

      expect(result, contains('<main>Content</main>'));
      expect(result.contains('Sure!'), isFalse);
      expect(result.contains('Done.'), isFalse);
    });

    test('adds DOCTYPE when missing', () {
      const raw = '<html><body>x</body></html>';
      expect(extractHtmlFromResponse(raw), startsWith('<!DOCTYPE html>'));
    });

    test('returns error document for non-HTML response', () {
      final result = extractHtmlFromResponse('I cannot help with that.');

      expect(result, contains('tidak mengembalikan HTML yang valid'));
      expect(result, startsWith('<!DOCTYPE html>'));
    });

    test('returns error document for empty response', () {
      final result = extractHtmlFromResponse('   ');

      expect(result, contains('Respons AI kosong'));
    });
  });
}
