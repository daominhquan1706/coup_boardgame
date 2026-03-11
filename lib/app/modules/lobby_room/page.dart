import 'package:coup_boardgame/app/data/model/firestore_model/coup_player_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'controller.dart';

const Color _kBg = Color(0xFF0F1728);
const Color _kSurface = Color(0xFF18243E);
const Color _kSurfaceHigh = Color(0xFF1E2D4E);
const Color _kBorder = Color(0xFF2A3A5E);
const Color _kGold = Color(0xFFD4AF37);
const Color _kGoldLight = Color(0xFFEDD97A);
const Color _kTextPrimary = Color(0xFFE8EDF5);
const Color _kTextSecondary = Color(0xFF7A8CA8);
const Color _kGreen = Color(0xFF2ECC71);
const Color _kRed = Color(0xFFE74C3C);

class LobbyRoomPage extends GetView<LobbyRoomController> {
  const LobbyRoomPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
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
                        _buildRoomCodeCard(),
                        const SizedBox(height: 16),
                        _buildPlayersCard(room),
                        const SizedBox(height: 16),
                        if (controller.isHost) _buildHostControls(),
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

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      decoration: const BoxDecoration(
        color: _kSurface,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: _kGold, size: 18),
          const SizedBox(width: 8),
          Text(
            'COUP',
            style: GoogleFonts.rajdhani(
              color: _kGold,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(width: 14),
          Container(width: 1, height: 16, color: _kBorder),
          const SizedBox(width: 14),
          Text(
            'LOBBY',
            style: GoogleFonts.rajdhani(
              color: _kTextSecondary,
              fontSize: 12,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Obx(() {
            final isHost = controller.isHost;
            if (!isHost) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _kGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kGold.withValues(alpha: 0.4)),
              ),
              child: Text(
                'HOST',
                style: TextStyle(
                  color: _kGold,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRoomCodeCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ROOM CODE',
                style: GoogleFonts.rajdhani(
                  color: _kTextSecondary,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                controller.roomCode ?? '—',
                style: GoogleFonts.rajdhani(
                  color: _kGoldLight,
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 10,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: controller.copyCode,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: _kSurfaceHigh,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.copy_outlined, color: _kTextSecondary, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Copy',
                    style: GoogleFonts.rajdhani(
                      color: _kTextSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersCard(dynamic room) {
    final players = (room?.players as List<CoupPlayerModel>?) ?? [];
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Row(
              children: [
                const Icon(Icons.people_outline, size: 15, color: _kTextSecondary),
                const SizedBox(width: 8),
                Text(
                  'PLAYERS',
                  style: GoogleFonts.rajdhani(
                    color: _kTextSecondary,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kSurfaceHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${players.length}',
                    style: const TextStyle(
                      color: _kTextPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _kBorder),
          if (players.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Waiting for players…',
                textAlign: TextAlign.center,
                style: GoogleFonts.rajdhani(
                  color: _kTextSecondary,
                  fontSize: 14,
                ),
              ),
            )
          else
            ...players.asMap().entries.map((entry) {
              final i = entry.key;
              final player = entry.value;
              return _buildPlayerRow(player, i == players.length - 1);
            }),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(CoupPlayerModel player, bool isLast) {
    final isMe = player.name == controller.userName;
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
                  color: isMe
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.15)
                      : _kSurfaceHigh,
                  border: Border.all(
                    color: isMe ? const Color(0xFF3B82F6).withValues(alpha: 0.5) : _kBorder,
                  ),
                ),
                child: Center(
                  child: Text(
                    player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: isMe ? const Color(0xFF3B82F6) : _kTextSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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
                          player.name,
                          style: GoogleFonts.rajdhani(
                            color: _kTextPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 6),
                          Text(
                            '(you)',
                            style: TextStyle(
                              color: _kTextSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                        if (player.isBot) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: _kGold.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _kGold.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'BOT',
                              style: TextStyle(
                                color: _kGold,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              _ReadyBadge(isReady: player.isReady),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, thickness: 1, color: _kBorder),
      ],
    );
  }

  Widget _buildHostControls() {
    return Obx(() {
      final canStart = controller.canStart;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Start game button
          GestureDetector(
            onTap: canStart ? controller.startGame : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: canStart
                    ? _kGreen.withValues(alpha: 0.14)
                    : _kSurfaceHigh,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: canStart ? _kGreen.withValues(alpha: 0.55) : _kBorder,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Start Game',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rajdhani(
                      color: canStart ? _kGreen : _kTextSecondary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (!canStart)
                    Text(
                      'Need at least 2 players',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _kTextSecondary, fontSize: 11),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SmallButton(
                  label: 'Add Bot',
                  icon: Icons.smart_toy_outlined,
                  color: _kGold,
                  onTap: controller.addAI,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SmallButton(
                  label: 'Remove Bot',
                  icon: Icons.remove_circle_outline,
                  color: _kRed,
                  onTap: controller.removeAI,
                ),
              ),
            ],
          ),
        ],
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
        color: isReady
            ? _kGreen.withValues(alpha: 0.12)
            : _kSurfaceHigh,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isReady ? _kGreen.withValues(alpha: 0.4) : _kBorder,
        ),
      ),
      child: Text(
        isReady ? 'Ready' : 'Waiting',
        style: TextStyle(
          color: isReady ? _kGreen : _kTextSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
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
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.rajdhani(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
