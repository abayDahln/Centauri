import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mode layout pratinjau kanvas: desktop atau mobile.
enum CanvasLayoutMode { desktop, mobile }

/// Menentukan mode layout pratinjau kanvas default berdasarkan platform target:
/// - Windows / desktop: default desktop.
/// - Android / mobile: default mobile.
CanvasLayoutMode get defaultCanvasLayoutMode {
  if (kIsWeb) return CanvasLayoutMode.desktop;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.fuchsia:
      return CanvasLayoutMode.mobile;
    case TargetPlatform.windows:
    case TargetPlatform.macOS:
    case TargetPlatform.linux:
      return CanvasLayoutMode.desktop;
  }
}

/// Mode layout pratinjau kanvas (desktop vs mobile).
final canvasLayoutModeProvider =
    NotifierProvider<CanvasLayoutModeNotifier, CanvasLayoutMode>(
      CanvasLayoutModeNotifier.new,
    );

class CanvasLayoutModeNotifier extends Notifier<CanvasLayoutMode> {
  @override
  CanvasLayoutMode build() => defaultCanvasLayoutMode;

  void set(CanvasLayoutMode mode) => state = mode;

  void toggle() => state = state == CanvasLayoutMode.desktop
      ? CanvasLayoutMode.mobile
      : CanvasLayoutMode.desktop;
}

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
