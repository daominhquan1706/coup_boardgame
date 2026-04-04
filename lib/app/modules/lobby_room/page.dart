import 'package:coup_boardgame/app/data/model/firestore_model/coup_player_model.dart';
import 'package:coup_boardgame/app/themes/app_colors.dart';
import 'package:coup_boardgame/app/themes/app_text_theme.dart';
import 'package:coup_boardgame/app/utils/widgets/e2e_tag.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:coup_boardgame/app/routes/app_pages.dart';
import 'controller.dart';

class LobbyRoomPage extends GetView<LobbyRoomController> {
  const LobbyRoomPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Obx(() {
                    final room = controller.room.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildRoomCodeCard(context),
                        const SizedBox(height: 16),
                        _buildMyInfoCard(context),
                        const SizedBox(height: 16),
                        _buildPlayersCard(context, room),
                        const SizedBox(height: 16),
                        if (controller.isHost) _buildHostControls(context),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      decoration: const BoxDecoration(
        color: AppColors.kSurface,
        border: Border(bottom: BorderSide(color: AppColors.kBorder)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.kGold, size: 18),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Get.offAllNamed(AppRoutes.home),
            child: Text(
              'COUP',
              style: AppTextStyles.display.w700.s20.goldColor.ls(4),
            ),
          ),
          const SizedBox(width: 14),
          Container(width: 1, height: 16, color: AppColors.kBorder),
          const SizedBox(width: 14),
          Text(
            'lobbyTitle'.tr,
            style: AppTextStyles.title,
          ),
          const Spacer(),
          Obx(() {
            final isHost = controller.isHost;
            if (!isHost) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.kGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.kGold.withValues(alpha: 0.4)),
              ),
              child: Text(
                'host'.tr,
                style: AppTextStyles.label.s10.w700.goldColor.ls(1.2),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRoomCodeCard(BuildContext context) {
    return E2ETag(
      label: 'e2e-lobby-room-code-card',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.kBorder),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'lobbyRoomCode'.tr,
                  style: AppTextStyles.title,
                ),
                const SizedBox(height: 4),
                Text(
                  controller.roomCode ?? '—',
                  style: AppTextStyles.display.w700.s38.goldLightColor.ls(10),
                ),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: controller.copyCode,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.kSurfaceHigh,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.copy_outlined, color: AppColors.kTextSecondary, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'copy'.tr,
                      style: AppTextStyles.label,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayersCard(BuildContext context, dynamic room) {
    final players = (room?.players as List<CoupPlayerModel>?) ?? [];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Row(
              children: [
                const Icon(Icons.people_outline, size: 15, color: AppColors.kTextSecondary),
                const SizedBox(width: 8),
                Text(
                  'lobbyPlayers'.tr,
                  style: AppTextStyles.title,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.kSurfaceHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${players.length}',
                    style: AppTextStyles.body.s11.w700.textPrimary,
                  ),
                ),
                const Spacer(),
                if (controller.isHost)
                  E2ETag(
                    label: 'e2e-lobby-add-bot-button',
                    button: true,
                    child: _SmallButton(
                      label: 'lobbyAddBot'.tr,
                      icon: Icons.smart_toy_outlined,
                      color: AppColors.kGold,
                      onTap: controller.addAI,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.kBorder),
          if (players.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'lobbyWaitingPlayers'.tr,
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
            )
          else
            ...players.asMap().entries.map((entry) {
              final i = entry.key;
              final player = entry.value;
              return _buildPlayerRow(context, player, i == players.length - 1);
            }),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(BuildContext context, CoupPlayerModel player, bool isLast) {
    final isMe = player.name == controller.userName;
    final canKick = controller.isHost && !isMe;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isMe ? AppColors.kBlue.withValues(alpha: 0.15) : AppColors.kSurfaceHigh,
                  border: Border.all(
                    color: isMe ? AppColors.kBlue.withValues(alpha: 0.5) : AppColors.kBorder,
                  ),
                ),
                child: Center(
                  child: Text(
                    player.shownName.isNotEmpty ? player.shownName[0].toUpperCase() : '?',
                    style: AppTextStyles.body.w700.s14.copyWith(
                      color: isMe ? AppColors.kBlue : AppColors.kTextSecondary,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          player.shownName,
                          style: AppTextStyles.body,
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 6),
                          Text(
                            '(${"you".tr})',
                            style: AppTextStyles.body.s11.textSecondary,
                          ),
                        ],
                        if (player.isBot) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.kGold.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.kGold.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'lobbyBot'.tr,
                              style: AppTextStyles.label.s9.w700.goldColor.ls(0.8),
                            ),
                          ),
                        ],
                        const SizedBox(width: 6),
                        _ReadyBadge(isReady: player.isReady),
                      ],
                    ),
                  ],
                ),
              ),
              if (canKick) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => controller.kickPlayer(player.name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.redAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.redAccent.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'lobbyKick'.tr,
                      style: AppTextStyles.body.s11.w700.redAccentColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, thickness: 1, color: AppColors.kBorder),
      ],
    );
  }

  Widget _buildHostControls(BuildContext context) {
    return Obx(() {
      final canStart = controller.canStart;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Start game button
          E2ETag(
            label: canStart
                ? 'e2e-lobby-start-game-button-ready'
                : 'e2e-lobby-start-game-button-disabled',
            button: true,
            enabled: canStart,
            child: GestureDetector(
              onTap: canStart ? controller.startGame : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: canStart
                      ? AppColors.greenLight.withValues(alpha: 0.14)
                      : AppColors.kSurfaceHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        canStart ? AppColors.greenLight.withValues(alpha: 0.55) : AppColors.kBorder,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'lobbyStartGame'.tr,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headline.w700.copyWith(
                        color: canStart ? AppColors.greenLight : AppColors.kTextSecondary,
                      ),
                    ),
                    if (!canStart)
                      Text(
                        'lobbyNeedTwoPlayers'.tr,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.s11.textSecondary,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildMyInfoCard(BuildContext context) {
    return Obx(() {
      final me = controller.mePlayer;
      final isReady = me?.isReady ?? false;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: AppColors.kTextSecondary),
                const SizedBox(width: 8),
                Text(
                  'lobbyMyInfo'.tr,
                  style: AppTextStyles.title.s12.w700.ls(1.5),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller.displayNameController,
              onChanged: controller.onDisplayNameChanged,
              style: AppTextStyles.body,
              cursorColor: AppColors.kGold,
              decoration: InputDecoration(
                hintText: 'homeEnterDisplayName'.tr,
                hintStyle: AppTextStyles.label,
                filled: true,
                fillColor: AppColors.kSurfaceHigh,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.kGold, width: 1.3),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SmallButton(
                    label: 'lobbyEditName'.tr,
                    icon: Icons.edit_outlined,
                    color: AppColors.kBlue,
                    onTap: controller.updateMyDisplayName,
                  ),
                ),
                if (!controller.isHost) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SmallButton(
                      label: isReady ? 'lobbyUnready'.tr : 'lobbyReady'.tr,
                      icon: isReady ? Icons.pause_circle_outline : Icons.check_circle_outline,
                      color: isReady ? AppColors.kTextSecondary : AppColors.greenLight,
                      onTap: controller.toggleReady,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _ReadyBadge extends StatelessWidget {
  final bool isReady;
  const _ReadyBadge({required this.isReady});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isReady ? AppColors.greenLight.withValues(alpha: 0.12) : AppColors.kSurfaceHigh,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isReady ? AppColors.greenLight.withValues(alpha: 0.4) : AppColors.kBorder,
        ),
      ),
      child: Text(
        isReady ? 'ready'.tr : 'waiting'.tr,
        style: AppTextStyles.body.s11.copyWith(
          color: isReady ? AppColors.greenLight : AppColors.kTextSecondary,
        ),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SmallButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14).paddingOnly(left: 6),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.label.w700.copyWith(color: color),
            ).paddingOnly(right: 6),
          ],
        ),
      ),
    );
  }
}
