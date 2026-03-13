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

part 'widgets/game_page_top_bar.dart';
part 'widgets/game_page_table_arena.dart';
part 'widgets/game_page_action_panel.dart';
part 'widgets/game_page_history.dart';
part 'widgets/game_page_rules_settings.dart';
part 'widgets/game_page_end_screen.dart';
part 'widgets/game_page_widgets.dart';

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
      );
    });
  }
}
