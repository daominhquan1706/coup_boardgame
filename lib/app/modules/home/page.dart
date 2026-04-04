import 'package:coup_boardgame/app/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:coup_boardgame/app/utils/widgets/e2e_tag.dart';
import 'controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 20),
                  _buildLanguageSelector(),
                  const SizedBox(height: 20),
                  _buildCreateSection(),
                  const SizedBox(height: 28),
                  _buildDivider(),
                  const SizedBox(height: 28),
                  _buildJoinSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_outlined, color: AppColors.kGold, size: 26),
            const SizedBox(width: 10),
            Text(
              'appTitle'.tr,
              style: GoogleFonts.rajdhani(
                color: AppColors.kGoldLight,
                fontSize: 36,
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.shield_outlined, color: AppColors.kGold, size: 26),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'appSubtitle'.tr,
          textAlign: TextAlign.center,
          style: GoogleFonts.rajdhani(
            color: AppColors.kTextSecondary,
            fontSize: 11,
            letterSpacing: 4,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Row(
        children: [
          Text(
            'homeLanguage'.tr,
            style: GoogleFonts.rajdhani(
              color: AppColors.kTextSecondary,
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Obx(
            () => Wrap(
              spacing: 8,
              children: [
                _LangButton(
                  label: 'languageEnglish'.tr,
                  selected: controller.selectedLanguage.value == 'en',
                  onTap: () => controller.changeLanguage('en'),
                ),
                _LangButton(
                  label: 'languageVietnamese'.tr,
                  selected: controller.selectedLanguage.value == 'vi',
                  onTap: () => controller.changeLanguage('vi'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.greenLight.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.add_circle_outline, color: AppColors.greenLight, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'homeCreateRoomTitle'.tr,
                style: GoogleFonts.rajdhani(
                  color: AppColors.kTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('homeCreateRoomDesc'.tr,
              style: const TextStyle(color: AppColors.kTextSecondary, fontSize: 12)),
          const SizedBox(height: 16),
          E2ETag(
            label: 'e2e-home-create-room-button',
            button: true,
            child: _BoardButton(
              label: 'homeCreateRoomButton'.tr,
              color: AppColors.greenLight,
              enabled: true,
              onTap: controller.onTapCreateRoom,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.kBorder, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'homeOr'.tr,
            style: GoogleFonts.rajdhani(
              color: AppColors.kTextSecondary,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.kBorder, thickness: 1)),
      ],
    );
  }

  Widget _buildJoinSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.kBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.login_outlined, color: AppColors.kBlue, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'homeJoinRoomTitle'.tr,
                style: GoogleFonts.rajdhani(
                  color: AppColors.kTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('homeJoinRoomDesc'.tr,
              style: const TextStyle(color: AppColors.kTextSecondary, fontSize: 12)),
          const SizedBox(height: 16),
          E2ETag(
            label: 'e2e-home-join-room-code-input',
            textField: true,
            child: _BoardTextField(
              onChanged: controller.roomCode.call,
              hintText: 'homeEnterRoomCode'.tr,
              prefixIcon: Icons.tag,
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => E2ETag(
              label: controller.roomCode.value.isNotEmpty
                  ? 'e2e-home-join-room-button-ready'
                  : 'e2e-home-join-room-button-disabled',
              button: true,
              enabled: controller.roomCode.value.isNotEmpty,
              child: _BoardButton(
                label: 'homeJoinRoomButton'.tr,
                color: AppColors.kBlue,
                enabled: controller.roomCode.value.isNotEmpty,
                onTap: controller.onTapJoinRoom,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.kGold.withValues(alpha: 0.14) : AppColors.kSurfaceHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.kGold.withValues(alpha: 0.55) : AppColors.kBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.rajdhani(
            color: selected ? AppColors.kGoldLight : AppColors.kTextSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Shared styled text field ─────────────────────────────────────────────────
class _BoardTextField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String hintText;
  final IconData prefixIcon;

  const _BoardTextField({
    required this.onChanged,
    required this.hintText,
    required this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.kTextPrimary, fontSize: 14),
      cursorColor: AppColors.kGold,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.kTextSecondary, fontSize: 13),
        prefixIcon: Icon(prefixIcon, color: AppColors.kTextSecondary, size: 18),
        filled: true,
        fillColor: AppColors.kSurfaceHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.kGold, width: 1.5),
        ),
      ),
    );
  }
}

// ─── Shared styled button ─────────────────────────────────────────────────────
class _BoardButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _BoardButton({
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: enabled ? color.withValues(alpha: 0.14) : AppColors.kSurfaceHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? color.withValues(alpha: 0.6) : AppColors.kBorder,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.rajdhani(
            color: enabled ? color : AppColors.kTextSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
