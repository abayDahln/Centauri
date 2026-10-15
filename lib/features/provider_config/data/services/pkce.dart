import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// PKCE (RFC 7636) — Proof Key for Code Exchange.
///
/// Membuat `code_verifier` acak dan `code_challenge` metode S256. Verifier
/// hanya hidup di memori selama satu alur otorisasi, tidak pernah dipersist.
class Pkce {
  Pkce._();

  static final Random _random = Random.secure();

  /// Panjang byte verifier. 32 byte → 43 karakter base64url (batas minimum
  /// RFC 7636 adalah 43 karakter, maksimum 128).
  static const int _verifierBytes = 32;

  /// Membuat `code_verifier` acak yang memenuhi charset unreserved RFC 7636.
  static String createVerifier() {
    final bytes = List<int>.generate(_verifierBytes, (_) => _random.nextInt(256));
    return _base64UrlNoPadding(bytes);
  }

  /// Menghitung `code_challenge` = BASE64URL(SHA256(ASCII(verifier))).
  static String challenge(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));
    return _base64UrlNoPadding(digest.bytes);
  }

  /// Membuat nilai `state` acak untuk proteksi CSRF.
  static String createState() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return _base64UrlNoPadding(bytes);
  }

  static String _base64UrlNoPadding(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');
}
