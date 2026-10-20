import 'package:flutter/animation.dart';

/// Token gerak aplikasi.
///
/// Semua animasi memakai durasi dan kurva yang sama supaya perpindahan panel
/// terasa konsisten. Animasi dimatikan otomatis saat pengguna mengaktifkan
/// "kurangi animasi" di sistem.
class AppMotion {
  AppMotion._();

  /// Buka/tutup panel samping dan panel mengambang.
  static const Duration panel = Duration(milliseconds: 220);

  /// Dialog muncul/hilang.
  static const Duration dialog = Duration(milliseconds: 160);

  /// Kurva untuk gerakan masuk/keluar panel.
  static const Curve panelCurve = Curves.easeOutCubic;

  /// Kurva untuk fade dialog.
  static const Curve dialogCurve = Curves.easeOut;
}
