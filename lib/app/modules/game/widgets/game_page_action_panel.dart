part of '../page.dart';

// ─── Action panel ─────────────────────────────────────────────────────────
class _ActionPanel extends StatelessWidget {
  final CoupRoomModel room;
  final GameStartController controller;
  final bool compact;

  const _ActionPanel({required this.room, required this.controller, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (room.roomState == GameState.finished) return const SizedBox.shrink();

    final panelRadius = BorderRadius.circular(compact ? 16 : 18);
    final phaseContentHeight = _phaseContentHeight(context);

    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        border: Border.all(color: _kBorder),
        borderRadius: panelRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDecisionBanner(context),
            const SizedBox(height: 8),
            SizedBox(height: phaseContentHeight, child: _buildPhaseContent()),
          ],
        ),
      ),
    );
  }

  double _phaseContentHeight(BuildContext context) {
    final viewport = _GameViewport.of(context);
    return viewport.isPhone ? 42 : 46;
  }

  Widget _buildDecisionBanner(BuildContext context) {
    final action = room.currentAction;
    final actorName = action == null ? null : controller.displayNameOf(action.source.name);
    final targetId = action?.target?.name;
    final targetName =
        targetId == null || targetId.isEmpty ? null : controller.displayNameOf(targetId);
    final actionLabel = action?.actionType.firestoreType.replaceAll('_', ' ').toUpperCase();
    final viewport = _GameViewport.of(context);

    String text;
    final phase = room.phase;
    if (phase == GamePhase.action) {
      text = controller.isMyTurn
          ? 'gameYourTurnChooseAction'.tr
          : 'gameWaitingFor'.trParams({'name': controller.displayNameOf(room.currentTurn)});
    } else if (phase == GamePhase.challenge && action != null) {
      text = controller.canRespondChallenge(room)
          ? ((targetName != null && targetName.isNotEmpty)
              ? 'gameRespondChallengePromptTarget'.trParams({
                  'actor': actorName ?? '',
                  'action': actionLabel ?? '',
                  'target': targetName,
                })
              : 'gameRespondChallengePrompt'
                  .trParams({'actor': actorName ?? '', 'action': actionLabel ?? ''}))
          : 'gameWaitingOthersResponse'.tr;
    } else if (phase == GamePhase.block && action != null) {
      text = controller.canRespondBlock(room)
          ? 'gameRespondBlockPrompt'
              .trParams({'actor': actorName ?? '', 'action': actionLabel ?? ''})
          : 'gameWaitingOthersResponse'.tr;
    } else if (phase == GamePhase.blockChallenge && action != null) {
      text = controller.canRespondBlockChallenge(room)
          ? 'gameRespondBlockChallengePrompt'
              .trParams({'actor': actorName ?? '', 'action': actionLabel ?? ''})
          : 'gameWaitingOthersResponse'.tr;
    } else {
      text = 'gameWaitingOthersResponse'.tr;
    }

    return AnimatedSwitcher(
      duration: _kEmphasisMotion,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.035),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(
          '${room.phase.name}-${room.currentAction?.actionType.firestoreType ?? 'idle'}-'
          '${controller.isMyTurn}-${controller.canRespondChallenge(room)}-'
          '${controller.canRespondBlock(room)}-${controller.canRespondBlockChallenge(room)}',
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: _kSurfaceHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
        ),
        child: viewport.isPhone
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 14, color: _kTextSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          text,
                          style: GoogleFonts.nunito(
                            color: _kTextPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Obx(() {
                    final count = controller.autoActionCountdown.value;
                    if (count <= 0) return const SizedBox.shrink();
                    return Text(
                      'gameAutoIn'.trParams({'sec': '$count'}),
                      style: GoogleFonts.nunito(
                        color: _kGold,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  }),
                ],
              )
            : Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: _kTextSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      text,
                      style: GoogleFonts.nunito(
                        color: _kTextPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Obx(() {
                    final count = controller.autoActionCountdown.value;
                    if (count <= 0) return const SizedBox.shrink();
                    return Text(
                      ' ${'gameAutoIn'.trParams({'sec': '$count'})}',
                      style: GoogleFonts.nunito(
                        color: _kGold,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }

  Widget _buildWaitingIndicator({String? message}) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.4, color: _kTextSecondary),
          ),
          const SizedBox(width: 8),
          Text(
            message ?? 'gameWaitingOthersResponse'.tr,
            style: GoogleFonts.nunito(color: _kTextSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseContent() {
    Widget content;
    switch (room.phase) {
      case GamePhase.action:
        content =
            controller.isMyTurn ? _ActionButtons(controller: controller) : _buildWaitingIndicator();
        break;
      case GamePhase.challenge:
        content = controller.canRespondChallenge(room)
            ? _ChallengeButtons(controller: controller)
            : _buildWaitingIndicator(
                message: 'gameWaitingOthersChallenge'.tr,
              );
        break;
      case GamePhase.block:
        content = controller.canRespondBlock(room)
            ? _BlockButtons(room: room, controller: controller)
            : _buildWaitingIndicator();
        break;
      case GamePhase.blockChallenge:
        content = controller.canRespondBlockChallenge(room)
            ? _BlockChallengeButtons(controller: controller)
            : _buildWaitingIndicator();
        break;
      default:
        content = const SizedBox.shrink();
        break;
    }

    return AnimatedSwitcher(
      duration: _kEmphasisMotion,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(
          '${room.phase.name}-${controller.isMyTurn}-${controller.canRespondChallenge(room)}-'
          '${controller.canRespondBlock(room)}-${controller.canRespondBlockChallenge(room)}',
        ),
        child: content,
      ),
    );
  }
}

// ─── Action phase buttons ─────────────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  final GameStartController controller;
  const _ActionButtons({required this.controller});

  @override
  Widget build(BuildContext context) {
    final options = _actionOptions(controller);
    return _GamePressable(
      onTap: () => _openActionsSheet(context, options),
      child: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          color: _kGold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kGold.withValues(alpha: 0.45), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: _kGold.withValues(alpha: 0.12),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bolt_rounded, color: _kGoldLight, size: 16),
            const SizedBox(width: 8),
            Text(
              'gameOpenActions'.tr,
              style: GoogleFonts.nunito(
                color: _kGoldLight,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_ActionOption> _actionOptions(GameStartController controller) {
    final me = controller.mePlayer.value;
    final coins = me?.coins ?? 0;
    final hiddenRoles = me == null
        ? <CoupRoleType>{}
        : me.cards.where((card) => !card.isRevealed).map((card) => card.roleType).toSet();

    return CoupFunction.normalAction().map((action) {
      var enabled = controller.canAct;
      if (action == CoupActionType.assassin && coins < 3) enabled = false;
      if (action == CoupActionType.coup && coins < 7) enabled = false;
      if (coins >= 10 && action != CoupActionType.coup) enabled = false;
      final claimedRole = action.claimedRole;
      final isFakeAction = claimedRole != null && !hiddenRoles.contains(claimedRole);
      return _ActionOption(
        action: action,
        enabled: enabled,
        isFakeAction: isFakeAction,
      );
    }).toList()
      ..sort((a, b) {
        if (a.enabled == b.enabled) {
          return a.action.index.compareTo(b.action.index);
        }
        return a.enabled ? -1 : 1;
      });
  }

  Future<void> _openActionsSheet(BuildContext context, List<_ActionOption> options) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (sheetContext) {
        final width = MediaQuery.sizeOf(sheetContext).width;
        final sheetMaxWidth = width >= 1500
            ? 1160.0
            : width >= 1280
                ? 1060.0
                : width >= 960
                    ? 920.0
                    : width;
        final crossAxisCount = width >= 1280
            ? 4
            : width >= 900
                ? 3
                : 2;
        final tileHeight = width < 640 ? 104.0 : 96.0;
        final enabledOptions = options.where((o) => o.enabled).toList();
        final disabledOptions = options.where((o) => !o.enabled).toList();
        final myCards = controller.mePlayer.value?.cards ?? const <CoupCardModel>[];

        Widget buildSection({
          required String title,
          required List<_ActionOption> sectionOptions,
          required Color titleColor,
          required IconData icon,
        }) {
          return Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            decoration: BoxDecoration(
              color: _kSurfaceHigh.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder.withValues(alpha: 0.8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 15, color: titleColor),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        color: titleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  itemCount: sectionOptions.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 9,
                    mainAxisSpacing: 9,
                    mainAxisExtent: tileHeight,
                  ),
                  itemBuilder: (_, index) {
                    final option = sectionOptions[index];
                    return _ActionTile(
                      action: option.action,
                      enabled: option.enabled,
                      showFakeBadge: option.isFakeAction,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        controller.performAction(option.action);
                      },
                    );
                  },
                ),
              ],
            ),
          );
        }

        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: sheetMaxWidth),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: _kBorder.withValues(alpha: 0.9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A254A),
                    Color(0xFF1B274F),
                    Color(0xFF182347),
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _kBorder,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kBorder.withValues(alpha: 0.85)),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _kGold.withValues(alpha: 0.10),
                          AppColors.kBlueLight.withValues(alpha: 0.12),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _kGold.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: _kGold.withValues(alpha: 0.45)),
                          ),
                          child:
                              const Icon(Icons.auto_awesome_rounded, color: _kGoldLight, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'gameOpenActions'.tr,
                                style: GoogleFonts.nunito(
                                  color: _kTextPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              Text(
                                'gameYourTurnChooseAction'.tr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(
                                  color: _kTextSecondary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _MyCardsPreview(cards: myCards),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (enabledOptions.isNotEmpty)
                    buildSection(
                      title: 'gameActionAvailable'.tr,
                      sectionOptions: enabledOptions,
                      titleColor: AppColors.greenLight,
                      icon: Icons.check_circle_rounded,
                    ),
                  if (disabledOptions.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    buildSection(
                      title: 'gameActionDisabled'.tr,
                      sectionOptions: disabledOptions,
                      titleColor: _kTextSecondary,
                      icon: Icons.lock_rounded,
                    ),
                  ],
                  if (enabledOptions.isEmpty && disabledOptions.isEmpty)
                    Text(
                      'gameNoActions'.tr,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color: _kTextSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    'gameActionSectionHint'.tr,
                    style: GoogleFonts.nunito(
                      color: _kTextSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MyCardsPreview extends StatelessWidget {
  final List<CoupCardModel> cards;

  const _MyCardsPreview({required this.cards});

  @override
  Widget build(BuildContext context) {
    final previewCards = cards.isEmpty ? [null, null] : List<CoupCardModel?>.from(cards);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: _kSurface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder.withValues(alpha: 0.9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'gameYourCards'.tr,
            style: GoogleFonts.nunito(
              color: _kTextSecondary,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < previewCards.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                SizedBox(
                  width: 33,
                  height: 48,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: CardWidget(
                      roleType: previewCards[i]?.roleType,
                      isHidden: previewCards[i] == null,
                      isEliminated: previewCards[i]?.isRevealed ?? false,
                      small: true,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionOption {
  final CoupActionType action;
  final bool enabled;
  final bool isFakeAction;

  const _ActionOption({
    required this.action,
    required this.enabled,
    required this.isFakeAction,
  });
}

class _ActionTile extends StatefulWidget {
  final CoupActionType action;
  final bool enabled;
  final bool showFakeBadge;
  final VoidCallback onTap;

  const _ActionTile({
    required this.action,
    required this.enabled,
    this.showFakeBadge = false,
    required this.onTap,
  });

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _hovered = false;

  String get _label {
    final isCompact = MediaQuery.sizeOf(context).width < 640;
    switch (widget.action) {
      case CoupActionType.income:
        return 'actionIncome'.tr;
      case CoupActionType.foreignAid:
        return isCompact ? 'Aid' : 'actionForeignAid'.tr;
      case CoupActionType.coup:
        return 'actionCoup'.tr;
      case CoupActionType.duke:
        return 'actionTax'.tr;
      case CoupActionType.assassin:
        return isCompact ? 'Assassin' : 'actionAssassinate'.tr;
      case CoupActionType.captain:
        return 'actionSteal'.tr;
      case CoupActionType.ambassador:
        return isCompact ? 'Swap' : 'actionExchange'.tr;
      default:
        return widget.action.firestoreType;
    }
  }

  String get _description {
    switch (widget.action) {
      case CoupActionType.income:
        return 'actionIncomeDesc'.tr;
      case CoupActionType.foreignAid:
        return 'actionForeignAidDesc'.tr;
      case CoupActionType.coup:
        return 'actionCoupDesc'.tr;
      case CoupActionType.duke:
        return 'actionTaxDesc'.tr;
      case CoupActionType.assassin:
        return 'actionAssassinateDesc'.tr;
      case CoupActionType.captain:
        return 'actionStealDesc'.tr;
      case CoupActionType.ambassador:
        return 'actionExchangeDesc'.tr;
      default:
        return '';
    }
  }

  IconData get _icon {
    switch (widget.action) {
      case CoupActionType.income:
        return Icons.savings_rounded;
      case CoupActionType.foreignAid:
        return Icons.public_rounded;
      case CoupActionType.coup:
        return Icons.gavel_rounded;
      case CoupActionType.duke:
        return Icons.account_balance_rounded;
      case CoupActionType.assassin:
        return Icons.flash_on_rounded;
      case CoupActionType.captain:
        return Icons.paid_rounded;
      case CoupActionType.ambassador:
        return Icons.swap_horiz_rounded;
      default:
        return Icons.play_arrow_rounded;
    }
  }

  Color get _color {
    switch (widget.action) {
      case CoupActionType.income:
        return AppColors.greenEmeraldDark;
      case CoupActionType.foreignAid:
        return AppColors.greenTeal;
      case CoupActionType.coup:
        return AppColors.redError;
      case CoupActionType.assassin:
        return AppColors.assassinAccent;
      default:
        final role = widget.action.claimedRole;
        return CardWidget.roleColor(role);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    final color = enabled ? _color : _kTextSecondary;
    final desc = _description;
    final scale = _hovered && enabled ? 1.018 : 1.0;
    final cardTop = enabled ? color.withValues(alpha: 0.18) : _kSurfaceHigh.withValues(alpha: 0.85);
    final cardBottom =
        enabled ? color.withValues(alpha: 0.10) : _kSurfaceHigh.withValues(alpha: 0.65);
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        scale: scale,
        child: _GamePressable(
          onTap: enabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.fromLTRB(9, 7, 9, 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cardTop, cardBottom],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: enabled ? color.withValues(alpha: 0.60) : _kBorder,
                width: enabled ? 1.2 : 1,
              ),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: _hovered ? 0.30 : 0.16),
                        blurRadius: _hovered ? 18 : 12,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: color.withValues(alpha: 0.32)),
                          ),
                          child: Icon(_icon, size: 13, color: color),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              color: color,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        color: enabled ? _kTextPrimary.withValues(alpha: 0.88) : _kTextSecondary,
                        fontSize: 10.9,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        if (_costTag != null) _metaTag(_costTag!, color),
                        if (_needTargetTag != null) ...[
                          const SizedBox(width: 4),
                          _metaTag(_needTargetTag!, color),
                        ],
                        if (_claimTag != null) ...[
                          const SizedBox(width: 4),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _metaTag(_claimTag!, color, rightAligned: true),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                if (widget.showFakeBadge)
                  Positioned(
                    top: -1,
                    right: -1,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.kGoldAmber,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.kGoldAmberDark, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.kGoldAmber.withValues(alpha: 0.34),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '!',
                        style: TextStyle(
                          color: AppColors.black.withValues(alpha: 0.85),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? get _costTag {
    switch (widget.action) {
      case CoupActionType.income:
        return '+1';
      case CoupActionType.foreignAid:
        return '+2';
      case CoupActionType.duke:
        return '+3';
      case CoupActionType.assassin:
        return '-3';
      case CoupActionType.coup:
        return '-7';
      default:
        return null;
    }
  }

  String? get _needTargetTag => CoupFunction.isNeedPlayerTarget(widget.action) ? 'Target' : null;

  String? get _claimTag {
    final role = widget.action.claimedRole;
    if (role == null) return null;
    return role.localizedName;
  }

  Widget _metaTag(String text, Color color, {bool rightAligned = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: rightAligned ? TextAlign.right : TextAlign.left,
        style: GoogleFonts.nunito(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

// ─── Challenge phase buttons ──────────────────────────────────────────────────
class _ChallengeButtons extends StatelessWidget {
  final GameStartController controller;
  const _ChallengeButtons({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PhaseActionButton(
            label: 'gameChallenge'.tr.toUpperCase(),
            icon: Icons.gavel_rounded,
            toneColor: AppColors.kGoldDark,
            onTap: controller.challengeAction,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PhaseActionButton(
            label: 'gamePass'.tr.toUpperCase(),
            icon: Icons.close_rounded,
            onTap: controller.passChallenge,
          ),
        ),
      ],
    );
  }
}

// ─── Block phase buttons ──────────────────────────────────────────────────────
class _BlockButtons extends StatelessWidget {
  final CoupRoomModel room;
  final GameStartController controller;
  const _BlockButtons({required this.room, required this.controller});

  @override
  Widget build(BuildContext context) {
    final action = room.currentAction?.actionType;
    final blockRoles = <String>[];

    if (action == CoupActionType.foreignAid) {
      blockRoles.add('duke');
    } else if (action == CoupActionType.assassin) {
      blockRoles.add('contessa');
    } else if (action == CoupActionType.captain) {
      blockRoles.addAll(['captain', 'ambassador']);
    }

    final buttons = <Widget>[];
    for (final role in blockRoles) {
      final roleType = CoupRoleType.values.firstWhereOrNull((r) => r.firestoreValue == role);
      buttons.add(
        Expanded(
          child: _PhaseActionButton(
            label: (roleType?.localizedName ?? role).toUpperCase(),
            icon: roleType?.icon ?? Icons.shield_rounded,
            toneColor: CardWidget.roleColor(roleType),
            onTap: () => controller.blockAction(role),
          ),
        ),
      );
    }

    buttons.add(
      Expanded(
        child: _PhaseActionButton(
          label: 'gamePass'.tr.toUpperCase(),
          icon: Icons.close_rounded,
          onTap: () => controller.passBlockOpportunity(),
        ),
      ),
    );

    final gap = buttons.length > 2 ? 6.0 : 8.0;

    return Row(
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          buttons[i],
        ],
      ],
    );
  }
}

// ─── Block-challenge phase buttons ────────────────────────────────────────────
class _BlockChallengeButtons extends StatelessWidget {
  final GameStartController controller;
  const _BlockChallengeButtons({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PhaseActionButton(
            label: 'gameChallengeBlock'.tr.toUpperCase(),
            icon: Icons.gavel_rounded,
            toneColor: AppColors.redError,
            onTap: controller.challengeBlock,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PhaseActionButton(
            label: 'gameAcceptBlock'.tr.toUpperCase(),
            icon: Icons.check_rounded,
            onTap: controller.passBlockChallenge,
          ),
        ),
      ],
    );
  }
}

class _PhaseActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? toneColor;
  final VoidCallback onTap;

  const _PhaseActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.toneColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = toneColor;
    final textColor = accent ?? _kTextSecondary;

    return _GamePressable(
      onTap: onTap,
      child: Container(
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: accent == null ? _kSurfaceHigh : accent.withValues(alpha: (0.15)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: accent == null ? _kBorder : accent.withValues(alpha: (0.60)),
            width: accent == null ? 1 : 1.2,
          ),
          boxShadow: accent == null
              ? null
              : [BoxShadow(color: accent.withValues(alpha: (0.12)), blurRadius: 8)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: textColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: textColor,
                  fontSize: 10.5,
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
