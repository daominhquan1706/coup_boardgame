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
const Color _kBlue = Color(0xFF3B82F6);

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 48),
                  _buildNameField(),
                  const SizedBox(height: 20),
                  _buildCreateSection(),
                  const SizedBox(height: 28),
                  _buildDivider(),
                  const SizedBox(height: 28),
                  _buildJoinSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_outlined, color: _kGold, size: 26),
            const SizedBox(width: 10),
            Text(
              'COUP',
              style: GoogleFonts.rajdhani(
                color: _kGoldLight,
                fontSize: 36,
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.shield_outlined, color: _kGold, size: 26),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'THE BOARD GAME',
          textAlign: TextAlign.center,
          style: GoogleFonts.rajdhani(
            color: _kTextSecondary,
            fontSize: 11,
            letterSpacing: 4,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR NAME',
          style: GoogleFonts.rajdhani(
            color: _kTextSecondary,
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _BoardTextField(
          onChanged: controller.name.call,
          hintText: 'Enter display name',
          prefixIcon: Icons.person_outline,
        ),
      ],
    );
  }

  Widget _buildCreateSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _kGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.add_circle_outline, color: _kGreen, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'Create a Room',
                style: GoogleFonts.rajdhani(
                  color: _kTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Start a new game and invite friends.',
            style: TextStyle(color: _kTextSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Obx(
            () => _BoardButton(
              label: 'Create Room',
              color: _kGreen,
              enabled: controller.name.value.isNotEmpty,
              onTap: controller.onTapCreateRoom,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: _kBorder, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'OR',
            style: GoogleFonts.rajdhani(
              color: _kTextSecondary,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: _kBorder, thickness: 1)),
      ],
    );
  }

  Widget _buildJoinSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _kBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.login_outlined, color: _kBlue, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'Join a Room',
                style: GoogleFonts.rajdhani(
                  color: _kTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Enter a room code to join a game.',
            style: TextStyle(color: _kTextSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          _BoardTextField(
            onChanged: controller.roomCode.call,
            hintText: 'Enter room code (e.g. 1234)',
            prefixIcon: Icons.tag,
          ),
          const SizedBox(height: 12),
          Obx(
            () => _BoardButton(
              label: 'Join Room',
              color: _kBlue,
              enabled: controller.roomCode.value.isNotEmpty,
              onTap: controller.onTapJoinRoom,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared styled text field ─────────────────────────────────────────────────
class _BoardTextField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String hintText;
  final IconData prefixIcon;

  const _BoardTextField({
    required this.onChanged,
    required this.hintText,
    required this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(color: _kTextPrimary, fontSize: 14),
      cursorColor: _kGold,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: _kTextSecondary, fontSize: 13),
        prefixIcon: Icon(prefixIcon, color: _kTextSecondary, size: 18),
        filled: true,
        fillColor: _kSurfaceHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kGold, width: 1.5),
        ),
      ),
    );
  }
}

// ─── Shared styled button ─────────────────────────────────────────────────────
class _BoardButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _BoardButton({
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: enabled ? color.withValues(alpha: 0.14) : _kSurfaceHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? color.withValues(alpha: 0.6) : _kBorder,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.rajdhani(
            color: enabled ? color : _kTextSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
