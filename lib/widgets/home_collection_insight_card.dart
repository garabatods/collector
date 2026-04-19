import 'package:flutter/material.dart';

import '../features/home/data/models/home_collection_insight.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../theme/app_spacing.dart';

class HomeCollectionInsightCard extends StatelessWidget {
  const HomeCollectionInsightCard({
    super.key,
    required this.insight,
    required this.onPressed,
  });

  final HomeCollectionInsight insight;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = resolveHomeCollectionInsightAccentStyle(insight.accent);
    final isInteractive = onPressed != null;

    return Semantics(
      button: isInteractive,
      label: 'Collection insight',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: accent.borderColor),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.backgroundColor,
                  AppColors.surfaceContainerHigh.withValues(alpha: 0.98),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.glowColor,
                  blurRadius: 28,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.headline,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontFamily: AppFonts.plusJakartaSans,
                      color: AppColors.onSurface,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    insight.supportingText,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  if (insight.action != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: accent.foregroundColor.withValues(
                              alpha: 0.12,
                            ),
                            border: Border.all(
                              color: accent.borderColor.withValues(alpha: 0.9),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                insight.action!.label,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: accent.foregroundColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: accent.foregroundColor,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

HomeCollectionInsightAccentStyle resolveHomeCollectionInsightAccentStyle(
  HomeCollectionInsightAccent accent,
) {
  switch (accent) {
    case HomeCollectionInsightAccent.violet:
      return const HomeCollectionInsightAccentStyle(
        backgroundColor: Color(0x332B2763),
        borderColor: Color(0x4D9396FF),
        foregroundColor: AppColors.primary,
        glowColor: Color(0x1F6063EE),
      );
    case HomeCollectionInsightAccent.azure:
      return const HomeCollectionInsightAccentStyle(
        backgroundColor: Color(0x33113545),
        borderColor: Color(0x4D86E3FF),
        foregroundColor: AppColors.categoryAzureForeground,
        glowColor: Color(0x1A169FD8),
      );
    case HomeCollectionInsightAccent.emerald:
      return const HomeCollectionInsightAccentStyle(
        backgroundColor: Color(0x3313352D),
        borderColor: Color(0x4D91F2C0),
        foregroundColor: AppColors.categoryEmeraldForeground,
        glowColor: Color(0x1A12A06F),
      );
    case HomeCollectionInsightAccent.amber:
      return const HomeCollectionInsightAccentStyle(
        backgroundColor: Color(0x33463716),
        borderColor: Color(0x4DFFD38A),
        foregroundColor: AppColors.categoryAmberForeground,
        glowColor: Color(0x18F59E0B),
      );
    case HomeCollectionInsightAccent.rose:
      return const HomeCollectionInsightAccentStyle(
        backgroundColor: Color(0x33462238),
        borderColor: Color(0x4DFFA5D9),
        foregroundColor: AppColors.categoryRoseForeground,
        glowColor: Color(0x1AAE3E73),
      );
    case HomeCollectionInsightAccent.warm:
      return const HomeCollectionInsightAccentStyle(
        backgroundColor: Color(0x33423124),
        borderColor: Color(0x4DFFB195),
        foregroundColor: AppColors.categoryCoralForeground,
        glowColor: Color(0x1A9F5537),
      );
  }
}

class HomeCollectionInsightAccentStyle {
  const HomeCollectionInsightAccentStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
    required this.glowColor,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final Color glowColor;
}
