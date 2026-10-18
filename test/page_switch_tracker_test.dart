import 'package:centauri/features/canvas_preview/presentation/widgets/page_switch_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PageSwitchTracker', () {
    test('overlay hanya pada pembukaan halaman baru, bukan mutasi halaman sama',
        () {
      final tracker = PageSwitchTracker();

      // Halaman pertama: wajib tunggu render pertama selesai.
      expect(tracker.isSwitching('page_1'), isTrue);
      // HTML halaman yang sama berubah (inline edit): bukan pindah halaman.
      expect(tracker.isSwitching('page_1'), isFalse);
      // Pindah ke page lain: overlay hidup sampai render selesai.
      expect(tracker.isSwitching('page_2'), isTrue);
      expect(tracker.isSwitching('page_2'), isFalse);
      // Kembali lagi ke page semula tetap dianggap pindah.
      expect(tracker.isSwitching('page_1'), isTrue);
    });
  });
}
