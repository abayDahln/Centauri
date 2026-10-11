import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Jenis balasan AI.
/// - [ui]   : dokumen HTML self-contained siap dirender di canvas.
/// - [chat] : jawaban percakapan teks biasa (tanpa UI).
enum AiResponseKind { ui, chat }

/// Balasan AI yang sudah diklasifikasi. Dipisah dari [html_parser] supaya
/// canvas bisa merender mode chat maupun UI secara dinamis.
@immutable
class AiResponse {
  const AiResponse._({
    required this.kind,
    this.html,
    this.text,
  });

  const AiResponse.ui(String html)
      : this._(kind: AiResponseKind.ui, html: html);

  const AiResponse.chat(String text)
      : this._(kind: AiResponseKind.chat, text: text);

  final AiResponseKind kind;

  /// HTML self-contained (hanya untuk [AiResponseKind.ui]).
  final String? html;

  /// Teks jawaban (hanya untuk [AiResponseKind.chat]).
  final String? text;

  bool get isUi => kind == AiResponseKind.ui;
  bool get isChat => kind == AiResponseKind.chat;

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'html': html,
    'text': text,
  };

  static AiResponse fromJson(Map<String, dynamic> json) {
    final kind = json['kind'] == 'ui' ? AiResponseKind.ui : AiResponseKind.chat;
    return AiResponse._(
      kind: kind,
      html: json['html'] as String?,
      text: json['text'] as String?,
    );
  }
}

/// Klasifikasi balasan AI murni (dijalankan di isolate via [classifyAiResponseInIsolate]).
///
/// Aturan:
/// 1. Fenced ```html / ```xml block -> UI.
/// 2. Ada dokumen HTML (`<!doctype` / `<html`) -> UI.
/// 3. `{ "html": ... }` -> UI.
/// 4. Selain itu -> chat (teks biasa).
AiResponse classifyAiResponse(String rawResponse) {
  final raw = rawResponse.trim();
  if (raw.isEmpty) {
    return const AiResponse.chat('Respons AI kosong. Coba kirim ulang prompt Anda.');
  }

  // 1. Fenced code block (```html / ```xml / ```).
  final fenceMatch = RegExp(
    r'```(?:html|xml|HTML|XML)?\s*([\s\S]*?)```',
  ).firstMatch(raw);
  if (fenceMatch != null) {
    final body = fenceMatch.group(1)!.trim();
    if (_looksLikeHtml(body)) {
      return AiResponse.ui(_ensureDoctype(body));
    }
    // Fence berisi teks/kode non-HTML -> tetap chat, pakai teks asli.
  }

  // 2. Dokumen HTML mentah di mana pun dalam respons.
  final lower = raw.toLowerCase();
  final doctypeIndex = lower.indexOf('<!doctype html');
  final htmlIndex = lower.indexOf('<html');
  final startIndex = doctypeIndex >= 0
      ? doctypeIndex
      : htmlIndex;
  if (startIndex >= 0) {
    var htmlPart = raw.substring(startIndex);
    final endIndex = htmlPart.toLowerCase().lastIndexOf('</html>');
    if (endIndex >= 0) {
      htmlPart = htmlPart.substring(0, endIndex + '</html>'.length);
    }
    return AiResponse.ui(_ensureDoctype(htmlPart.trim()));
  }

  // 3. JSON wrapper {"html": "..."}.
  if (raw.startsWith('{')) {
    final decoded = _tryDecodeJson(raw);
    if (decoded != null) {
      for (final key in const ['html', 'code', 'output', 'result']) {
        final value = decoded[key];
        if (value is String && _looksLikeHtml(value)) {
          return AiResponse.ui(_ensureDoctype(value.trim()));
        }
      }
      for (final key in const ['text', 'message', 'content', 'answer']) {
        final value = decoded[key];
        if (value is String && value.trim().isNotEmpty) {
          return AiResponse.chat(value.trim());
        }
      }
    }
  }

  // 4. Fallback: teks percakapan.
  return AiResponse.chat(_stripMarkdownFences(raw));
}

/// Versi isolate (NFR-02).
Future<AiResponse> classifyAiResponseInIsolate(String rawResponse) =>
    compute(classifyAiResponse, rawResponse);

bool _looksLikeHtml(String text) {
  final lower = text.toLowerCase();
  return lower.contains('<!doctype') ||
      lower.contains('<html') ||
      lower.contains('<body') ||
      (lower.contains('<div') && lower.contains('>')) ||
      (lower.contains('<section') && lower.contains('>')) ||
      (lower.contains('<style') && lower.contains('>'));
}

String _ensureDoctype(String html) {
  if (html.toLowerCase().startsWith('<!doctype')) return html;
  return '<!DOCTYPE html>\n$html';
}

/// Buang fence markdown agar jawaban chat tampil bersih.
String _stripMarkdownFences(String text) {
  final fence = RegExp(r'```[\w]*\s*([\s\S]*?)```');
  if (!fence.hasMatch(text)) return text;
  return text.replaceAllMapped(fence, (m) => m.group(1) ?? '').trim();
}

Map<String, dynamic>? _tryDecodeJson(String source) {
  try {
    final value = jsonDecode(source);
    return value is Map<String, dynamic> ? value : null;
  } on FormatException {
    return null;
  }
}
