import 'package:coup_boardgame/app/themes/app_colors.dart';
import 'package:coup_boardgame/app/themes/app_text_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
                  _buildLogo(context),
                  const SizedBox(height: 20),
                  _buildLanguageSelector(context),
                  const SizedBox(height: 20),
                  _buildCreateSection(context),
                  const SizedBox(height: 28),
                  _buildDivider(context),
                  const SizedBox(height: 28),
                  _buildJoinSection(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_outlined, color: AppColors.kGold, size: 26),
            const SizedBox(width: 10),
            Text(
              'appTitle'.tr,
              style: AppTextStyles.display.w700.s36.goldLightColor.ls(8),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.shield_outlined, color: AppColors.kGold, size: 26),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'appSubtitle'.tr,
          textAlign: TextAlign.center,
          style: AppTextStyles.title.s11.w500.ls(4),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
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
            style: AppTextStyles.title,
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

  Widget _buildCreateSection(BuildContext context) {
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
                style: AppTextStyles.headline.w700.s16.textPrimary.ls(0.5),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('homeCreateRoomDesc'.tr, style: AppTextStyles.body.s12.textSecondary),
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

  Widget _buildDivider(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.kBorder, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'homeOr'.tr,
            style: AppTextStyles.title,
          ),
        ),
        const Expanded(child: Divider(color: AppColors.kBorder, thickness: 1)),
      ],
    );
  }

  Widget _buildJoinSection(BuildContext context) {
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
                style: AppTextStyles.headline.w700.s16.textPrimary.ls(0.5),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('homeJoinRoomDesc'.tr, style: AppTextStyles.body.s12.textSecondary),
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
          style: AppTextStyles.body.s12.w700.copyWith(
            color: selected ? AppColors.kGoldLight : AppColors.kTextSecondary,
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
      style: AppTextStyles.body,
      cursorColor: AppColors.kGold,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.label,
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
          style: AppTextStyles.body.s15.w700.copyWith(
            color: enabled ? color : AppColors.kTextSecondary,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
