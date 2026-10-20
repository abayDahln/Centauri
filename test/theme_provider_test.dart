import 'package:centauri/app/config/app_palette.dart';
import 'package:centauri/app/config/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('default: terang + biru, seperti tampilan sebelum fitur tema', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final selection = container.read(appThemeProvider);
    expect(selection.mode, AppThemeMode.light);
    expect(selection.primary, AppAccentPreset.blue);
    expect(selection.flutterMode, ThemeMode.light);
  });

  test('mode tak dikenal jatuh ke terang', () {
    expect(AppThemeMode.byId(null), AppThemeMode.light);
    expect(AppThemeMode.byId('rusak'), AppThemeMode.light);
    expect(AppThemeMode.byId('dark'), AppThemeMode.dark);
    expect(AppThemeMode.byId('system'), AppThemeMode.system);
  });

  test('ganti mode dan warna langsung terlihat di state', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(appThemeProvider.notifier);

    await notifier.selectMode(AppThemeMode.dark);
    expect(container.read(appThemeProvider).mode, AppThemeMode.dark);
    expect(container.read(appThemeProvider).flutterMode, ThemeMode.dark);

    await notifier.selectPrimary(AppAccentPreset.violet);
    expect(container.read(appThemeProvider).primary, AppAccentPreset.violet);

    await notifier.selectMode(AppThemeMode.system);
    expect(container.read(appThemeProvider).flutterMode, ThemeMode.system);
  });

  test('reset mengembalikan semua pilihan ke default', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(appThemeProvider.notifier);

    await notifier.selectMode(AppThemeMode.dark);
    await notifier.selectPrimary(AppAccentPreset.rose);

    await notifier.reset();

    final selection = container.read(appThemeProvider);
    expect(selection.mode, AppThemeMode.light);
    expect(selection.primary, AppAccentPreset.blue);
  });

  test('palet gelap menerangkan aksen yang dipilih', () {
    const selection = AppThemeSelection(
      mode: AppThemeMode.dark,
      primary: AppAccentPreset.violet,
    );
    final dark = selection.darkPalette;
    expect(
      dark.primary.computeLuminance(),
      greaterThan(AppAccentPreset.violet.seedColor.computeLuminance()),
    );
    expect(selection.lightPalette.primary, AppAccentPreset.violet.seedColor);
  });

  test('palet mengikuti warna yang dipilih', () {
    const selection = AppThemeSelection(primary: AppAccentPreset.teal);
    expect(selection.lightPalette.primary, AppAccentPreset.teal.seedColor);
    expect(selection.lightPalette.link, AppAccentPreset.teal.seedColor);
  });
}
