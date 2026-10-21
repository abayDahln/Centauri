import 'package:hive/hive.dart';

/// Tutup semua box Hive tanpa bisa menggantung.
///
/// `testWidgets` berjalan di zona fake-async. Tulisan yang dijadwalkan di
/// dalamnya tidak pernah di-flush setelah test selesai, sehingga `Hive.close()`
/// menunggu selamanya dan suite berhenti di `tearDownAll` (timeout 12 menit per
/// file). Batas waktu ini memastikan suite tetap selesai; data test memang
/// dibuang bersama folder sementaranya.
Future<void> closeHiveForTests() async {
  await Hive.close().timeout(
    const Duration(seconds: 2),
    onTimeout: () => <void>[],
  );
}
