import 'package:flutter/material.dart';

/// Palet visual Centauri: tema TERANG, lembut, lapang (mengacu pada estetika
/// Google Stitch). Bukan lagi VS Code dark.
///
/// Prinsip:
///  - Latar terang, kartu putih, sudut membulat besar.
///  - Kedalaman lewat shadow lembut, bukan garis 1px kaku.
///  - Satu aksen biru lembut; warna semantik dipakai hemat.
class AppColors {
  AppColors._();

  /// Latar aplikasi (canvas luar / page background).
  static const Color bgBase = Color(0xFFF6F7F9);

  /// Permukaan kartu/panel (putih).
  static const Color bgSurface = Color(0xFFFFFFFF);

  /// Permukaan sedikit lebih gelap untuk area terkubur (mis. track input).
  static const Color bgSunken = Color(0xFFF1F2F5);

  /// Permukaan mengambang (dropdown, dialog, popover, sheet).
  static const Color bgElevated = Color(0xFFFFFFFF);

  /// Hover pada baris/daftar.
  static const Color hoverBg = Color(0xFFF1F2F5);

  /// Item terpilih (biru sangat lembut).
  static const Color selectionBg = Color(0xFFE8F0FE);

  /// Highlight seleksi teks. Sengaja amber/emas agar TIDAK menyatu dengan
  /// bubble chat user yang biru (aksen) — user jadi jelas mana yang terseleksi.
  static const Color textSelection = Color(0xFFFFD54F);

  /// Warna handle & kursor seleksi teks.
  static const Color textSelectionHandle = Color(0xFF1A73E8);

  /// Latar input.
  static const Color inputBg = Color(0xFFFFFFFF);

  /// Garis tipis, hanya untuk pemisah halus.
  static const Color borderSubtle = Color(0xFFE8EAED);

  /// Garis lebih tegas untuk kontrol (input, tombol outline).
  static const Color borderStrong = Color(0xFFDADCE0);

  /// Aksen utama (biru Google-ish, lembut).
  static const Color accentPrimary = Color(0xFF1A73E8);

  /// Aksen generatif AI.
  static const Color accentAi = Color(0xFF4285F4);

  /// Varian aksen lembut untuk latar chip/badge.
  static const Color accentSoft = Color(0xFFE8F0FE);

  static const Color link = Color(0xFF1A73E8);

  static const Color textPrimary = Color(0xFF202124);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textDisabled = Color(0xFF9AA0A6);

  static const Color statusSuccess = Color(0xFF1E8E3E);
  static const Color statusError = Color(0xFFD93025);
  static const Color statusWarning = Color(0xFFF29900);

  // Dimensi chrome.
  static const double sideBarWidth = 280;
  static const double titleBarHeight = 40;
  static const double topBarHeight = 56;
  static const double toolbarHeight = 48;
  static const double statusBarHeight = 0; // status bar dihapus di layout baru

  /// Shadow lembut untuk panel mengambang.
  static const List<BoxShadow> shadowSoft = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  /// Shadow lebih tegas untuk dialog/popover.
  static const List<BoxShadow> shadowRaised = [
    BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, 8)),
  ];
}

/// Shape Consistency Lock: satu skala radius besar dan membulat.
class AppRadius {
  AppRadius._();

  /// Kontrol kecil (chip, tag, tombol ikon).
  static const BorderRadius sm = BorderRadius.all(Radius.circular(8));

  /// Kontrol utama (tombol, input, tab).
  static const BorderRadius md = BorderRadius.all(Radius.circular(12));

  /// Panel/kartu besar.
  static const BorderRadius lg = BorderRadius.all(Radius.circular(16));

  /// Kartu besar / sheet.
  static const BorderRadius xl = BorderRadius.all(Radius.circular(24));

  /// Pil penuh.
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
    fontSize: 13.5,
    height: 1.45,
    color: AppColors.textPrimary,
  );

  static const TextStyle uiSmall = TextStyle(
    fontFamily: AppFonts.uiFamily,
    fontFamilyFallback: AppFonts.uiFallback,
    fontSize: 12.5,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: AppFonts.uiFamily,
    fontFamilyFallback: AppFonts.uiFallback,
    fontSize: 11.5,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  /// Judul section panel (tidak lagi uppercase kaku).
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: AppFonts.uiFamily,
    fontFamilyFallback: AppFonts.uiFallback,
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
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
      ),

      fontFamily: AppFonts.uiFamily,
      fontFamilyFallback: AppFonts.uiFallback,

      hoverColor: AppColors.hoverBg,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,

      // Seleksi teks: latar amber + teks tetap gelap agar kontras di bubble
      // biru maupun permukaan terang. Handle pakai aksen biru.
      // Catatan: `SelectionArea` (chat) memakai `selectionColor` dari sini.
      // Amber dipilih karena bubble chat user berwarna biru — highlight biru
      // samar membuat user ragu apakah teks benar-benar terseleksi.
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.accentPrimary,
        selectionColor: AppColors.textSelection.withValues(alpha: 0.55),
        selectionHandleColor: AppColors.accentPrimary,
      ),

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
        backgroundColor: AppColors.bgSurface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.uiFamily,
          fontFamilyFallback: AppFonts.uiFallback,
          fontSize: 14,
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
          borderRadius: AppRadius.lg,
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
        actionTextColor: const Color(0xFF8AB4F8),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
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
          (states) => states.contains(WidgetState.hovered) ? 10 : 8,
        ),
        thumbColor: WidgetStateProperty.all(const Color(0x33737380)),
        radius: const Radius.circular(999),
      ),

      // Buttons: membulat, tanpa elevation, ramah.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accentPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.bgSunken,
          disabledForegroundColor: AppColors.textDisabled,
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: AppFonts.uiFamily,
            fontFamilyFallback: AppFonts.uiFallback,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          minimumSize: const Size(0, 38),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.bgSunken,
          disabledForegroundColor: AppColors.textDisabled,
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: AppFonts.uiFamily,
            fontFamilyFallback: AppFonts.uiFallback,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          minimumSize: const Size(0, 38),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.bgSurface,
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.borderStrong),
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: AppFonts.uiFamily,
            fontFamilyFallback: AppFonts.uiFallback,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          minimumSize: const Size(0, 38),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentPrimary,
          textStyle: const TextStyle(
            fontFamily: AppFonts.uiFamily,
            fontFamilyFallback: AppFonts.uiFallback,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
        ),
      ),

      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.inputBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        isDense: true,
        border: const OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: AppColors.borderStrong),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: AppColors.borderStrong),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: AppColors.accentPrimary, width: 1.6),
        ),
        hintStyle: const TextStyle(
          fontFamily: AppFonts.uiFamily,
          fontFamilyFallback: AppFonts.uiFallback,
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
              return AppColors.accentSoft;
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.accentPrimary;
            }
            return AppColors.textSecondary;
          }),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.borderStrong),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.pill),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bgElevated,
        elevation: 0,
        titleTextStyle: const TextStyle(
          fontFamily: AppFonts.uiFamily,
          fontFamilyFallback: AppFonts.uiFallback,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: AppText.ui,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xl),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.bgElevated,
        textStyle: AppText.ui,
        elevation: 1,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
      ),
    );
  }
}
