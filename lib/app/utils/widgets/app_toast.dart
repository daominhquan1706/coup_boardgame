import 'package:coup_boardgame/app/themes/app_colors.dart';
import 'package:coup_boardgame/app/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppToast {
  AppToast._();

  static const Color _surface = AppColors.kSurface;
  static const Color _success = AppColors.greenSuccess;
  static const Color _error = AppColors.redError;
  static const Color _info = AppColors.kGold;

  static final _toastTextStyle =
      AppThemes.themData.textTheme.bodyLarge?.copyWith(
    fontWeight: FontWeight.w700,
  );

  static void success(String message,
      {Duration duration = const Duration(milliseconds: 1400)}) {
    _show(
      message: message,
      icon: Icons.check_circle_rounded,
      accent: _success,
      duration: duration,
    );
  }

  static void error(String message,
      {Duration duration = const Duration(milliseconds: 1800)}) {
    _show(
      message: message,
      icon: Icons.error_rounded,
      accent: _error,
      duration: duration,
    );
  }

  static void info(String message,
      {Duration duration = const Duration(milliseconds: 1500)}) {
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
    if (_tryShowMaterialSnackBar(
      message: message,
      icon: icon,
      accent: accent,
      duration: duration,
    )) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _tryShowMaterialSnackBar(
          message: message,
          icon: icon,
          accent: accent,
          duration: duration,
        );
      } catch (_) {
        // Intentionally swallow toast failures so app flows never crash.
      }
    });
  }

  static bool _tryShowMaterialSnackBar({
    required String message,
    required IconData icon,
    required Color accent,
    required Duration duration,
  }) {
    final context = Get.overlayContext ?? Get.context;
    if (context == null) return false;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return false;

    try {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          duration: duration,
          behavior: SnackBarBehavior.floating,
          backgroundColor: _surface,
          content: Row(
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
      return true;
    } catch (_) {
      return false;
    }
  }
}
