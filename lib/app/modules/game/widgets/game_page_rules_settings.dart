part of '../page.dart';

class _RulesTabView extends StatelessWidget {
  const _RulesTabView();

  List<({String title, String body})> _sections() {
    return const [
      (title: 'rulesObjectiveTitle', body: 'rulesObjectiveBody'),
      (title: 'rulesTurnFlowTitle', body: 'rulesTurnFlowBody'),
      (title: 'rulesChallengeBlockTitle', body: 'rulesChallengeBlockBody'),
      (title: 'rulesInfluenceTitle', body: 'rulesInfluenceBody'),
      (title: 'rulesThresholdTitle', body: 'rulesThresholdBody'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoHeader(
            title: 'rulesHeaderTitle'.tr,
            subtitle: 'rulesHeaderSubtitle'.tr,
            icon: Icons.menu_book_rounded,
          ),
          const SizedBox(height: 12),
          for (final section in sections) ...[
            _InfoCard(title: section.title.tr, body: section.body.tr),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _SettingsTabView extends StatelessWidget {
  final CoupRoomModel room;
  final GameStartController controller;

  const _SettingsTabView({required this.room, required this.controller});

  @override
  Widget build(BuildContext context) {
    final selectedLanguage = Get.locale?.languageCode == 'vi' ? 'vi' : 'en';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoHeader(
            title: 'settingsHeaderTitle'.tr,
            subtitle: 'settingsHeaderSubtitle'.tr,
            icon: Icons.tune_rounded,
          ),
          const SizedBox(height: 12),
          _SettingsSection(
            title: 'homeLanguage'.tr,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _LanguageChip(
                  label: 'languageEnglish'.tr,
                  selected: selectedLanguage == 'en',
                  onTap: () => Get.updateLocale(const Locale('en')),
                ),
                _LanguageChip(
                  label: 'languageVietnamese'.tr,
                  selected: selectedLanguage == 'vi',
                  onTap: () => Get.updateLocale(const Locale('vi')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SettingsSection(
            title: 'settingsAutoActionTitle'.tr,
            child: Obx(
              () => SwitchListTile.adaptive(
                value: controller.autoActionEnabled.value,
                onChanged: controller.setAutoActionEnabled,
                title: Text(
                  'settingsAutoActionEnable'.tr,
                  style: GoogleFonts.rajdhani(
                    color: _kTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  'settingsAutoActionSubtitle'.tr,
                  style: GoogleFonts.rajdhani(
                    color: _kTextSecondary,
                    fontSize: 13,
                  ),
                ),
                activeThumbColor: _kGold,
                activeTrackColor: _kGold.withValues(alpha: 0.32),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SettingsSection(
            title: 'settingsTableInfoTitle'.tr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SettingsMetaRow(
                  label: 'settingsRoomCode'.tr,
                  value: controller.roomCode.toUpperCase(),
                ),
                const SizedBox(height: 8),
                _SettingsMetaRow(
                  label: 'settingsPlayers'.tr,
                  value: '${room.players.length}',
                ),
                const SizedBox(height: 8),
                _SettingsMetaRow(
                  label: 'settingsPhase'.tr,
                  value: room.phase.name.toUpperCase(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: controller.endGame,
            icon: const Icon(Icons.logout_rounded),
            label: Text('gameEndGame'.tr),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kRed,
              side: BorderSide(color: _kRed.withValues(alpha: (0.45))),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _InfoHeader({required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kGold.withValues(alpha: (0.12)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kGold.withValues(alpha: (0.3))),
            ),
            child: Icon(icon, color: _kGold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.rajdhani(
                    color: _kTextPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.rajdhani(
                    color: _kTextSecondary,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String body;

  const _InfoCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.rajdhani(
              color: _kGoldLight,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: GoogleFonts.rajdhani(
              color: _kTextPrimary,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.rajdhani(
              color: _kGoldLight,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _kGold.withValues(alpha: (0.14)) : _kSurfaceHigh,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? _kGold : _kBorder),
        ),
        child: Text(
          label,
          style: GoogleFonts.rajdhani(
            color: selected ? _kGoldLight : _kTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SettingsMetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _SettingsMetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.rajdhani(
              color: _kTextSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.rajdhani(
            color: _kTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
