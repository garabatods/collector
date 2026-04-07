import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../theme/app_spacing.dart';

class CollectorWordmark extends StatelessWidget {
  const CollectorWordmark({
    super.key,
    this.showAccentLine = true,
    this.scale = 1,
    this.useShareTechMono = false,
  });

  final bool showAccentLine;
  final double scale;
  final bool useShareTechMono;

  @override
  Widget build(BuildContext context) {
    final baseTitleStyle = Theme.of(context).textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -1.6 * scale,
        );
    final titleStyle = useShareTechMono
        ? baseTitleStyle?.copyWith(
            fontFamily: AppFonts.shareTechMono,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.8 * scale,
          )
        : baseTitleStyle;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showAccentLine)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 48 * scale,
              height: 2,
              color: AppColors.primary.withValues(alpha: 0.4),
              margin: EdgeInsets.only(
                left: 12 * scale,
                bottom: AppSpacing.sm * scale,
              ),
            ),
          ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 180 * scale,
              height: 90 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    blurRadius: 64 * scale,
                    spreadRadius: 12 * scale,
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: Center(
                child: Text(
                  'COLLECTOR',
                  style: titleStyle,
                ),
              ),
            ),
            Positioned(
              right: 12 * scale,
              top: 18 * scale,
              child: Container(
                width: 8 * scale,
                height: 8 * scale,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.45),
                      blurRadius: 12 * scale,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
