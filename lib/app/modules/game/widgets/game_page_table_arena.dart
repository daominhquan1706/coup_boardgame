part of '../page.dart';

class _GameBoardTab extends StatelessWidget {
  final CoupRoomModel room;
  final GameStartController controller;
  final _GameViewport viewport;

  const _GameBoardTab({
    required this.room,
    required this.controller,
    required this.viewport,
  });

  bool _shouldShowActionPanel() {
    if (room.roomState != GameState.playing) return false;

    switch (room.phase) {
      case GamePhase.action:
        return true;
      case GamePhase.challenge:
        return controller.canRespondChallenge(room);
      case GamePhase.block:
        return controller.canRespondBlock(room);
      case GamePhase.blockChallenge:
        return controller.canRespondBlockChallenge(room);
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFinished = room.roomState == GameState.finished;
    final showActionPanel = _shouldShowActionPanel();

    final board = E2ETag(
      label: viewport.isCompact ? 'e2e-game-layout-compact' : 'e2e-game-layout-wide',
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          viewport.isPhone ? 10 : 14,
          viewport.isPhone ? 8 : 12,
          viewport.isPhone ? 10 : 14,
          viewport.isPhone ? 10 : 12,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: viewport.isCompact ? 940 : 1220),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: _TableArena(
                        room: room, controller: controller, compact: viewport.isCompact),
                  ),
                ),
                if (showActionPanel) ...[
                  const SizedBox(height: 10),
                  _ActionPanel(
                    room: room,
                    controller: controller,
                    compact: viewport.isCompact,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (!isFinished) return board;

    return Stack(
      children: [
        board,
        _GameEndScreen(room: room, controller: controller),
      ],
    );
  }
}

class _TableArena extends StatelessWidget {
  final CoupRoomModel room;
  final GameStartController controller;
  final bool compact;

  const _TableArena({required this.room, required this.controller, this.compact = false});

  List<CoupPlayerModel> _orderedPlayers(CoupPlayerModel? me) {
    if (room.players.isEmpty) return const [];
    if (me == null) return List<CoupPlayerModel>.from(room.players);
    final meIndex = room.players.indexWhere((player) => player.name == me.name);
    if (meIndex < 0) return List<CoupPlayerModel>.from(room.players);

    final ordered = <CoupPlayerModel>[me];
    for (var index = 1; index < room.players.length; index++) {
      ordered.add(room.players[(meIndex + index) % room.players.length]);
    }
    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    final viewport = _GameViewport.of(context);
    final me = controller.mePlayer.value;
    final orderedPlayers = _orderedPlayers(me);
    final meSeat = me ?? (orderedPlayers.isEmpty ? null : orderedPlayers.first);
    final opponents = orderedPlayers
        .where((player) => meSeat == null || player.name != meSeat.name)
        .toList(growable: false);

    return LayoutBuilder(
      builder: (context, lc) {
        final availableWidth = lc.maxWidth;
        final topSpacing = viewport.isPhone ? 8.0 : 10.0;
        final seatCount = math.max(1, opponents.length);
        final opponentMaxWidth = seatCount >= 5
            ? (compact ? 164.0 : 172.0)
            : seatCount >= 4
                ? (compact ? 178.0 : 196.0)
                : (compact ? 224.0 : 244.0);
        final opponentTileWidth = ((availableWidth - ((seatCount - 1) * topSpacing)) / seatCount)
            .clamp(compact ? 128.0 : 138.0, opponentMaxWidth)
            .toDouble();
        final meCardWidth = ((availableWidth - 48) / 2)
            .clamp(viewport.isPhone ? 96.0 : 110.0, compact ? 140.0 : 160.0)
            .toDouble();

        return Container(
          constraints: BoxConstraints(minHeight: compact ? 390 : 460),
          padding: EdgeInsets.fromLTRB(
            compact ? 10 : 14,
            compact ? 10 : 14,
            compact ? 10 : 14,
            compact ? 14 : 16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 20 : 24),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF143148), Color(0xFF102332)],
            ),
            border: Border.all(color: _kBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: (0.28)),
                blurRadius: 24,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (opponents.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: availableWidth),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < opponents.length; i++) ...[
                          if (i > 0) SizedBox(width: topSpacing),
                          SizedBox(
                            width: opponentTileWidth,
                            child: _OpponentSeat(
                              player: opponents[i],
                              compact: compact,
                              isCurrentTurn: opponents[i].name == room.currentTurn,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: (0.12)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Text(
                    'msgWaitingForPlayers'.tr,
                    style: GoogleFonts.rajdhani(
                      color: _kTextSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              SizedBox(height: compact ? 14 : 18),
              if (meSeat != null)
                _MeSeat(
                  player: meSeat,
                  compact: compact,
                  isCurrentTurn: meSeat.name == room.currentTurn,
                  cardWidth: meCardWidth,
                ),
              if (meSeat == null)
                Center(
                  child: Text(
                    'msgLoadingGame'.tr,
                    style: GoogleFonts.rajdhani(
                      color: _kTextSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _OpponentSeat extends StatelessWidget {
  final CoupPlayerModel player;
  final bool compact;
  final bool isCurrentTurn;

  const _OpponentSeat({
    required this.player,
    required this.compact,
    required this.isCurrentTurn,
  });

  Widget _buildAvatar(double avatarSize) {
    return AnimatedContainer(
      duration: _kEmphasisMotion,
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: player.isBot
              ? [const Color(0xFF334155), const Color(0xFF1E293B)]
              : [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
        ),
        border: Border.all(
          color: isCurrentTurn ? _kGold : Colors.white.withValues(alpha: (0.22)),
          width: isCurrentTurn ? 1.8 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: player.isBot
          ? Icon(
              Icons.smart_toy_rounded,
              color: Colors.white.withValues(alpha: (0.9)),
              size: avatarSize * 0.5,
            )
          : Text(
              player.shownName.isNotEmpty ? player.shownName[0].toUpperCase() : '?',
              style: GoogleFonts.rajdhani(
                color: Colors.white,
                fontSize: avatarSize * 0.44,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double avatarSize = compact ? 38.0 : 42.0;
    final double cardH = compact ? 56.0 : 64.0;
    final double cardW = cardH * (64 / 92);
    final totalCards = player.cards.isNotEmpty ? player.cards.length : 2;
    final seat = AnimatedContainer(
      duration: _kEmphasisMotion,
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 9, vertical: compact ? 9 : 11),
      decoration: BoxDecoration(
        color: isCurrentTurn ? _kSurfaceHigh : _kSurface.withValues(alpha: (0.72)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentTurn ? _kGold.withValues(alpha: (0.88)) : _kBorder,
          width: isCurrentTurn ? 1.5 : 1,
        ),
        boxShadow: isCurrentTurn
            ? [
                BoxShadow(
                  color: _kGold.withValues(alpha: (0.24)),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _AnimatedTurnAvatar(
                isCurrentTurn: isCurrentTurn,
                size: avatarSize,
                child: _buildAvatar(avatarSize),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.shownName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.rajdhani(
                        color: isCurrentTurn ? _kGoldLight : _kTextPrimary,
                        fontSize: compact ? 13 : 14,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    _AnimatedCoinValue(
                      coins: player.coins,
                      deltaAlignment: Alignment.topLeft,
                      deltaTravel: const Offset(0, -14),
                      builder: (context, displayCoins, emphasisScale) {
                        return Transform.scale(
                          scale: emphasisScale,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.monetization_on_rounded,
                                color: _kGold,
                                size: 13,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '$displayCoins ${'coins'.tr}',
                                style: const TextStyle(
                                  color: _kGold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalCards, (index) {
              final card = index < player.cards.length ? player.cards[index] : null;
              return Padding(
                padding: EdgeInsets.only(left: index == 0 ? 0 : 5),
                child: SizedBox(
                  width: cardW,
                  height: cardH,
                  child: _AnimatedInfluenceMarker(
                    card: card,
                    compact: compact,
                    markerHeight: cardH,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );

    return Opacity(
      opacity: player.isAlive ? 1 : 0.42,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          seat,
          if (!player.isAlive)
            const Positioned(
              top: -6,
              right: -4,
              child: _OutBadge(),
            ),
        ],
      ),
    );
  }
}

class _MeSeat extends StatelessWidget {
  final CoupPlayerModel player;
  final bool compact;
  final bool isCurrentTurn;
  final double cardWidth;

  const _MeSeat({
    required this.player,
    required this.compact,
    required this.isCurrentTurn,
    required this.cardWidth,
  });

  @override
  Widget build(BuildContext context) {
    final totalCards = math.max(2, player.cards.length);
    return AnimatedContainer(
      duration: _kEmphasisMotion,
      padding: EdgeInsets.fromLTRB(
        compact ? 10 : 12,
        compact ? 8 : 10,
        compact ? 10 : 12,
        compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: _kSurface.withValues(alpha: (0.58)),
        borderRadius: BorderRadius.circular(compact ? 18 : 22),
        border: Border.all(
          color: isCurrentTurn ? _kGold.withValues(alpha: (0.85)) : _kBorder,
          width: isCurrentTurn ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrentTurn
                ? _kGold.withValues(alpha: (0.16))
                : Colors.black.withValues(alpha: (0.18)),
            blurRadius: isCurrentTurn ? 22 : 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AnimatedCoinValue(
                coins: player.coins,
                deltaAlignment: Alignment.topCenter,
                deltaTravel: const Offset(0, -14),
                builder: (context, displayCoins, emphasisScale) {
                  return Transform.scale(
                    scale: emphasisScale,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kGold.withValues(alpha: (0.18)),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _kGold.withValues(alpha: (0.55))),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on_rounded, color: _kGold, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            '$displayCoins ${'coins'.tr}',
                            style: const TextStyle(
                              color: _kGold,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${player.shownName} (${'you'.tr})',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.rajdhani(
              color: _kTextPrimary,
              fontSize: compact ? 14 : 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: compact ? 10 : 14,
            runSpacing: 8,
            children: List.generate(totalCards, (index) {
              final card = index < player.cards.length ? player.cards[index] : null;
              return _MeInfluenceCard(card: card, width: cardWidth);
            }),
          ),
        ],
      ),
    );
  }
}

class _MeInfluenceCard extends StatelessWidget {
  final CoupCardModel? card;
  final double width;

  const _MeInfluenceCard({
    required this.card,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isRevealed = card?.isRevealed ?? false;

    return SizedBox(
      width: width,
      child: AspectRatio(
        aspectRatio: 96 / 136,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CardWidget(
              roleType: card?.roleType,
              isHidden: card == null,
              isEliminated: isRevealed,
            ),
            if (isRevealed)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Transform.rotate(
                      angle: -0.2,
                      child: Icon(
                        Icons.close_rounded,
                        size: width * 0.86,
                        color: const Color(0xCCDC2626),
                      ),
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

class _OutBadge extends StatelessWidget {
  const _OutBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: _kRed.withValues(alpha: (0.18)),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _kRed.withValues(alpha: (0.4)), width: 0.5),
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
