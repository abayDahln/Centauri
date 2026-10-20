import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_storage_service.dart';
import 'app_palette.dart';

/// Pilihan tampilan: mode (terang/gelap/ikut sistem) dan dua warna aksen.
///
/// Dibaca dari Hive saat aplikasi mulai (storage sudah siap sebelum `runApp`)
/// dan ditulis kembali setiap kali pengguna mengganti pilihan, jadi tidak perlu
/// restart.
///
/// Ini **hanya tampilan aplikasi**. Warna dan mode tidak pernah dikirim ke
/// model AI dan tidak memengaruhi HTML prototype yang dihasilkan.
class AppThemeSelection {
  const AppThemeSelection({
    this.mode = AppThemeMode.light,
    this.primary = AppAccentPreset.blue,
    this.secondary = AppAccentPreset.blue,
  });

  /// Default tampilan: identik dengan sebelum fitur tema ada.
  static const AppThemeSelection defaults = AppThemeSelection();

  final AppThemeMode mode;
  final AppAccentPreset primary;
  final AppAccentPreset secondary;

  /// Palet yang dipakai saat aplikasi tampil terang.
  AppPalette get lightPalette => AppPalette.light(
    primary: primary.seedColor,
    secondary: secondary.seedColor,
  );

  /// Palet yang dipakai saat aplikasi tampil gelap; aksen diterangkan otomatis
  /// oleh [AppPalette.dark] supaya tetap terbaca.
  AppPalette get darkPalette => AppPalette.dark(
    primary: primary.seedColor,
    secondary: secondary.seedColor,
  );

  /// Nilai untuk `MaterialApp.themeMode`.
  ThemeMode get flutterMode => switch (mode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };

  AppThemeSelection copyWith({
    AppThemeMode? mode,
    AppAccentPreset? primary,
    AppAccentPreset? secondary,
  }) {
    return AppThemeSelection(
      mode: mode ?? this.mode,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
    );
  }
}

/// Mode tampilan aplikasi.
enum AppThemeMode {
  system('system'),
  light('light'),
  dark('dark');

  const AppThemeMode(this.id);

  /// Nilai yang disimpan di Hive.
  final String id;

  /// Nilai tak dikenal (data lama/rusak) jatuh ke terang.
  static AppThemeMode byId(String? id) =>
      values.firstWhere((mode) => mode.id == id, orElse: () => light);
}

/// Tampilan aplikasi yang sedang aktif.
final appThemeProvider = NotifierProvider<AppThemeNotifier, AppThemeSelection>(
  AppThemeNotifier.new,
);

class AppThemeNotifier extends Notifier<AppThemeSelection> {
  @override
  AppThemeSelection build() {
    final storage = LocalStorageService();
    return AppThemeSelection(
      mode: AppThemeMode.byId(storage.appThemeMode),
      primary: AppAccentPreset.byId(storage.appAccentPrimary),
      secondary: AppAccentPreset.byId(storage.appAccentSecondary),
    );
  }

  /// Ganti mode. Tampilan berubah lebih dulu; penulisan ke disk menyusul supaya
  /// pergantian terasa instan.
  Future<void> selectMode(AppThemeMode mode) async {
    if (mode == state.mode) return;
    state = state.copyWith(mode: mode);
    await LocalStorageService().setAppThemeMode(mode.id);
  }

  /// Ganti aksen utama.
  Future<void> selectPrimary(AppAccentPreset preset) async {
    if (preset == state.primary) return;
    state = state.copyWith(primary: preset);
    await LocalStorageService().setAppAccentPrimary(preset.id);
  }

  /// Ganti aksen AI/generatif.
  Future<void> selectSecondary(AppAccentPreset preset) async {
    if (preset == state.secondary) return;
    state = state.copyWith(secondary: preset);
    await LocalStorageService().setAppAccentSecondary(preset.id);
  }

  /// Kembalikan seluruh pilihan tampilan ke default (terang + biru).
  Future<void> reset() async {
    state = AppThemeSelection.defaults;
    final storage = LocalStorageService();
    await storage.setAppThemeMode(AppThemeMode.light.id);
    await storage.setAppAccentPrimary(AppAccentPreset.blue.id);
    await storage.setAppAccentSecondary(AppAccentPreset.blue.id);
  }
}
