import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class AppToast {
  AppToast._();

  static const Color _surface = Color(0xFF18243E);
  static const Color _border = Color(0xFF2A3A5E);
  static const Color _text = Color(0xFFE8EDF5);
  static const Color _success = Color(0xFF16A34A);
  static const Color _error = Color(0xFFDC2626);
  static const Color _info = Color(0xFFD4AF37);

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
    final screenWidth = Get.width;
    final toastMaxWidth = screenWidth < 520
        ? ((screenWidth - 24).clamp(240, screenWidth)).toDouble()
        : 420.0;

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
                style: GoogleFonts.rajdhani(
                  color: _text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
