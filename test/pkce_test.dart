import 'package:centauri/features/provider_config/data/services/pkce.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pkce', () {
    test('challenge matches RFC 7636 Appendix B vector (S256)', () {
      // Verifier & challenge dari RFC 7636.
      const verifier = 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';
      const expected = 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM';
      expect(Pkce.challenge(verifier), expected);
    });

    test('createVerifier is base64url, 43 chars, and unique', () {
      final a = Pkce.createVerifier();
      final b = Pkce.createVerifier();

      expect(a.length, 43); // 32 byte → 43 karakter base64url tanpa padding
      expect(a, isNot(equals(b)));
      expect(RegExp(r'^[A-Za-z0-9\-_]+$').hasMatch(a), isTrue);
      expect(a.contains('='), isFalse);
    });

    test('createState is non-empty and url-safe', () {
      final state = Pkce.createState();
      expect(state.isNotEmpty, isTrue);
      expect(RegExp(r'^[A-Za-z0-9\-_]+$').hasMatch(state), isTrue);
    });

    test('challenge is deterministic for the same verifier', () {
      final verifier = Pkce.createVerifier();
      expect(Pkce.challenge(verifier), Pkce.challenge(verifier));
    });
  });
}
