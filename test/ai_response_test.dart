import 'package:centauri/features/prompt_editor/domain/ai_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('classifyAiResponse', () {
    test('treats a plain conversational reply as chat', () {
      final result = classifyAiResponse(
        'Halo! Saya Centauri, siap membantu mendesain UI. Mau mulai dari apa?',
      );
      expect(result.isChat, isTrue);
      expect(result.text, contains('Halo!'));
      expect(result.html, isNull);
    });

    test('treats an Indonesian explanation as chat', () {
      final result = classifyAiResponse(
        'Tentu. Untuk membuat landing page, kita butuh hero, fitur, dan CTA.',
      );
      expect(result.isChat, isTrue);
    });

    test('detects a fenced html document as UI', () {
      const raw = '''
Berikut UI-nya:

```html
<!DOCTYPE html>
<html><head><style>body{}</style></head><body><h1>Hi</h1></body></html>
```
''';
      final result = classifyAiResponse(raw);
      expect(result.isUi, isTrue);
      expect(result.html, startsWith('<!DOCTYPE html>'));
    });

    test('detects a raw html document without fences as UI', () {
      final result = classifyAiResponse(
        '<!DOCTYPE html><html><body><div>Hello</div></body></html>',
      );
      expect(result.isUi, isTrue);
      expect(result.html, contains('<div>Hello</div>'));
    });

    test('adds doctype when missing on a detected document', () {
      final result = classifyAiResponse('<html><body><p>x</p></body></html>');
      expect(result.isUi, isTrue);
      expect(result.html, startsWith('<!DOCTYPE html>'));
    });

    test('parses a JSON wrapper with html field', () {
      final result = classifyAiResponse(
        '{"html": "<!DOCTYPE html><html><body>ok</body></html>"}',
      );
      expect(result.isUi, isTrue);
    });

    test('parses a JSON wrapper with text field as chat', () {
      final result = classifyAiResponse('{"text": "Ini penjelasan."}');
      expect(result.isChat, isTrue);
      expect(result.text, 'Ini penjelasan.');
    });

    test('keeps a short code snippet as chat, not UI', () {
      const raw = 'Gunakan kode ini:\n\n```dart\nfinal x = 1;\n```\n';
      final result = classifyAiResponse(raw);
      expect(result.isChat, isTrue);
      expect(result.text, contains('final x = 1;'));
    });

    test('strips markdown fences from chat replies', () {
      final result = classifyAiResponse('Contoh:\n```\nnpm run dev\n```');
      expect(result.isChat, isTrue);
      expect(result.text, contains('npm run dev'));
      expect(result.text, isNot(contains('```')));
    });

    test('returns a helpful chat message for empty responses', () {
      final result = classifyAiResponse('   ');
      expect(result.isChat, isTrue);
      expect(result.text, isNotEmpty);
    });

    test('handles indented html inside a fence', () {
      const raw = '''
```html
  <!DOCTYPE html>
  <html><body>x</body></html>
```
''';
      final result = classifyAiResponse(raw);
      expect(result.isUi, isTrue);
    });

    test('embeds an explanation note before the html', () {
      const raw = '''
Saya membuat landing page dengan hero, pricing, dan footer.

```html
<!DOCTYPE html><html><body>Hi</body></html>
```
''';
      final result = classifyAiResponse(raw);
      expect(result.isUi, isTrue);
      expect(result.note, contains('landing page'));
    });

    test('extracts multiple screens from multiple fences', () {
      const raw = '''
Berikut 3 layar:

### Home
```html
<!DOCTYPE html><html><body>Home</body></html>
```

### Profile
```html
<!DOCTYPE html><html><body>Profile</body></html>
```

### Settings
```html
<!DOCTYPE html><html><body>Settings</body></html>
```
''';
      final result = classifyAiResponse(raw);
      expect(result.isUi, isTrue);
      expect(result.screens.length, 3);
      expect(result.screens[0].title, 'Home');
      expect(result.screens[1].title, 'Profile');
      expect(result.screens[1].html, contains('Profile'));
      expect(result.note, contains('3 layar'));
    });

    test('does not treat a tiny partial snippet as a screen', () {
      const raw = 'Contoh markup:\n\n```html\n<div class="x">hi</div>\n```\n';
      final result = classifyAiResponse(raw);
      // Snippet kecil (tanpa doctype/html/body) tetap dianggap chat.
      expect(result.isChat, isTrue);
    });
  });

  group('AiResponse serialization', () {
    test('round-trips a ui response', () {
      final original = AiResponse.ui('<!DOCTYPE html><html></html>');
      final restored = AiResponse.fromJson(original.toJson());
      expect(restored.isUi, isTrue);
      expect(restored.html, original.html);
    });

    test('round-trips a chat response', () {
      const original = AiResponse.chat('hello');
      final restored = AiResponse.fromJson(original.toJson());
      expect(restored.isChat, isTrue);
      expect(restored.text, 'hello');
    });
  });
}
