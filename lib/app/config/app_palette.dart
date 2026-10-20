import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Aksen default aplikasi (biru Centauri). Dipakai sebagai nilai awal pilihan
/// pengguna dan sebagai warna pengganti bila id preset tidak dikenal.
const Color kDefaultAccent = Color(0xFF2150E8);

/// Warna leaf/label di atas aksen.
const Color _inkOnLightAccent = Color(0xFF16181D);

/// Warna aksen yang bisa dipilih pengguna.
///
/// [seedColor] adalah warna untuk mode terang; mode gelap memakai versi yang
/// diterangkan oleh [liftForDark] supaya tetap terbaca di kanvas gelap.
enum AppAccentPreset {
  blue('blue', kDefaultAccent),
  indigo('indigo', Color(0xFF4F46E5)),
  violet('violet', Color(0xFF7C3AED)),
  teal('teal', Color(0xFF0F766E)),
  green('green', Color(0xFF15803D)),
  amber('amber', Color(0xFFB45309)),
  rose('rose', Color(0xFFBE123C)),
  slate('slate', Color(0xFF475569));

  const AppAccentPreset(this.id, this.seedColor);

  /// Nilai yang disimpan di Hive.
  final String id;

  /// Warna dasar untuk mode terang (sudah lulus uji kontras).
  final Color seedColor;

  /// Id yang tidak dikenal (data lama/rusak) jatuh ke biru.
  static AppAccentPreset byId(String? id) =>
      values.firstWhere((preset) => preset.id == id, orElse: () => blue);
}

/// Warna teks/ikon yang dipakai **di atas** [base].
///
/// Dipilih dari rasio kontras WCAG tertinggi antara tinta gelap dan putih,
/// sehingga tombol tetap terbaca untuk aksen terang maupun gelap.
Color onAccent(Color base) {
  final withWhite = contrastRatio(Colors.white, base);
  final withInk = contrastRatio(_inkOnLightAccent, base);
  return withInk >= withWhite ? _inkOnLightAccent : Colors.white;
}

/// Aksen lembut untuk latar chip/badge/tab aktif: [base] ditumpuk di atas
/// [surface] dengan alpha, jadi hasilnya ikut mode terang/gelap.
Color softAccent(Color base, Color surface, {required bool dark}) =>
    Color.alphaBlend(base.withValues(alpha: dark ? 0.22 : 0.10), surface);

/// Terangkan aksen untuk mode gelap.
///
/// Preset dipilih di mode terang; di kanvas gelap warna yang sama jadi terlalu
/// pekat, jadi lightness dinaikkan (dan saturation dibatasi agar tidak menyala).
/// 0.70 dipilih agar setiap preset lulus kontras 4.5:1 dengan teks di atasnya.
Color liftForDark(Color base) {
  final hsl = HSLColor.fromColor(base);
  return hsl
      .withLightness(math.max(hsl.lightness, 0.70))
      .withSaturation(math.min(hsl.saturation, 0.80))
      .toColor();
}

/// Rasio kontras WCAG 2.1 antara dua warna (1.0–21.0).
///
/// Dipakai test agar setiap preset terbaca di kedua mode.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

/// Palet warna aplikasi untuk satu mode tampilan.
///
/// Ini **satu-satunya** sumber warna UI. Widget mengambil warnanya lewat
/// `context.palette`, bukan dari konstanta statis, supaya mode terang/gelap dan
/// warna kustom pengguna bisa berubah saat aplikasi berjalan.
///
/// Warna di sini tidak pernah masuk ke prototype HTML — canvas adalah WebView
/// mandiri dengan CSS-nya sendiri.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bgBase,
    required this.bgSurface,
    required this.bgSunken,
    required this.bgElevated,
    required this.hoverBg,
    required this.selectionBg,
    required this.textSelection,
    required this.textSelectionHandle,
    required this.inputBg,
    required this.borderSubtle,
    required this.borderStrong,
    required this.primary,
    required this.primarySoft,
    required this.onPrimary,
    required this.link,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.scrollbarThumb,
    required this.statusSuccess,
    required this.statusError,
    required this.statusWarning,
    required this.shadowSoft,
    required this.shadowRaised,
  });

  /// Palet default mode terang. Nilainya identik dengan tampilan sebelum fitur
  /// tema ada, jadi pengguna lama tidak melihat perubahan apa pun.
  factory AppPalette.light({Color primary = kDefaultAccent}) {
    const surface = Color(0xFFFFFFFF);
    return AppPalette(
      bgBase: const Color(0xFFF6F7F8),
      bgSurface: surface,
      bgSunken: const Color(0xFFF6F7F8),
      bgElevated: surface,
      hoverBg: const Color(0xFFF6F7F8),
      selectionBg: softAccent(primary, surface, dark: false),
      textSelection: const Color(0xFFFFD54F),
      textSelectionHandle: primary,
      inputBg: surface,
      borderSubtle: const Color(0xFFE3E5E8),
      borderStrong: const Color(0xFFD5D8DC),
      primary: primary,
      primarySoft: softAccent(primary, surface, dark: false),
      onPrimary: onAccent(primary),
      link: primary,
      textPrimary: const Color(0xFF16181D),
      textSecondary: const Color(0xFF5B616B),
      textDisabled: const Color(0xFF8B9199),
      scrollbarThumb: const Color(0x33737380),
      statusSuccess: const Color(0xFF1F7A4D),
      statusError: const Color(0xFFB42318),
      statusWarning: const Color(0xFFB25E09),
      shadowSoft: const [
        BoxShadow(
          color: Color(0x0F16181D),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
      ],
      shadowRaised: const [
        BoxShadow(
          color: Color(0x1416181D),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
        BoxShadow(
          color: Color(0x1A16181D),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
    );
  }

  /// Palet default mode gelap (token di `docs/design_system.md`).
  ///
  /// Aksen yang dipilih pengguna diterangkan lebih dulu lewat [liftForDark].
  factory AppPalette.dark({Color primary = kDefaultAccent}) {
    final liftedPrimary = liftForDark(primary);
    const surface = Color(0xFF18181B);
    return AppPalette(
      bgBase: const Color(0xFF09090B),
      bgSurface: surface,
      bgSunken: const Color(0xFF0B0B0D),
      bgElevated: const Color(0xFF1F1F23),
      hoverBg: const Color(0xFF222227),
      selectionBg: softAccent(liftedPrimary, surface, dark: true),
      textSelection: const Color(0x59FFD54F),
      textSelectionHandle: liftedPrimary,
      inputBg: const Color(0xFF141417),
      borderSubtle: const Color(0xFF27272A),
      borderStrong: const Color(0xFF3F3F46),
      primary: liftedPrimary,
      primarySoft: softAccent(liftedPrimary, surface, dark: true),
      onPrimary: onAccent(liftedPrimary),
      link: liftedPrimary,
      textPrimary: const Color(0xFFFAFAFA),
      textSecondary: const Color(0xFFA1A1AA),
      textDisabled: const Color(0xFF6B6B74),
      scrollbarThumb: const Color(0x33A1A1AA),
      statusSuccess: const Color(0xFF10B981),
      statusError: const Color(0xFFEF4444),
      statusWarning: const Color(0xFFF59E0B),
      shadowSoft: const [
        BoxShadow(
          color: Color(0x59000000),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
      ],
      shadowRaised: const [
        BoxShadow(
          color: Color(0x73000000),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
        BoxShadow(
          color: Color(0x8C000000),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
    );
  }

  /// Dipakai test dan widget yang dipump tanpa `ThemeData` berisi palet.
  static final AppPalette lightDefault = AppPalette.light();

  /// Kanvas aplikasi.
  final Color bgBase;

  /// Permukaan panel/kartu.
  final Color bgSurface;

  /// Permukaan terkubur (track, area sekunder).
  final Color bgSunken;

  /// Permukaan mengambang (dialog, popover, sheet).
  final Color bgElevated;

  /// Hover pada baris/daftar.
  final Color hoverBg;

  /// Item terpilih (aksen lembut).
  final Color selectionBg;

  /// Highlight seleksi teks. Amber agar tidak menyatu dengan aksen biru.
  final Color textSelection;

  /// Warna handle & kursor seleksi teks.
  final Color textSelectionHandle;

  /// Latar input.
  final Color inputBg;

  /// Garis pemisah dan border kontrol.
  final Color borderSubtle;

  /// Garis lebih tegas untuk kontrol yang butuh penekanan.
  final Color borderStrong;

  /// Aksen utama: aksi, tab aktif, fokus, tautan.
  final Color primary;

  /// Aksen utama versi lembut (chip/badge/tab aktif).
  final Color primarySoft;

  /// Teks/ikon di atas [primary].
  final Color onPrimary;

  /// Tautan di dalam teks (markdown).
  final Color link;

  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;

  /// Thumb scrollbar (tipis, hanya terlihat saat digulir).
  final Color scrollbarThumb;

  final Color statusSuccess;
  final Color statusError;
  final Color statusWarning;

  /// Shadow tipis untuk elemen mengambang (prompt bar, popover).
  final List<BoxShadow> shadowSoft;

  /// Shadow untuk dialog/sheet.
  final List<BoxShadow> shadowRaised;

  @override
  AppPalette copyWith({
    Color? bgBase,
    Color? bgSurface,
    Color? bgSunken,
    Color? bgElevated,
    Color? hoverBg,
    Color? selectionBg,
    Color? textSelection,
    Color? textSelectionHandle,
    Color? inputBg,
    Color? borderSubtle,
    Color? borderStrong,
    Color? primary,
    Color? primarySoft,
    Color? onPrimary,
    Color? link,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? scrollbarThumb,
    Color? statusSuccess,
    Color? statusError,
    Color? statusWarning,
    List<BoxShadow>? shadowSoft,
    List<BoxShadow>? shadowRaised,
  }) {
    return AppPalette(
      bgBase: bgBase ?? this.bgBase,
      bgSurface: bgSurface ?? this.bgSurface,
      bgSunken: bgSunken ?? this.bgSunken,
      bgElevated: bgElevated ?? this.bgElevated,
      hoverBg: hoverBg ?? this.hoverBg,
      selectionBg: selectionBg ?? this.selectionBg,
      textSelection: textSelection ?? this.textSelection,
      textSelectionHandle: textSelectionHandle ?? this.textSelectionHandle,
      inputBg: inputBg ?? this.inputBg,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
      onPrimary: onPrimary ?? this.onPrimary,
      link: link ?? this.link,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      scrollbarThumb: scrollbarThumb ?? this.scrollbarThumb,
      statusSuccess: statusSuccess ?? this.statusSuccess,
      statusError: statusError ?? this.statusError,
      statusWarning: statusWarning ?? this.statusWarning,
      shadowSoft: shadowSoft ?? this.shadowSoft,
      shadowRaised: shadowRaised ?? this.shadowRaised,
    );
  }

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      bgBase: Color.lerp(bgBase, other.bgBase, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      bgSunken: Color.lerp(bgSunken, other.bgSunken, t)!,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t)!,
      hoverBg: Color.lerp(hoverBg, other.hoverBg, t)!,
      selectionBg: Color.lerp(selectionBg, other.selectionBg, t)!,
      textSelection: Color.lerp(textSelection, other.textSelection, t)!,
      textSelectionHandle: Color.lerp(
        textSelectionHandle,
        other.textSelectionHandle,
        t,
      )!,
      inputBg: Color.lerp(inputBg, other.inputBg, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      link: Color.lerp(link, other.link, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      scrollbarThumb: Color.lerp(scrollbarThumb, other.scrollbarThumb, t)!,
      statusSuccess: Color.lerp(statusSuccess, other.statusSuccess, t)!,
      statusError: Color.lerp(statusError, other.statusError, t)!,
      statusWarning: Color.lerp(statusWarning, other.statusWarning, t)!,
      shadowSoft: _lerpShadows(shadowSoft, other.shadowSoft, t),
      shadowRaised: _lerpShadows(shadowRaised, other.shadowRaised, t),
    );
  }

  static List<BoxShadow> _lerpShadows(
    List<BoxShadow> a,
    List<BoxShadow> b,
    double t,
  ) {
    final length = math.min(a.length, b.length);
    return List<BoxShadow>.generate(length, (i) {
      return BoxShadow.lerp(a[i], b[i], t) ?? a[i];
    });
  }
}

/// Akses palet dari widget: `context.palette.primary`.
extension AppPaletteContext on BuildContext {
  /// Bila `ThemeData` belum memasang [AppPalette] (mis. widget dipump tanpa
  /// helper test), palet terang dipakai sebagai fallback.
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.lightDefault;
}
