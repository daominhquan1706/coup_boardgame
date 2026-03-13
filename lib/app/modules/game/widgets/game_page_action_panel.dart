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

    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        border:
            compact ? Border.all(color: _kBorder) : const Border(top: BorderSide(color: _kBorder)),
        borderRadius: compact ? BorderRadius.circular(12) : null,
      ),
      child: Column(
        mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MyInfoBar(controller: controller),
          const Divider(height: 1, thickness: 1, color: _kBorder),
          if (compact)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDecisionBanner(context),
                    const SizedBox(height: 10),
                    Expanded(child: _buildPhaseContent()),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDecisionBanner(context),
                  const SizedBox(height: 10),
                  _buildPhaseContent(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDecisionBanner(BuildContext context) {
    final action = room.currentAction;
    final actorName = action == null ? null : controller.displayNameOf(action.source.name);
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: _kSurfaceHigh,
        borderRadius: BorderRadius.circular(8),
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
                        style: GoogleFonts.rajdhani(
                          color: _kTextPrimary,
                          fontSize: 13,
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
                const Icon(Icons.info_outline, size: 14, color: _kTextSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: GoogleFonts.rajdhani(
                      color: _kTextPrimary,
                      fontSize: 13,
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
    );
  }

  Widget _buildWaitingIndicator() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: _kTextSecondary),
          ),
          const SizedBox(width: 10),
          Text(
            'gameWaitingOthersResponse'.tr,
            style: GoogleFonts.rajdhani(color: _kTextSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseContent() {
    switch (room.phase) {
      case GamePhase.action:
        return controller.isMyTurn
            ? _ActionButtons(controller: controller)
            : _buildWaitingIndicator();
      case GamePhase.challenge:
        return controller.canRespondChallenge(room)
            ? _ChallengeButtons(controller: controller)
            : _buildWaitingIndicator();
      case GamePhase.block:
        return controller.canRespondBlock(room)
            ? _BlockButtons(room: room, controller: controller)
            : _buildWaitingIndicator();
      case GamePhase.blockChallenge:
        return controller.canRespondBlockChallenge(room)
            ? _BlockChallengeButtons(controller: controller)
            : _buildWaitingIndicator();
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── My info bar ─────────────────────────────────────────────────────────────
class _MyInfoBar extends StatelessWidget {
  final GameStartController controller;
  const _MyInfoBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final me = controller.mePlayer.value;
    if (me == null) return const SizedBox.shrink();
    final viewport = _GameViewport.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: viewport.isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person, size: 14, color: _kTextSecondary),
                            const SizedBox(width: 5),
                            Text(
                              me.shownName,
                              style: GoogleFonts.rajdhani(
                                color: _kTextPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on_rounded, size: 14, color: _kGold),
                            const SizedBox(width: 4),
                            Text(
                              '${me.coins} ${'coins'.tr}',
                              style: const TextStyle(
                                color: _kGold,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Expanded(child: Container()),
                    Obx(
                      () => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'gameAutoAction'.tr,
                            style: GoogleFonts.rajdhani(
                              color: _kTextSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Switch.adaptive(
                            value: controller.autoActionEnabled.value,
                            activeThumbColor: _kGold,
                            activeTrackColor: _kGold.withValues(alpha: 0.35),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            onChanged: controller.setAutoActionEnabled,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: me.cards
                      .map((card) => _CardChip(
                            roleType: card.roleType,
                            isEliminated: card.isRevealed,
                          ))
                      .toList(),
                ),
              ],
            )
          : Row(
              children: [
                const Icon(Icons.person, size: 14, color: _kTextSecondary),
                const SizedBox(width: 5),
                Text(
                  me.shownName,
                  style: GoogleFonts.rajdhani(
                      color: _kTextPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 14),
                const Icon(Icons.monetization_on_rounded, size: 14, color: _kGold),
                const SizedBox(width: 4),
                Text(
                  '${me.coins} ${'coins'.tr}',
                  style: const TextStyle(color: _kGold, fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 16),
                ...me.cards.map((card) => Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: _CardChip(
                        roleType: card.roleType,
                        isEliminated: card.isRevealed,
                      ),
                    )),
                const Spacer(),
                Obx(
                  () => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'gameAutoAction'.tr,
                        style: GoogleFonts.rajdhani(
                          color: _kTextSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Switch.adaptive(
                        value: controller.autoActionEnabled.value,
                        activeThumbColor: _kGold,
                        activeTrackColor: _kGold.withValues(alpha: 0.35),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: controller.setAutoActionEnabled,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _CardChip extends StatelessWidget {
  final CoupRoleType roleType;
  final bool isEliminated;
  const _CardChip({required this.roleType, required this.isEliminated});

  @override
  Widget build(BuildContext context) {
    final color = CardWidget.roleColor(roleType);
    return Opacity(
      opacity: isEliminated ? 0.4 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: (0.15)),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: (0.5)), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(roleType.icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              roleType.name,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            if (isEliminated) ...[
              const SizedBox(width: 4),
              Text('✕', style: TextStyle(color: color.withValues(alpha: (0.6)), fontSize: 9)),
            ],
          ],
        ),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = _GameViewport.of(context);
        // Force seven columns so all 7 action buttons sit on a single row
        const columns = 7;
        const spacing = 8.0;
        final tileWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        final options = CoupFunction.normalAction().map((action) {
          var enabled = controller.canAct;
          if (action == CoupActionType.assassin && coins < 3) enabled = false;
          if (action == CoupActionType.coup && coins < 7) enabled = false;
          if (coins >= 10 && action != CoupActionType.coup) enabled = false;
          return (action: action, enabled: enabled);
        }).toList()
          ..sort((a, b) {
            if (a.enabled == b.enabled) return a.action.index.compareTo(b.action.index);
            return a.enabled ? -1 : 1;
          });

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: options.map((option) {
            final action = option.action;

            return SizedBox(
              width: tileWidth,
              child: _ActionTile(
                action: action,
                coins: coins,
                enabled: option.enabled,
                compact: viewport.isMobile,
                onTap: () => controller.performAction(action),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  final CoupActionType action;
  final int coins;
  final bool enabled;
  final bool compact;
  final VoidCallback onTap;

  const _ActionTile({
    required this.action,
    required this.coins,
    required this.enabled,
    this.compact = false,
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
      case CoupActionType.foreignAid:
        return 'Aid';
      case CoupActionType.assassin:
        return 'Assassin';
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

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: enabled ? color.withValues(alpha: (0.15)) : _kSurfaceHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? color.withValues(alpha: (0.60)) : _kBorder,
            width: enabled ? 1.2 : 1,
          ),
          boxShadow: enabled ? [BoxShadow(color: color.withValues(alpha: (0.14)), blurRadius: 10)] : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(_icon, size: 20, color: color),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _compactLabel,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
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
    const challengeColor = Color(0xFFD97706);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'gameChallengeQuestion'.tr,
          style: GoogleFonts.rajdhani(color: _kTextSecondary, fontSize: 12, letterSpacing: 0.5),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: controller.challengeAction,
          child: Container(
            height: 110,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [challengeColor.withValues(alpha: (0.22)), challengeColor.withValues(alpha: (0.07))],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: challengeColor.withValues(alpha: (0.75)), width: 1.5),
              boxShadow: [BoxShadow(color: challengeColor.withValues(alpha: (0.20)), blurRadius: 20)],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gavel_rounded, size: 36, color: challengeColor),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'gameChallenge'.tr.toUpperCase(),
                    style: const TextStyle(
                      color: challengeColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'gameCallBluff'.tr,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: challengeColor.withValues(alpha: (0.75)),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: controller.passChallenge,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _kSurfaceHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'gamePass'.tr.toUpperCase(),
                  style: GoogleFonts.rajdhani(
                    color: _kTextSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'gameBlockQuestion'.tr,
          style: GoogleFonts.rajdhani(color: _kTextSecondary, fontSize: 12, letterSpacing: 0.5),
        ),
        const SizedBox(height: 10),
        if (blockRoles.isNotEmpty)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(blockRoles.length, (i) {
                final role = blockRoles[i];
                final roleType =
                    CoupRoleType.values.firstWhereOrNull((r) => r.firestoreValue == role);
                final color = CardWidget.roleColor(roleType);
                final label = '${role[0].toUpperCase()}${role.substring(1)}';
                return Expanded(
                  child: GestureDetector(
                    onTap: () => controller.blockAction(role),
                    child: Container(
                      margin: EdgeInsets.only(right: i < blockRoles.length - 1 ? 10 : 0),
                      constraints: const BoxConstraints(minHeight: 110),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [color.withValues(alpha: (0.22)), color.withValues(alpha: (0.07))],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: color.withValues(alpha: (0.75)), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: color.withValues(alpha: (0.22)), blurRadius: 20),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(roleType?.icon ?? Icons.shield_rounded, size: 36, color: color),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              label.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: color,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'gameClaimRole'.trParams({'role': label}),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: color.withValues(alpha: (0.70)),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: controller.passBlockOpportunity,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _kSurfaceHigh,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'gamePass'.tr.toUpperCase(),
                        style: GoogleFonts.rajdhani(
                          color: _kTextSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
    const blockChallengeColor = Color(0xFFDC2626);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'gameBlockChallengeQuestion'.tr,
          style: GoogleFonts.rajdhani(color: _kTextSecondary, fontSize: 12, letterSpacing: 0.5),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: controller.challengeBlock,
          child: Container(
            height: 110,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  blockChallengeColor.withValues(alpha: (0.22)),
                  blockChallengeColor.withValues(alpha: (0.07))
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: blockChallengeColor.withValues(alpha: (0.75)), width: 1.5),
              boxShadow: [BoxShadow(color: blockChallengeColor.withValues(alpha: (0.20)), blurRadius: 20)],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gavel_rounded, size: 36, color: blockChallengeColor),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'gameChallengeBlock'.tr.toUpperCase(),
                    style: const TextStyle(
                      color: blockChallengeColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'gameCallBluff'.tr,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: blockChallengeColor.withValues(alpha: (0.75)),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: controller.passBlockChallenge,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _kSurfaceHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'gameAcceptBlock'.tr.toUpperCase(),
                  style: GoogleFonts.rajdhani(
                    color: _kTextSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
