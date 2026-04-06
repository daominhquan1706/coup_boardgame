import 'package:coup_boardgame/app/themes/app_colors.dart';
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
          primary: AppColors.dukePrimary,
          secondary: AppColors.dukeSecondary,
          accent: AppColors.dukeAccent,
          ink: AppColors.dukeInk,
        );
      case CoupRoleType.assassin:
        return const _RoleCardPalette(
          primary: AppColors.assassinPrimary,
          secondary: AppColors.assassinSecondary,
          accent: AppColors.assassinAccent,
          ink: AppColors.assassinInk,
        );
      case CoupRoleType.contessa:
        return const _RoleCardPalette(
          primary: AppColors.contessaPrimary,
          secondary: AppColors.contessaSecondary,
          accent: AppColors.contessaAccent,
          ink: AppColors.contessaInk,
        );
      case CoupRoleType.captain:
        return const _RoleCardPalette(
          primary: AppColors.captainPrimary,
          secondary: AppColors.captainSecondary,
          accent: AppColors.captainAccent,
          ink: AppColors.captainInk,
        );
      case CoupRoleType.ambassador:
        return const _RoleCardPalette(
          primary: AppColors.ambassadorPrimary,
          secondary: AppColors.ambassadorSecondary,
          accent: AppColors.ambassadorAccent,
          ink: AppColors.ambassadorInk,
        );
      case CoupRoleType.inquisitor:
        return const _RoleCardPalette(
          primary: AppColors.inquisitorPrimary,
          secondary: AppColors.inquisitorSecondary,
          accent: AppColors.inquisitorAccent,
          ink: AppColors.inquisitorInk,
        );
      default:
        return const _RoleCardPalette(
          primary: AppColors.defaultCardPrimary,
          secondary: AppColors.defaultCardSecondary,
          accent: AppColors.defaultCardAccent,
          ink: AppColors.defaultCardInk,
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
    final imagePath = roleType == null ? null : AssetPaths.roleCardFront(roleType!);
    final w = small ? 64.0 : 96.0;
    final h = small ? 92.0 : 136.0;
    final radius = small ? 10.0 : 14.0;
    final iconSize = small ? 18.0 : 30.0;
    final titleSize = small ? 8.8 : 10.6;
    final nameBarHeight = small ? 16.0 : 22.0;

    return KeyedSubtree(
      key: ValueKey('${roleType?.firestoreValue ?? 'unknown'}-$localeTag-$small-$isEliminated'),
      child: Opacity(
        opacity: isEliminated ? 0.35 : 1.0,
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: AppColors.kBg,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: palette.primary.withValues(alpha: 0.9), width: 1.3),
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
                              padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8),
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
                                    color: palette.primary.withValues(alpha: 0.9),
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
                                      style: GoogleFonts.nunito(
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.52),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: palette.accent.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          'cardStatusLost'.tr,
                          style: GoogleFonts.nunito(
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
    final initial = roleType?.localizedInitial ?? (title.isNotEmpty ? title[0].toUpperCase() : '?');

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
          colors: [AppColors.boardBgDark, AppColors.kBg],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.kGold.withValues(alpha: 0.65), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: (0.4)),
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
              color: AppColors.kGold.withValues(alpha: (0.3)),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.shield_outlined,
            color: AppColors.kGold.withValues(alpha: 0.65),
            size: small ? 16 : 24,
          ),
        ),
      ),
    );
  }
}
