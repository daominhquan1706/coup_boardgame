part of '../page.dart';

// ─── Game end screen overlay ──────────────────────────────────────────────────
class _GameEndScreen extends StatelessWidget {
  final CoupRoomModel room;
  final GameStartController controller;

  const _GameEndScreen({required this.room, required this.controller});

  @override
  Widget build(BuildContext context) {
    final viewport = _GameViewport.of(context);
    final myName = controller.userName;
    final winnerId = room.winnerId;
    final isVictory = winnerId != null && winnerId == myName;

    final sortedPlayers = [...room.players];
    sortedPlayers.sort((a, b) {
      if (a.name == winnerId) return -1;
      if (b.name == winnerId) return 1;
      if (a.isAlive != b.isAlive) return a.isAlive ? -1 : 1;
      return b.coins.compareTo(a.coins);
    });

    final history = controller.historyEntries;
    final totalCoups = history.where((e) => e.actionType == 'coup').length;
    final claimCounts = <String, int>{};
    for (final e in history) {
      if (e.claimedCard != null) {
        claimCounts[e.actorName] = (claimCounts[e.actorName] ?? 0) + 1;
      }
    }
    String? biggestBluffer;
    int maxClaims = 0;
    claimCounts.forEach((name, count) {
      if (count > maxClaims) {
        maxClaims = count;
        biggestBluffer = name;
      }
    });

    return Material(
      color: Colors.black.withValues(alpha: (0.88)),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: viewport.isPhone ? double.infinity : 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(isVictory),
                  const SizedBox(height: 12),
                  _buildSection(
                    icon: Icons.leaderboard_rounded,
                    title: 'gameRanking'.tr,
                    child: _buildRanking(sortedPlayers, winnerId),
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    icon: Icons.bar_chart_rounded,
                    title: 'gameSummary'.tr,
                    child: _buildSummary(biggestBluffer, maxClaims, totalCoups),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: controller.endGame,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kGold, AppColors.kGoldDark],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'gameEndGame'.tr.toUpperCase(),
                          style: GoogleFonts.rajdhani(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isVictory) {
    final winnerPlayer = room.players.firstWhereOrNull((p) => p.name == room.winnerId);
    final winnerShown = winnerPlayer?.shownName ?? room.winnerId ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isVictory
              ? [_kGold.withValues(alpha: (0.22)), _kGold.withValues(alpha: (0.05))]
              : [_kRed.withValues(alpha: (0.18)), _kRed.withValues(alpha: (0.04))],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVictory ? _kGold.withValues(alpha: (0.55)) : _kRed.withValues(alpha: (0.45)),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVictory ? Icons.emoji_events_rounded : Icons.sentiment_very_dissatisfied_rounded,
            size: 56,
            color: isVictory ? _kGold : _kRed,
          ),
          const SizedBox(height: 10),
          Text(
            isVictory ? 'gameVictory'.tr : 'gameDefeated'.tr,
            style: GoogleFonts.rajdhani(
              color: isVictory ? _kGoldLight : _kRed,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isVictory ? 'gameYouWon'.tr : 'gameWinner'.trParams({'name': winnerShown}),
            textAlign: TextAlign.center,
            style: GoogleFonts.rajdhani(
              color: _kTextSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required IconData icon, required String title, required Widget child}) {
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
          Row(
            children: [
              Icon(icon, size: 13, color: _kGold),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.rajdhani(
                  color: _kGold,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildRanking(List<CoupPlayerModel> players, String? winnerId) {
    return Column(
      children: List.generate(players.length, (i) {
        final player = players[i];
        final rank = i + 1;
        final isWinner = player.name == winnerId;
        final rankLabel = rank == 1
            ? '🥇'
            : rank == 2
                ? '🥈'
                : rank == 3
                    ? '🥉'
                    : '#$rank';
        return Padding(
          padding: EdgeInsets.only(bottom: i < players.length - 1 ? 10 : 0),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(rankLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: rank <= 3 ? 16 : 12, color: _kTextSecondary)),
              ),
              const SizedBox(width: 8),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isWinner
                        ? [AppColors.kBlueLight, AppColors.kBlueDark]
                        : [AppColors.boardOverlay, AppColors.boardOverlayDark],
                  ),
                  border: Border.all(
                    color: isWinner ? _kGold : _kBorder,
                    width: isWinner ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: player.isBot
                      ? Icon(Icons.smart_toy_rounded,
                          size: 14, color: isWinner ? _kGoldLight : _kTextSecondary)
                      : Text(
                          player.shownName.isNotEmpty ? player.shownName[0].toUpperCase() : '?',
                          style: GoogleFonts.rajdhani(
                            color: isWinner ? _kGoldLight : _kTextPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  player.shownName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.rajdhani(
                    color:
                        isWinner ? _kGoldLight : (player.isAlive ? _kTextPrimary : _kTextSecondary),
                    fontSize: 15,
                    fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
                    decoration: player.isAlive ? null : TextDecoration.lineThrough,
                    decorationColor: _kTextSecondary,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(r'$',
                      style: TextStyle(color: _kGold, fontSize: 10, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 2),
                  Text('${player.coins}',
                      style: GoogleFonts.rajdhani(
                          color: _kGold, fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(width: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: player.cards.map((card) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: SizedBox(
                      width: 34,
                      height: 50,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: CardWidget(
                          roleType: card.roleType,
                          small: true,
                          isHidden: false,
                          isEliminated: false,
                        ),
                      ),
                    ),
                  );
                }).toList(growable: false),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSummary(String? biggestBluffer, int maxClaims, int totalCoups) {
    return Column(
      children: [
        _SummaryRow(
          icon: Icons.casino_rounded,
          label: 'gameMostBluffs'.tr,
          value: biggestBluffer != null ? '$biggestBluffer ($maxClaims)' : '—',
        ),
        const SizedBox(height: 8),
        _SummaryRow(
          icon: Icons.gavel_rounded,
          label: 'gameTotalCoups'.tr,
          value: totalCoups.toString(),
        ),
      ],
    );
  }
}
