import 'dart:convert';
import 'dart:io';

import 'package:centauri/features/provider_config/data/datasources/ai_api_service.dart';
import 'package:centauri/features/provider_config/domain/entities/api_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// End-to-end: menjalankan server HTTP lokal yang meniru gateway nyata
/// (SSE streaming, JSON biasa, HTML salah alamat) lalu memastikan
/// [AiApiService.generateUI] mengurai semuanya dengan benar.
void main() {
  Future<HttpServer> startServer(
    void Function(HttpRequest request) handler,
  ) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen(handler);
    return server;
  }

  ApiProvider providerFor(int port) => ApiProvider(
    id: 'p1',
    name: 'local',
    baseUrl: 'http://127.0.0.1:$port/v1',
    model: 'test-model',
    apiKey: 'sk-test',
  );

  test('parses a streaming SSE response end to end', () async {
    final server = await startServer((request) async {
      request.response.headers.contentType = ContentType(
        'text',
        'event-stream',
      );
      // Tulis bertahap agar benar-benar menyerupai stream jaringan.
      request.response.write(
        'data: {"id":"gen-1","object":"chat.completion","choices":[{"delta":{"role":"assistant"}}]}\n\n',
      );
      request.response.write(
        'data: {"id":"gen-1","choices":[{"delta":{"content":"<!DOCTYPE html><html>"}}]}\n\n',
      );
      await request.response.flush();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      request.response.write(
        'data: {"id":"gen-1","choices":[{"delta":{"content":"<body>streamed</body></html>"}}]}\n\n',
      );
      request.response.write('data: [DONE]\n\n');
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));

    const service = AiApiService();
    final result = await service.generateUI(
      provider: providerFor(server.port),
      messages: [
        {'role': 'user', 'content': 'hi'},
      ],
    );

    expect(result, '<!DOCTYPE html><html><body>streamed</body></html>');
  });

  test('parses a plain JSON response end to end', () async {
    final server = await startServer((request) async {
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'choices': [
            {
              'message': {'role': 'assistant', 'content': '<p>json</p>'},
            },
          ],
        }),
      );
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));

    const service = AiApiService();
    final result = await service.generateUI(
      provider: providerFor(server.port),
      messages: [
        {'role': 'user', 'content': 'hi'},
      ],
    );
    expect(result, '<p>json</p>');
  });

  test('reports a clear error when the endpoint returns HTML', () async {
    final server = await startServer((request) async {
      request.response.headers.contentType = ContentType.html;
      request.response.write('<!DOCTYPE html><html><body>404</body></html>');
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));

    const service = AiApiService();
    await expectLater(
      service.generateUI(
        provider: providerFor(server.port),
        messages: [
          {'role': 'user', 'content': 'hi'},
        ],
      ),
      throwsA(
        isA<ApiConnectionException>().having(
          (e) => e.message,
          'message',
          contains('HTML'),
        ),
      ),
    );
  });

  test('testConnection succeeds against a JSON /models', () async {
    final server = await startServer((request) async {
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'data': []}));
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));

    const service = AiApiService();
    await service.testConnection(providerFor(server.port));
  });

  test('surfaces the provider 404 message, URL and model end to end', () async {
    // Meniru OpenRouter: model tanpa endpoint membalas 404 + error.message.
    final server = await startServer((request) async {
      request.response.statusCode = 404;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'error': {
            'message': 'No endpoints found for test-model.',
            'code': 404,
          },
        }),
      );
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));

    const service = AiApiService();
    await expectLater(
      service.generateUI(
        provider: providerFor(server.port),
        messages: [
          {'role': 'user', 'content': 'hi'},
        ],
      ),
      throwsA(
        isA<ApiConnectionException>().having(
          (e) => e.message,
          'message',
          allOf(
            contains('404'),
            contains('No endpoints found for test-model.'),
            contains('http://127.0.0.1:${server.port}/v1/chat/completions'),
            contains('Model: test-model'),
          ),
        ),
      ),
    );
  });
}
