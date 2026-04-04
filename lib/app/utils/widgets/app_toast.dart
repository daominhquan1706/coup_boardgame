import 'package:coup_boardgame/app/themes/app_colors.dart';
import 'package:coup_boardgame/app/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppToast {
  AppToast._();

  static const Color _surface = AppColors.kSurface;
  static const Color _border = AppColors.kBorder;
  static const Color _success = AppColors.greenSuccess;
  static const Color _error = AppColors.redError;
  static const Color _info = AppColors.kGold;

  static final _toastTextStyle = AppThemes.themData.textTheme.bodyLarge?.copyWith(
    fontWeight: FontWeight.w700,
  );

  static void success(String message, {Duration duration = const Duration(milliseconds: 1400)}) {
    _show(
      message: message,
      icon: Icons.check_circle_rounded,
      accent: _success,
      duration: duration,
    );
  }

  static void error(String message, {Duration duration = const Duration(milliseconds: 1800)}) {
    _show(
      message: message,
      icon: Icons.error_rounded,
      accent: _error,
      duration: duration,
    );
  }

  static void info(String message, {Duration duration = const Duration(milliseconds: 1500)}) {
    _show(
      message: message,
      icon: Icons.info_rounded,
      accent: _info,
      duration: duration,
    );
  }

  static void _show({
    required String message,
    required IconData icon,
    required Color accent,
    required Duration duration,
  }) {
    final screenWidth = Get.width;
    final toastMaxWidth =
        screenWidth < 520 ? ((screenWidth - 24).clamp(240, screenWidth)).toDouble() : 420.0;

    Get.closeAllSnackbars();
    Get.showSnackbar(
      GetSnackBar(
        snackPosition: SnackPosition.BOTTOM,
        maxWidth: toastMaxWidth,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
        borderRadius: 14,
        backgroundColor: _surface,
        borderColor: _border,
        borderWidth: 1,
        duration: duration,
        animationDuration: const Duration(milliseconds: 180),
        isDismissible: true,
        messageText: Row(
          children: [
            Icon(icon, size: 18, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _toastTextStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
