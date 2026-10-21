import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_storage_service.dart';
import 'app_language.dart';

/// Bahasa antarmuka yang sedang aktif.
///
/// Dibaca dari Hive saat aplikasi mulai (storage sudah siap sebelum `runApp`)
/// dan ditulis kembali setiap kali pengguna memilih bahasa lain, jadi pilihan
/// bertahan tanpa perlu restart.
///
/// Ini hanya bahasa **teks UI**. Percakapan dengan AI tidak terpengaruh:
/// Alpha menjawab dalam bahasa Inggris secara default, dan meniru bahasa user
/// hanya kalau user jelas menulis dalam bahasa lain.
final appLanguageProvider = NotifierProvider<AppLanguageNotifier, AppLanguage>(
  AppLanguageNotifier.new,
);

class AppLanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() => AppLanguage.byCode(LocalStorageService().appLocale);

  /// Ganti bahasa UI. Tampilan berubah lebih dulu; penulisan ke disk menyusul
  /// supaya pergantian bahasa terasa instan.
  Future<void> select(AppLanguage language) async {
    if (language.code == state.code) return;
    state = language;
    await LocalStorageService().setAppLocale(language.code);
  }
}
