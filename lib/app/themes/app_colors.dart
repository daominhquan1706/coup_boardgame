import 'package:flutter/material.dart';

/// Centralized color constants for the entire app.
/// All colors should be defined here — never hardcode Color() elsewhere.
class AppColors {
  AppColors._();

  // ─── Primary Brand ─────────────────────────────────────────────────────────
  static const MaterialColor kPrimaryColor = MaterialColor(
    0xFFEE4463,
    <int, Color>{
      50: Color(0x88FFC7FF),
      100: Color(0xFFFFC7FF),
      200: Color(0xFFF1A6AA),
      300: Color(0xFFFF99E0),
      400: Color(0xFFFF6DA3),
      500: Color(0xFFEE4463),
      600: Color(0xFFEE4463),
      700: Color(0xFFEE4463),
      800: Color(0xFFEE4463),
      900: Color(0xFF895E6B),
    },
  );

  // ─── Basic ─────────────────────────────────────────────────────────────────
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Color(0x00000000);

  // ─── Semantic / Status ─────────────────────────────────────────────────────
  static const Color green = Color(0xFF43A838);
  static const Color greenLight = Color(0xFF2ECC71);
  static const Color greenSuccess = Color(0xFF16A34A);
  static const Color greenEmerald = Color(0xFF10B981);
  static const Color greenEmeraldDark = Color(0xFF059669);
  static const Color greenTeal = Color(0xFF0891B2);
  static const Color greenMint = Color(0xFF4ADE80);
  static const Color greenLime = Color(0xFF84CC16);
  static const Color greenLimeDark = Color(0xFF365314);
  static const Color greenLimeAccent = Color(0xFFEAB308);

  static const Color red = Color(0xFFFF3B3B);
  static const Color redAccent = Color(0xFFE74C3C);
  static const Color redError = Color(0xFFDC2626);
  static const Color redErrorDark = Color(0xFF7F1D1D);
  static const Color redRose = Color(0xFFFB7185);
  static const Color redLight = Color(0xFFFCA5A5);
  static const Color redInk = Color(0xFFFFF1F2);

  static const Color gray = Color(0xFFAAAAAA);
  static const Color lightGray = Color(0xFF909296);
  static const Color colorDivider = Color(0xFFEBEBEB);

  // ─── Neutral ───────────────────────────────────────────────────────────────
  static const Color neutral6 = Color(0xFFF1F2F9);
  static const Color neutral3 = Color(0xFFADAFC5);

  // ─── Dark Theme — Background & Surface ─────────────────────────────────────
  static const Color kBg = Color(0xFF0F1728);
  static const Color kSurface = Color(0xFF18243E);
  static const Color kSurfaceHigh = Color(0xFF1E2D4E);
  static const Color kBorder = Color(0xFF2A3A5E);

  // ─── Dark Theme — Text ─────────────────────────────────────────────────────
  static const Color kTextPrimary = Color(0xFFE8EDF5);
  static const Color kTextSecondary = Color(0xFF7A8CA8);

  // ─── Dark Theme — Accent ───────────────────────────────────────────────────
  static const Color kGold = Color(0xFFD4AF37);
  static const Color kGoldLight = Color(0xFFEDD97A);
  static const Color kGoldDark = Color(0xFFD97706);
  static const Color kGoldAmber = Color(0xFFF59E0B);
  static const Color kGoldAmberDark = Color(0xFF3E2A06);
  static const Color kBlue = Color(0xFF3B82F6);
  static const Color kBlueDark = Color(0xFF1D4ED8);
  static const Color kBlueLight = Color(0xFF4D8DFF);

  // ─── Game Board ────────────────────────────────────────────────────────────
  static const Color boardBgDark = Color(0xFF143148);
  static const Color boardBgDarker = Color(0xFF102332);
  static const Color boardCardBg = Color(0xFF334155);
  static const Color boardCardBgDark = Color(0xFF1E293B);
  static const Color boardOverlay = Color(0xFF243047);
  static const Color boardOverlayDark = Color(0xFF161F30);

  // ─── Role Card Palettes ────────────────────────────────────────────────────
  // Duke
  static const Color dukePrimary = Color(0xFFBE185D);
  static const Color dukeSecondary = Color(0xFF831843);
  static const Color dukeAccent = Color(0xFFF9A8D4);
  static const Color dukeInk = Color(0xFFFFF1F8);

  // Assassin
  static const Color assassinPrimary = Color(0xFF374151);
  static const Color assassinSecondary = Color(0xFF111827);
  static const Color assassinAccent = Color(0xFF9CA3AF);
  static const Color assassinInk = Color(0xFFF3F4F6);

  // Contessa
  static const Color contessaPrimary = Color(0xFFDC2626);
  static const Color contessaSecondary = Color(0xFF7F1D1D);
  static const Color contessaAccent = Color(0xFFFCA5A5);
  static const Color contessaInk = Color(0xFFFFF1F2);

  // Captain
  static const Color captainPrimary = Color(0xFF38BDF8);
  static const Color captainSecondary = Color(0xFF075985);
  static const Color captainAccent = Color(0xFFBAE6FD);
  static const Color captainInk = Color(0xFFF0F9FF);

  // Ambassador
  static const Color ambassadorPrimary = Color(0xFF84CC16);
  static const Color ambassadorSecondary = Color(0xFF365314);
  static const Color ambassadorAccent = Color(0xFFEAB308);
  static const Color ambassadorInk = Color(0xFFF7FEE7);

  // Inquisitor
  static const Color inquisitorPrimary = Color(0xFFD97706);
  static const Color inquisitorSecondary = Color(0xFF4A2508);
  static const Color inquisitorAccent = Color(0xFFFDE68A);
  static const Color inquisitorInk = Color(0xFFFFFAEE);

  // Default / Unknown
  static const Color defaultCardPrimary = Color(0xFF475569);
  static const Color defaultCardSecondary = Color(0xFF0F172A);
  static const Color defaultCardAccent = Color(0xFFCBD5E1);
  static const Color defaultCardInk = Color(0xFFF8FAFC);

  // ─── Event / Action Accent Colors ──────────────────────────────────────────
  static const Color eventCyan = Color(0xFF06B6D4);
  static const Color eventPurple = Color(0xFF7C3AED);
  static const Color eventViolet = Color(0xFF8B5CF6);
  static const Color eventTeal = Color(0xFF14B8A6);

  // ─── Alpha Variants (convenience) ──────────────────────────────────────────
  static Color goldWithAlpha(double alpha) => kGold.withValues(alpha: alpha);
  static Color goldLightWithAlpha(double alpha) => kGoldLight.withValues(alpha: alpha);
  static Color greenWithAlpha(double alpha) => greenLight.withValues(alpha: alpha);
  static Color redWithAlpha(double alpha) => redAccent.withValues(alpha: alpha);
  static Color blueWithAlpha(double alpha) => kBlue.withValues(alpha: alpha);
  static Color surfaceWithAlpha(double alpha) => kSurface.withValues(alpha: alpha);
  static Color borderWithAlpha(double alpha) => kBorder.withValues(alpha: alpha);
  static Color textSecondaryWithAlpha(double alpha) => kTextSecondary.withValues(alpha: alpha);
  static Color blackWithAlpha(double alpha) => black.withValues(alpha: alpha);
  static Color whiteWithAlpha(double alpha) => white.withValues(alpha: alpha);
}
