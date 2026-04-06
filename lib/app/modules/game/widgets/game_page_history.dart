part of '../page.dart';

String _localizedRoleLabel(String? card, {String fallback = 'UNKNOWN'}) {
  final roleType = CoupRoleTypeX.tryFromFirestoreValue(card);
  if (roleType != null) return roleType.localizedName;

  final normalized = card?.trim();
  if (normalized == null || normalized.isEmpty) return fallback;
  return normalized.toUpperCase();
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
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: _HistoryPanel(entries: entries, controller: controller),
        ),
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
        final card = _localizedRoleLabel(entry.claimedCard);
        return '$actor reveal $card';
      case 'challenge_called':
        return target == null
            ? '$actor ${'gameChallenge'.tr} $action'
            : '$actor ${'gameChallenge'.tr} $target ($action)';
      case 'challenge_pass':
        return 'gamePassedChallenge'.trParams({'actor': actor});
      case 'block_called':
        final card = _localizedRoleLabel(entry.claimedCard);
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
    AppToast.success('gameLogsCopied'.tr);
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupedEntries();
    final timelineStartMs = _timelineStartMs();
    final viewport = _GameViewport.of(context);

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
            child: viewport.isPhone
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.history_rounded, size: 18, color: _kGold),
                          const SizedBox(width: 8),
                          Text(
                            'gameHistory'.tr,
                            style: GoogleFonts.nunito(
                              color: _kGoldLight,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'gameEvents'.trParams({'count': '${entries.length}'}),
                            style: GoogleFonts.nunito(
                              color: _kTextSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                            ),
                          ),
                          if (groups.isNotEmpty) ...[
                            const SizedBox(width: 6),
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
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      const Icon(Icons.history_rounded, size: 18, color: _kGold),
                      const SizedBox(width: 8),
                      Text(
                        'gameHistory'.tr,
                        style: GoogleFonts.nunito(
                          color: _kGoldLight,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'gameEvents'.trParams({'count': '${entries.length}'}),
                        style: GoogleFonts.nunito(
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
                      style: GoogleFonts.nunito(
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
      return delta < 0 ? AppColors.redError : AppColors.greenEmerald;
    }
    if (entry.eventType == 'influence_revealed') {
      return AppColors.kGoldAmber;
    }

    switch (entry.eventType) {
      case 'challenge_called':
      case 'block_challenge_called':
        return AppColors.kGoldDark;
      case 'block_called':
        return AppColors.eventPurple;
      default:
        break;
    }

    final role = _roleFromActionType(entry.actionType);
    if (role != null) return CardWidget.roleColor(role);

    switch (entry.actionType) {
      case 'income':
        return AppColors.greenEmerald;
      case 'foreign_aid':
        return AppColors.eventCyan;
      case 'tax':
        return AppColors.eventViolet;
      case 'assassinate':
        return AppColors.redError;
      case 'steal':
        return AppColors.kBlue;
      case 'exchange':
        return AppColors.eventTeal;
      case 'coup':
        return AppColors.kGoldAmber;
      default:
        return _kTextSecondary;
    }
  }

  List<InlineSpan> _spans(GameHistoryEntry entry) {
    final actor = controller.displayNameOf(entry.actorName);
    final target = entry.targetName == null ? null : controller.displayNameOf(entry.targetName);
    final actionLabel = _actionLabel(entry.actionType);
    final actionColor = _eventAccent(entry);
    final base = GoogleFonts.nunito(
      color: _kTextSecondary,
      fontSize: 11.5,
      fontWeight: FontWeight.w500,
    );
    final strong = GoogleFonts.nunito(
      color: _kTextPrimary,
      fontSize: 11.8,
      fontWeight: FontWeight.w700,
    );
    final actionStrong = GoogleFonts.nunito(
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
          style: GoogleFonts.nunito(
            color: delta < 0 ? AppColors.redError : AppColors.greenEmerald,
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
        final roleType = CoupRoleTypeX.tryFromFirestoreValue(entry.claimedCard);
        final card = roleType?.localizedName ?? _localizedRoleLabel(entry.claimedCard);
        final revealColor = roleType == null ? actionColor : CardWidget.roleColor(roleType);
        spans.add(TextSpan(text: ' reveal ', style: base));
        spans.add(TextSpan(
          text: card,
          style: GoogleFonts.nunito(
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
        final roleType = CoupRoleTypeX.tryFromFirestoreValue(entry.claimedCard);
        final card =
            roleType?.localizedName ?? _localizedRoleLabel(entry.claimedCard, fallback: '');
        final roleColor = roleType == null ? actionColor : CardWidget.roleColor(roleType);
        spans.add(TextSpan(
            text: " ${'gameBlockedWith'.trParams({'actor': '', 'card': ''}).trim()} ",
            style: base));
        spans.add(TextSpan(
          text: card,
          style: GoogleFonts.nunito(
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
        color: _kSurfaceHigh.withValues(alpha: (0.92)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder.withValues(alpha: (0.9))),
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
                  style: GoogleFonts.nunito(
                    color: _eventAccent(root),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Text(
                _timeLabel(root.createdAt),
                style: GoogleFonts.nunito(
                  color: _kTextSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          for (var i = 0; i < group.entries.length; i++)
            _TimelineEntryRow(
              spans: _spans(group.entries[i]),
              timeLabel: _timeLabel(group.entries[i].createdAt),
              isFirst: i == 0,
              isLast: i == group.entries.length - 1,
              accentColor: _eventAccent(group.entries[i]),
            ),
        ],
      ),
    );
  }
}

class _TimelineEntryRow extends StatelessWidget {
  final List<InlineSpan> spans;
  final String timeLabel;
  final bool isFirst;
  final bool isLast;
  final Color accentColor;

  const _TimelineEntryRow({
    required this.spans,
    required this.timeLabel,
    required this.isFirst,
    required this.isLast,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isFirst ? Colors.transparent : _kBorder.withValues(alpha: (0.6)),
                    ),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: (0.9)),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isLast ? Colors.transparent : _kBorder.withValues(alpha: (0.6)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: RichText(text: TextSpan(children: spans))),
            const SizedBox(width: 6),
            Text(
              timeLabel,
              style: GoogleFonts.nunito(
                color: _kTextSecondary.withValues(alpha: (0.9)),
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
            style: GoogleFonts.nunito(
              color: _kTextSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.nunito(
            color: _kTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
