part of '../page.dart';

// ─── Action panel ─────────────────────────────────────────────────────────
class _ActionPanel extends StatelessWidget {
  final CoupRoomModel room;
  final GameStartController controller;
  final bool compact;

  const _ActionPanel(
      {required this.room, required this.controller, this.compact = false});

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
    final actorName =
        action == null ? null : controller.displayNameOf(action.source.name);
    final actionLabel =
        action?.actionType.firestoreType.replaceAll('_', ' ').toUpperCase();
    final viewport = _GameViewport.of(context);

    String text;
    final phase = room.phase;
    if (phase == GamePhase.action) {
      text = controller.isMyTurn
          ? 'gameYourTurnChooseAction'.tr
          : 'gameWaitingFor'
              .trParams({'name': controller.displayNameOf(room.currentTurn)});
    } else if (phase == GamePhase.challenge && action != null) {
      text = controller.canRespondChallenge(room)
          ? 'gameRespondChallengePrompt'
              .trParams({'actor': actorName ?? '', 'action': actionLabel ?? ''})
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
                      const Icon(Icons.info_outline,
                          size: 14, color: _kTextSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          text,
                          style: GoogleFonts.rajdhani(
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
                      style: GoogleFonts.rajdhani(
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
                  const Icon(Icons.info_outline,
                      size: 14, color: _kTextSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      text,
                      style: GoogleFonts.rajdhani(
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
                      style: GoogleFonts.rajdhani(
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

  Widget _buildWaitingIndicator() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
                strokeWidth: 1.4, color: _kTextSecondary),
          ),
          const SizedBox(width: 8),
          Text(
            'gameWaitingOthersResponse'.tr,
            style: GoogleFonts.rajdhani(color: _kTextSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseContent() {
    Widget content;
    switch (room.phase) {
      case GamePhase.action:
        content = controller.isMyTurn
            ? _ActionButtons(controller: controller)
            : _buildWaitingIndicator();
        break;
      case GamePhase.challenge:
        content = controller.canRespondChallenge(room)
            ? _ChallengeButtons(controller: controller)
            : _buildWaitingIndicator();
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
    final me = controller.mePlayer.value;
    final coins = me?.coins ?? 0;
    final hiddenRoles = me == null
        ? <CoupRoleType>{}
        : me.cards
            .where((card) => !card.isRevealed)
            .map((card) => card.roleType)
            .toSet();

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = _GameViewport.of(context);
        const spacing = 6.0;
        final minChipWidth = viewport.isPhone ? 84.0 : 92.0;
        final chipWidth = ((constraints.maxWidth - (spacing * 3)) / 4)
            .clamp(minChipWidth, viewport.isPhone ? 96.0 : 108.0)
            .toDouble();
        const compactTile = true;
        final tileHeight = viewport.isPhone ? 40.0 : 44.0;

        final options = CoupFunction.normalAction().map((action) {
          var enabled = controller.canAct;
          if (action == CoupActionType.assassin && coins < 3) enabled = false;
          if (action == CoupActionType.coup && coins < 7) enabled = false;
          if (coins >= 10 && action != CoupActionType.coup) enabled = false;
          final claimedRole = action.claimedRole;
          final isFakeAction =
              claimedRole != null && !hiddenRoles.contains(claimedRole);
          return (action: action, enabled: enabled, isFakeAction: isFakeAction);
        }).toList()
          ..sort((a, b) {
            if (a.enabled == b.enabled) {
              return a.action.index.compareTo(b.action.index);
            }
            return a.enabled ? -1 : 1;
          });

        return SizedBox(
          height: tileHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: options.length,
            separatorBuilder: (_, __) => const SizedBox(width: spacing),
            itemBuilder: (context, index) {
              final option = options[index];
              final action = option.action;

              return SizedBox(
                width: chipWidth,
                child: _ActionTile(
                  action: action,
                  enabled: option.enabled,
                  compact: compactTile,
                  height: tileHeight,
                  showFakeBadge: option.isFakeAction,
                  onTap: () => controller.performAction(action),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  final CoupActionType action;
  final bool enabled;
  final bool compact;
  final double height;
  final bool showFakeBadge;
  final VoidCallback onTap;

  const _ActionTile({
    required this.action,
    required this.enabled,
    this.compact = false,
    this.height = 60,
    this.showFakeBadge = false,
    required this.onTap,
  });

  String get _label {
    switch (action) {
      case CoupActionType.income:
        return 'actionIncome'.tr;
      case CoupActionType.foreignAid:
        return 'actionForeignAid'.tr;
      case CoupActionType.coup:
        return 'actionCoup'.tr;
      case CoupActionType.duke:
        return 'actionTax'.tr;
      case CoupActionType.assassin:
        return 'actionAssassinate'.tr;
      case CoupActionType.captain:
        return 'actionSteal'.tr;
      case CoupActionType.ambassador:
        return 'actionExchange'.tr;
      default:
        return action.firestoreType;
    }
  }

  String get _compactLabel {
    switch (action) {
      case CoupActionType.income:
        return 'Income';
      case CoupActionType.foreignAid:
        return 'Aid';
      case CoupActionType.coup:
        return 'Coup';
      case CoupActionType.duke:
        return 'Tax';
      case CoupActionType.assassin:
        return 'Assassin';
      case CoupActionType.captain:
        return 'Steal';
      case CoupActionType.ambassador:
        return 'Swap';
      default:
        return _label;
    }
  }

  IconData get _icon {
    switch (action) {
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
    switch (action) {
      case CoupActionType.income:
        return const Color(0xFF059669);
      case CoupActionType.foreignAid:
        return const Color(0xFF0891B2);
      case CoupActionType.coup:
        return const Color(0xFFDC2626);
      default:
        final role = action.claimedRole;
        return CardWidget.roleColor(role);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = enabled ? _color : _kTextSecondary;
    final label = _compactLabel;

    return _GamePressable(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: BoxConstraints(minHeight: height, maxHeight: height),
        padding:
            EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 0),
        decoration: BoxDecoration(
          color: enabled ? color.withValues(alpha: (0.15)) : _kSurfaceHigh,
          borderRadius: BorderRadius.circular(compact ? 11 : 12),
          border: Border.all(
            color: enabled ? color.withValues(alpha: (0.60)) : _kBorder,
            width: enabled ? 1.2 : 1,
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: (0.12)), blurRadius: 8)
                ]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(_icon, size: compact ? 14 : 15, color: color),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: color,
                        fontSize: compact ? 10 : 11,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (showFakeBadge)
              Positioned(
                top: -1,
                right: -1,
                child: Container(
                  width: compact ? 14 : 16,
                  height: compact ? 14 : 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: const Color(0xFF3E2A06), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color:
                            const Color(0xFFF59E0B).withValues(alpha: (0.34)),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '!',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: (0.85)),
                      fontSize: compact ? 9.5 : 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
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
            toneColor: const Color(0xFFD97706),
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
      final roleType =
          CoupRoleType.values.firstWhereOrNull((r) => r.firestoreValue == role);
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
            toneColor: const Color(0xFFDC2626),
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
          color:
              accent == null ? _kSurfaceHigh : accent.withValues(alpha: (0.15)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: accent == null ? _kBorder : accent.withValues(alpha: (0.60)),
            width: accent == null ? 1 : 1.2,
          ),
          boxShadow: accent == null
              ? null
              : [
                  BoxShadow(
                      color: accent.withValues(alpha: (0.12)), blurRadius: 8)
                ],
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
                style: GoogleFonts.rajdhani(
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
