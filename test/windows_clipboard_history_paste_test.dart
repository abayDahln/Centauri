import 'dart:ui' show KeyData, KeyEventType;

import 'package:centauri/core/platform/windows_clipboard_history_paste.dart';
import 'package:flutter_test/flutter_test.dart';

/// Perilaku intersepsi Win+V: urutan rusak dari clipboard history dipakai
/// sebagai pemicu paste, sementara Ctrl+V biasa tidak tersentuh.
void main() {
  const junkPhysical = 0x1600000000;
  const controlLeft = 0x200000100;

  KeyData event({
    required KeyEventType type,
    required int physical,
    required int logical,
    bool synthesized = false,
  }) {
    return KeyData(
      timeStamp: Duration.zero,
      type: type,
      physical: physical,
      logical: logical,
      character: null,
      synthesized: synthesized,
    );
  }

  late List<String> passed;
  late int pasteCount;

  bool inner(KeyData data) {
    passed.add('${data.type.name}:${data.physical}');
    return false;
  }

  WindowsClipboardHistoryPaste createFix() =>
      WindowsClipboardHistoryPaste(onPaste: () => pasteCount++);

  setUp(() {
    passed = [];
    pasteCount = 0;
  });

  test('urutan Win+V yang rusak memicu satu paste dan ditelan', () {
    final fix = createFix();

    expect(
      fix.handleKeyData(
        event(
          type: KeyEventType.down,
          physical: junkPhysical,
          logical: controlLeft,
        ),
        inner,
      ),
      isTrue,
    );
    expect(pasteCount, 1);

    // Probe tanpa physical/logical wajib diteruskan ke framework.
    expect(
      fix.handleKeyData(
        event(type: KeyEventType.down, physical: 0, logical: 0),
        inner,
      ),
      isFalse,
    );

    // Sisa urutan rusak ditelan, tidak menambah paste.
    for (final data in [
      event(
        type: KeyEventType.up,
        physical: junkPhysical,
        logical: controlLeft,
      ),
      event(
        type: KeyEventType.down,
        physical: junkPhysical,
        logical: controlLeft,
        synthesized: true,
      ),
      event(
        type: KeyEventType.up,
        physical: junkPhysical,
        logical: controlLeft,
        synthesized: true,
      ),
    ]) {
      expect(fix.handleKeyData(data, inner), isTrue);
    }

    expect(pasteCount, 1);
    expect(passed, ['down:0']);
  });

  test('Ctrl+V biasa diteruskan tanpa memicu paste', () {
    final fix = createFix();

    expect(
      fix.handleKeyData(
        event(type: KeyEventType.down, physical: 0x700e0, logical: controlLeft),
        inner,
      ),
      isFalse,
    );
    expect(
      fix.handleKeyData(
        event(type: KeyEventType.down, physical: 0x70019, logical: 0x76),
        inner,
      ),
      isFalse,
    );

    expect(pasteCount, 0);
    expect(passed, ['down:${0x700e0}', 'down:${0x70019}']);
  });

  test('setelah urutan rusak, tombol biasa kembali normal', () {
    final fix = createFix();

    fix.handleKeyData(
      event(
        type: KeyEventType.down,
        physical: junkPhysical,
        logical: controlLeft,
      ),
      inner,
    );
    fix.handleKeyData(
      event(type: KeyEventType.down, physical: 0x70019, logical: 0x76),
      inner,
    );

    expect(passed, ['down:${0x70019}']);
  });
}
