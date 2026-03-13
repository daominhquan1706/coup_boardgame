part of '../page.dart';

// ─── Top bar ─────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final CoupRoomModel room;
  final GameStartController controller;

  const _TopBar({required this.room, required this.controller});

  @override
  Widget build(BuildContext context) {
    final viewport = _GameViewport.of(context);

    Widget roomLabel() => Text(
          'ROOM ${controller.roomCode.toUpperCase()}',
          style: GoogleFonts.rajdhani(
            color: _kTextSecondary,
            fontSize: 13,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        );

    Widget turnSummary() {
      if (room.currentTurn == null) return const SizedBox.shrink();
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_outline, size: 14, color: _kTextSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              controller.displayNameOf(room.currentTurn),
              style: GoogleFonts.rajdhani(
                color: _kTextPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: viewport.isPhone ? 12 : 20,
        vertical: viewport.isPhone ? 10 : 11,
      ),
      decoration: const BoxDecoration(
        color: _kSurface,
        border: Border(bottom: BorderSide(color: _kBorder, width: 1)),
      ),
      child: viewport.isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 6,
                        children: [
                          GestureDetector(
                            onTap: () => Get.offAllNamed(AppRoutes.home),
                            child: Text(
                              'COUP',
                              style: GoogleFonts.rajdhani(
                                color: _kGold,
                                fontSize: viewport.isPhone ? 20 : 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: viewport.isPhone ? 3 : 4,
                              ),
                            ),
                          ),
                          if (!viewport.isPhone) Container(width: 1, height: 18, color: _kBorder),
                          roomLabel(),
                        ],
                      ),
                    ),
                    if (room.roomState != GameState.finished)
                      GestureDetector(
                        onTap: controller.endGame,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _kRed,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            'gameEndGame'.tr.toUpperCase(),
                            style: GoogleFonts.rajdhani(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
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
                roomLabel(),
                const Spacer(),
                _PhaseBadge(phase: room.phase),
                const SizedBox(width: 12),
                Flexible(child: turnSummary()),
                const SizedBox(width: 14),
                if (room.roomState != GameState.finished)
                  GestureDetector(
                    onTap: controller.endGame,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: _kRed,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'gameEndGame'.tr.toUpperCase(),
                        style: GoogleFonts.rajdhani(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

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
        color: _color.withValues(alpha: (0.12)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: (0.45))),
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
