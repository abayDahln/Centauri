import 'package:centauri/features/provider_config/domain/entities/oauth_token_set.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OAuthTokenSet.fromTokenResponse', () {
    test('parses access token and expires_in', () {
      final tokens = OAuthTokenSet.fromTokenResponse({
        'access_token': 'at-1',
        'refresh_token': 'rt-1',
        'expires_in': 3600,
        'token_type': 'Bearer',
        'scope': 'a b',
      });

      expect(tokens.accessToken, 'at-1');
      expect(tokens.refreshToken, 'rt-1');
      expect(tokens.tokenType, 'Bearer');
      expect(tokens.scope, 'a b');
      expect(tokens.expiresAt.isAfter(DateTime.now()), isTrue);
    });

    test('keeps previous refresh token when response omits it', () {
      final previous = OAuthTokenSet(
        accessToken: 'old',
        refreshToken: 'rt-old',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      final refreshed = OAuthTokenSet.fromTokenResponse(
        {'access_token': 'new', 'expires_in': 60},
        previous: previous,
      );

      expect(refreshed.accessToken, 'new');
      expect(refreshed.refreshToken, 'rt-old');
    });

    test('throws when access_token is missing', () {
      expect(
        () => OAuthTokenSet.fromTokenResponse({'expires_in': 60}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('expiry logic', () {
    test('isExpired true when past expiry', () {
      final tokens = OAuthTokenSet(
        accessToken: 'a',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      expect(tokens.isExpired, isTrue);
      expect(tokens.needsRefresh, isTrue);
    });

    test('needsRefresh true within the 5-minute skew window', () {
      final tokens = OAuthTokenSet(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAt: DateTime.now().add(const Duration(minutes: 3)),
      );
      expect(tokens.isExpired, isFalse);
      expect(tokens.needsRefresh, isTrue);
      expect(tokens.canRefresh, isTrue);
    });

    test('fresh token needs no refresh', () {
      final tokens = OAuthTokenSet(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(tokens.needsRefresh, isFalse);
    });

    test('canRefresh false without a refresh token', () {
      final tokens = OAuthTokenSet(
        accessToken: 'a',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(tokens.canRefresh, isFalse);
    });
  });

  group('serialization', () {
    test('round-trips through JSON', () {
      final tokens = OAuthTokenSet(
        accessToken: 'at',
        refreshToken: 'rt',
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
        scope: 'x',
      );
      final restored = OAuthTokenSet.fromJson(tokens.toJson());
      expect(restored.accessToken, 'at');
      expect(restored.refreshToken, 'rt');
      expect(restored.scope, 'x');
      expect(
        restored.expiresAt.millisecondsSinceEpoch,
        tokens.expiresAt.millisecondsSinceEpoch,
      );
    });
  });
}
