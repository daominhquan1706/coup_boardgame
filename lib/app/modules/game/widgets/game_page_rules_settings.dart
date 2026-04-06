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

  List<({String title, String body, CoupRoleType? roleType})> _roleSections() {
    return const [
      (title: 'rulesDukeTitle', body: 'rulesDukeBody', roleType: CoupRoleType.duke),
      (title: 'rulesAssassinTitle', body: 'rulesAssassinBody', roleType: CoupRoleType.assassin),
      (title: 'rulesCaptainTitle', body: 'rulesCaptainBody', roleType: CoupRoleType.captain),
      (
        title: 'rulesAmbassadorTitle',
        body: 'rulesAmbassadorBody',
        roleType: CoupRoleType.ambassador
      ),
      (title: 'rulesContessaTitle', body: 'rulesContessaBody', roleType: CoupRoleType.contessa),
      (title: 'rulesChallengeTitle', body: 'rulesChallengeBody', roleType: null),
      (title: 'rulesBlockTitle', body: 'rulesBlockBody', roleType: null),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections();
    final roleSections = _roleSections();
    final viewport = _GameViewport.of(context);
    final isWide = !viewport.isCompact; // >= 1040px
    final isMobile = viewport.isMobile; // < 720px

    final crossAxisCount = isWide ? 2 : 1;
    final mainAxisSpacing = isMobile ? 8.0 : 10.0;
    final crossAxisSpacing = isMobile ? 8.0 : 10.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 10 : 14,
        10,
        isMobile ? 10 : 14,
        14,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 1100 : double.infinity),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── General Rules Header ──
              _InfoHeader(
                title: 'rulesHeaderTitle'.tr,
                subtitle: 'rulesHeaderSubtitle'.tr,
                icon: Icons.menu_book_rounded,
              ),
              const SizedBox(height: 10),

              // ── General Rules Grid ──
              _ResponsiveGrid(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: mainAxisSpacing,
                crossAxisSpacing: crossAxisSpacing,
                children:
                    sections.map((s) => _InfoCard(title: s.title.tr, body: s.body.tr)).toList(),
              ),

              const SizedBox(height: 12),

              // ── Roles Header ──
              _InfoHeader(
                title: 'rulesRolesTitle'.tr,
                subtitle: 'rulesRolesSubtitle'.tr,
                icon: Icons.groups_rounded,
              ),
              const SizedBox(height: 10),

              // ── Roles Grid ──
              _ResponsiveGrid(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: mainAxisSpacing,
                crossAxisSpacing: crossAxisSpacing,
                children: roleSections
                    .map((s) => _RoleCard(
                          title: s.title.tr,
                          body: s.body.tr,
                          roleType: s.roleType,
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A responsive grid that adapts from single column (mobile) to multi-column (web).
class _ResponsiveGrid extends StatelessWidget {
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final List<Widget> children;

  const _ResponsiveGrid({
    required this.crossAxisCount,
    required this.mainAxisSpacing,
    required this.crossAxisSpacing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (crossAxisCount <= 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) SizedBox(height: mainAxisSpacing),
          ],
        ],
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      childAspectRatio: 2.2,
      children: children,
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
    final viewport = _GameViewport.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: viewport.isCompact ? double.infinity : 980),
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
                      style: GoogleFonts.nunito(
                        color: _kTextPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'settingsAutoActionSubtitle'.tr,
                      style: GoogleFonts.nunito(
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
        ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _kGold.withValues(alpha: (0.12)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kGold.withValues(alpha: (0.3))),
            ),
            child: Icon(icon, color: _kGold, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    color: _kTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.nunito(
                    color: _kTextSecondary,
                    fontSize: 13,
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

class _RoleCard extends StatelessWidget {
  final String title;
  final String body;
  final CoupRoleType? roleType;

  const _RoleCard({required this.title, required this.body, this.roleType});

  @override
  Widget build(BuildContext context) {
    final viewport = _GameViewport.of(context);
    final isMobile = viewport.isMobile;
    final cardPadding = isMobile ? 10.0 : 12.0;
    final cardWidth = isMobile ? 48.0 : 56.0;
    final gap = isMobile ? 8.0 : 10.0;
    final titleSize = isMobile ? 14.0 : 16.0;
    final bodySize = isMobile ? 12.0 : 13.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: roleType != null
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: CardWidget(roleType: roleType, small: true),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: _RoleText(
                      title: title,
                      body: body,
                      titleSize: titleSize,
                      bodySize: bodySize,
                      icon: roleType!.icon),
                ),
              ],
            )
          : _RoleText(title: title, body: body, titleSize: titleSize, bodySize: bodySize),
    );
  }
}

class _RoleText extends StatelessWidget {
  final String title;
  final String body;
  final double titleSize;
  final double bodySize;
  final IconData? icon;

  const _RoleText({
    required this.title,
    required this.body,
    required this.titleSize,
    required this.bodySize,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: titleSize * 0.9, color: _kGoldLight),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.nunito(
                  color: _kGoldLight,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          body,
          style: GoogleFonts.nunito(
            color: _kTextPrimary,
            fontSize: bodySize,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String body;

  const _InfoCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final viewport = _GameViewport.of(context);
    final isMobile = viewport.isMobile;
    final padding = isMobile ? 10.0 : 12.0;
    final titleSize = isMobile ? 14.0 : 16.0;
    final bodySize = isMobile ? 12.0 : 13.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: GoogleFonts.nunito(
              color: _kGoldLight,
              fontSize: titleSize,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            body,
            style: GoogleFonts.nunito(
              color: _kTextPrimary,
              fontSize: bodySize,
              height: 1.3,
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
            style: GoogleFonts.nunito(
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
          style: GoogleFonts.nunito(
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
            style: GoogleFonts.nunito(
              color: _kTextSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.nunito(
            color: _kTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
