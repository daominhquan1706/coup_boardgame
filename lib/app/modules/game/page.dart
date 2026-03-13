import 'package:coup_boardgame/app/data/model/firestore_model/coup_action_model.dart';
import 'package:coup_boardgame/app/data/model/game_history_entry.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_player_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_room_model.dart';
import 'package:coup_boardgame/app/modules/game/widgets/card_widget.dart';
import 'package:coup_boardgame/app/routes/app_pages.dart';
import 'package:coup_boardgame/app/utils/functions/coup_function.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';
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

class _GameViewport {
  final double width;

  const _GameViewport(this.width);

  factory _GameViewport.of(BuildContext context) {
    return _GameViewport(MediaQuery.sizeOf(context).width);
  }

  bool get isCompact => width < 1040;

  bool get isMobile => width < 720;

  bool get isPhone => width < 520;
}

enum _GameScreenTab { game, history, rules, settings }

// ─── Main page ───────────────────────────────────────────────────────────────
class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final GameStartController controller = Get.find<GameStartController>();
  _GameScreenTab _currentTab = _GameScreenTab.game;

  String _labelForTab(_GameScreenTab tab) {
    final isVietnamese = Get.locale?.languageCode == 'vi';
    switch (tab) {
      case _GameScreenTab.game:
        return isVietnamese ? 'Ván chơi' : 'Game';
      case _GameScreenTab.history:
        return isVietnamese ? 'Lịch sử' : 'History';
      case _GameScreenTab.rules:
        return isVietnamese ? 'Luật chơi' : 'Rules';
      case _GameScreenTab.settings:
        return isVietnamese ? 'Cài đặt' : 'Settings';
    }
  }

  IconData _iconForTab(_GameScreenTab tab) {
    switch (tab) {
      case _GameScreenTab.game:
        return Icons.sports_esports_rounded;
      case _GameScreenTab.history:
        return Icons.history_rounded;
      case _GameScreenTab.rules:
        return Icons.menu_book_rounded;
      case _GameScreenTab.settings:
        return Icons.tune_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewport = _GameViewport.of(context);

    return Obx(() {
      final room = controller.currentRoom.value;
      final entries = controller.historyEntries.toList(growable: false);

      return Scaffold(
        backgroundColor: _kBg,
        body: room == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: _kGold, strokeWidth: 2),
                    const SizedBox(height: 16),
                    Text('msgLoadingGame'.tr,
                        style: GoogleFonts.rajdhani(color: _kTextSecondary, fontSize: 14)),
                  ],
                ),
              )
            : SafeArea(
                child: Column(
                  children: [
                    _TopBar(room: room, controller: controller),
                    Expanded(
                      child: IndexedStack(
                        index: _currentTab.index,
                        children: [
                          _GameBoardTab(room: room, controller: controller, viewport: viewport),
                          _HistoryTabView(
                              entries: entries, controller: controller, viewport: viewport),
                          const _RulesTabView(),
                          _SettingsTabView(room: room, controller: controller),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        bottomNavigationBar: room == null
            ? null
            : NavigationBar(
                height: 74,
                backgroundColor: _kSurface,
                indicatorColor: _kGold.withOpacity(0.16),
                surfaceTintColor: Colors.transparent,
                selectedIndex: _currentTab.index,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                onDestinationSelected: (index) {
                  setState(() {
                    _currentTab = _GameScreenTab.values[index];
                  });
                },
                destinations: _GameScreenTab.values
                    .map(
                      (tab) => NavigationDestination(
                        icon: Icon(_iconForTab(tab), color: _kTextSecondary),
                        selectedIcon: Icon(_iconForTab(tab), color: _kGold),
                        label: _labelForTab(tab),
                      ),
                    )
                    .toList(),
              ),
      );
    });
  }
}

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

class _HistoryTabView extends StatelessWidget {
  final List<GameHistoryEntry> entries;
  final GameStartController controller;
  final _GameViewport viewport;

  const _HistoryTabView({
    required this.entries,
    required this.controller,
    required this.viewport,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        viewport.isPhone ? 12 : 16,
        12,
        viewport.isPhone ? 12 : 16,
        16,
      ),
      child: _HistoryPanel(entries: entries, controller: controller),
    );
  }
}

class _RulesTabView extends StatelessWidget {
  const _RulesTabView();

  List<({String title, String body})> _sections(bool isVietnamese) {
    return isVietnamese
        ? const [
            (
              title: 'Mục tiêu',
              body:
                  'Trở thành người sống sót cuối cùng bằng cách loại toàn bộ influence của đối thủ.',
            ),
            (
              title: 'Lượt chơi',
              body:
                  'Mỗi lượt bạn chọn một hành động: Income, Foreign Aid, Tax, Steal, Exchange, Assassinate hoặc Coup.',
            ),
            (
              title: 'Challenge và Block',
              body:
                  'Nhiều hành động yêu cầu claim vai. Người chơi khác có thể challenge claim đó hoặc block bằng vai phù hợp.',
            ),
            (
              title: 'Influence',
              body:
                  'Khi bị mất influence, bạn phải lật một lá. Khi lật hết 2 lá, bạn bị loại khỏi ván.',
            ),
            (
              title: 'Mốc quan trọng',
              body:
                  'Coup tốn 7 xu và không thể bị chặn. Nếu bạn có từ 10 xu trở lên, bạn buộc phải Coup.',
            ),
          ]
        : const [
            (
              title: 'Objective',
              body: 'Be the last player alive by eliminating all opponents’ influence cards.',
            ),
            (
              title: 'Turn Flow',
              body:
                  'Each turn you choose one action: Income, Foreign Aid, Tax, Steal, Exchange, Assassinate, or Coup.',
            ),
            (
              title: 'Challenge and Block',
              body:
                  'Many actions require claiming a role. Other players may challenge that claim or block with a valid role.',
            ),
            (
              title: 'Influence',
              body:
                  'When you lose influence, reveal one card. If both cards are revealed, you are out of the game.',
            ),
            (
              title: 'Important Thresholds',
              body:
                  'Coup costs 7 coins and cannot be blocked. If you reach 10 or more coins, you must Coup.',
            ),
          ];
  }

  @override
  Widget build(BuildContext context) {
    final isVietnamese = Get.locale?.languageCode == 'vi';
    final sections = _sections(isVietnamese);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoHeader(
            title: isVietnamese ? 'Luật chơi COUP' : 'COUP Rules',
            subtitle: isVietnamese
                ? 'Tóm tắt nhanh để xem trong lúc đang chơi.'
                : 'Quick reference while you are in the match.',
            icon: Icons.menu_book_rounded,
          ),
          const SizedBox(height: 12),
          for (final section in sections) ...[
            _InfoCard(title: section.title, body: section.body),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _SettingsTabView extends StatelessWidget {
  final CoupRoomModel room;
  final GameStartController controller;

  const _SettingsTabView({required this.room, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isVietnamese = Get.locale?.languageCode == 'vi';
    final selectedLanguage = Get.locale?.languageCode == 'vi' ? 'vi' : 'en';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoHeader(
            title: isVietnamese ? 'Thiết lập ván chơi' : 'Game Settings',
            subtitle: isVietnamese
                ? 'Điều chỉnh trải nghiệm chơi và ngôn ngữ hiển thị.'
                : 'Adjust in-game preferences and display language.',
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
            title: isVietnamese ? 'Tự động hành động' : 'Auto Action',
            child: Obx(
              () => SwitchListTile.adaptive(
                value: controller.autoActionEnabled.value,
                onChanged: controller.setAutoActionEnabled,
                title: Text(
                  isVietnamese ? 'Bật phản hồi tự động' : 'Enable automatic response',
                  style: GoogleFonts.rajdhani(
                    color: _kTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  isVietnamese
                      ? 'Game sẽ tự pass hoặc phản hồi khi hết thời gian.'
                      : 'The game will auto-pass or respond when the countdown ends.',
                  style: GoogleFonts.rajdhani(
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
            title: isVietnamese ? 'Thông tin bàn chơi' : 'Table Info',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SettingsMetaRow(
                  label: isVietnamese ? 'Mã phòng' : 'Room code',
                  value: controller.roomCode.toUpperCase(),
                ),
                const SizedBox(height: 8),
                _SettingsMetaRow(
                  label: isVietnamese ? 'Người chơi' : 'Players',
                  value: '${room.players.length}',
                ),
                const SizedBox(height: 8),
                _SettingsMetaRow(
                  label: isVietnamese ? 'Giai đoạn' : 'Phase',
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
              side: BorderSide(color: _kRed.withOpacity(0.45)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kGold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kGold.withOpacity(0.3)),
            ),
            child: Icon(icon, color: _kGold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.rajdhani(
                    color: _kTextPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.rajdhani(
                    color: _kTextSecondary,
                    fontSize: 14,
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

class _InfoCard extends StatelessWidget {
  final String title;
  final String body;

  const _InfoCard({required this.title, required this.body});

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
            style: GoogleFonts.rajdhani(
              color: _kGoldLight,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: GoogleFonts.rajdhani(
              color: _kTextPrimary,
              fontSize: 14,
              height: 1.35,
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
            style: GoogleFonts.rajdhani(
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
          color: selected ? _kGold.withOpacity(0.14) : _kSurfaceHigh,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? _kGold : _kBorder),
        ),
        child: Text(
          label,
          style: GoogleFonts.rajdhani(
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
            style: GoogleFonts.rajdhani(
              color: _kTextSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.rajdhani(
            color: _kTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
                color: Colors.black.withOpacity(0.28),
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
                        colors: [_kGold.withOpacity(0.08), Colors.transparent],
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
                for (var index = 0; index < opponents.length && index < seatAlignments.length; index++)
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

class _TableInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TableInfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _kSurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _kGold),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.rajdhani(
              color: _kTextPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TablePlayerSeat extends StatelessWidget {
  final CoupPlayerModel player;
  final bool isMe;
  final bool isCurrentTurn;
  final bool compact;
  final bool emphasize;

  const _TablePlayerSeat({
    required this.player,
    required this.isMe,
    required this.isCurrentTurn,
    required this.compact,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final double avatarSize = compact ? (emphasize ? 48.0 : 38.0) : (emphasize ? 56.0 : 44.0);
    final double cardW = compact ? (emphasize ? 28.0 : 22.0) : (emphasize ? 34.0 : 26.0);
    final double cardH = compact ? (emphasize ? 15.0 : 11.0) : (emphasize ? 19.0 : 14.0);
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
                              color: _kGold.withOpacity(0.35),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ]
                        : isMe
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF4D8DFF).withOpacity(0.2),
                                  blurRadius: 10,
                                ),
                              ]
                            : [],
                  ),
                  alignment: Alignment.center,
                  child: player.isBot
                      ? Icon(
                          Icons.smart_toy_rounded,
                          color: isCurrentTurn ? _kGoldLight : Colors.white.withOpacity(0.85),
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
                  fontSize: emphasize ? 14 : 12,
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
                      color: isRevealed ? _kBorder.withOpacity(0.25) : roleColor.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: isRevealed ? _kBorder.withOpacity(0.4) : roleColor.withOpacity(0.75),
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
      return _FinishedBanner(
        winnerName: winner,
        onBackLobby: controller.endGame,
      );
    }
    final action = room.currentAction;
    if (action == null) return const SizedBox.shrink();
    return _ActionBanner(action: action);
  }
}

class _FinishedBanner extends StatelessWidget {
  final String? winnerName;
  final VoidCallback onBackLobby;

  const _FinishedBanner({
    this.winnerName,
    required this.onBackLobby,
  });

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
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
          const SizedBox(height: 14),
          SizedBox(
            width: 210,
            child: ElevatedButton.icon(
              onPressed: onBackLobby,
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: Text('gameBackToLobby'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGold.withOpacity(0.16),
                foregroundColor: _kGoldLight,
                side: BorderSide(color: _kGold.withOpacity(0.45)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
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
    final viewport = _GameViewport.of(context);
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
      child: viewport.isPhone
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.play_circle_outline, size: 16, color: _kTextSecondary),
                const SizedBox(height: 8),
                RichText(
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
                          color: claimedRole != null
                              ? CardWidget.roleColor(claimedRole)
                              : _kTextPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (claimedRole != null)
                        TextSpan(
                          text: ' (${claimedRole.name})',
                          style:
                              TextStyle(color: CardWidget.roleColor(claimedRole).withOpacity(0.7)),
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
              ],
            )
          : Row(
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
                            color: claimedRole != null
                                ? CardWidget.roleColor(claimedRole)
                                : _kTextPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (claimedRole != null)
                          TextSpan(
                            text: ' (${claimedRole.name})',
                            style: TextStyle(
                                color: CardWidget.roleColor(claimedRole).withOpacity(0.7)),
                          ),
                        if (target != null) ...[
                          const TextSpan(text: ' → '),
                          TextSpan(
                            text: target,
                            style:
                                const TextStyle(color: _kTextPrimary, fontWeight: FontWeight.w700),
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

  List<_HistoryGroup> _groupedEntries() {
    final map = <String, List<GameHistoryEntry>>{};
    final order = <String>[];

    for (final entry in entries) {
      final baseId = entry.id.split('#').first;
      if (!map.containsKey(baseId)) {
        map[baseId] = <GameHistoryEntry>[];
        order.add(baseId);
      }
      map[baseId]!.add(entry);
    }

    return order.map((id) {
      final grouped = map[id]!;
      grouped.sort((a, b) {
        final aMs = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bMs = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return aMs.compareTo(bMs);
      });
      return _HistoryGroup(id: id, entries: grouped);
    }).toList(growable: false);
  }

  String _actionLabel(String actionType) {
    switch (actionType) {
      case 'income':
        return 'actionIncome'.tr;
      case 'foreign_aid':
        return 'actionForeignAid'.tr;
      case 'coup':
        return 'actionCoup'.tr;
      case 'tax':
        return 'actionTax'.tr;
      case 'assassinate':
        return 'actionAssassinate'.tr;
      case 'steal':
        return 'actionSteal'.tr;
      case 'exchange':
        return 'actionExchange'.tr;
      default:
        return actionType.replaceAll('_', ' ').toUpperCase();
    }
  }

  int? _timelineStartMs() {
    int? minMs;
    for (final entry in entries) {
      final ms = entry.createdAt?.millisecondsSinceEpoch;
      if (ms == null) continue;
      if (minMs == null || ms < minMs) minMs = ms;
    }
    return minMs;
  }

  String _fmtTime(DateTime? time, int? timelineStartMs) {
    if (time == null || timelineStartMs == null) return '--:--';
    final deltaMs = time.millisecondsSinceEpoch - timelineStartMs;
    final totalSeconds = (deltaMs < 0 ? 0 : deltaMs) ~/ 1000;
    final mm = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final ss = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  String _rawLine(GameHistoryEntry entry) {
    final actor = controller.displayNameOf(entry.actorName);
    final target = entry.targetName == null ? null : controller.displayNameOf(entry.targetName);
    final action = _actionLabel(entry.actionType);

    switch (entry.eventType) {
      case 'coins_changed':
        final delta = entry.coinDelta ?? 0;
        final sign = delta >= 0 ? '+' : '';
        if (target == null || target.isEmpty) {
          return '$actor $sign$delta coins';
        }
        return '$actor $sign$delta coins ($target)';
      case 'influence_revealed':
        final card = entry.claimedCard?.toUpperCase() ?? 'UNKNOWN';
        return '$actor reveal $card';
      case 'challenge_called':
        return target == null
            ? '$actor ${'gameChallenge'.tr} $action'
            : '$actor ${'gameChallenge'.tr} $target ($action)';
      case 'challenge_pass':
        return 'gamePassedChallenge'.trParams({'actor': actor});
      case 'block_called':
        final card = entry.claimedCard?.toUpperCase() ?? 'UNKNOWN';
        return 'gameBlockedWith'.trParams({'actor': actor, 'card': card});
      case 'block_pass':
        return 'gamePassedBlockOpportunity'.trParams({'actor': actor});
      case 'block_challenge_called':
        return target == null
            ? '$actor ${'gameChallengeBlock'.tr}'
            : '$actor ${'gameChallengeBlock'.tr} $target';
      case 'action_played':
        if (target == null || target.isEmpty) {
          return '$actor ${'gameUsedAction'.tr} $action';
        }
        return '$actor ${'gameUsedAction'.tr} $action -> $target';
      default:
        return entry.eventType.replaceAll('_', ' ');
    }
  }

  Future<void> _copyAllLogs(List<_HistoryGroup> groups, int? timelineStartMs) async {
    final buffer = StringBuffer();
    for (final group in groups) {
      for (final entry in group.entries) {
        buffer.writeln('[${_fmtTime(entry.createdAt, timelineStartMs)}] ${_rawLine(entry)}');
      }
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    Get.snackbar(
      'successful'.tr,
      'gameLogsCopied'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: _kSurface,
      colorText: _kTextPrimary,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupedEntries();
    final timelineStartMs = _timelineStartMs();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                const Icon(Icons.history_rounded, size: 18, color: _kGold),
                const SizedBox(width: 8),
                Text(
                  'gameHistory'.tr,
                  style: GoogleFonts.rajdhani(
                    color: _kGoldLight,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
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
                const SizedBox(width: 6),
                if (groups.isNotEmpty)
                  IconButton(
                    tooltip: 'gameCopyLogs'.tr,
                    onPressed: () => _copyAllLogs(groups, timelineStartMs),
                    splashRadius: 18,
                    iconSize: 18,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    padding: const EdgeInsets.all(4),
                    icon: const Icon(Icons.copy_rounded, color: _kGold),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _kBorder),
          Expanded(
            child: groups.isEmpty
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
                    itemCount: groups.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => _HistoryGroupCard(
                      group: groups[index],
                      controller: controller,
                      timelineStartMs: timelineStartMs,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistoryGroup {
  final String id;
  final List<GameHistoryEntry> entries;

  const _HistoryGroup({required this.id, required this.entries});

  GameHistoryEntry? get actionEntry =>
      entries.firstWhereOrNull((entry) => entry.eventType == 'action_played');
}

class _HistoryGroupCard extends StatelessWidget {
  final _HistoryGroup group;
  final GameStartController controller;
  final int? timelineStartMs;

  const _HistoryGroupCard({
    required this.group,
    required this.controller,
    required this.timelineStartMs,
  });

  CoupRoleType? _roleFromActionType(String actionType) {
    if (actionType == 'block_contessa') return CoupRoleType.contessa;
    return CoupActionTypeX.fromFirestoreType(actionType).claimedRole;
  }

  String _actionLabel(String actionType) {
    switch (actionType) {
      case 'income':
        return 'actionIncome'.tr;
      case 'foreign_aid':
        return 'actionForeignAid'.tr;
      case 'coup':
        return 'actionCoup'.tr;
      case 'tax':
        return 'actionTax'.tr;
      case 'assassinate':
        return 'actionAssassinate'.tr;
      case 'steal':
        return 'actionSteal'.tr;
      case 'exchange':
        return 'actionExchange'.tr;
      default:
        return actionType.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _timeLabel(DateTime? createdAt) {
    if (createdAt == null || timelineStartMs == null) return '--:--';
    final deltaMs = createdAt.millisecondsSinceEpoch - timelineStartMs!;
    final totalSeconds = (deltaMs < 0 ? 0 : deltaMs) ~/ 1000;
    final mm = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final ss = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Color _eventAccent(GameHistoryEntry entry) {
    if (entry.eventType == 'coins_changed') {
      final delta = entry.coinDelta ?? 0;
      return delta < 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    }
    if (entry.eventType == 'influence_revealed') {
      return const Color(0xFFF59E0B);
    }

    switch (entry.eventType) {
      case 'challenge_called':
      case 'block_challenge_called':
        return const Color(0xFFD97706);
      case 'block_called':
        return const Color(0xFF7C3AED);
      default:
        break;
    }

    final role = _roleFromActionType(entry.actionType);
    if (role != null) return CardWidget.roleColor(role);

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

  List<InlineSpan> _spans(GameHistoryEntry entry) {
    final actor = controller.displayNameOf(entry.actorName);
    final target = entry.targetName == null ? null : controller.displayNameOf(entry.targetName);
    final actionLabel = _actionLabel(entry.actionType);
    final actionColor = _eventAccent(entry);
    final base = GoogleFonts.rajdhani(
      color: _kTextSecondary,
      fontSize: 11.5,
      fontWeight: FontWeight.w500,
    );
    final strong = GoogleFonts.rajdhani(
      color: _kTextPrimary,
      fontSize: 11.8,
      fontWeight: FontWeight.w700,
    );
    final actionStrong = GoogleFonts.rajdhani(
      color: actionColor,
      fontSize: 11.8,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );

    final spans = <InlineSpan>[
      TextSpan(text: actor, style: strong),
    ];

    switch (entry.eventType) {
      case 'coins_changed':
        final delta = entry.coinDelta ?? 0;
        final sign = delta >= 0 ? '+' : '';
        spans.add(TextSpan(text: ' ', style: base));
        spans.add(TextSpan(
          text: '$sign$delta',
          style: GoogleFonts.rajdhani(
            color: delta < 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
            fontSize: 11.8,
            fontWeight: FontWeight.w700,
          ),
        ));
        spans.add(TextSpan(text: ' coins', style: base));
        if (target != null && target.isNotEmpty) {
          spans.add(TextSpan(text: ' ($target)', style: base));
        }
        return spans;
      case 'influence_revealed':
        final card = entry.claimedCard?.toUpperCase() ?? 'UNKNOWN';
        final roleType =
            CoupRoleType.values.firstWhereOrNull((r) => r.firestoreValue == card.toLowerCase());
        final revealColor = roleType == null ? actionColor : CardWidget.roleColor(roleType);
        spans.add(TextSpan(text: ' reveal ', style: base));
        spans.add(TextSpan(
          text: card,
          style: GoogleFonts.rajdhani(
            color: revealColor,
            fontSize: 11.8,
            fontWeight: FontWeight.w700,
          ),
        ));
        return spans;
      case 'challenge_called':
        spans.add(TextSpan(text: " ${'gameChallenge'.tr.toLowerCase()} ", style: base));
        if (target != null) {
          spans.add(TextSpan(text: target, style: strong));
          spans.add(TextSpan(text: ' (', style: base));
          spans.add(TextSpan(text: actionLabel, style: actionStrong));
          spans.add(TextSpan(text: ')', style: base));
        } else {
          spans.add(TextSpan(text: actionLabel, style: actionStrong));
        }
        return spans;
      case 'challenge_pass':
        spans.add(TextSpan(
            text: " ${'gamePassedChallenge'.trParams({'actor': ''}).trim()}", style: base));
        return spans;
      case 'block_called':
        final card = entry.claimedCard?.toUpperCase() ?? '';
        final roleType = card.isEmpty
            ? null
            : CoupRoleType.values.firstWhereOrNull((r) => r.firestoreValue == card.toLowerCase());
        final roleColor = roleType == null ? actionColor : CardWidget.roleColor(roleType);
        spans.add(TextSpan(
            text: " ${'gameBlockedWith'.trParams({'actor': '', 'card': ''}).trim()} ",
            style: base));
        spans.add(TextSpan(
          text: card,
          style: GoogleFonts.rajdhani(
            color: roleColor,
            fontSize: 11.8,
            fontWeight: FontWeight.w700,
          ),
        ));
        return spans;
      case 'block_pass':
        spans.add(TextSpan(
            text: " ${'gamePassedBlockOpportunity'.trParams({'actor': ''}).trim()}", style: base));
        return spans;
      case 'block_challenge_called':
        spans.add(TextSpan(text: " ${'gameChallengeBlock'.tr.toLowerCase()} ", style: base));
        if (target != null) {
          spans.add(TextSpan(text: target, style: strong));
        } else {
          spans.add(TextSpan(text: '...', style: base));
        }
        return spans;
      case 'block_challenge_pass':
        spans.add(TextSpan(text: " ${'gameAcceptBlock'.tr.toLowerCase()}", style: base));
        return spans;
      default:
        spans.add(TextSpan(text: " ${'gameUsedAction'.tr} ", style: base));
        spans.add(TextSpan(text: actionLabel, style: actionStrong));
        if (target != null) {
          spans.add(TextSpan(text: " ${'gameOnTarget'.tr} ", style: base));
          spans.add(TextSpan(text: target, style: strong));
        }
        return spans;
    }
  }

  @override
  Widget build(BuildContext context) {
    final root = group.actionEntry ?? group.entries.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _kSurfaceHigh.withOpacity(0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder.withOpacity(0.9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: _eventAccent(root), shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _actionLabel(root.actionType).toUpperCase(),
                  style: GoogleFonts.rajdhani(
                    color: _eventAccent(root),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Text(
                _timeLabel(root.createdAt),
                style: GoogleFonts.rajdhani(
                  color: _kTextSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          for (final entry in group.entries)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: _eventAccent(entry).withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: RichText(text: TextSpan(children: _spans(entry))),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _timeLabel(entry.createdAt),
                    style: GoogleFonts.rajdhani(
                      color: _kTextSecondary.withOpacity(0.9),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
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

// Action panel
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
          color: enabled ? color.withOpacity(0.15) : _kSurfaceHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? color.withOpacity(0.60) : _kBorder,
            width: enabled ? 1.2 : 1,
          ),
          boxShadow: enabled ? [BoxShadow(color: color.withOpacity(0.14), blurRadius: 10)] : null,
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
                colors: [challengeColor.withOpacity(0.22), challengeColor.withOpacity(0.07)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: challengeColor.withOpacity(0.75), width: 1.5),
              boxShadow: [BoxShadow(color: challengeColor.withOpacity(0.20), blurRadius: 20)],
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
                      color: challengeColor.withOpacity(0.75),
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
                          colors: [color.withOpacity(0.22), color.withOpacity(0.07)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: color.withOpacity(0.75), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: color.withOpacity(0.22), blurRadius: 20),
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
                              color: color.withOpacity(0.70),
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
                colors: [blockChallengeColor.withOpacity(0.22), blockChallengeColor.withOpacity(0.07)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: blockChallengeColor.withOpacity(0.75), width: 1.5),
              boxShadow: [BoxShadow(color: blockChallengeColor.withOpacity(0.20), blurRadius: 20)],
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
                      color: blockChallengeColor.withOpacity(0.75),
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
      color: Colors.black.withOpacity(0.88),
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
                          colors: [_kGold, Color(0xFFD97706)],
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
              ? [_kGold.withOpacity(0.22), _kGold.withOpacity(0.05)]
              : [_kRed.withOpacity(0.18), _kRed.withOpacity(0.04)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVictory ? _kGold.withOpacity(0.55) : _kRed.withOpacity(0.45),
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
                        ? [const Color(0xFF4D8DFF), const Color(0xFF245CC9)]
                        : [const Color(0xFF243047), const Color(0xFF161F30)],
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
                  final roleColor = CardWidget.roleColor(card.roleType);
                  return Container(
                    margin: const EdgeInsets.only(left: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: card.isRevealed ? roleColor.withOpacity(0.14) : _kSurfaceHigh,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: card.isRevealed ? roleColor.withOpacity(0.55) : _kBorder),
                    ),
                    child: Text(
                      card.isRevealed ? card.roleType.firestoreValue[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: card.isRevealed ? roleColor : _kTextSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                }).toList(),
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

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _kTextSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.rajdhani(
              color: _kTextSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.rajdhani(
            color: _kTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
