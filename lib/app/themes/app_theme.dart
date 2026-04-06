import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:coup_boardgame/app/themes/app_colors.dart';

class AppThemes {
  AppThemes._();

  /// Nunito text theme — used app-wide for headings, labels, body text.
  static final TextTheme _nunitoText = GoogleFonts.nunitoTextTheme();

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
    textTheme: _nunitoText.copyWith(
      // Display / Large titles
      displayLarge: _nunitoText.displayLarge?.copyWith(
        color: AppColors.kGoldLight,
        fontWeight: FontWeight.w700,
        letterSpacing: 8,
      ),
      displayMedium: _nunitoText.displayMedium?.copyWith(
        color: AppColors.kGoldLight,
        fontWeight: FontWeight.w700,
        letterSpacing: 6,
      ),
      displaySmall: _nunitoText.displaySmall?.copyWith(
        color: AppColors.kGoldLight,
        fontWeight: FontWeight.w700,
        letterSpacing: 4,
      ),

      // Headings
      headlineLarge: _nunitoText.headlineLarge?.copyWith(
        color: AppColors.kTextPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
      headlineMedium: _nunitoText.headlineMedium?.copyWith(
        color: AppColors.kTextPrimary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      headlineSmall: _nunitoText.headlineSmall?.copyWith(
        color: AppColors.kTextPrimary,
        fontWeight: FontWeight.w600,
      ),

      // Titles (section labels)
      titleLarge: _nunitoText.titleLarge?.copyWith(
        color: AppColors.kTextPrimary,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
      titleMedium: _nunitoText.titleMedium?.copyWith(
        color: AppColors.kTextSecondary,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
        fontSize: 11,
      ),
      titleSmall: _nunitoText.titleSmall?.copyWith(
        color: AppColors.kTextSecondary,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
        fontSize: 10,
      ),

      // Body text
      bodyLarge: _nunitoText.bodyLarge?.copyWith(
        color: AppColors.kTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      bodyMedium: _nunitoText.bodyMedium?.copyWith(
        color: AppColors.kTextPrimary,
        fontWeight: FontWeight.w400,
        fontSize: 14,
      ),
      bodySmall: _nunitoText.bodySmall?.copyWith(
        color: AppColors.kTextSecondary,
        fontWeight: FontWeight.w400,
        fontSize: 11,
      ),

      // Labels / badges
      labelLarge: _nunitoText.labelLarge?.copyWith(
        color: AppColors.kTextSecondary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      labelMedium: _nunitoText.labelMedium?.copyWith(
        color: AppColors.kTextSecondary,
        fontWeight: FontWeight.w600,
        fontSize: 11,
      ),
      labelSmall: _nunitoText.labelSmall?.copyWith(
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
      titleTextStyle: GoogleFonts.nunito(
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
      titleTextStyle: GoogleFonts.nunito(
        color: AppColors.kTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: GoogleFonts.nunito(
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
        textStyle: GoogleFonts.nunito(
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
