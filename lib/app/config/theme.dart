import 'package:flutter/material.dart';

class AppColors {
  static const Color bgBase = Color(0xFF09090B);     // Zinc 950
  static const Color bgSurface = Color(0xFF18181B);  // Zinc 900
  static const Color bgElevated = Color(0xFF27272A); // Zinc 800
  
  static const Color borderSubtle = Color(0xFF27272A); // Zinc 800
  static const Color borderStrong = Color(0xFF3F3F46); // Zinc 700
  
  static const Color textPrimary = Color(0xFFFAFAFA);  // Zinc 50
  static const Color textSecondary = Color(0xFFA1A1AA); // Zinc 400
  static const Color textDisabled = Color(0xFF52525B);  // Zinc 600
  
  static const Color accentPrimary = Color(0xFF3B82F6); // Blue 500
  static const Color accentAi = Color(0xFF8B5CF6);      // Violet 500
  
  static const Color statusSuccess = Color(0xFF10B981);
  static const Color statusError = Color(0xFFEF4444);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgBase,
      
      // Hapus semua shadow/elevation bawaan MD3
      shadowColor: Colors.transparent,
      
      // Tipografi
      fontFamily: 'Inter', // Pastikan font Inter ada di pubspec.yaml
      textTheme: const TextTheme(
        displayMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        bodyMedium: TextStyle(color: AppColors.textPrimary, fontSize: 14),
        bodySmall: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        labelSmall: TextStyle(fontFamily: 'JetBrainsMono', color: AppColors.textSecondary, fontSize: 12),
      ),

      // Matikan efek ripple/ink MD3 yang berlebihan
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,

      // AppBar (flat, tanpa shadow)
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgBase,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.bgElevated,
        contentTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accentPrimary,
      ),

      iconTheme: const IconThemeData(color: AppColors.textSecondary),

      // Card Style (Border, no shadow)
      cardTheme: CardThemeData(
        color: AppColors.bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Elevated Button Style (Primary)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      // Outlined Button Style (Secondary/Ghost)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      // Input Field Style
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgBase,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.accentPrimary, width: 1),
        ),
      ),
    );
  }
}