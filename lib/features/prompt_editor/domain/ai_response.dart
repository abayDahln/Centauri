import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Satu layar UI hasil generate.
@immutable
class UiScreen {
  const UiScreen({required this.title, required this.html});

  /// Judul layar (dari heading sebelum blok, mis. "Home"); boleh kosong.
  final String title;

  /// HTML self-contained layar ini.
  final String html;

  Map<String, dynamic> toJson() => {'title': title, 'html': html};

  static UiScreen fromJson(Map<String, dynamic> json) => UiScreen(
    title: json['title'] as String? ?? '',
    html: json['html'] as String? ?? '',
  );
}

/// Jenis balasan AI.
/// - [ui]   : minimal satu dokumen HTML siap dirender di canvas.
/// - [chat] : jawaban percakapan teks biasa (tanpa UI).
enum AiResponseKind { ui, chat }

/// Balasan AI yang sudah diklasifikasi.
@immutable
class AiResponse {
  const AiResponse._({
    required this.kind,
    this.screens = const [],
    this.text,
    this.note,
  });

  /// Satu layar UI.
  AiResponse.ui(String html, {String? title, String? note})
    : this._(
        kind: AiResponseKind.ui,
        screens: [UiScreen(title: title ?? '', html: html)],
        note: note,
      );

  /// Beberapa layar UI sekaligus.
  // ignore: prefer_const_constructors_in_immutables
  AiResponse.screens(List<UiScreen> screens, {String? note})
    : this._(kind: AiResponseKind.ui, screens: screens, note: note);

  /// Jawaban percakapan biasa.
  const AiResponse.chat(String text)
    : this._(kind: AiResponseKind.chat, text: text);

  final AiResponseKind kind;

  /// Layar-layar UI (hanya untuk [AiResponseKind.ui]).
  final List<UiScreen> screens;

  /// Teks jawaban percakapan (hanya untuk [AiResponseKind.chat]).
  final String? text;

  /// Catatan penjelasan yang menyertai hasil UI (PART 1 dari MODE B).
  final String? note;

  bool get isUi => kind == AiResponseKind.ui;
  bool get isChat => kind == AiResponseKind.chat;

  /// Layar pertama (untuk kompatibilitas/back-compat).
  String? get html => screens.isEmpty ? null : screens.first.html;

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'screens': screens.map((s) => s.toJson()).toList(),
    'text': text,
    'note': note,
  };

  static AiResponse fromJson(Map<String, dynamic> json) {
    final kind = json['kind'] == 'ui' ? AiResponseKind.ui : AiResponseKind.chat;
    return AiResponse._(
      kind: kind,
      screens: (json['screens'] as List<dynamic>? ?? [])
          .map((s) => UiScreen.fromJson(s as Map<String, dynamic>))
          .toList(),
      text: json['text'] as String?,
      note: json['note'] as String?,
    );
  }
}

/// Klasifikasi balasan AI murni (dijalankan di isolate via
/// [classifyAiResponseInIsolate]).
///
/// Aturan MODE B: balasan boleh berisi catatan teks (PART 1) lalu satu atau
/// lebih blok ```html (PART 2). Semua blok HTML diambil sebagai layar.
/// Bila tidak ada HTML sama sekali -> chat biasa.
AiResponse classifyAiResponse(String rawResponse) {
  final raw = rawResponse.trim();
  if (raw.isEmpty) {
    return const AiResponse.chat(
      'Respons AI kosong. Coba kirim ulang prompt Anda.',
    );
  }

  // 1. Kumpulkan semua fence berisi HTML (satu per layar).
  final fenceRegex = RegExp(r'```[a-zA-Z]*[ \t]*\n?([\s\S]*?)```');
  final screens = <UiScreen>[];
  final matches = fenceRegex.allMatches(raw).toList();
  for (var i = 0; i < matches.length; i++) {
    final match = matches[i];
    final body = match.group(1)!.trim();
    if (!_looksLikeHtml(body)) continue;
    screens.add(
      UiScreen(
        title: _titleBeforeFence(raw, match.start),
        html: _ensureDoctype(body),
      ),
    );
  }

  if (screens.isNotEmpty) {
    return AiResponse.screens(
      screens,
      note: _noteText(raw, matches.isEmpty ? 0 : matches.first.start),
    );
  }

  // 2. Dokumen HTML mentah tanpa fence.
  final lower = raw.toLowerCase();
  final doctypeIndex = lower.indexOf('<!doctype html');
  final htmlIndex = lower.indexOf('<html');
  final startIndex = doctypeIndex >= 0 ? doctypeIndex : htmlIndex;
  if (startIndex >= 0) {
    var htmlPart = raw.substring(startIndex);
    final endIndex = htmlPart.toLowerCase().lastIndexOf('</html>');
    if (endIndex >= 0) {
      htmlPart = htmlPart.substring(0, endIndex + '</html>'.length);
    }
    return AiResponse.ui(
      _ensureDoctype(htmlPart.trim()),
      note: _noteText(raw, startIndex),
    );
  }

  // 3. JSON wrapper {"html": "..."} atau {"screens": [...]}.
  if (raw.startsWith('{')) {
    final decoded = _tryDecodeJson(raw);
    if (decoded != null) {
      final screensJson = decoded['screens'];
      if (screensJson is List && screensJson.isNotEmpty) {
        final list = <UiScreen>[];
        for (final item in screensJson) {
          if (item is Map<String, dynamic>) {
            final screen = UiScreen.fromJson(item);
            if (_looksLikeHtml(screen.html)) {
              list.add(UiScreen(
                title: screen.title,
                html: _ensureDoctype(screen.html.trim()),
              ));
            }
          }
        }
        if (list.isNotEmpty) {
          return AiResponse.screens(
            list,
            note: decoded['note'] as String? ?? decoded['text'] as String?,
          );
        }
      }
      for (final key in const ['html', 'code', 'output', 'result']) {
        final value = decoded[key];
        if (value is String && _looksLikeHtml(value)) {
          return AiResponse.ui(
            _ensureDoctype(value.trim()),
            note: decoded['note'] as String?,
          );
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
  return AiResponse.chat(_sanitizeChatText(raw));
}

/// Versi isolate (NFR-02).
Future<AiResponse> classifyAiResponseInIsolate(String rawResponse) =>
    compute(classifyAiResponse, rawResponse);

/// Ambil heading singkat tepat sebelum sebuah fence (mis. "### Home").
/// Hanya menerima baris pendek seperti heading. Kalimat panjang dari catatan
/// penjelasan AI (PART 1) sengaja ditolak agar tidak menjadi judul frame
/// yang membingungkan di board.
String _titleBeforeFence(String raw, int fenceStart) {
  final before = raw.substring(0, fenceStart);
  final lines = before.split('\n');
  for (var i = lines.length - 1; i >= 0 && i >= lines.length - 4; i--) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;
    // Heading markdown selalu diterima (mis. "### Pricing").
    if (RegExp(r'^#+\s').hasMatch(line)) {
      final cleaned = line
          .replaceAll(RegExp(r'^#+\s*'), '')
          .replaceAll(':', '')
          .trim();
      if (cleaned.isEmpty || cleaned.length > 60) return '';
      return cleaned;
    }
    // Tanpa heading: tolak kalimat panjang (catatan PART 1), hanya terima
    // label pendek satu baris tanpa titik (mis. "Pricing Page").
    if (line.length > 60 || line.contains('.') || line.contains('!')) {
      return '';
    }
    final words = line.split(RegExp(r'\s+'));
    if (words.length > 8) return '';
    return line.replaceAll(RegExp(r'^#+\s*'), '').replaceAll(':', '').trim();
  }
  return '';
}

/// Teks catatan (penjelasan) sebelum bagian HTML pertama.
String? _noteText(String raw, int firstHtmlIndex) {
  if (firstHtmlIndex <= 0) return null;
  var before = raw.substring(0, firstHtmlIndex).trim();
  if (before.endsWith('```')) {
    before = before.substring(0, before.length - 3).trim();
  }
  // Buang heading layar pertama bila ada di ujung (mis. "### Home").
  final lines = before.split('\n');
  while (lines.isNotEmpty) {
    final last = lines.last.trim();
    if (last.isEmpty || RegExp(r'^#+\s').hasMatch(last)) {
      lines.removeLast();
    } else {
      break;
    }
  }
  final note = lines.join('\n').trim();
  return note.isEmpty ? null : note;
}

/// Apakah teks ini dokumen HTML yang lengkap (layak jadi satu layar).
/// Snippet parsial (mis. hanya `<div>`) sengaja TIDAK dihitung agar potongan
/// kode di jawaban chat tidak salah dirender sebagai UI.
bool _looksLikeHtml(String text) {
  final lower = text.toLowerCase();
  return lower.contains('<!doctype') ||
      lower.contains('<html') ||
      lower.contains('<body');
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

/// Bersihkan teks chat dari sisa tag HTML inline yang bocor dari model.
///
/// Kasus nyata: model kecil menjawab sapaan dengan
/// `Hello! How can <a href="#main">Skip to content</a> I can help...`
/// Renderer markdown membuang tag tanpa menyisip spasi sehingga tampil
/// rusak: "How canSkip to contentI can...". Di sini tag diganti satu spasi.
///
/// Hanya dipakai untuk prosa murni (tanpa fenced block) agar contoh kode
/// ```html <div>...``` tidak ikut rusak.
String _sanitizeChatText(String text) {
  var out = _stripMarkdownFences(text);
  // Ada fenced block (contoh kode): jangan sentuh isi tag-nya.
  if (text.contains('```')) return out;
  out = out.replaceAll(RegExp(r'<[^<>\n]+>'), ' ');
  out = out.replaceAll(RegExp(r'[ \t]+'), ' ');
  return out.trim();
}

Map<String, dynamic>? _tryDecodeJson(String source) {
  try {
    final value = jsonDecode(source);
    return value is Map<String, dynamic> ? value : null;
  } on FormatException {
    return null;
  }
}
