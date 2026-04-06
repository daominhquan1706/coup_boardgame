import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_theme.dart';
import 'package:flutter/material.dart';

/// Standardized textstyle using ThemeData as base.
/// Chain extensions: weight + size + color + style + decoration
/// Example:
/// ```dart
/// Text('Hello', style: AppTextStyles.body.w700.s16.whiteColor)
/// Text('Title', style: AppTextStyles.headline.w600.s20)
/// ```
class AppTextStyles {
  AppTextStyles._();

  static final TextTheme _tt = AppThemes.themData.textTheme;

  /// Base text style from ThemeData bodyMedium — inherits Rajdhani font,
  /// dark theme colors, and responsive sizing.
  static TextStyle get body => _tt.bodyMedium ?? _fallbackBody;

  /// Headline style — larger, bolder text for titles.
  static TextStyle get headline => _tt.headlineMedium ?? _fallbackHeadline;

  /// Title style — section labels and subtitles.
  static TextStyle get title => _tt.titleMedium ?? _fallbackTitle;

  /// Label style — small text for badges, chips, captions.
  static TextStyle get label => _tt.labelMedium ?? _fallbackLabel;

  /// Display style — large hero text.
  static TextStyle get display => _tt.displayMedium ?? _fallbackDisplay;

  // ─── Fallbacks ───────────────────────────────────────────────────
  static const _fallbackBody = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.kTextPrimary,
  );
  static const _fallbackHeadline = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.kTextPrimary,
  );
  static const _fallbackTitle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.kTextSecondary,
    letterSpacing: 2,
  );
  static const _fallbackLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.kTextSecondary,
  );
  static const _fallbackDisplay = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColors.kGoldLight,
    letterSpacing: 6,
  );

  /// Legacy base for backward compatibility.
  @Deprecated('Use AppTextStyles.body instead')
  static const TextStyle base = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.kPrimaryColor,
  );
}

extension AppFontWeight on TextStyle {
  /// FontWeight.w100
  TextStyle get w100 => copyWith(
        fontWeight: FontWeight.w100,
      );

  /// FontWeight.w200
  TextStyle get w200 => copyWith(
        fontWeight: FontWeight.w200,
      );

  /// FontWeight.w300
  TextStyle get w300 => copyWith(
        fontWeight: FontWeight.w300,
      );

  /// FontWeight.w400
  TextStyle get w400 => copyWith(
        fontWeight: FontWeight.w400,
      );

  /// FontWeight.w500
  TextStyle get w500 => copyWith(
        fontWeight: FontWeight.w500,
      );

  /// FontWeight.w600
  TextStyle get w600 => copyWith(
        fontWeight: FontWeight.w600,
      );

  /// FontWeight.w700
  TextStyle get w700 => copyWith(
        fontWeight: FontWeight.w700,
      );

  /// FontWeight.w800
  TextStyle get w800 => copyWith(
        fontWeight: FontWeight.w800,
      );

  /// FontWeight.w900
  TextStyle get w900 => copyWith(
        fontWeight: FontWeight.w900,
      );
}

extension AppFontSize on TextStyle {
  /// fontSize: 9
  TextStyle get s9 => copyWith(fontSize: 9);

  /// fontSize: 10
  TextStyle get s10 => copyWith(fontSize: 10);

  /// fontSize: 11
  TextStyle get s11 => copyWith(fontSize: 11);

  /// fontSize: 12
  TextStyle get s12 => copyWith(fontSize: 12);

  /// fontSize: 13
  TextStyle get s13 => copyWith(fontSize: 13);

  /// fontSize: 14
  TextStyle get s14 => copyWith(fontSize: 14);

  /// fontSize: 15
  TextStyle get s15 => copyWith(fontSize: 15);

  /// fontSize: 16
  TextStyle get s16 => copyWith(fontSize: 16);

  /// fontSize: 18
  TextStyle get s18 => copyWith(fontSize: 18);

  /// fontSize: 20
  TextStyle get s20 => copyWith(fontSize: 20);

  /// fontSize: 24
  TextStyle get s24 => copyWith(fontSize: 24);

  /// fontSize: 32
  TextStyle get s32 => copyWith(fontSize: 32);

  /// fontSize: 36
  TextStyle get s36 => copyWith(fontSize: 36);

  /// fontSize: 38
  TextStyle get s38 => copyWith(fontSize: 38);

  /// fontSize: 40
  TextStyle get s40 => copyWith(fontSize: 40);

  /// fontSize: 48
  TextStyle get s48 => copyWith(fontSize: 48);
}

extension AppFontColor on TextStyle {
  /// color: AppColors.white,
  TextStyle get whiteColor => copyWith(color: AppColors.white);

  /// color: AppColors.black,
  TextStyle get blackColor => copyWith(color: AppColors.black);

  /// color: AppColors.kPrimaryColor,
  TextStyle get kPrimaryColor => copyWith(color: AppColors.kPrimaryColor);

  /// color: AppColors.neutral3,
  TextStyle get neutral3Color => copyWith(color: AppColors.neutral3);

  /// color: AppColors.red,
  TextStyle get redColor => copyWith(color: AppColors.red);

  // ─── Dark Theme Text Colors ──────────────────────────────────────
  /// color: AppColors.kTextPrimary,
  TextStyle get textPrimary => copyWith(color: AppColors.kTextPrimary);

  /// color: AppColors.kTextSecondary,
  TextStyle get textSecondary => copyWith(color: AppColors.kTextSecondary);

  /// color: AppColors.kGold,
  TextStyle get goldColor => copyWith(color: AppColors.kGold);

  /// color: AppColors.kGoldLight,
  TextStyle get goldLightColor => copyWith(color: AppColors.kGoldLight);

  /// color: AppColors.kBlue,
  TextStyle get blueColor => copyWith(color: AppColors.kBlue);

  /// color: AppColors.greenLight,
  TextStyle get greenLightColor => copyWith(color: AppColors.greenLight);

  /// color: AppColors.redAccent,
  TextStyle get redAccentColor => copyWith(color: AppColors.redAccent);
}

extension AppFontStyle on TextStyle {
  /// color: AppColors.white,
  TextStyle get italic => copyWith(fontStyle: FontStyle.italic);
}

extension AppFontDecoration on TextStyle {
  /// decoration: TextDecoration.overline,
  TextStyle get overline => copyWith(decoration: TextDecoration.overline);

  /// decoration: TextDecoration.underline,
  TextStyle get underline => copyWith(decoration: TextDecoration.underline);

  /// decoration: TextDecoration.none,
  TextStyle get noneDecoration => copyWith(decoration: TextDecoration.none);

  /// decoration: TextDecoration.lineThrough,
  TextStyle get lineThrough => copyWith(decoration: TextDecoration.lineThrough);
}

extension AppLetterSpacing on TextStyle {
  /// Set custom letter spacing
  TextStyle ls(double value) => copyWith(letterSpacing: value);
}

extension AppFontFamily on TextStyle {
  /// fontFamily: GoogleFonts.roboto().fontFamily,
  TextStyle get roboto => copyWith(fontFamily: GoogleFonts.roboto().fontFamily);
}
