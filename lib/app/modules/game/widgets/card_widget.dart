import 'package:coup_boardgame/app/utils/constants.dart';
import 'package:coup_boardgame/app/utils/functions/coup_function.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class _RoleCardPalette {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color ink;

  const _RoleCardPalette({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.ink,
  });
}

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

  static _RoleCardPalette _rolePalette(CoupRoleType? type) {
    switch (type) {
      case CoupRoleType.duke:
        return const _RoleCardPalette(
          primary: Color(0xFFBE185D),
          secondary: Color(0xFF831843),
          accent: Color(0xFFF9A8D4),
          ink: Color(0xFFFFF1F8),
        );
      case CoupRoleType.assassin:
        return const _RoleCardPalette(
          primary: Color(0xFF374151),
          secondary: Color(0xFF111827),
          accent: Color(0xFF9CA3AF),
          ink: Color(0xFFF3F4F6),
        );
      case CoupRoleType.contessa:
        return const _RoleCardPalette(
          primary: Color(0xFFDC2626),
          secondary: Color(0xFF7F1D1D),
          accent: Color(0xFFFCA5A5),
          ink: Color(0xFFFFF1F2),
        );
      case CoupRoleType.captain:
        return const _RoleCardPalette(
          primary: Color(0xFF38BDF8),
          secondary: Color(0xFF075985),
          accent: Color(0xFFBAE6FD),
          ink: Color(0xFFF0F9FF),
        );
      case CoupRoleType.ambassador:
        return const _RoleCardPalette(
          primary: Color(0xFF84CC16),
          secondary: Color(0xFF365314),
          accent: Color(0xFFEAB308),
          ink: Color(0xFFF7FEE7),
        );
      case CoupRoleType.inquisitor:
        return const _RoleCardPalette(
          primary: Color(0xFFD97706),
          secondary: Color(0xFF4A2508),
          accent: Color(0xFFFDE68A),
          ink: Color(0xFFFFFAEE),
        );
      default:
        return const _RoleCardPalette(
          primary: Color(0xFF475569),
          secondary: Color(0xFF0F172A),
          accent: Color(0xFFCBD5E1),
          ink: Color(0xFFF8FAFC),
        );
    }
  }

  static Color roleColor(CoupRoleType? type) {
    return _rolePalette(type).primary;
  }

  @override
  Widget build(BuildContext context) {
    if (isHidden) return _buildCardBack();
    return _buildCardFront(context);
  }

  Widget _buildCardFront(BuildContext context) {
    final palette = _rolePalette(roleType);
    final title = roleType?.localizedName ?? '?';
    final localeTag = Get.locale?.toLanguageTag() ?? 'en';
    final imagePath =
        roleType == null ? null : AssetPaths.roleCardFront(roleType!);
    final w = small ? 64.0 : 96.0;
    final h = small ? 92.0 : 136.0;
    final radius = small ? 10.0 : 14.0;
    final iconSize = small ? 18.0 : 30.0;
    final titleSize = small ? 8.8 : 10.6;
    final nameBarHeight = small ? 16.0 : 22.0;

    return KeyedSubtree(
      key: ValueKey(
          '${roleType?.firestoreValue ?? 'unknown'}-$localeTag-$small-$isEliminated'),
      child: Opacity(
        opacity: isEliminated ? 0.35 : 1.0,
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: const Color(0xFF0A1020),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
                color: palette.primary.withValues(alpha: 0.9), width: 1.3),
            boxShadow: isEliminated
                ? null
                : [
                    BoxShadow(
                      color: palette.primary.withValues(alpha: 0.26),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius - 0.4),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (imagePath != null)
                            Image.asset(
                              imagePath,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildArtFallback(
                                  palette: palette,
                                  iconSize: iconSize,
                                  title: title,
                                );
                              },
                            )
                          else
                            _buildArtFallback(
                              palette: palette,
                              iconSize: iconSize,
                              title: title,
                            ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.16),
                                  Colors.black.withValues(alpha: 0.58),
                                ],
                                stops: const [0.0, 0.46, 0.72, 1.0],
                              ),
                            ),
                          ),
                          Positioned(
                            top: small ? 5 : 7,
                            right: small ? 5 : 7,
                            child: Container(
                              width: small ? 16 : 20,
                              height: small ? 16 : 20,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.54),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                roleType?.icon ?? Icons.help_outline,
                                color: palette.accent,
                                size: small ? 9 : 11,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              height: nameBarHeight,
                              padding: EdgeInsets.symmetric(
                                  horizontal: small ? 6 : 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.82),
                                    Colors.black.withValues(alpha: 0.7),
                                  ],
                                ),
                                border: Border(
                                  top: BorderSide(
                                    color:
                                        palette.primary.withValues(alpha: 0.9),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: small ? 3 : 4,
                                    height: double.infinity,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: palette.primary,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.rajdhani(
                                        color: Colors.white,
                                        fontSize: titleSize,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.12,
                                        height: 0.98,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isEliminated)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.24),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.52),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: palette.accent.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          'cardStatusLost'.tr,
                          style: GoogleFonts.rajdhani(
                            color: palette.ink.withValues(alpha: 0.78),
                            fontSize: small ? 8 : 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
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
    );
  }

  Widget _buildArtFallback({
    required _RoleCardPalette palette,
    required double iconSize,
    required String title,
  }) {
    final initial = roleType?.localizedInitial ??
        (title.isNotEmpty ? title[0].toUpperCase() : '?');

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.primary.withValues(alpha: 0.9),
            palette.secondary.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            bottom: -12,
            right: -8,
            child: Text(
              initial,
              style: GoogleFonts.cinzel(
                color: Colors.white.withValues(alpha: 0.12),
                fontSize: iconSize * 2.0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Center(
            child: Icon(
              roleType?.icon ?? Icons.help_outline,
              size: iconSize,
              color: palette.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack() {
    final w = small ? 64.0 : 96.0;
    final h = small ? 92.0 : 136.0;
    final radius = small ? 10.0 : 14.0;

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A5F), Color(0xFF0F1E3A)],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFAA9342), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: (0.4)),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: w * 0.7,
          height: h * 0.72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: const Color(0xFFAA9342).withValues(alpha: (0.3)),
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
