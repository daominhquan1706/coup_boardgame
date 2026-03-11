import 'package:coup_boardgame/app/utils/functions/coup_function.dart';
import 'package:flutter/material.dart';

class CardWidget extends StatelessWidget {
  final CoupRoleType? roleType;
  final bool isHidden;
  final bool isEliminated;
  final bool small;

  const CardWidget({
    super.key,
    this.roleType,
    this.isHidden = false,
    this.isEliminated = false,
    this.small = false,
  });

  static Color roleColor(CoupRoleType? type) {
    switch (type) {
      case CoupRoleType.duke:
        return const Color(0xFF7C3AED);
      case CoupRoleType.assassin:
        return const Color(0xFFDC2626);
      case CoupRoleType.contessa:
        return const Color(0xFFDB2777);
      case CoupRoleType.captain:
        return const Color(0xFF2563EB);
      case CoupRoleType.ambassador:
        return const Color(0xFF059669);
      case CoupRoleType.inquisitor:
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF475569);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isHidden) return _buildCardBack();
    return _buildCardFront();
  }

  Widget _buildCardFront() {
    final color = roleColor(roleType);
    final w = small ? 52.0 : 80.0;
    final h = small ? 70.0 : 112.0;
    final iconSize = small ? 18.0 : 28.0;
    final fontSize = small ? 8.0 : 10.0;

    return Opacity(
      opacity: isEliminated ? 0.35 : 1.0,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.72)],
          ),
          borderRadius: BorderRadius.circular(small ? 7 : 10),
          boxShadow: isEliminated
              ? null
              : [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              top: -14,
              right: -14,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(roleType?.icon ?? Icons.help_outline, size: iconSize, color: Colors.white),
                    const SizedBox(height: 5),
                    Text(
                      roleType?.name ?? '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (isEliminated && !small) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LOST',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack() {
    final w = small ? 52.0 : 80.0;
    final h = small ? 70.0 : 112.0;

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A5F), Color(0xFF0F1E3A)],
        ),
        borderRadius: BorderRadius.circular(small ? 7 : 10),
        border: Border.all(color: const Color(0xFFAA9342), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: w * 0.75,
          height: h * 0.78,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: const Color(0xFFAA9342).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.shield_outlined,
            color: const Color(0xFFAA9342),
            size: small ? 16 : 24,
          ),
        ),
      ),
    );
  }
}
