import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/partial_html.dart';

/// Tahap proses generate yang ditampilkan ke pengguna.
enum GenerationPhase {
  idle,
  preparing,
  waiting,
  streaming,
  assembling,
  done,
  failed,
  cancelled;

  /// true selama proses berjalan (overlay kanvas & kartu langkah tampil).
  bool get isActive =>
      this == preparing ||
      this == waiting ||
      this == streaming ||
      this == assembling;
}

@immutable
class GenerationStreamState {
  const GenerationStreamState({
    this.phase = GenerationPhase.idle,
    this.streaming = false,
    this.charCount = 0,
    this.previewHtml,
    this.previewSlug,
    this.previewPageIndex = 0,
    this.knownScreenCount,
    this.startedAt,
    this.uiRequest = false,
  });

  final GenerationPhase phase;

  /// false = provider tidak mengalirkan token; UI memakai animasi bertahap.
  final bool streaming;

  final int charCount;

  /// Dokumen parsial yang siap ditampilkan di kanvas (null = belum ada).
  final String? previewHtml;

  /// Slug halaman yang sedang dipratinjau (dari meta `centauri-page`).
  final String? previewSlug;

  /// Halaman ke berapa yang sedang ditulis (1-based).
  final int previewPageIndex;

  /// Jumlah halaman yang diminta user, bila disebut di prompt.
  final int? knownScreenCount;

  final DateTime? startedAt;

  /// true bila permintaan ini menghasilkan/mengubah UI, sehingga kanvas
  /// menampilkan pratinjau. Percakapan biasa tidak menyentuh kanvas.
  final bool uiRequest;

  GenerationStreamState copyWith({
    GenerationPhase? phase,
    bool? streaming,
    int? charCount,
    String? previewHtml,
    String? previewSlug,
    int? previewPageIndex,
    int? knownScreenCount,
    DateTime? startedAt,
    bool? uiRequest,
    bool clearPreview = false,
  }) {
    return GenerationStreamState(
      phase: phase ?? this.phase,
      streaming: streaming ?? this.streaming,
      charCount: charCount ?? this.charCount,
      previewHtml: clearPreview ? null : (previewHtml ?? this.previewHtml),
      previewSlug: clearPreview ? null : (previewSlug ?? this.previewSlug),
      previewPageIndex: previewPageIndex ?? this.previewPageIndex,
      knownScreenCount: knownScreenCount ?? this.knownScreenCount,
      startedAt: startedAt ?? this.startedAt,
      uiRequest: uiRequest ?? this.uiRequest,
    );
  }
}

/// State pratinjau saat generate.
///
/// Sengaja terpisah dari [WorkspaceState]: state ini berubah tiap beberapa
/// ratus milidetik, sedangkan WorkspaceState ikut di-snapshot untuk undo dan
/// dibaca banyak panel. Teks parsial tidak boleh masuk ke sana.
class GenerationStreamNotifier extends Notifier<GenerationStreamState> {
  static const Duration _tickInterval = Duration(milliseconds: 160);
  static const Duration _settleDelay = Duration(milliseconds: 900);
  static const int _minNewChars = 400;

  final StringBuffer _raw = StringBuffer();
  Timer? _tick;
  Timer? _settle;
  int _publishedChars = 0;

  @override
  GenerationStreamState build() {
    ref.onDispose(() {
      _tick?.cancel();
      _settle?.cancel();
    });
    return const GenerationStreamState();
  }

  /// Mulai sesi baru. [knownScreenCount] diisi bila user menyebut jumlah
  /// halaman di prompt, supaya UI bisa menampilkan "Halaman 1 dari 3".
  void begin({int? knownScreenCount, bool uiRequest = false}) {
    _tick?.cancel();
    _settle?.cancel();
    _tick = null;
    _settle = null;
    _raw.clear();
    _publishedChars = 0;
    state = GenerationStreamState(
      phase: GenerationPhase.preparing,
      knownScreenCount: knownScreenCount,
      startedAt: DateTime.now(),
      uiRequest: uiRequest,
    );
  }

  void onStart({required bool streaming}) {
    if (state.phase == GenerationPhase.idle) return;
    state = state.copyWith(
      phase: streaming ? GenerationPhase.streaming : GenerationPhase.waiting,
      streaming: streaming,
    );
  }

  /// Token baru masuk: ditampung dulu, dipublikasikan tiap ~160 ms.
  void onDelta(String text) {
    if (state.phase == GenerationPhase.idle) return;
    _raw.write(text);
    _tick ??= Timer(_tickInterval, () {
      _tick = null;
      _publish();
    });
  }

  void _publish() {
    final raw = _raw.toString();
    if (raw.length - _publishedChars >= _minNewChars) {
      _publishedChars = raw.length;
      final html = extractPartialHtml(raw);
      if (html != null && html != state.previewHtml) {
        state = state.copyWith(
          previewHtml: html,
          previewSlug: slugOfPartial(html) ?? state.previewSlug,
          previewPageIndex: _pageIndex(raw),
        );
      }
    }
    if (state.charCount != raw.length) {
      state = state.copyWith(charCount: raw.length);
    }
  }

  /// Nomor halaman yang sedang ditulis: tiap pasangan fence = satu halaman.
  int _pageIndex(String raw) {
    final ticks = '```'.allMatches(raw).length;
    final page = (ticks + 1) ~/ 2;
    return page < 1 ? 1 : page;
  }

  /// Teks selesai; halaman sedang dirakit (stamp DOM + simpan).
  void assembling() {
    if (state.phase == GenerationPhase.idle) return;
    state = state.copyWith(phase: GenerationPhase.assembling);
  }

  /// Selesai dan halaman sudah di-commit.
  void finish() {
    _tick?.cancel();
    _tick = null;
    state = state.copyWith(phase: GenerationPhase.done);
    // Pratinjau parsial dilepas setelah commit + render ulang selesai, supaya
    // kanvas tidak berkedip kembali ke halaman lama.
    _settle?.cancel();
    _settle = Timer(_settleDelay, _reset);
  }

  void fail() {
    _tick?.cancel();
    _tick = null;
    _settle?.cancel();
    state = state.copyWith(phase: GenerationPhase.failed, clearPreview: true);
    _settle = Timer(const Duration(milliseconds: 400), _reset);
  }

  void cancel() {
    _tick?.cancel();
    _tick = null;
    _settle?.cancel();
    state = state.copyWith(
      phase: GenerationPhase.cancelled,
      clearPreview: true,
    );
    _settle = Timer(const Duration(milliseconds: 400), _reset);
  }

  void _reset() {
    _settle = null;
    _raw.clear();
    _publishedChars = 0;
    state = const GenerationStreamState();
  }
}

final generationStreamProvider =
    NotifierProvider<GenerationStreamNotifier, GenerationStreamState>(
      GenerationStreamNotifier.new,
    );
