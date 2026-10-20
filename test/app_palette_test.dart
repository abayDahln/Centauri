import 'package:centauri/app/config/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppPalette.light', () {
    final palette = AppPalette.light();

    test('mempertahankan warna tampilan lama', () {
      expect(palette.bgBase, const Color(0xFFF6F7F8));
      expect(palette.bgSurface, const Color(0xFFFFFFFF));
      expect(palette.bgSunken, const Color(0xFFF6F7F8));
      expect(palette.bgElevated, const Color(0xFFFFFFFF));
      expect(palette.hoverBg, const Color(0xFFF6F7F8));
      expect(palette.textSelection, const Color(0xFFFFD54F));
      expect(palette.inputBg, const Color(0xFFFFFFFF));
      expect(palette.borderSubtle, const Color(0xFFE3E5E8));
      expect(palette.borderStrong, const Color(0xFFD5D8DC));
      expect(palette.textPrimary, const Color(0xFF16181D));
      expect(palette.textSecondary, const Color(0xFF5B616B));
      expect(palette.textDisabled, const Color(0xFF8B9199));
      expect(palette.scrollbarThumb, const Color(0x33737380));
      expect(palette.statusSuccess, const Color(0xFF1F7A4D));
      expect(palette.statusError, const Color(0xFFB42318));
      expect(palette.statusWarning, const Color(0xFFB25E09));
      expect(palette.primary, kDefaultAccent);
      expect(palette.secondary, kDefaultAccent);
      expect(palette.link, palette.primary);
      expect(palette.textSelectionHandle, palette.primary);
    });

    test('secondary default sama dengan primary (tampilan lama)', () {
      expect(palette.secondary, palette.primary);
      expect(palette.secondarySoft, palette.primarySoft);
    });

    test('selection dan soft accent bukan latar polos', () {
      expect(palette.selectionBg, isNot(palette.bgSurface));
      expect(palette.primarySoft, isNot(palette.bgSurface));
      expect(palette.primarySoft.a, greaterThan(0.9));
    });

    test('shadow sama dengan token lama', () {
      expect(palette.shadowSoft, hasLength(1));
      expect(palette.shadowSoft.first.color, const Color(0x0F16181D));
      expect(palette.shadowSoft.first.blurRadius, 2);
      expect(palette.shadowRaised, hasLength(2));
      expect(palette.shadowRaised.first.color, const Color(0x1416181D));
      expect(palette.shadowRaised.last.blurRadius, 24);
    });
  });

  group('AppPalette.dark', () {
    final palette = AppPalette.dark();

    test('memakai neutral kanvas gelap', () {
      expect(palette.bgBase, const Color(0xFF09090B));
      expect(palette.bgSurface, const Color(0xFF18181B));
      expect(palette.bgElevated, const Color(0xFF1F1F23));
      expect(palette.inputBg, const Color(0xFF141417));
      expect(palette.borderSubtle, const Color(0xFF27272A));
      expect(palette.borderStrong, const Color(0xFF3F3F46));
      expect(palette.textPrimary, const Color(0xFFFAFAFA));
      expect(palette.textSecondary, const Color(0xFFA1A1AA));
      expect(palette.scrollbarThumb, const Color(0x33A1A1AA));
      expect(palette.statusSuccess, const Color(0xFF10B981));
    });

    test('aksen diterangkan agar terbaca di kanvas gelap', () {
      final dark = AppPalette.dark(
        primary: AppAccentPreset.violet.seedColor,
        secondary: AppAccentPreset.teal.seedColor,
      );
      expect(
        dark.primary.computeLuminance(),
        greaterThan(AppAccentPreset.violet.seedColor.computeLuminance()),
      );
      expect(dark.secondary, isNot(AppAccentPreset.teal.seedColor));
    });

    test('warna teks sekunder tetap kontras', () {
      expect(
        contrastRatio(palette.textPrimary, palette.bgSurface),
        greaterThanOrEqualTo(7),
      );
      expect(
        contrastRatio(palette.textSecondary, palette.bgSurface),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  test('semua preset lulus kontras di kedua mode', () {
    for (final preset in AppAccentPreset.values) {
      final light = AppPalette.light(primary: preset.seedColor);
      final dark = AppPalette.dark(primary: preset.seedColor);

      expect(
        contrastRatio(light.onPrimary, light.primary),
        greaterThanOrEqualTo(4.5),
        reason: 'light ${preset.id}',
      );
      expect(
        contrastRatio(dark.onPrimary, dark.primary),
        greaterThanOrEqualTo(4.5),
        reason: 'dark ${preset.id}',
      );
      expect(
        contrastRatio(light.textPrimary, light.bgSurface),
        greaterThanOrEqualTo(7),
        reason: 'light text ${preset.id}',
      );
      expect(
        contrastRatio(dark.textPrimary, dark.bgSurface),
        greaterThanOrEqualTo(7),
        reason: 'dark text ${preset.id}',
      );
    }
  });

  test('secondary juga lulus kontras saat berbeda dari primary', () {
    for (final preset in AppAccentPreset.values) {
      for (final palette in [
        AppPalette.light(secondary: preset.seedColor),
        AppPalette.dark(secondary: preset.seedColor),
      ]) {
        expect(
          contrastRatio(palette.onSecondary, palette.secondary),
          greaterThanOrEqualTo(4.5),
          reason: preset.id,
        );
      }
    }
  });

  test('preset tak dikenal jatuh ke biru', () {
    expect(AppAccentPreset.byId(null), AppAccentPreset.blue);
    expect(AppAccentPreset.byId('tidak-ada'), AppAccentPreset.blue);
    expect(AppAccentPreset.byId('violet'), AppAccentPreset.violet);
  });

  test('copyWith hanya mengganti warna yang diminta', () {
    final palette = AppPalette.light();
    final changed = palette.copyWith(primary: const Color(0xFF00FF00));
    expect(changed.primary, const Color(0xFF00FF00));
    expect(changed.bgSurface, palette.bgSurface);
    expect(changed.shadowSoft, palette.shadowSoft);
  });

  test('lerp menghasilkan warna di antara dua palet', () {
    final light = AppPalette.light();
    final dark = AppPalette.dark();
    final middle = light.lerp(dark, 0.5);
    expect(middle.bgBase, isNot(light.bgBase));
    expect(middle.bgBase, isNot(dark.bgBase));
    expect(middle.shadowSoft, hasLength(1));
  });
}
