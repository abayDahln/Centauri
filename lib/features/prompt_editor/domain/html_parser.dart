import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Ekstraksi HTML dari respons AI (FR-04 parser / risk mitigation:
/// "fallback parser" jika AI membungkus output dengan markdown/prose).
///
/// Fungsi ini murni dan dijalankan di Isolate via [parseHtmlInIsolate]
/// agar tidak memblokir Main UI Thread (NFR-02).
String extractHtmlFromResponse(String rawResponse) {
  var text = rawResponse.trim();
  if (text.isEmpty) return _errorDocument('Respons AI kosong.');

  // 1. Ambil isi fenced code block (```html ... ``` atau ``` ... ```).
  final fenceMatch = RegExp(r'```(?:html|xml|HTML)?\s*([\s\S]*?)```')
      .firstMatch(text);
  if (fenceMatch != null) {
    text = fenceMatch.group(1)!.trim();
  }

  // 2. Bungkus JSON {"html": "..."} / {"code": "..."} / {"content": "..."}.
  if (text.startsWith('{')) {
    final decoded = _tryDecodeJson(text);
    if (decoded != null) {
      for (final key in const ['html', 'code', 'content', 'output', 'result']) {
        final value = decoded[key];
        if (value is String && value.contains('<')) {
          text = value.trim();
          break;
        }
      }
    }
  }

  // 3. Buang prose sebelum/ setelah dokumen HTML.
  final lower = text.toLowerCase();
  var startIndex = lower.indexOf('<!doctype html');
  if (startIndex < 0) startIndex = lower.indexOf('<html');
  if (startIndex >= 0) {
    text = text.substring(startIndex);
    final endIndex = text.toLowerCase().lastIndexOf('</html>');
    if (endIndex >= 0) text = text.substring(0, endIndex + '</html>'.length);
  }

  // 4. Validasi akhir.
  final finalLower = text.toLowerCase();
  final looksLikeHtml =
      finalLower.contains('<html') ||
      finalLower.contains('<!doctype') ||
      (finalLower.contains('<div') && finalLower.contains('<'));

  if (!looksLikeHtml) {
    return _errorDocument(
      'AI tidak mengembalikan HTML yang valid. Coba ulangi dengan instruksi yang lebih spesifik.',
    );
  }

  if (!finalLower.startsWith('<!doctype')) {
    text = '<!DOCTYPE html>\n$text';
  }
  return text;
}

/// Versi isolate dari [extractHtmlFromResponse] (NFR-02).
Future<String> parseHtmlInIsolate(String rawResponse) =>
    compute(extractHtmlFromResponse, rawResponse);

Map<String, dynamic>? _tryDecodeJson(String source) {
  try {
    final value = jsonDecode(source);
    return value is Map<String, dynamic> ? value : null;
  } on FormatException {
    return null;
  }
}

String _errorDocument(String message) {
  final escaped = const HtmlEscape().convert(message);
  return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  body {
    margin: 0; height: 100vh;
    display: flex; align-items: center; justify-content: center;
    background: #0F0F11; color: #A1A1AA;
    font-family: Inter, system-ui, sans-serif; text-align: center;
  }
  p { max-width: 420px; line-height: 1.6; font-size: 14px; }
</style>
</head>
<body><p>$escaped</p></body>
</html>
''';
}
