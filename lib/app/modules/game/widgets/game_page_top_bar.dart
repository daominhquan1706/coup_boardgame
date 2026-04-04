part of '../page.dart';

// ─── Top bar ─────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final CoupRoomModel room;
  final GameStartController controller;

  const _TopBar({required this.room, required this.controller});

  @override
  Widget build(BuildContext context) {
    final viewport = _GameViewport.of(context);
    final roomCode = controller.roomCode.toUpperCase();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: viewport.isPhone ? 12 : 20,
        vertical: viewport.isPhone ? 10 : 11,
      ),
      decoration: const BoxDecoration(
        color: _kSurface,
        border: Border(bottom: BorderSide(color: _kBorder, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    'ROOM $roomCode',
                    style: GoogleFonts.rajdhani(
                      color: _kTextSecondary,
                      fontSize: viewport.isPhone ? 13 : 14,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'copy'.tr,
                  child: _GamePressable(
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: roomCode));
                      HapticFeedback.selectionClick();
                      AppToast.success('msgRoomCodeCopied'.tr);
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _kSurfaceHigh,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _kBorder),
                      ),
                      child: const Icon(Icons.copy_rounded,
                          size: 15, color: _kGold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (room.roomState != GameState.finished)
            _GamePressable(
              onTap: controller.endGame,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: viewport.isPhone ? 12 : 14,
                  vertical: viewport.isPhone ? 6 : 7,
                ),
                decoration: BoxDecoration(
                  color: _kRed,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'gameEndGame'.tr.toUpperCase(),
                  style: GoogleFonts.rajdhani(
                    color: Colors.white,
                    fontSize: viewport.isPhone ? 12 : 13,
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
