import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:coup_boardgame/app/themes/app_colors.dart';

class AppThemes {
  AppThemes._();

  /// Rajdhani text theme — used app-wide for headings, labels, body text.
  static final TextTheme _rajdhaniText = GoogleFonts.rajdhaniTextTheme();

  static final ThemeData themData = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primarySwatch: AppColors.kPrimaryColor,
    primaryColor: AppColors.kPrimaryColor,
    scaffoldBackgroundColor: AppColors.kBg,
    visualDensity: VisualDensity.adaptivePlatformDensity,

    // ─── Color Scheme ────────────────────────────────────────────────
    colorScheme: const ColorScheme.dark(
      primary: AppColors.kPrimaryColor,
      secondary: AppColors.kGold,
      surface: AppColors.kSurface,
      surfaceContainerHigh: AppColors.kSurfaceHigh,
      onPrimary: AppColors.white,
      onSecondary: AppColors.kBg,
      onSurface: AppColors.kTextPrimary,
      error: AppColors.redError,
      onError: AppColors.white,
    ),

    // ─── Text Theme ──────────────────────────────────────────────────
    textTheme: _rajdhaniText.copyWith(
      // Display / Large titles
      displayLarge: _rajdhaniText.displayLarge?.copyWith(
        color: AppColors.kGoldLight,
        fontWeight: FontWeight.w700,
        letterSpacing: 8,
      ),
      displayMedium: _rajdhaniText.displayMedium?.copyWith(
        color: AppColors.kGoldLight,
        fontWeight: FontWeight.w700,
        letterSpacing: 6,
      ),
      displaySmall: _rajdhaniText.displaySmall?.copyWith(
        color: AppColors.kGoldLight,
        fontWeight: FontWeight.w700,
        letterSpacing: 4,
      ),

      // Headings
      headlineLarge: _rajdhaniText.headlineLarge?.copyWith(
        color: AppColors.kTextPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
      headlineMedium: _rajdhaniText.headlineMedium?.copyWith(
        color: AppColors.kTextPrimary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      headlineSmall: _rajdhaniText.headlineSmall?.copyWith(
        color: AppColors.kTextPrimary,
        fontWeight: FontWeight.w600,
      ),

      // Titles (section labels)
      titleLarge: _rajdhaniText.titleLarge?.copyWith(
        color: AppColors.kTextPrimary,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
      titleMedium: _rajdhaniText.titleMedium?.copyWith(
        color: AppColors.kTextSecondary,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
        fontSize: 11,
      ),
      titleSmall: _rajdhaniText.titleSmall?.copyWith(
        color: AppColors.kTextSecondary,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
        fontSize: 10,
      ),

      // Body text
      bodyLarge: _rajdhaniText.bodyLarge?.copyWith(
        color: AppColors.kTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      bodyMedium: _rajdhaniText.bodyMedium?.copyWith(
        color: AppColors.kTextPrimary,
        fontWeight: FontWeight.w400,
        fontSize: 14,
      ),
      bodySmall: _rajdhaniText.bodySmall?.copyWith(
        color: AppColors.kTextSecondary,
        fontWeight: FontWeight.w400,
        fontSize: 11,
      ),

      // Labels / badges
      labelLarge: _rajdhaniText.labelLarge?.copyWith(
        color: AppColors.kTextSecondary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      labelMedium: _rajdhaniText.labelMedium?.copyWith(
        color: AppColors.kTextSecondary,
        fontWeight: FontWeight.w600,
        fontSize: 11,
      ),
      labelSmall: _rajdhaniText.labelSmall?.copyWith(
        color: AppColors.kTextSecondary,
        fontWeight: FontWeight.w700,
        fontSize: 9,
        letterSpacing: 0.8,
      ),
    ),

    // ─── AppBar ──────────────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.kSurface,
      foregroundColor: AppColors.kGold,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.rajdhani(
        color: AppColors.kGold,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 4,
      ),
    ),

    // ─── Card ────────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: AppColors.kSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.kBorder),
      ),
    ),

    // ─── Divider ─────────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.kBorder,
      thickness: 1,
      space: 1,
    ),

    // ─── Dialog ──────────────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.kSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.kBorder),
      ),
      titleTextStyle: GoogleFonts.rajdhani(
        color: AppColors.kTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: GoogleFonts.rajdhani(
        color: AppColors.kTextSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    ),

    // ─── Button ──────────────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.kSurfaceHigh,
        foregroundColor: AppColors.kTextPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.kBorder),
        ),
        textStyle: GoogleFonts.rajdhani(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    ),

    // ─── Icon ────────────────────────────────────────────────────────
    iconTheme: const IconThemeData(
      color: AppColors.kTextSecondary,
      size: 20,
    ),
  );
}
