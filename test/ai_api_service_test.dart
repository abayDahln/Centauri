import 'package:centauri/features/provider_config/data/datasources/ai_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = AiApiService();

  group('resolveEndpoint', () {
    test('appends path to a versioned base url', () {
      expect(
        AiApiService.resolveEndpoint(
          'https://api.openai.com/v1',
          '/chat/completions',
        ),
        'https://api.openai.com/v1/chat/completions',
      );
    });

    test('tolerates trailing slash', () {
      expect(
        AiApiService.resolveEndpoint(
          'https://api.openai.com/v1/',
          '/chat/completions',
        ),
        'https://api.openai.com/v1/chat/completions',
      );
    });

    test('does not double up when base already has the endpoint', () {
      expect(
        AiApiService.resolveEndpoint(
          'https://api.openai.com/v1/chat/completions',
          '/chat/completions',
        ),
        'https://api.openai.com/v1/chat/completions',
      );
    });

    test('does not double up when base has /models', () {
      expect(
        AiApiService.resolveEndpoint(
          'https://api.openai.com/v1/models',
          '/models',
        ),
        'https://api.openai.com/v1/models',
      );
    });

    test('strips accidental query string', () {
      expect(
        AiApiService.resolveEndpoint(
          'https://api.openai.com/v1?foo=1',
          '/chat/completions',
        ),
        'https://api.openai.com/v1/chat/completions',
      );
    });

    test('works for groq and ollama style bases', () {
      expect(
        AiApiService.resolveEndpoint(
          'https://api.groq.com/openai/v1',
          '/chat/completions',
        ),
        'https://api.groq.com/openai/v1/chat/completions',
      );
      expect(
        AiApiService.resolveEndpoint(
          'http://localhost:11434/v1',
          '/chat/completions',
        ),
        'http://localhost:11434/v1/chat/completions',
      );
    });
  });

  group('extractFromSse', () {
    test('joins OpenAI streaming deltas', () {
      const sse =
          'data: {"id":"gen-1","object":"chat.completion.chunk","choices":[{"delta":{"content":"<html>"}}]}\n\n'
          'data: {"id":"gen-1","choices":[{"delta":{"content":"<body>"}}]}\n\n'
          'data: {"id":"gen-1","choices":[{"delta":{"content":"hi"}}]}\n\n'
          'data: [DONE]\n\n';
      expect(service.extractFromSse(sse), '<html><body>hi');
    });

    test('handles role-only delta without content', () {
      const sse =
          'data: {"choices":[{"delta":{"role":"assistant"}}]}\n\n'
          'data: {"choices":[{"delta":{"content":"ok"}}]}\n\n'
          'data: [DONE]\n\n';
      expect(service.extractFromSse(sse), 'ok');
    });

    test('handles Ollama-style streaming message.content', () {
      const sse =
          'data: {"message":{"content":"<div>"}}\n\n'
          'data: {"message":{"content":"</div>"}}\n\n';
      expect(service.extractFromSse(sse), '<div></div>');
    });

    test('returns null when no content found', () {
      expect(service.extractFromSse('data: [DONE]\n\n'), isNull);
    });

    test('returns null for non-string payload', () {
      expect(service.extractFromSse({'foo': 'bar'}), isNull);
    });

    test('skips malformed json lines without throwing', () {
      const sse =
          'data: {not valid json}\n\n'
          'data: {"choices":[{"delta":{"content":"valid"}}]}\n\n';
      expect(service.extractFromSse(sse), 'valid');
    });
  });

  group('extractContent', () {
    test('reads standard OpenAI choices[0].message.content', () {
      final content = service.extractContent({
        'choices': [
          {
            'message': {'role': 'assistant', 'content': '<html></html>'},
          },
        ],
      });
      expect(content, '<html></html>');
    });

    test('reads choices[0].text fallback', () {
      final content = service.extractContent({
        'choices': [
          {'text': '<div>hi</div>'},
        ],
      });
      expect(content, '<div>hi</div>');
    });

    test('reads multimodal content parts list', () {
      final content = service.extractContent({
        'choices': [
          {
            'message': {
              'content': [
                {'type': 'text', 'text': '<section>'},
                {'type': 'text', 'text': 'hi</section>'},
              ],
            },
          },
        ],
      });
      expect(content, '<section>hi</section>');
    });

    test('reads Ollama native message.content', () {
      final content = service.extractContent({
        'message': {'role': 'assistant', 'content': '<p>ollama</p>'},
      });
      expect(content, '<p>ollama</p>');
    });

    test('reads Ollama generate response field', () {
      final content = service.extractContent({'response': '<p>gen</p>'});
      expect(content, '<p>gen</p>');
    });

    test('reads top-level content string', () {
      final content = service.extractContent({'content': '<p>top</p>'});
      expect(content, '<p>top</p>');
    });

    test('throws with provider error message when present', () {
      expect(
        () => service.extractContent({
          'error': {'message': 'model not found: gpt-99'},
        }),
        throwsA(
          isA<ApiConnectionException>().having(
            (e) => e.message,
            'message',
            contains('model not found: gpt-99'),
          ),
        ),
      );
    });

    test('throws non-object error for non-JSON payload', () {
      expect(
        () => service.extractContent('not json'),
        throwsA(isA<ApiConnectionException>()),
      );
    });

    test('throws unrecognized-structure error with keys for unknown shape', () {
      expect(
        () => service.extractContent({'foo': 1, 'bar': 2}),
        throwsA(
          isA<ApiConnectionException>().having(
            (e) => e.message,
            'message',
            contains('foo'),
          ),
        ),
      );
    });

    test('ignores empty content and falls through to error', () {
      expect(
        () => service.extractContent({
          'choices': [
            {
              'message': {'content': '   '},
            },
          ],
        }),
        throwsA(isA<ApiConnectionException>()),
      );
    });
  });
}
