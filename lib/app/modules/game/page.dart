import 'package:coup_boardgame/app/data/model/firestore_model/coup_action_model.dart';
import 'package:coup_boardgame/app/data/model/game_history_entry.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_player_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_room_model.dart';
import 'package:coup_boardgame/app/modules/game/widgets/card_widget.dart';
import 'package:coup_boardgame/app/routes/app_pages.dart';
import 'package:coup_boardgame/app/utils/functions/coup_function.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import 'controller.dart';

// ─── Design tokens ───────────────────────────────────────────────────────────
const Color _kBg = Color(0xFF0F1728);
const Color _kSurface = Color(0xFF18243E);
const Color _kSurfaceHigh = Color(0xFF1E2D4E);
const Color _kBorder = Color(0xFF2A3A5E);
const Color _kGold = Color(0xFFD4AF37);
const Color _kGoldLight = Color(0xFFEDD97A);
const Color _kTextPrimary = Color(0xFFE8EDF5);
const Color _kTextSecondary = Color(0xFF7A8CA8);
const Color _kRed = Color(0xFFE74C3C);

// ─── Main page ───────────────────────────────────────────────────────────────
class GamePage extends GetView<GameStartController> {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Obx(() {
        final room = controller.currentRoom.value;
        if (room == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: _kGold, strokeWidth: 2),
                const SizedBox(height: 16),
                Text('msgLoadingGame'.tr,
                    style: GoogleFonts.rajdhani(color: _kTextSecondary, fontSize: 14)),
              ],
            ),
          );
        }

        return SafeArea(
          child: Column(
            children: [
              _TopBar(room: room, controller: controller),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PlayerGrid(room: room, controller: controller),
                      const SizedBox(height: 12),
                      _GameStatusCard(room: room, controller: controller),
                    ],
                  ),
                ),
              ),
              Obx(() {
                final entries = controller.historyEntries.toList(growable: false);
                return _HistoryPanel(entries: entries, controller: controller);
              }),
              _ActionPanel(room: room, controller: controller),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Top bar ─────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final CoupRoomModel room;
  final GameStartController controller;

  const _TopBar({required this.room, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      decoration: const BoxDecoration(
        color: _kSurface,
        border: Border(bottom: BorderSide(color: _kBorder, width: 1)),
      ),
      child: Row(
        children: [
          // Logo
          GestureDetector(
            onTap: () => Get.offAllNamed(AppRoutes.home),
            child: Text(
              'COUP',
              style: GoogleFonts.rajdhani(
                color: _kGold,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(width: 1, height: 18, color: _kBorder),
          const SizedBox(width: 14),
          Text(
            'ROOM ${controller.roomCode.toUpperCase()}',
            style: GoogleFonts.rajdhani(
              color: _kTextSecondary,
              fontSize: 13,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _PhaseBadge(phase: room.phase),
          const SizedBox(width: 12),
          if (room.currentTurn != null) ...[
            const Icon(Icons.person_outline, size: 14, color: _kTextSecondary),
            const SizedBox(width: 4),
            Text(
              controller.displayNameOf(room.currentTurn),
              style: GoogleFonts.rajdhani(
                color: _kTextPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 14),
          ],
          TextButton(
            onPressed: controller.endGame,
            style: TextButton.styleFrom(
              foregroundColor: _kRed.withOpacity(0.75),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('gameEndGame'.tr,
                style: GoogleFonts.rajdhani(fontSize: 12, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }
}

// ─── Phase badge ─────────────────────────────────────────────────────────────
class _PhaseBadge extends StatelessWidget {
  final GamePhase phase;
  const _PhaseBadge({required this.phase});

  Color get _color {
    switch (phase) {
      case GamePhase.action:
        return const Color(0xFF3B82F6);
      case GamePhase.challenge:
        return const Color(0xFFD97706);
      case GamePhase.block:
        return const Color(0xFF7C3AED);
      case GamePhase.blockChallenge:
        return const Color(0xFFDC2626);
      default:
        return _kTextSecondary;
    }
  }

  String get _label {
    switch (phase) {
      case GamePhase.action:
        return 'ACTION';
      case GamePhase.challenge:
        return 'CHALLENGE';
      case GamePhase.block:
        return 'BLOCK';
      case GamePhase.blockChallenge:
        return 'BLOCK CHALLENGE';
      case GamePhase.resolve:
        return 'RESOLVING';
      case GamePhase.finished:
        return 'FINISHED';
      default:
        return phase.name.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.45)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ─── Player grid ─────────────────────────────────────────────────────────────
class _PlayerGrid extends StatelessWidget {
  final CoupRoomModel room;
  final GameStartController controller;

  const _PlayerGrid({required this.room, required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 800
          ? 3
          : constraints.maxWidth > 500
              ? 2
              : 1;
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.6,
        children: room.players.map((player) {
          final isMe = player.name == controller.mePlayer.value?.name;
          final isCurrentTurn = player.name == room.currentTurn;
          return _PlayerSeat(player: player, isMe: isMe, isCurrentTurn: isCurrentTurn);
        }).toList(),
      );
    });
  }
}

// ─── Player seat ─────────────────────────────────────────────────────────────
class _PlayerSeat extends StatelessWidget {
  final CoupPlayerModel player;
  final bool isMe;
  final bool isCurrentTurn;

  const _PlayerSeat({
    required this.player,
    required this.isMe,
    required this.isCurrentTurn,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      decoration: BoxDecoration(
        color: isCurrentTurn ? const Color(0xFF1A2E52) : _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentTurn
              ? _kGold
              : isMe
                  ? const Color(0xFF3B82F6).withOpacity(0.55)
                  : _kBorder,
          width: isCurrentTurn ? 1.5 : 1,
        ),
        boxShadow: isCurrentTurn
            ? [
                BoxShadow(
                  color: _kGold.withOpacity(0.12),
                  blurRadius: 14,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Opacity(
        opacity: player.isAlive ? 1.0 : 0.38,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // Player info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        if (isCurrentTurn)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: _kGold,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            '${player.shownName}${player.isBot ? ' 🤖' : ''}${isMe ? ' (${'you'.tr})' : ''}',
                            style: GoogleFonts.rajdhani(
                              color: isCurrentTurn ? _kGoldLight : _kTextPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.monetization_on_rounded, size: 13, color: _kGold),
                        const SizedBox(width: 3),
                        Text(
                          '${player.coins}',
                          style: const TextStyle(
                            color: _kGold,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (!player.isAlive) ...[
                          const SizedBox(width: 8),
                          _OutBadge(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Cards
              Row(
                mainAxisSize: MainAxisSize.min,
                children: player.cards
                    .map((card) => Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: CardWidget(
                            roleType: card.roleType,
                            isHidden: !isMe && !card.isRevealed,
                            isEliminated: card.isRevealed,
                            small: true,
                          ),
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

class _OutBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: _kRed.withOpacity(0.18),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _kRed.withOpacity(0.4), width: 0.5),
      ),
      child: Text(
        'out'.tr,
        style: const TextStyle(
          color: _kRed,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─── Game status card ────────────────────────────────────────────────────────
class _GameStatusCard extends StatelessWidget {
  final CoupRoomModel room;
  final GameStartController controller;
  const _GameStatusCard({required this.room, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (room.roomState == GameState.finished) {
      final winner = room.players.firstWhereOrNull((p) => p.name == room.winnerId)?.shownName;
      return _FinishedBanner(winnerName: winner);
    }
    final action = room.currentAction;
    if (action == null) return const SizedBox.shrink();
    return _ActionBanner(action: action);
  }
}

class _FinishedBanner extends StatelessWidget {
  final String? winnerName;
  const _FinishedBanner({this.winnerName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kGold.withOpacity(0.14), _kGold.withOpacity(0.04)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kGold.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events_rounded, color: _kGold, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('gameOver'.tr,
                  style: GoogleFonts.rajdhani(
                    color: _kGoldLight,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  )),
              if (winnerName != null)
                Text('gameWinner'.trParams({'name': winnerName!}),
                    style: GoogleFonts.rajdhani(
                        color: _kTextPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBanner extends StatelessWidget {
  final CoupActionModel action;
  const _ActionBanner({required this.action});

  @override
  Widget build(BuildContext context) {
    final label = action.actionType.firestoreType.replaceAll('_', ' ').toUpperCase();
    final target = action.target?.shownName;
    final claimedRole = action.actionType.claimedRole;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: _kSurfaceHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.play_circle_outline, size: 16, color: _kTextSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.rajdhani(
                    color: _kTextSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                children: [
                  TextSpan(
                    text: action.source.shownName,
                    style: const TextStyle(color: _kTextPrimary, fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ' ${'gameUsedAction'.tr} '),
                  TextSpan(
                    text: label,
                    style: TextStyle(
                      color:
                          claimedRole != null ? CardWidget.roleColor(claimedRole) : _kTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (claimedRole != null)
                    TextSpan(
                      text: ' (${claimedRole.name})',
                      style: TextStyle(color: CardWidget.roleColor(claimedRole).withOpacity(0.7)),
                    ),
                  if (target != null) ...[
                    const TextSpan(text: ' → '),
                    TextSpan(
                      text: target,
                      style: const TextStyle(color: _kTextPrimary, fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  final List<GameHistoryEntry> entries;
  final GameStartController controller;

  const _HistoryPanel({required this.entries, required this.controller});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final panelHeight = screenHeight < 700 ? 128.0 : 176.0;

    return Container(
      height: panelHeight,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Row(
              children: [
                const Icon(Icons.history_rounded, size: 16, color: _kGold),
                const SizedBox(width: 8),
                Text(
                  'gameHistory'.tr,
                  style: GoogleFonts.rajdhani(
                    color: _kGoldLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Text(
                  'gameEvents'.trParams({'count': '${entries.length}'}),
                  style: GoogleFonts.rajdhani(
                    color: _kTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _kBorder),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      'gameNoActions'.tr,
                      style: GoogleFonts.rajdhani(
                        color: _kTextSecondary,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _HistoryRow(entry: entries[index], controller: controller),
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final GameHistoryEntry entry;
  final GameStartController controller;

  const _HistoryRow({required this.entry, required this.controller});

  Color get _accentColor {
    switch (entry.actionType) {
      case 'income':
        return const Color(0xFF10B981);
      case 'foreign_aid':
        return const Color(0xFF06B6D4);
      case 'tax':
        return const Color(0xFF8B5CF6);
      case 'assassinate':
        return const Color(0xFFEF4444);
      case 'steal':
        return const Color(0xFF3B82F6);
      case 'exchange':
        return const Color(0xFF14B8A6);
      case 'coup':
        return const Color(0xFFF59E0B);
      default:
        return _kTextSecondary;
    }
  }

  String get _actionLabel => entry.actionType.replaceAll('_', ' ').toUpperCase();

  String get _statusLabel {
    final status = entry.status;
    if (status == null || status.isEmpty) return 'gamePending'.tr;
    return status[0].toUpperCase() + status.substring(1);
  }

  String get _timeLabel {
    final createdAt = entry.createdAt;
    if (createdAt == null) return 'gameJustNow'.tr;
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: _kSurfaceHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder.withOpacity(0.9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: _accentColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.rajdhani(
                      color: _kTextSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text: controller.displayNameOf(entry.actorName),
                        style: const TextStyle(color: _kTextPrimary, fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: ' ${'gameUsedAction'.tr} '),
                      TextSpan(
                        text: _actionLabel,
                        style: TextStyle(color: _accentColor, fontWeight: FontWeight.w700),
                      ),
                      if (entry.targetName != null) ...[
                        TextSpan(text: ' ${'gameOnTarget'.tr} '),
                        TextSpan(
                          text: controller.displayNameOf(entry.targetName),
                          style: const TextStyle(color: _kTextPrimary, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _MiniBadge(label: _statusLabel, color: _accentColor),
                    if (entry.claimedCard != null)
                      _MiniBadge(label: entry.claimedCard!, color: _kGold),
                    _MiniBadge(label: _timeLabel, color: _kTextSecondary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.rajdhani(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─── Action panel ─────────────────────────────────────────────────────────────
class _ActionPanel extends StatelessWidget {
  final CoupRoomModel room;
  final GameStartController controller;

  const _ActionPanel({required this.room, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (room.roomState == GameState.finished) return const SizedBox.shrink();

    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MyInfoBar(controller: controller),
          const Divider(height: 1, thickness: 1, color: _kBorder),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: _buildPhaseContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseContent() {
    final phase = room.phase;
    if (phase == GamePhase.action && !controller.isMyTurn) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: _kTextSecondary),
            ),
            const SizedBox(width: 10),
            Text(
              'gameWaitingFor'.trParams({'name': controller.displayNameOf(room.currentTurn)}),
              style: GoogleFonts.rajdhani(color: _kTextSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    switch (phase) {
      case GamePhase.action:
        return _ActionButtons(controller: controller);
      case GamePhase.challenge:
        return _ChallengeButtons(controller: controller);
      case GamePhase.block:
        return _BlockButtons(room: room, controller: controller);
      case GamePhase.blockChallenge:
        return _BlockChallengeButtons(controller: controller);
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
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
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.5), width: 1),
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
              Text('✕', style: TextStyle(color: color.withOpacity(0.6), fontSize: 9)),
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

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: CoupFunction.normalAction().map((action) {
        var enabled = controller.canAct;
        if (action == CoupActionType.assassin && coins < 3) enabled = false;
        if (action == CoupActionType.coup && coins < 7) enabled = false;
        if (coins >= 10 && action != CoupActionType.coup) enabled = false;

        return _ActionTile(
          action: action,
          coins: coins,
          enabled: enabled,
          onTap: () => controller.performAction(action),
        );
      }).toList(),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final CoupActionType action;
  final int coins;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionTile({
    required this.action,
    required this.coins,
    required this.enabled,
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

  String get _sublabel {
    switch (action) {
      case CoupActionType.income:
        return 'actionIncomeSub'.tr;
      case CoupActionType.foreignAid:
        return 'actionForeignAidSub'.tr;
      case CoupActionType.coup:
        return 'actionCoupSub'.tr;
      case CoupActionType.duke:
        return 'actionTaxSub'.tr;
      case CoupActionType.assassin:
        return 'actionAssassinateSub'.tr;
      case CoupActionType.captain:
        return 'actionStealSub'.tr;
      case CoupActionType.ambassador:
        return 'actionExchangeSub'.tr;
      default:
        return '';
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
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minWidth: 110),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.12) : _kSurfaceHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? color.withOpacity(0.5) : _kBorder,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _sublabel,
              style: TextStyle(
                color: enabled ? color.withOpacity(0.65) : _kBorder,
                fontSize: 10,
                fontWeight: FontWeight.w500,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'gameChallengeQuestion'.tr,
          style: GoogleFonts.rajdhani(color: _kTextSecondary, fontSize: 12, letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _PanelButton(
              label: 'gameChallenge'.tr,
              sublabel: 'gameCallBluff'.tr,
              color: const Color(0xFFD97706),
              onTap: controller.challengeAction,
            ),
            const SizedBox(width: 8),
            _PanelButton(
              label: 'gamePass'.tr,
              sublabel: 'gameLetItHappen'.tr,
              color: _kTextSecondary,
              outlined: true,
              onTap: controller.passChallenge,
            ),
          ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'gameBlockQuestion'.tr,
          style: GoogleFonts.rajdhani(color: _kTextSecondary, fontSize: 12, letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...blockRoles.map((role) {
              final roleType =
                  CoupRoleType.values.firstWhereOrNull((r) => r.firestoreValue == role);
              return _PanelButton(
                label: 'gameBlockAs'
                    .trParams({'role': '${role[0].toUpperCase()}${role.substring(1)}'}),
                sublabel: 'gameClaimRole'.trParams({'role': role}),
                color: CardWidget.roleColor(roleType),
                onTap: () => controller.blockAction(role),
              );
            }),
            _PanelButton(
              label: 'gameNoBlock'.tr,
              sublabel: 'gameAllowAction'.tr,
              color: _kTextSecondary,
              outlined: true,
              onTap: controller.passBlockOpportunity,
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Block challenge buttons ──────────────────────────────────────────────────
class _BlockChallengeButtons extends StatelessWidget {
  final GameStartController controller;
  const _BlockChallengeButtons({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'gameChallengeBlockQuestion'.tr,
          style: GoogleFonts.rajdhani(color: _kTextSecondary, fontSize: 12, letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _PanelButton(
              label: 'gameChallengeBlock'.tr,
              sublabel: 'gameCallBluff'.tr,
              color: const Color(0xFFDC2626),
              onTap: controller.challengeBlock,
            ),
            const SizedBox(width: 8),
            _PanelButton(
              label: 'gameAcceptBlock'.tr,
              sublabel: 'gameActionFails'.tr,
              color: _kTextSecondary,
              outlined: true,
              onTap: controller.passBlockChallenge,
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Shared panel button ──────────────────────────────────────────────────────
class _PanelButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;

  const _PanelButton({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 120),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: outlined ? _kBorder : color.withOpacity(0.55),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: outlined ? _kTextSecondary : color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              sublabel,
              style: TextStyle(
                color: (outlined ? _kTextSecondary : color).withOpacity(0.6),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
