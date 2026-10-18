import 'dart:async';
import 'dart:ui'
    show KeyData, KeyDataCallback, KeyEventType, PlatformDispatcher;

import 'package:flutter/widgets.dart';

/// Workaround flutter/flutter#143997 untuk Windows 11.
///
/// Saat item di clipboard history (Win+V) dipilih, Windows menaruh item itu di
/// clipboard lalu mensintesis Ctrl+V. Sayangnya event yang dikirim rusak:
/// physical key-nya `0x1600000000` (tanpa scan code) dan Ctrl-up mendahului
/// V-down, sehingga shortcut paste Flutter tidak pernah terpicu.
///
/// Daripada menulis ulang urutan key (rapuh terhadap variasi engine), event
/// rusak pertama dipakai sebagai pemicu: tempel langsung ke field yang sedang
/// fokus lewat [PasteTextIntent], lalu sisa urutan rusak ditelan agar tidak
/// mengacaukan state keyboard framework.
class WindowsClipboardHistoryPaste {
  WindowsClipboardHistoryPaste({VoidCallback? onPaste})
    : _onPaste = onPaste ?? _pasteIntoFocusedField;

  /// Satu instance untuk seluruh aplikasi; intersepsi bersifat global.
  static final WindowsClipboardHistoryPaste instance =
      WindowsClipboardHistoryPaste();

  /// Physical key palsu pada event sintetis clipboard history.
  static const int _junkPhysical = 0x1600000000;

  /// Logical key Ctrl kiri.
  static const int _controlLeft = 0x200000100;

  final VoidCallback _onPaste;

  KeyDataCallback? _inner;
  bool _swallowing = false;
  Timer? _stopTimer;

  /// Pasang intersepsi. Aman dipanggil berkali-kali.
  void install() {
    if (_inner != null) return;
    _tryInstall(attempts: 20);
  }

  void _tryInstall({required int attempts}) {
    final inner = PlatformDispatcher.instance.onKeyData;
    if (inner == null) {
      // Binding belum memasang callback-nya; coba lagi sebentar.
      if (attempts <= 0) return;
      Timer(
        const Duration(milliseconds: 100),
        () => _tryInstall(attempts: attempts - 1),
      );
      return;
    }
    _inner = inner;
    PlatformDispatcher.instance.onKeyData = _handleKeyData;
  }

  /// Mengembalikan true bila event ditelan, sama seperti [KeyDataCallback].
  @visibleForTesting
  bool handleKeyData(KeyData data, KeyDataCallback inner) {
    if (!_swallowing) {
      if (!_isJunkStart(data)) return inner(data);

      _swallowing = true;
      _armStop();
      // Windows sudah menaruh item pilihan di clipboard sebelum event ini,
      // jadi menempel sekarang memakai isi yang benar.
      _onPaste();
      return true;
    }

    // Event probe tanpa physical/logical harus diteruskan: menelannya membuat
    // framework kehilangan transit mode dan melempar assertion.
    if (data.physical == 0 && data.logical == 0) {
      _armStop();
      return inner(data);
    }

    if (data.physical == _junkPhysical) {
      _armStop();
      return true;
    }

    // Urutan rusak berhenti lebih cepat dari perkiraan: lanjutkan normal.
    _swallowing = false;
    _stopTimer?.cancel();
    return inner(data);
  }

  bool _handleKeyData(KeyData data) {
    final inner = _inner;
    if (inner == null) return false;
    return handleKeyData(data, inner);
  }

  bool _isJunkStart(KeyData data) {
    return data.type == KeyEventType.down &&
        data.physical == _junkPhysical &&
        data.logical == _controlLeft &&
        !data.synthesized;
  }

  void _armStop() {
    _stopTimer?.cancel();
    _stopTimer = Timer(
      const Duration(milliseconds: 300),
      () => _swallowing = false,
    );
  }

  static void _pasteIntoFocusedField() {
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) return;
    Actions.maybeInvoke(
      context,
      const PasteTextIntent(SelectionChangedCause.keyboard),
    );
  }
}
