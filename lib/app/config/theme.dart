import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_palette.dart';

/// Centauri Design System — token visual tunggal untuk seluruh aplikasi.
///
/// Sumber kebenaran: `design/Centauri_Design_System.html`.
///
/// Prinsip:
///  - Kanvas netral dingin, panel solid, garis 1 px. Tanpa bayangan dekoratif.
///  - Satu aksen per layar; warna semantik hanya untuk status.
///  - Bentuk tegas: kontrol 6, kartu 10, bingkai 14, panel mengambang 16.
///  - Tipografi Instrument Sans; JetBrains Mono untuk kode dan label teknis.
///  - Warna diambil dari [AppPalette] lewat `context.palette` supaya mode
///    terang/gelap dan warna kustom pengguna bisa berubah saat aplikasi jalan.
///
/// Dimensi chrome aplikasi. Bukan warna, jadi tidak ikut tema.
class AppMetrics {
  AppMetrics._();

  static const double sideBarWidth = 340;
  static const double titleBarHeight = 40;
  static const double topBarHeight = 52;

  /// Jarak antar panel mengambang.
  static const double panelGutter = 12;

  /// Jarak panel mengambang dari tepi jendela.
  static const double windowInset = 16;
  static const double toolbarHeight = 40;
  static const double statusBarHeight = 0;
}

/// Skala radius: kontrol 6 · kartu 10 · bingkai 14.
class AppRadius {
  AppRadius._();

  /// Kontrol (tombol, ikon, chip, tab).
  static const BorderRadius sm = BorderRadius.all(Radius.circular(6));

  /// Kontrol besar & kartu (input, panel, kartu).
  static const BorderRadius md = BorderRadius.all(Radius.circular(10));

  /// Kartu/panel.
  static const BorderRadius lg = BorderRadius.all(Radius.circular(10));

  /// Bingkai layar, dialog, sheet.
  static const BorderRadius xl = BorderRadius.all(Radius.circular(14));

  /// Panel & toolbar yang mengambang di atas kanvas (sidebar chat, riwayat,
  /// panel kode, bar atas). Sudutnya lebih besar dari kartu biasa karena
  /// panel tidak menempel ke tepi jendela.
  static const BorderRadius panel = BorderRadius.all(Radius.circular(16));

  /// Pil penuh.
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
}

class AppFonts {
  AppFonts._();

  /// Keluarga font untuk aksara yang tidak dimiliki Instrument Sans/Inter:
  /// CJK, Thai, Arab, Ibrani. Mencakup Windows (Microsoft YaHei / Yu Gothic /
  /// Malgun Gothic / Leelawadee UI) dan Android (Noto Sans per aksara).
  ///
  /// Urutan penting: keluarga Latin dulu, aksara khusus menyusul, sehingga
  /// glyph Latin selalu diambil dari Instrument Sans.
  static const List<String> scriptFallback = [
    'Segoe UI',
    'Microsoft YaHei UI',
    'Microsoft YaHei',
    'Noto Sans SC',
    'Noto Sans CJK SC',
    'Yu Gothic UI',
    'Yu Gothic',
    'Noto Sans JP',
    'Noto Sans CJK JP',
    'Malgun Gothic',
    'Noto Sans KR',
    'Noto Sans CJK KR',
    'Leelawadee UI',
    'Noto Sans Thai',
    'Tahoma',
    'Noto Naskh Arabic',
    'Noto Sans Arabic',
  ];

  /// Font UI utama aplikasi: Instrument Sans.
  static const String uiFamily = 'InstrumentSans';
  static const List<String> uiFallback = [
    'Inter',
    'Roboto',
    'sans-serif',
    ...scriptFallback,
  ];

  /// Mono font untuk kode dan label teknis: JetBrains Mono bundled.
  static const String monoFamily = 'JetBrainsMono';
  static const List<String> monoFallback = [
    'Cascadia Mono',
    'Consolas',
    'Roboto Mono',
    'monospace',
    ...scriptFallback,
  ];
}

/// Skala tipografi aplikasi.
///
/// Ukuran, berat, dan spasi tetap; **hanya warna** yang mengikuti [AppPalette].
/// Ambil dari widget dengan `context.text.panelTitle`, dari kode tanpa
/// `BuildContext` dengan `AppText(palette).panelTitle`.
@immutable
class AppText {
  const AppText(this.palette);

  final AppPalette palette;

  TextStyle _ui({
    required double fontSize,
    required double height,
    FontWeight weight = FontWeight.w400,
    double? letterSpacing,
    required Color color,
  }) {
    return TextStyle(
      fontFamily: AppFonts.uiFamily,
      fontFamilyFallback: AppFonts.uiFallback,
      fontSize: fontSize,
      height: height,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  TextStyle _mono({
    required double fontSize,
    required double height,
    FontWeight weight = FontWeight.w400,
    double? letterSpacing,
    required Color color,
  }) {
    return TextStyle(
      fontFamily: AppFonts.monoFamily,
      fontFamilyFallback: AppFonts.monoFallback,
      fontSize: fontSize,
      height: height,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  /// Judul layar: 700 · 28/34.
  TextStyle get screenTitle => _ui(
    fontSize: 28,
    height: 34 / 28,
    weight: FontWeight.w700,
    letterSpacing: -0.4,
    color: palette.textPrimary,
  );

  /// Judul panel: 600 · 15/20.
  TextStyle get panelTitle => _ui(
    fontSize: 15,
    height: 20 / 15,
    weight: FontWeight.w600,
    color: palette.textPrimary,
  );

  /// Isi dan kontrol: 400 · 14/20.
  TextStyle get ui =>
      _ui(fontSize: 14, height: 20 / 14, color: palette.textPrimary);

  /// Teks bantu: 400 · 13/19.
  TextStyle get uiSmall =>
      _ui(fontSize: 13, height: 19 / 13, color: palette.textSecondary);

  /// Label dan bantuan: 500 · 12/16.
  TextStyle get label => _ui(
    fontSize: 12,
    height: 16 / 12,
    weight: FontWeight.w500,
    color: palette.textSecondary,
  );

  TextStyle get caption =>
      _ui(fontSize: 12, height: 16 / 12, color: palette.textSecondary);

  /// Judul section ringkas di dalam panel.
  TextStyle get sectionTitle => _ui(
    fontSize: 12,
    height: 16 / 12,
    weight: FontWeight.w600,
    color: palette.textPrimary,
  );

  /// Label teknis (mono, kapital, spasi lebar).
  TextStyle get sectionLabel => _mono(
    fontSize: 12,
    height: 16 / 12,
    weight: FontWeight.w600,
    letterSpacing: 0.48,
    color: palette.textSecondary,
  );

  TextStyle get mono =>
      _mono(fontSize: 12, height: 1.5, color: palette.textPrimary);

  TextStyle get monoSmall =>
      _mono(fontSize: 11, height: 1.4, color: palette.textSecondary);

  /// Gaya tombol: 600 · 13.
  TextStyle get button => _ui(
    fontSize: 13,
    height: 18 / 13,
    weight: FontWeight.w600,
    color: palette.textPrimary,
  );
}

/// Akses gaya teks dari widget: `context.text.ui`.
extension AppTextContext on BuildContext {
  AppText get text => AppText(palette);
}

class AppTheme {
  /// Bangun `ThemeData` untuk satu palet. Palet dipasang juga sebagai
  /// [ThemeExtension] supaya `context.palette` mengembalikan nilai yang sama
  /// dengan yang sedang dipakai.
  static ThemeData build({
    required AppPalette palette,
    required Brightness brightness,
  }) {
    final text = AppText(palette);
    final isDark = brightness == Brightness.dark;

    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: palette.primary,
            onPrimary: palette.onPrimary,
            secondary: palette.primary,
            onSecondary: palette.onPrimary,
            surface: palette.bgSurface,
            onSurface: palette.textPrimary,
            error: palette.statusError,
            onError: onAccent(palette.statusError),
            outline: palette.borderSubtle,
            outlineVariant: palette.borderStrong,
          )
        : ColorScheme.light(
            primary: palette.primary,
            onPrimary: palette.onPrimary,
            secondary: palette.primary,
            onSecondary: palette.onPrimary,
            surface: palette.bgSurface,
            onSurface: palette.textPrimary,
            error: palette.statusError,
            onError: onAccent(palette.statusError),
            outline: palette.borderSubtle,
            outlineVariant: palette.borderStrong,
          );

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      extensions: [palette],
      scaffoldBackgroundColor: palette.bgBase,
      colorScheme: colorScheme,

      fontFamily: AppFonts.uiFamily,
      fontFamilyFallback: AppFonts.uiFallback,

      hoverColor: palette.hoverBg,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: palette.primary,
        selectionColor: palette.textSelection.withValues(alpha: 0.55),
        selectionHandleColor: palette.textSelectionHandle,
      ),

      textTheme: TextTheme(
        displaySmall: text.screenTitle,
        headlineSmall: text.panelTitle,
        titleLarge: text.panelTitle,
        titleMedium: text.ui,
        titleSmall: text.sectionTitle,
        bodyLarge: text.ui,
        bodyMedium: text.ui,
        bodySmall: text.uiSmall,
        labelLarge: text.button,
        labelMedium: text.label,
        labelSmall: text.caption,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: palette.bgSurface,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: AppMetrics.topBarHeight,
        shape: Border(bottom: BorderSide(color: palette.borderSubtle)),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.uiFamily,
          fontFamilyFallback: AppFonts.uiFallback,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
        ),
      ),

      dividerTheme: DividerThemeData(
        color: palette.borderSubtle,
        thickness: 1,
        space: 1,
      ),

      cardTheme: CardThemeData(
        color: palette.bgSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: palette.borderSubtle),
          borderRadius: AppRadius.md,
        ),
      ),

      iconTheme: IconThemeData(color: palette.textSecondary, size: 18),

      primaryIconTheme: IconThemeData(color: palette.textSecondary, size: 18),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.primary,
        linearTrackColor: palette.bgSunken,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.textPrimary,
        contentTextStyle: TextStyle(
          fontFamily: AppFonts.uiFamily,
          fontFamilyFallback: AppFonts.uiFallback,
          fontSize: 13,
          color: palette.bgSurface,
        ),
        actionTextColor: palette.primary,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
      ),

      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          color: palette.textPrimary,
          borderRadius: AppRadius.sm,
        ),
        textStyle: TextStyle(
          fontFamily: AppFonts.uiFamily,
          fontFamilyFallback: AppFonts.uiFallback,
          fontSize: 12,
          color: palette.bgSurface,
        ),
      ),

      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: const WidgetStatePropertyAll(false),
        thickness: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered) ? 8 : 6,
        ),
        thumbColor: WidgetStatePropertyAll(palette.scrollbarThumb),
        radius: const Radius.circular(999),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          disabledBackgroundColor: palette.bgSunken,
          disabledForegroundColor: palette.textDisabled,
          elevation: 0,
          textStyle: text.button,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          minimumSize: const Size(0, 36),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          disabledBackgroundColor: palette.bgSunken,
          disabledForegroundColor: palette.textDisabled,
          elevation: 0,
          textStyle: text.button,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          minimumSize: const Size(0, 36),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: palette.bgSurface,
          foregroundColor: palette.textPrimary,
          side: BorderSide(color: palette.borderSubtle),
          elevation: 0,
          textStyle: text.button,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          minimumSize: const Size(0, 36),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          textStyle: text.button,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: const Size(0, 32),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
        ),
      ),

      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: palette.inputBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
        hintStyle: TextStyle(
          fontFamily: AppFonts.uiFamily,
          fontFamilyFallback: AppFonts.uiFallback,
          fontSize: 14,
          color: palette.textDisabled,
        ),
        helperStyle: text.label,
        errorStyle: TextStyle(
          fontFamily: AppFonts.uiFamily,
          fontFamilyFallback: AppFonts.uiFallback,
          fontSize: 12,
          color: palette.statusError,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: palette.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: palette.borderSubtle),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: palette.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: palette.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: palette.statusError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: palette.statusError, width: 1.4),
        ),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStatePropertyAll(text.label),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return palette.primarySoft;
            }
            return palette.bgSurface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return palette.primary;
            }
            return palette.textSecondary;
          }),
          side: WidgetStatePropertyAll(BorderSide(color: palette.borderSubtle)),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.sm),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: palette.bgElevated,
        elevation: 0,
        titleTextStyle: text.panelTitle,
        contentTextStyle: text.ui,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.xl,
          side: BorderSide(color: palette.borderSubtle),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          side: BorderSide(color: palette.borderSubtle),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: palette.bgElevated,
        textStyle: text.ui,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.md,
          side: BorderSide(color: palette.borderSubtle),
        ),
      ),
    );
  }

  /// Tema mode terang untuk palet [palette].
  static ThemeData light(AppPalette palette) =>
      build(palette: palette, brightness: Brightness.light);

  /// Tema mode gelap untuk palet [palette].
  static ThemeData dark(AppPalette palette) =>
      build(palette: palette, brightness: Brightness.dark);
}
