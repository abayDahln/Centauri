import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Visibilitas area UI (kanvas pratinjau + panel kode).
///
/// Saat dimatikan, panel chat memakai seluruh lebar jendela — mode fokus
/// chat, berguna saat user hanya ingin mengobrol atau membaca riwayat.
final canvasVisibleProvider = NotifierProvider<CanvasVisibleNotifier, bool>(
  CanvasVisibleNotifier.new,
);

class CanvasVisibleNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool value) => state = value;

  void toggle() => state = !state;
}

/// Visibilitas sidebar riwayat (daftar percakapan) di desktop.
///
/// Bisa disembunyikan agar percakapan punya lebih banyak ruang, termasuk saat
/// mode fokus chat.
final historyVisibleProvider = NotifierProvider<HistoryVisibleNotifier, bool>(
  HistoryVisibleNotifier.new,
);

class HistoryVisibleNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool value) => state = value;

  void toggle() => state = !state;
}
