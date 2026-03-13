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

  @override
  Widget build(BuildContext context) {
    final isFinished = room.roomState == GameState.finished;

    Widget board;
    if (viewport.isCompact) {
      board = Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TableArena(room: room, controller: controller, compact: true),
            const SizedBox(height: 12),
            Expanded(child: _ActionPanel(room: room, controller: controller, compact: true)),
          ],
        ),
      );
    } else {
      board = Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: _TableArena(room: room, controller: controller),
            ),
          ),
          _ActionPanel(room: room, controller: controller),
        ],
      );
    }

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

  List<Alignment> _opponentAlignments(int count) {
    switch (count) {
      case 0:
        return const [];
      case 1:
        return const [Alignment(0, -0.92)];
      case 2:
        return const [Alignment(-0.82, -0.7), Alignment(0.82, -0.7)];
      case 3:
        return const [
          Alignment(-0.88, -0.62),
          Alignment(0, -0.98),
          Alignment(0.88, -0.62),
        ];
      case 4:
        return const [
          Alignment(-0.94, -0.38),
          Alignment(-0.38, -0.98),
          Alignment(0.38, -0.98),
          Alignment(0.94, -0.38),
        ];
      default:
        return const [
          Alignment(-0.96, -0.28),
          Alignment(-0.56, -0.92),
          Alignment(0, -1.04),
          Alignment(0.56, -0.92),
          Alignment(0.96, -0.28),
        ];
    }
  }

  Widget _buildPhoneGrid(List<CoupPlayerModel> opponents, double availW) {
    if (opponents.isEmpty) return const SizedBox.shrink();
    const spacing = 6.0;
    final row1 = opponents.take(math.min(3, opponents.length)).toList();
    final row2 = opponents.skip(row1.length).toList();
    final seatW = math.min(
      110.0,
      (availW - spacing * math.max(0, row1.length - 1)) / row1.length,
    );

    Widget buildRow(List<CoupPlayerModel> rowPlayers) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < rowPlayers.length; i++) ...[
              if (i > 0) const SizedBox(width: spacing),
              SizedBox(
                width: seatW,
                child: _TablePlayerSeat(
                  player: rowPlayers[i],
                  isMe: false,
                  isCurrentTurn: rowPlayers[i].name == room.currentTurn,
                  compact: true,
                ),
              ),
            ],
          ],
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildRow(row1),
        if (row2.isNotEmpty) ...[
          const SizedBox(height: spacing),
          buildRow(row2),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewport = _GameViewport.of(context);
    final me = controller.mePlayer.value;
    final orderedPlayers = _orderedPlayers(me);
    final bottomPlayer = orderedPlayers.isNotEmpty ? orderedPlayers.first : null;
    final opponents = orderedPlayers.skip(bottomPlayer == null ? 0 : 1).toList(growable: false);
    final seatAlignments = _opponentAlignments(opponents.length);
    final arenaHeight = compact
        ? (viewport.isPhone ? (opponents.length > 3 ? 220.0 : 200.0) : 600.0)
        : (room.players.length <= 3 ? 620.0 : 700.0);
    final seatWidth = compact ? 170.0 : 196.0;
    final seatHeight = compact ? 108.0 : 118.0;

    return LayoutBuilder(
      builder: (context, lc) {
        final availW = lc.maxWidth;
        return Container(
          height: arenaHeight,
          padding: EdgeInsets.fromLTRB(
            compact ? 10 : 16,
            compact ? 10 : 18,
            compact ? 10 : 16,
            compact ? 14 : 18,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 20 : 24),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF15233F), Color(0xFF0D1426)],
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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(compact ? 18 : 22),
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.08),
                        radius: 1.1,
                        colors: [_kGold.withValues(alpha: (0.08)), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ),
              if (compact && viewport.isPhone)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildPhoneGrid(opponents, availW - 20),
                )
              else
                for (var index = 0;
                    index < opponents.length && index < seatAlignments.length;
                    index++)
                  Align(
                    alignment: seatAlignments[index],
                    child: FractionalTranslation(
                      translation: const Offset(0, -0.02),
                      child: SizedBox(
                        width: seatWidth,
                        height: seatHeight,
                        child: _TablePlayerSeat(
                          player: opponents[index],
                          isMe: false,
                          isCurrentTurn: opponents[index].name == room.currentTurn,
                          compact: compact,
                        ),
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

class _TablePlayerSeat extends StatelessWidget {
  final CoupPlayerModel player;
  final bool isMe;
  final bool isCurrentTurn;
  final bool compact;

  const _TablePlayerSeat({
    required this.player,
    required this.isMe,
    required this.isCurrentTurn,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final double avatarSize = compact ? 38.0 : 44.0;
    final double cardW = compact ? 22.0 : 26.0;
    final double cardH = compact ? 11.0 : 14.0;
    final double nameWidth = avatarSize * 2.6;

    return Opacity(
      opacity: player.isAlive ? 1 : 0.42,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Avatar + coin badge ───────────────────────────────────────
          SizedBox(
            width: avatarSize + 14,
            height: avatarSize + 10,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isMe
                          ? [const Color(0xFF4D8DFF), const Color(0xFF245CC9)]
                          : isCurrentTurn
                              ? [const Color(0xFF3A4F72), const Color(0xFF1E2B44)]
                              : [const Color(0xFF243047), const Color(0xFF161F30)],
                    ),
                    border: Border.all(
                      color: isCurrentTurn
                          ? _kGold
                          : isMe
                              ? const Color(0xFF4D8DFF)
                              : _kBorder,
                      width: isCurrentTurn ? 2.5 : 1.2,
                    ),
                    boxShadow: isCurrentTurn
                        ? [
                            BoxShadow(
                              color: _kGold.withValues(alpha: (0.35)),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ]
                        : isMe
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF4D8DFF).withValues(alpha: (0.2)),
                                  blurRadius: 10,
                                ),
                              ]
                            : [],
                  ),
                  alignment: Alignment.center,
                  child: player.isBot
                      ? Icon(
                          Icons.smart_toy_rounded,
                          color:
                              isCurrentTurn ? _kGoldLight : Colors.white.withValues(alpha: (0.85)),
                          size: avatarSize * 0.46,
                        )
                      : Text(
                          player.shownName.isNotEmpty ? player.shownName[0].toUpperCase() : '?',
                          style: GoogleFonts.rajdhani(
                            color: isCurrentTurn ? _kGoldLight : Colors.white,
                            fontSize: avatarSize * 0.40,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                // Coin badge at bottom-right
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: _kGold,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: _kBg, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          r'$',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 1),
                        Text(
                          '${player.coins}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // ── Player name ───────────────────────────────────────────────
          SizedBox(
            width: nameWidth,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${player.shownName}${isMe ? ' (${'you'.tr})' : ''}',
                maxLines: 1,
                textAlign: TextAlign.center,
                style: GoogleFonts.rajdhani(
                  color: isCurrentTurn ? _kGoldLight : _kTextPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
          if (!player.isAlive) ...[
            const SizedBox(height: 3),
            _OutBadge(),
          ],
          const SizedBox(height: 5),
          // ── Card placeholders ─────────────────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              player.cards.isNotEmpty ? player.cards.length : 2,
              (i) {
                final card = i < player.cards.length ? player.cards[i] : null;
                final isRevealed = card?.isRevealed ?? false;
                final roleColor = card != null ? CardWidget.roleColor(card.roleType) : _kBorder;
                return Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    width: cardW,
                    height: cardH,
                    decoration: BoxDecoration(
                      color: isRevealed
                          ? _kBorder.withValues(alpha: (0.25))
                          : roleColor.withValues(alpha: (0.20)),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: isRevealed
                            ? _kBorder.withValues(alpha: (0.4))
                            : roleColor.withValues(alpha: (0.75)),
                        width: 1.0,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
