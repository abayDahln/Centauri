import 'package:flutter/material.dart';

/// Centauri Design System — token visual tunggal untuk seluruh aplikasi.
///
/// Sumber kebenaran: `design/Centauri_Design_System.html`.
///
/// Prinsip:
///  - Kanvas netral dingin, panel putih, garis 1 px. Tanpa bayangan dekoratif.
///  - Satu aksen biru per layar; warna semantik hanya untuk status.
///  - Bentuk tegas: kontrol 6, kartu/panel 10, bingkai 14.
///  - Tipografi Instrument Sans; JetBrains Mono untuk kode dan label teknis.
class AppColors {
  AppColors._();

  /// Kanvas aplikasi.
  static const Color bgBase = Color(0xFFF6F7F8);

  /// Permukaan panel/kartu (putih).
  static const Color bgSurface = Color(0xFFFFFFFF);

  /// Permukaan terkubur (track, area sekunder).
  static const Color bgSunken = Color(0xFFF6F7F8);

  /// Permukaan mengambang (dialog, popover, sheet).
  static const Color bgElevated = Color(0xFFFFFFFF);

  /// Hover pada baris/daftar.
  static const Color hoverBg = Color(0xFFF6F7F8);

  /// Item terpilih (aksen lembut).
  static const Color selectionBg = Color(0xFFE9EEFE);

  /// Highlight seleksi teks. Amber agar tidak menyatu dengan aksen biru.
  static const Color textSelection = Color(0xFFFFD54F);

  /// Warna handle & kursor seleksi teks.
  static const Color textSelectionHandle = Color(0xFF2150E8);

  /// Latar input.
  static const Color inputBg = Color(0xFFFFFFFF);

  /// Garis pemisah dan border kontrol.
  static const Color borderSubtle = Color(0xFFE3E5E8);

  /// Garis lebih tegas untuk kontrol yang butuh penekanan.
  static const Color borderStrong = Color(0xFFD5D8DC);

  /// Aksen utama.
  static const Color accentPrimary = Color(0xFF2150E8);

  /// Aksen generatif AI (sama dengan aksen utama — satu aksen per layar).
  static const Color accentAi = Color(0xFF2150E8);

  /// Varian aksen lembut untuk latar chip/badge/tab aktif.
  static const Color accentSoft = Color(0xFFE9EEFE);

  static const Color link = Color(0xFF2150E8);

  static const Color textPrimary = Color(0xFF16181D);
  static const Color textSecondary = Color(0xFF5B616B);
  static const Color textDisabled = Color(0xFF8B9199);

  static const Color statusSuccess = Color(0xFF1F7A4D);
  static const Color statusError = Color(0xFFB42318);
  static const Color statusWarning = Color(0xFFB25E09);

  // Dimensi chrome.
  static const double sideBarWidth = 340;
  static const double titleBarHeight = 40;
  static const double topBarHeight = 52;
  static const double toolbarHeight = 40;
  static const double statusBarHeight = 0;

  /// Shadow tipis untuk elemen mengambang (prompt bar, popover).
  static const List<BoxShadow> shadowSoft = [
    BoxShadow(color: Color(0x0F16181D), blurRadius: 2, offset: Offset(0, 1)),
  ];

  /// Shadow untuk dialog/sheet.
  static const List<BoxShadow> shadowRaised = [
    BoxShadow(color: Color(0x1416181D), blurRadius: 6, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x1A16181D), blurRadius: 24, offset: Offset(0, 8)),
  ];
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

  /// Pil penuh.
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
}

class AppFonts {
  AppFonts._();

  /// Font UI utama aplikasi: Instrument Sans.
  static const String uiFamily = 'InstrumentSans';
  static const List<String> uiFallback = ['Inter', 'Roboto', 'sans-serif'];

  /// Mono font untuk kode dan label teknis: JetBrains Mono bundled.
  static const String monoFamily = 'JetBrainsMono';
  static const List<String> monoFallback = [
    'Cascadia Mono',
    'Consolas',
    'Roboto Mono',
    'monospace',
  ];
}

class AppText {
  AppText._();

  /// Judul layar: 700 · 28/34.
  static const TextStyle screenTitle = TextStyle(
    fontFamily: AppFonts.uiFamily,
    fontFamilyFallback: AppFonts.uiFallback,
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
  );

  /// Judul panel: 600 · 15/20.
  static const TextStyle panelTitle = TextStyle(
    fontFamily: AppFonts.uiFamily,
    fontFamilyFallback: AppFonts.uiFallback,
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Isi dan kontrol: 400 · 14/20.
  static const TextStyle ui = TextStyle(
    fontFamily: AppFonts.uiFamily,
    fontFamilyFallback: AppFonts.uiFallback,
    fontSize: 14,
    height: 20 / 14,
    color: AppColors.textPrimary,
  );

  /// Teks bantu: 400 · 13/19.
  static const TextStyle uiSmall = TextStyle(
    fontFamily: AppFonts.uiFamily,
    fontFamilyFallback: AppFonts.uiFallback,
    fontSize: 13,
    height: 19 / 13,
    color: AppColors.textSecondary,
  );

  /// Label dan bantuan: 500 · 12/16.
  static const TextStyle label = TextStyle(
    fontFamily: AppFonts.uiFamily,
    fontFamilyFallback: AppFonts.uiFallback,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: AppFonts.uiFamily,
    fontFamilyFallback: AppFonts.uiFallback,
    fontSize: 12,
    height: 16 / 12,
    color: AppColors.textSecondary,
  );

  /// Judul section ringkas di dalam panel.
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: AppFonts.uiFamily,
    fontFamilyFallback: AppFonts.uiFallback,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Label teknis (mono, kapital, spasi lebar).
  static const TextStyle sectionLabel = TextStyle(
    fontFamily: AppFonts.monoFamily,
    fontFamilyFallback: AppFonts.monoFallback,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.48,
    color: AppColors.textSecondary,
  );

  static const TextStyle mono = TextStyle(
    fontFamily: AppFonts.monoFamily,
    fontFamilyFallback: AppFonts.monoFallback,
    fontSize: 12,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle monoSmall = TextStyle(
    fontFamily: AppFonts.monoFamily,
    fontFamilyFallback: AppFonts.monoFallback,
    fontSize: 11,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  /// Gaya tombol: 600 · 13.
  static const TextStyle button = TextStyle(
    fontFamily: AppFonts.uiFamily,
    fontFamilyFallback: AppFonts.uiFallback,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w600,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bgBase,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accentPrimary,
        surface: AppColors.bgSurface,
        onSurface: AppColors.textPrimary,
        outline: AppColors.borderSubtle,
      ),

      fontFamily: AppFonts.uiFamily,
      fontFamilyFallback: AppFonts.uiFallback,

      hoverColor: AppColors.hoverBg,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.accentPrimary,
        selectionColor: AppColors.textSelection.withValues(alpha: 0.55),
        selectionHandleColor: AppColors.accentPrimary,
      ),

      textTheme: const TextTheme(
        displaySmall: AppText.screenTitle,
        headlineSmall: AppText.panelTitle,
        titleLarge: AppText.panelTitle,
        titleMedium: AppText.ui,
        titleSmall: AppText.sectionTitle,
        bodyLarge: AppText.ui,
        bodyMedium: AppText.ui,
        bodySmall: AppText.uiSmall,
        labelLarge: AppText.button,
        labelMedium: AppText.label,
        labelSmall: AppText.caption,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgSurface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: AppColors.topBarHeight,
        shape: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.uiFamily,
          fontFamilyFallback: AppFonts.uiFallback,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),

      cardTheme: CardThemeData(
        color: AppColors.bgSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.borderSubtle),
          borderRadius: AppRadius.md,
        ),
      ),

      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 18),

      primaryIconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 18,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accentPrimary,
        linearTrackColor: AppColors.bgSunken,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(
          fontFamily: AppFonts.uiFamily,
          fontFamilyFallback: AppFonts.uiFallback,
          fontSize: 13,
          color: Colors.white,
        ),
        actionTextColor: const Color(0xFF9DB4FF),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
      ),

      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: AppRadius.sm,
        ),
        textStyle: const TextStyle(
          fontFamily: AppFonts.uiFamily,
          fontFamilyFallback: AppFonts.uiFallback,
          fontSize: 12,
          color: Colors.white,
        ),
      ),

      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: WidgetStateProperty.all(false),
        thickness: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered) ? 8 : 6,
        ),
        thumbColor: WidgetStateProperty.all(const Color(0x33737380)),
        radius: const Radius.circular(999),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accentPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.bgSunken,
          disabledForegroundColor: AppColors.textDisabled,
          elevation: 0,
          textStyle: AppText.button,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          minimumSize: const Size(0, 36),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.bgSunken,
          disabledForegroundColor: AppColors.textDisabled,
          elevation: 0,
          textStyle: AppText.button,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          minimumSize: const Size(0, 36),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.bgSurface,
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.borderSubtle),
          elevation: 0,
          textStyle: AppText.button,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          minimumSize: const Size(0, 36),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentPrimary,
          textStyle: AppText.button,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: const Size(0, 32),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
        ),
      ),

      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.inputBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
        hintStyle: const TextStyle(
          fontFamily: AppFonts.uiFamily,
          fontFamilyFallback: AppFonts.uiFallback,
          fontSize: 14,
          color: AppColors.textDisabled,
        ),
        helperStyle: AppText.label,
        errorStyle: const TextStyle(
          fontFamily: AppFonts.uiFamily,
          fontFamilyFallback: AppFonts.uiFallback,
          fontSize: 12,
          color: AppColors.statusError,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: AppColors.borderSubtle),
        ),
        disabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: AppColors.accentPrimary, width: 1.4),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: AppColors.statusError),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: AppColors.statusError, width: 1.4),
        ),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStateProperty.all(AppText.label),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.accentSoft;
            }
            return AppColors.bgSurface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.accentPrimary;
            }
            return AppColors.textSecondary;
          }),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.borderSubtle),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.sm),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bgElevated,
        elevation: 0,
        titleTextStyle: AppText.panelTitle,
        contentTextStyle: AppText.ui,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.xl,
          side: BorderSide(color: AppColors.borderSubtle),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          side: BorderSide(color: AppColors.borderSubtle),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.bgElevated,
        textStyle: AppText.ui,
        elevation: 1,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.md,
          side: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
    );
  }
}
