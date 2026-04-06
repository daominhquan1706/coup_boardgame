import 'dart:async';
import 'dart:math' as math;

import 'package:coup_boardgame/app/data/model/game_history_entry.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_card_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_player_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_room_model.dart';
import 'package:coup_boardgame/app/modules/game/widgets/card_widget.dart';
import 'package:coup_boardgame/app/themes/app_colors.dart';
import 'package:coup_boardgame/app/utils/functions/coup_function.dart';
import 'package:coup_boardgame/app/utils/widgets/app_toast.dart';
import 'package:coup_boardgame/app/utils/widgets/e2e_tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import 'controller.dart';

part 'widgets/game_page_top_bar.dart';
part 'widgets/game_page_table_arena.dart';
part 'widgets/game_page_action_panel.dart';
part 'widgets/game_page_history.dart';
part 'widgets/game_page_rules_settings.dart';
part 'widgets/game_page_end_screen.dart';
part 'widgets/game_page_widgets.dart';
part 'widgets/game_page_motion.dart';

// ─── Design tokens (aliases to AppColors for convenience within game module) ──
const _kBg = AppColors.kBg;
const _kSurface = AppColors.kSurface;
const _kSurfaceHigh = AppColors.kSurfaceHigh;
const _kBorder = AppColors.kBorder;
const _kGold = AppColors.kGold;
const _kGoldLight = AppColors.kGoldLight;
const _kTextPrimary = AppColors.kTextPrimary;
const _kTextSecondary = AppColors.kTextSecondary;
const _kRed = AppColors.redAccent;

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

class _WaitingIndicator extends StatelessWidget {
  final String? message;

  const _WaitingIndicator({this.message});

  @override
  Widget build(BuildContext context) {
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
}

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
    switch (tab) {
      case _GameScreenTab.game:
        return 'tabGame'.tr;
      case _GameScreenTab.history:
        return 'tabHistory'.tr;
      case _GameScreenTab.rules:
        return 'tabRules'.tr;
      case _GameScreenTab.settings:
        return 'tabSettings'.tr;
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

  bool _shouldShowWaitingBar(CoupRoomModel room) {
    if (room.roomState != GameState.playing) return false;

    switch (room.phase) {
      case GamePhase.challenge:
        return !controller.canRespondChallenge(room);
      case GamePhase.block:
        return !controller.canRespondBlock(room);
      case GamePhase.blockChallenge:
        return !controller.canRespondBlockChallenge(room);
      default:
        return false;
    }
  }

  String _getWaitingMessageForPhase(CoupRoomModel room) {
    switch (room.phase) {
      case GamePhase.challenge:
        return 'gameWaitingChallenge'.tr;
      case GamePhase.block:
        return 'gameWaitingBlock'.tr;
      case GamePhase.blockChallenge:
        return 'gameWaitingBlockChallenge'.tr;
      default:
        return 'gameWaitingOthersResponse'.tr;
    }
  }

  Widget _buildWaitingIndicatorForPhase(CoupRoomModel room) {
    return _WaitingIndicator(message: _getWaitingMessageForPhase(room));
  }

  Widget _tabViewFor(
    _GameScreenTab tab, {
    required CoupRoomModel room,
    required List<GameHistoryEntry> entries,
    required _GameViewport viewport,
  }) {
    switch (tab) {
      case _GameScreenTab.game:
        return _GameBoardTab(room: room, controller: controller, viewport: viewport);
      case _GameScreenTab.history:
        return _HistoryTabView(entries: entries, controller: controller, viewport: viewport);
      case _GameScreenTab.rules:
        return const _RulesTabView();
      case _GameScreenTab.settings:
        return _SettingsTabView(room: room, controller: controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewport = _GameViewport.of(context);
    final useRailNav = viewport.width >= 1120;

    return Obx(() {
      final room = controller.currentRoom.value;
      final entries = controller.historyEntries.toList(growable: false);
      final tabContent = room == null
          ? const SizedBox.shrink()
          : IndexedStack(
              index: _currentTab.index,
              children: _GameScreenTab.values
                  .map(
                    (tab) => _tabViewFor(
                      tab,
                      room: room,
                      entries: entries,
                      viewport: viewport,
                    ),
                  )
                  .toList(),
            );

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
                        style: GoogleFonts.nunito(color: _kTextSecondary, fontSize: 14)),
                  ],
                ),
              )
            : E2ETag(
                label: 'e2e-game-screen',
                child: SafeArea(
                  child: Column(
                    children: [
                      _TopBar(room: room, controller: controller),
                      Expanded(
                        child: useRailNav
                            ? Row(
                                children: [
                                  E2ETag(
                                    label: 'e2e-game-nav-rail',
                                    child: Container(
                                      width: 96,
                                      decoration: const BoxDecoration(
                                        color: _kSurface,
                                        border: Border(right: BorderSide(color: _kBorder)),
                                      ),
                                      child: NavigationRail(
                                        backgroundColor: Colors.transparent,
                                        selectedIndex: _currentTab.index,
                                        labelType: NavigationRailLabelType.all,
                                        minWidth: 68,
                                        minExtendedWidth: 96,
                                        selectedLabelTextStyle: GoogleFonts.nunito(
                                          color: _kGold,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        unselectedLabelTextStyle: GoogleFonts.nunito(
                                          color: _kTextSecondary,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        onDestinationSelected: (index) {
                                          setState(() {
                                            _currentTab = _GameScreenTab.values[index];
                                          });
                                        },
                                        destinations: _GameScreenTab.values
                                            .map(
                                              (tab) => NavigationRailDestination(
                                                icon:
                                                    Icon(_iconForTab(tab), color: _kTextSecondary),
                                                selectedIcon:
                                                    Icon(_iconForTab(tab), color: _kGoldLight),
                                                label: Text(_labelForTab(tab)),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                  Expanded(child: tabContent),
                                ],
                              )
                            : tabContent,
                      ),
                    ],
                  ),
                ),
              ),
        bottomNavigationBar: room == null || useRailNav
            ? null
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_shouldShowWaitingBar(room))
                    Container(
                      height: 32,
                      color: _kSurfaceHigh,
                      child: _buildWaitingIndicatorForPhase(room),
                    ),
                  E2ETag(
                    label: 'e2e-game-nav-bottom',
                    child: NavigationBar(
                      height: 74,
                      backgroundColor: _kSurface,
                      indicatorColor: _kGold.withValues(alpha: (0.16)),
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
                  ),
                ],
              ),
      );
    });
  }
}
