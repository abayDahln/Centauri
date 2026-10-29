import 'dart:convert';
import 'dart:typed_data';

import 'package:centauri/core/errors/app_error.dart';
import 'package:centauri/features/provider_config/data/datasources/ai_api_service.dart';
import 'package:centauri/features/provider_config/data/datasources/cline_oauth_service.dart';
import 'package:centauri/features/provider_config/domain/entities/oauth_session.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Membangun `code` seperti milik Cline: base64url dari JSON sesi plus ekor
/// biner, sehingga decoder harus berhenti di `}` terakhir.
String buildCode({
  String accessToken = 'acc-token',
  String refreshToken = 'ref-token',
  Object? expiresAt = '2026-11-01T12:00:00.000Z',
  String? email = 'orang@contoh.com',
  String? name,
  String? firstName,
  String? lastName,
}) {
  final payload = <String, dynamic>{
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresAt': ?expiresAt,
    'email': ?email,
    'name': ?name,
    'firstName': ?firstName,
    'lastName': ?lastName,
  };
  final bytes = <int>[...utf8.encode(jsonEncode(payload)), 0x00, 0x01, 0xff];
  return base64Url.encode(bytes);
}

void main() {
  group('extractCode', () {
    test('mengambil code dari tautan vscode://', () {
      expect(
        ClineOAuthService.extractCode(
          'vscode://saoudrizwan.claude-dev/auth?code=abc-123&state=xyz',
        ),
        'abc-123',
      );
    });

    test('mengambil code dari tautan loopback', () {
      expect(
        ClineOAuthService.extractCode(
          'http://127.0.0.1:8765/callback?code=abc',
        ),
        'abc',
      );
    });

    test('teks base64 mentah dikembalikan apa adanya', () {
      expect(ClineOAuthService.extractCode('  eyJhIjoxfQ  '), 'eyJhIjoxfQ');
    });

    test('URL tanpa parameter code ditolak', () {
      expect(
        ClineOAuthService.extractCode('vscode://saoudrizwan.claude-dev/auth'),
        isNull,
      );
    });

    test('teks kosong ditolak', () {
      expect(ClineOAuthService.extractCode('   '), isNull);
    });
  });

  group('decodeSession', () {
    test('mengurai sesi dari tautan vscode://', () {
      final code = buildCode(firstName: 'Orang', lastName: 'Contoh');
      final session = ClineOAuthService.decodeSession(
        'vscode://saoudrizwan.claude-dev/auth?code=$code',
      );

      expect(session, isNotNull);
      expect(session!.accessToken, 'acc-token');
      expect(session.refreshToken, 'ref-token');
      expect(session.email, 'orang@contoh.com');
      expect(session.displayName, 'Orang Contoh');
      expect(session.expiresAt, DateTime.utc(2026, 11, 1, 12));
    });

    test('menerima base64 mentah dan memakai name bila ada', () {
      final session = ClineOAuthService.decodeSession(
        buildCode(name: 'Nama Lengkap'),
      );
      expect(session?.displayName, 'Nama Lengkap');
    });

    test('menerima expiresAt berupa epoch milidetik', () {
      final session = ClineOAuthService.decodeSession(
        buildCode(expiresAt: 1793544000000),
      );
      expect(session?.expiresAt.isUtc, isTrue);
      expect(session?.expiresAt.year, 2026);
    });

    test('code rusak menghasilkan null', () {
      expect(ClineOAuthService.decodeSession('bukan-base64!!!'), isNull);
    });

    test('JSON tanpa refresh token menghasilkan null', () {
      final code = base64Url.encode(
        utf8.encode(jsonEncode({'accessToken': 'acc-token'})),
      );
      expect(ClineOAuthService.decodeSession(code), isNull);
    });
  });

  group('refresh', () {
    test('mengirim field camelCase dan mengembalikan token baru', () async {
      final adapter = _FakeAdapter({
        '/api/v1/auth/refresh': (
          200,
          '{"accessToken":"acc-2","refreshToken":"ref-2",'
              '"expiresAt":"2026-12-01T00:00:00.000Z"}',
        ),
      });
      final service = ClineOAuthService(
        dio: Dio()..httpClientAdapter = adapter,
      );

      final refreshed = await service.refresh(_session());

      final request = adapter.requests.single;
      expect(request.uri.path, '/api/v1/auth/refresh');
      expect(request.data, {
        'grantType': 'refresh_token',
        'refreshToken': 'ref-token',
      });
      expect(refreshed.accessToken, 'acc-2');
      // Rotasi: refresh token baru wajib ikut tersimpan.
      expect(refreshed.refreshToken, 'ref-2');
      expect(refreshed.expiresAt, DateTime.utc(2026, 12, 1));
    });

    test(
      'mempertahankan refresh token lama bila respons tanpa token baru',
      () async {
        final adapter = _FakeAdapter({
          '/api/v1/auth/refresh': (200, '{"accessToken":"acc-2"}'),
        });
        final service = ClineOAuthService(
          dio: Dio()..httpClientAdapter = adapter,
        );

        final refreshed = await service.refresh(_session());
        expect(refreshed.accessToken, 'acc-2');
        expect(refreshed.refreshToken, 'ref-token');
      },
    );

    test('401 dipetakan ke apiUnauthorized', () async {
      final adapter = _FakeAdapter({
        '/api/v1/auth/refresh': (401, '{"error":"invalid_grant"}'),
      });
      final service = ClineOAuthService(
        dio: Dio()..httpClientAdapter = adapter,
      );

      await expectLater(
        service.refresh(_session()),
        throwsA(
          isA<ApiConnectionException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.apiUnauthorized,
          ),
        ),
      );
    });
  });

  group('connect', () {
    test('mengisi profil dari /users/me dengan header workos:', () async {
      final adapter = _FakeAdapter({
        '/api/v1/users/me': (
          200,
          '{"data":{"id":"user-1","email":"orang@contoh.com","name":"Orang"}}',
        ),
      });
      final service = ClineOAuthService(
        dio: Dio()..httpClientAdapter = adapter,
      );

      final session = await service.connect(buildCode());

      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer workos:acc-token',
      );
      expect(session.userId, 'user-1');
      expect(session.email, 'orang@contoh.com');
      expect(session.displayName, 'Orang');
      expect(session.accessToken, 'acc-token');
    });

    test('tautan tanpa sesi ditolak tanpa memanggil jaringan', () async {
      final adapter = _FakeAdapter({});
      final service = ClineOAuthService(
        dio: Dio()..httpClientAdapter = adapter,
      );

      await expectLater(
        service.connect('vscode://saoudrizwan.claude-dev/auth'),
        throwsA(
          isA<ApiConnectionException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.apiUnauthorized,
          ),
        ),
      );
      expect(adapter.requests, isEmpty);
    });
  });

  group('fetchBalance', () {
    test('mikro-USD dibaca sebagai dolar', () async {
      final adapter = _FakeAdapter({
        '/api/v1/users/user-1/balance': (200, '{"balance":1234567}'),
      });
      final service = ClineOAuthService(
        dio: Dio()..httpClientAdapter = adapter,
      );

      expect(await service.fetchBalance(_session()), closeTo(1.234567, 1e-9));
    });

    test('saldo negatif tetap terbaca', () async {
      final adapter = _FakeAdapter({
        '/api/v1/users/user-1/balance': (200, '{"balance":-10000}'),
      });
      final service = ClineOAuthService(
        dio: Dio()..httpClientAdapter = adapter,
      );

      expect(await service.fetchBalance(_session()), closeTo(-0.01, 1e-9));
    });

    test('tanpa userId tidak memanggil jaringan', () async {
      final adapter = _FakeAdapter({});
      final service = ClineOAuthService(
        dio: Dio()..httpClientAdapter = adapter,
      );

      await expectLater(
        service.fetchBalance(_session(userId: null)),
        throwsA(
          isA<ApiConnectionException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.apiBadResponse,
          ),
        ),
      );
      expect(adapter.requests, isEmpty);
    });
  });
}

OAuthSession _session({String? userId = 'user-1'}) => OAuthSession(
  accessToken: 'acc-token',
  refreshToken: 'ref-token',
  expiresAt: DateTime.utc(2026, 10, 28),
  userId: userId,
  email: 'orang@contoh.com',
);

/// Adapter Dio palsu: menjawab berdasarkan path tanpa menyentuh jaringan.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.responses);

  /// path → (status, body).
  final Map<String, (int, String)> responses;

  /// Semua request yang lewat, dipakai untuk memeriksa header dan body.
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final entry = responses[options.uri.path] ?? (404, '{}');
    return ResponseBody.fromString(
      entry.$2,
      entry.$1,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
