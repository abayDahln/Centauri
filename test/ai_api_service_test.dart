import 'dart:typed_data';

import 'package:centauri/core/errors/app_error.dart';
import 'package:centauri/core/utils/app_constants.dart';
import 'package:centauri/features/provider_config/data/datasources/ai_api_service.dart';
import 'package:centauri/features/provider_config/domain/entities/api_provider.dart';
import 'package:centauri/features/provider_config/domain/entities/oauth_session.dart';
import 'package:dio/dio.dart';
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
          isA<ApiConnectionException>()
              .having((e) => e.code, 'code', AppErrorCode.apiProviderReported)
              .having(
                (e) => e.detail,
                'detail',
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
          isA<ApiConnectionException>()
              .having((e) => e.code, 'code', AppErrorCode.apiBadResponse)
              .having((e) => e.detail, 'detail', contains('foo')),
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

  group('mapDioError', () {
    DioException badResponse(int status, {dynamic body}) => DioException(
      requestOptions: RequestOptions(path: '/chat/completions'),
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: '/chat/completions'),
        statusCode: status,
        data: body,
      ),
    );

    test('404 jadi apiNotFound, detail memuat pesan asli provider', () {
      final e = badResponse(
        404,
        body: {
          'error': {
            'message': 'No endpoints found for stealth/space-bunny-alpha.',
            'code': 404,
          },
        },
      );

      expect(AiApiService.mapDioError(e), AppErrorCode.apiNotFound);
      final detail = AiApiService.dioErrorDetail(e)!;
      expect(detail, contains('HTTP 404'));
      expect(detail, contains('space-bunny-alpha'));
    });

    test('detail menyertakan URL final dan nama model', () {
      final detail = AiApiService.dioErrorDetail(
        badResponse(404),
        responseBody: '{"error":{"message":"No endpoints found for openai/gpt-9.","code":404}}',
        url: 'https://openrouter.ai/api/v1/chat/completions',
        model: 'openai/gpt-9',
      )!;

      expect(detail, contains('No endpoints found for openai/gpt-9'));
      expect(detail, contains('https://openrouter.ai/api/v1/chat/completions'));
      expect(detail, contains('model=openai/gpt-9'));
    });

    test('body HTML tetap terbaca sebagai detail', () {
      final detail = AiApiService.dioErrorDetail(
        badResponse(404),
        responseBody: '<!DOCTYPE html><html><body>404 Not Found</body></html>',
        url: 'https://api.example.com/v1/chat/completions',
      )!;

      expect(detail, contains('HTTP 404'));
      expect(detail, contains('https://api.example.com/v1/chat/completions'));
    });

    test('status non-404 memakai apiRejected + status di detail', () {
      final e = badResponse(400);

      expect(AiApiService.mapDioError(e), AppErrorCode.apiRejected);
      expect(AiApiService.dioErrorDetail(e), contains('HTTP 400'));
    });

    test('401 dan 403 jadi apiUnauthorized', () {
      expect(
        AiApiService.mapDioError(badResponse(401)),
        AppErrorCode.apiUnauthorized,
      );
      expect(
        AiApiService.mapDioError(badResponse(403)),
        AppErrorCode.apiUnauthorized,
      );
    });

    test('429 jadi apiRateLimited', () {
      expect(
        AiApiService.mapDioError(badResponse(429)),
        AppErrorCode.apiRateLimited,
      );
    });

    test('timeout, koneksi putus, dan cancel punya kode masing-masing', () {
      DioException typed(DioExceptionType type) => DioException(
        requestOptions: RequestOptions(path: '/models'),
        type: type,
      );

      expect(
        AiApiService.mapDioError(typed(DioExceptionType.connectionTimeout)),
        AppErrorCode.apiTimeout,
      );
      expect(
        AiApiService.mapDioError(typed(DioExceptionType.receiveTimeout)),
        AppErrorCode.apiTimeout,
      );
      expect(
        AiApiService.mapDioError(typed(DioExceptionType.connectionError)),
        AppErrorCode.apiUnreachable,
      );
      expect(
        AiApiService.mapDioError(typed(DioExceptionType.cancel)),
        AppErrorCode.cancelled,
      );
    });
  });

  group('testConnection', () {
    const provider = ApiProvider(
      id: 'p1',
      name: 'OpenRouter',
      baseUrl: 'https://openrouter.ai/api/v1',
      model: 'openai/gpt-5.4',
      apiKey: 'sk-test',
    );

    AiApiService serviceWith(String body, {int status = 200}) => AiApiService(
      clientFactory: (_) =>
          Dio()..httpClientAdapter = _FakeAdapter(body, statusCode: status),
    );

    test('lolos saat model tercantum di /models', () async {
      await serviceWith('{"data":[{"id":"openai/gpt-5.4"}]}')
          .testConnection(provider);
    });

    test('gagal saat model tidak ada di /models', () async {
      final service = serviceWith('{"data":[{"id":"openai/gpt-5.4"}]}');
      await expectLater(
        service.testConnection(provider.copyWith(model: 'space-bunny-alpha')),
        throwsA(
          isA<ApiConnectionException>()
              .having((e) => e.code, 'code', AppErrorCode.apiModelUnavailable)
              .having((e) => e.detail, 'detail', contains('space-bunny-alpha')),
        ),
      );
    });

    test('menerima bentuk Ollama models[].name', () async {
      await serviceWith('{"models":[{"name":"llama3:latest"}]}')
          .testConnection(provider.copyWith(model: 'llama3'));
    });

    test('melewati cek model bila respons tanpa daftar', () async {
      await serviceWith('{}').testConnection(provider);
    });

    test('tetap menolak halaman HTML', () async {
      await expectLater(
        serviceWith('<!DOCTYPE html><html></html>').testConnection(provider),
        throwsA(isA<ApiConnectionException>()),
      );
    });
  });

  group('generateUI', () {
    const provider = ApiProvider(
      id: 'p1',
      name: 'OpenRouter',
      baseUrl: 'https://openrouter.ai/api/v1',
      model: 'x-ai/grok-4.5',
      apiKey: 'sk-test',
    );

    test(
      'tidak mengirim max_tokens agar tidak melewati context window',
      () async {
        final adapter = _FakeAdapter(
          '{"choices":[{"message":{"content":"<html></html>"}}]}',
        );
        final service = AiApiService(
          clientFactory: (_) => Dio()..httpClientAdapter = adapter,
        );

        await service.generateUI(
          provider: provider,
          messages: const [
            {'role': 'user', 'content': 'buat halaman login'},
          ],
        );

        final body = adapter.lastRequest!.data as Map<String, dynamic>;
        expect(body.containsKey('max_tokens'), isFalse);
        expect(body['model'], 'x-ai/grok-4.5');
        expect(body['stream'], isFalse);
      },
    );

    test('mengirim header atribusi ke OpenRouter', () async {
      final adapter = _FakeAdapter(
        '{"choices":[{"message":{"content":"<html></html>"}}]}',
      );
      final service = AiApiService(
        clientFactory: (_) => Dio()..httpClientAdapter = adapter,
      );

      await service.generateUI(
        provider: provider,
        messages: const [
          {'role': 'user', 'content': 'halo'},
        ],
      );

      final headers = adapter.lastRequest!.headers;
      expect(headers['HTTP-Referer'], AppConstants.appReferer);
      expect(headers['X-OpenRouter-Title'], 'Centauri');
      expect(headers['X-OpenRouter-Categories'], 'native-app-builder');
    });

    test('provider lain tidak dikirimi header atribusi', () async {
      final adapter = _FakeAdapter(
        '{"choices":[{"message":{"content":"<html></html>"}}]}',
      );
      final service = AiApiService(
        clientFactory: (_) => Dio()..httpClientAdapter = adapter,
      );

      await service.generateUI(
        provider: provider.copyWith(baseUrl: 'https://api.openai.com/v1'),
        messages: const [
          {'role': 'user', 'content': 'halo'},
        ],
      );

      final headers = adapter.lastRequest!.headers;
      expect(headers.containsKey('HTTP-Referer'), isFalse);
      expect(headers.containsKey('X-OpenRouter-Title'), isFalse);
    });
  });

  group('OAuth Cline', () {
    ApiProvider oauthProvider() => ApiProvider(
      id: 'cline-1',
      name: 'Cline',
      baseUrl: 'https://api.cline.bot/api/v1',
      model: 'anthropic/claude-sonnet-4.5',
      authType: AuthType.oauth,
      oauthProvider: 'cline',
      oauthSession: OAuthSession(
        accessToken: 'acc-token',
        refreshToken: 'ref-token',
        expiresAt: DateTime.utc(2026, 12, 1),
        userId: 'user-1',
      ),
    );

    test('sesi OAuth dikirim dengan prefix workos:', () async {
      final adapter = _FakeAdapter(
        '{"choices":[{"message":{"content":"<html></html>"}}]}',
      );
      final service = AiApiService(
        clientFactory: (_) => Dio()..httpClientAdapter = adapter,
      );

      await service.generateUI(
        provider: oauthProvider(),
        messages: const [
          {'role': 'user', 'content': 'halo'},
        ],
      );

      expect(
        adapter.lastRequest!.headers['Authorization'],
        'Bearer workos:acc-token',
      );
    });

    test('API key tetap dikirim tanpa prefix', () async {
      final adapter = _FakeAdapter(
        '{"choices":[{"message":{"content":"<html></html>"}}]}',
      );
      final service = AiApiService(
        clientFactory: (_) => Dio()..httpClientAdapter = adapter,
      );

      await service.generateUI(
        provider: const ApiProvider(
          id: 'p1',
          name: 'Groq',
          baseUrl: 'https://api.groq.com/openai/v1',
          model: 'llama3',
          apiKey: 'gsk-test',
        ),
        messages: const [
          {'role': 'user', 'content': 'halo'},
        ],
      );

      expect(adapter.lastRequest!.headers['Authorization'], 'Bearer gsk-test');
    });

    test('400 meneruskan pesan provider, bukan pesan generik', () async {
      final service = AiApiService(
        clientFactory: (_) => Dio()
          ..httpClientAdapter = _FakeAdapter(
            '{"error":"invalid model format. Expected format: modelType/model"}',
            statusCode: 400,
          ),
      );

      await expectLater(
        service.testConnection(oauthProvider()),
        throwsA(
          isA<ApiConnectionException>()
              .having((e) => e.code, 'code', AppErrorCode.apiProviderReported)
              .having((e) => e.detail, 'detail', contains('modelType/model')),
        ),
      );
    });

    test('402 dipetakan ke saldo habis, bukan kunci tidak berlaku', () async {
      final service = AiApiService(
        clientFactory: (_) => Dio()
          ..httpClientAdapter = _FakeAdapter(
            '{"error":"insufficient_credits"}',
            statusCode: 402,
          ),
      );

      await expectLater(
        service.testConnection(oauthProvider()),
        throwsA(
          isA<ApiConnectionException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.apiInsufficientCredits,
          ),
        ),
      );
    });
  });
}

/// Adapter Dio palsu: membalas body tetap tanpa menyentuh jaringan.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.body, {this.statusCode = 200});

  final String body;
  final int statusCode;

  /// Request terakhir, dipakai untuk memeriksa body yang dikirim.
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
