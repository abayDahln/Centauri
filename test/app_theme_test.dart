import 'package:centauri/app/config/app_palette.dart';
import 'package:centauri/app/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final lightPalette = AppPalette.light();
  final darkPalette = AppPalette.dark();

  test('tema terang memakai kanvas dan teks lama', () {
    final theme = AppTheme.light(lightPalette);
    expect(theme.brightness, Brightness.light);
    expect(theme.scaffoldBackgroundColor, lightPalette.bgBase);
    expect(theme.colorScheme.primary, lightPalette.primary);
    expect(theme.colorScheme.surface, lightPalette.bgSurface);
    expect(theme.colorScheme.onSurface, lightPalette.textPrimary);
    expect(theme.textTheme.bodyMedium?.color, lightPalette.textPrimary);
    expect(theme.textTheme.bodySmall?.color, lightPalette.textSecondary);
  });

  test('tema gelap memakai skema gelap', () {
    final theme = AppTheme.dark(darkPalette);
    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, const Color(0xFF09090B));
    expect(theme.colorScheme.onPrimary, darkPalette.onPrimary);
  });

  test('palet terpasang sebagai ThemeExtension', () {
    final theme = AppTheme.light(lightPalette);
    final extension = theme.extension<AppPalette>();
    expect(extension, isNotNull);
    expect(extension!.primary, lightPalette.primary);
    expect(extension.bgBase, lightPalette.bgBase);
  });

  test('kontrol memakai warna palet', () {
    final theme = AppTheme.light(
      lightPalette.copyWith(primary: const Color(0xFF00AA55)),
    );
    final focused =
        theme.inputDecorationTheme.focusedBorder as OutlineInputBorder;
    expect(focused.borderSide.color, const Color(0xFF00AA55));

    final filled = theme.filledButtonTheme.style!;
    expect(
      filled.backgroundColor!.resolve(<WidgetState>{}),
      const Color(0xFF00AA55),
    );
    expect(filled.foregroundColor!.resolve(<WidgetState>{}), isNotNull);
  });

  test('ikon status bar mengikuti mode', () {
    expect(
      AppTheme.light(lightPalette).appBarTheme.systemOverlayStyle,
      SystemUiOverlayStyle.dark,
    );
    expect(
      AppTheme.dark(darkPalette).appBarTheme.systemOverlayStyle,
      SystemUiOverlayStyle.light,
    );
  });

  test('warna aksen kustom sampai ke secondary', () {
    final palette = AppPalette.light(
      primary: AppAccentPreset.violet.seedColor,
      secondary: AppAccentPreset.teal.seedColor,
    );
    final theme = AppTheme.light(palette);
    expect(theme.colorScheme.primary, AppAccentPreset.violet.seedColor);
    expect(theme.colorScheme.secondary, AppAccentPreset.teal.seedColor);
  });
}
