import 'package:flutter/material.dart';

/// Warna mengikuti VS Code "Dark Modern" theme.
/// Aplikasi shell memakai token ini; UI yang di-generate user tidak terpengaruh.
class AppColors {
  // Chrome: activity bar, sidebar, title bar, status bar, tab bar.
  static const Color chromeBg = Color(0xFF181818);

  // Editor background (area utama).
  static const Color bgBase = Color(0xFF1F1F1F);

  // Panel/card/sidebar content.
  static const Color bgSurface = Color(0xFF181818);

  // Menu, dropdown, dialog, snackbar.
  static const Color bgElevated = Color(0xFF202020);

  static const Color hoverBg = Color(0xFF2A2D2E);
  static const Color selectionBg = Color(0xFF04395E);
  static const Color inputBg = Color(0xFF313131);

  static const Color borderSubtle = Color(0xFF2B2B2B);
  static const Color borderStrong = Color(0xFF454545);

  static const Color accentPrimary = Color(0xFF0078D4);

  /// Aksen khusus aksi generatif. Sengaja bukan ungu AI (`#B180D7`) yang
  /// menjadi penanda visual "AI slop". Dipakai sangat hemat, hanya pada
  /// affordance generate (tombol send, indikator generating).
  static const Color accentAi = Color(0xFF4EA1FF);

  static const Color link = Color(0xFF3794FF);

  static const Color textPrimary = Color(0xFFCCCCCC);
  static const Color textSecondary = Color(0xFF9D9D9D);
  static const Color textDisabled = Color(0xFF6E7681);

  static const Color statusSuccess = Color(0xFF89D185);
  static const Color statusError = Color(0xFFF14C4C);
  static const Color statusWarning = Color(0xFFCCA700);

  // Dimensi khas VS Code.
  static const double activityBarWidth = 48;
  static const double sideBarWidth = 300;
  static const double tabHeight = 35;
  static const double titleBarHeight = 30;
  static const double statusBarHeight = 22;
  static const double toolbarHeight = 32;

  /// Skala radius tunggal (Shape Consistency Lock). Pro-tool = tajam.
  /// Gunakan `AppRadius.sm` untuk kontrol, `md` untuk panel/card ringan.
  static const double radiusSm = 2;
  static const double radiusMd = 3;
}

/// Shape Consistency Lock: satu skala radius dipakai di seluruh shell.
class AppRadius {
  AppRadius._();

  /// Kontrol (button, input, chip, tab): hampir tajam.
  static const BorderRadius sm = BorderRadius.all(Radius.circular(2));

  /// Panel/card ringan: hampir tajam, sedikit lebih lembut.
  static const BorderRadius md = BorderRadius.all(Radius.circular(3));

  /// Pil penuh untuk chip status kecil yang perlu terasa "kapsul".
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
}

class AppFonts {
  AppFonts._();

  /// Font UI utama aplikasi (mobile + Windows): Plus Jakarta Sans.
  static const String uiFamily = 'PlusJakartaSans';
  static const List<String> uiFallback = ['Inter', 'Roboto', 'sans-serif'];

  /// Mono font untuk kode: JetBrains Mono bundled (lintas platform).
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

  static const TextStyle ui = TextStyle(
    fontFamily: AppFonts.uiFamily,
    fontFamilyFallback: AppFonts.uiFallback,
    fontSize: 13,
    color: AppColors.textPrimary,
  );

  static const TextStyle uiSmall = TextStyle(
    fontFamily: AppFonts.uiFamily,
    fontFamilyFallback: AppFonts.uiFallback,
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: AppFonts.uiFamily,
    fontFamilyFallback: AppFonts.uiFallback,
    fontSize: 11,
    color: AppColors.textSecondary,
  );

  /// Section header sidebar ala VS Code (11px, bold, letter-spaced).
  static const TextStyle sectionHeader = TextStyle(
    fontFamily: AppFonts.uiFamily,
    fontFamilyFallback: AppFonts.uiFallback,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: Color(0xFFBBBBBB),
  );

  static const TextStyle mono = TextStyle(
    fontFamily: AppFonts.monoFamily,
    fontFamilyFallback: AppFonts.monoFallback,
    fontSize: 12,
    color: AppColors.textPrimary,
  );

  static const TextStyle monoSmall = TextStyle(
    fontFamily: AppFonts.monoFamily,
    fontFamilyFallback: AppFonts.monoFallback,
    fontSize: 11,
    color: AppColors.textSecondary,
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: false,
      scaffoldBackgroundColor: AppColors.bgBase,

      fontFamily: AppFonts.uiFamily,
      fontFamilyFallback: AppFonts.uiFallback,

      // Matikan efek tinggi/bayangan MD3.
      shadowColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: AppColors.hoverBg,

      textTheme: const TextTheme(
        displaySmall: AppText.ui,
        headlineSmall: AppText.ui,
        titleLarge: AppText.ui,
        titleMedium: AppText.ui,
        titleSmall: AppText.ui,
        bodyLarge: AppText.ui,
        bodyMedium: AppText.ui,
        bodySmall: AppText.uiSmall,
        labelLarge: AppText.ui,
        labelMedium: AppText.uiSmall,
        labelSmall: AppText.caption,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.chromeBg,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.uiFamily,
          fontSize: 12,
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
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppColors.borderSubtle),
          borderRadius: BorderRadius.all(Radius.circular(2)),
        ),
      ),

      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 16),

      primaryIconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 16,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accentPrimary,
        linearTrackColor: AppColors.bgElevated,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.bgElevated,
        contentTextStyle: AppText.ui,
        actionTextColor: AppColors.link,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppColors.borderStrong),
        ),
      ),

      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 400),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          border: Border.fromBorderSide(
            BorderSide(color: AppColors.borderStrong),
          ),
        ),
        textStyle: TextStyle(
          fontFamily: AppFonts.uiFamily,
          fontSize: 12,
          color: AppColors.textPrimary,
        ),
      ),

      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: WidgetStateProperty.all(false),
        thickness: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered) ? 10 : 6,
        ),
        thumbColor: WidgetStateProperty.all(const Color(0x66797979)),
        radius: const Radius.circular(0),
      ),

      // Buttons: flat, sudut 2px, tinggi minimal 26px ala VS Code.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF3A3D41),
          disabledForegroundColor: const Color(0xFF989898),
          elevation: 0,
          textStyle: AppText.ui,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          minimumSize: const Size(0, 26),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.hoverBg,
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.borderStrong),
          elevation: 0,
          textStyle: AppText.ui,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          minimumSize: const Size(0, 26),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          textStyle: AppText.ui,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),

      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.inputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        isDense: true,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
          borderSide: BorderSide(color: AppColors.borderStrong),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
          borderSide: BorderSide(color: AppColors.borderStrong),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
          borderSide: BorderSide(color: AppColors.accentPrimary),
        ),
        hintStyle: const TextStyle(
          fontFamily: AppFonts.uiFamily,
          fontSize: 13,
          color: AppColors.textDisabled,
        ),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStateProperty.all(AppText.uiSmall),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.selectionBg;
            }
            return AppColors.chromeBg;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.textPrimary;
            }
            return AppColors.textSecondary;
          }),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.borderSubtle),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(2)),
            ),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bgElevated,
        elevation: 0,
        titleTextStyle: AppText.ui,
        contentTextStyle: AppText.ui,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.md,
          side: BorderSide(color: AppColors.borderStrong),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.chromeBg,
        elevation: 0,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.bgElevated,
        textStyle: AppText.ui,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.md,
          side: BorderSide(color: AppColors.borderStrong),
        ),
      ),
    );
  }
}
