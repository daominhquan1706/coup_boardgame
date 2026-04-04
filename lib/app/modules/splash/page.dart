import 'package:coup_boardgame/app/modules/splash/controller.dart';
import 'package:coup_boardgame/app/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashPage extends GetView<SplashController> {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Coup crest
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.kGold, width: 2),
                color: AppColors.kSurface,
              ),
              child: const Icon(Icons.shield_outlined, size: 52, color: AppColors.kGold),
            ),
            const SizedBox(height: 24),
            Text(
              'appTitle'.tr,
              style: GoogleFonts.rajdhani(
                color: AppColors.kGoldLight,
                fontSize: 48,
                fontWeight: FontWeight.w700,
                letterSpacing: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'appSubtitle'.tr,
              style: GoogleFonts.rajdhani(
                color: AppColors.kTextSecondary,
                fontSize: 13,
                letterSpacing: 4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.kGold.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'loading'.tr,
              style: GoogleFonts.rajdhani(
                color: AppColors.kTextSecondary,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
