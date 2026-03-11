import 'package:coup_boardgame/app/modules/splash/controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _kBg = Color(0xFF0F1728);
const Color _kGold = Color(0xFFD4AF37);
const Color _kGoldLight = Color(0xFFEDD97A);
const Color _kTextSecondary = Color(0xFF7A8CA8);

class SplashPage extends GetView<SplashController> {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
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
                border: Border.all(color: _kGold, width: 2),
                color: const Color(0xFF18243E),
              ),
              child: const Icon(Icons.shield_outlined, size: 52, color: _kGold),
            ),
            const SizedBox(height: 24),
            Text(
              'appTitle'.tr,
              style: GoogleFonts.rajdhani(
                color: _kGoldLight,
                fontSize: 48,
                fontWeight: FontWeight.w700,
                letterSpacing: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'appSubtitle'.tr,
              style: GoogleFonts.rajdhani(
                color: _kTextSecondary,
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
                color: _kGold.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'loading'.tr,
              style: GoogleFonts.rajdhani(
                color: _kTextSecondary,
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
