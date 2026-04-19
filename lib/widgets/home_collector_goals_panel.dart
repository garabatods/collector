import 'package:flutter/material.dart';

import '../features/gamification/data/models/collector_badge.dart';
import '../features/gamification/data/models/collector_goal.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'collector_panel.dart';

class HomeCollectorGoalsPanel extends StatelessWidget {
  const HomeCollectorGoalsPanel({super.key, required this.goals});

  final List<CollectorGoal> goals;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COLLECTOR GOALS',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.88),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        CollectorPanel(
          padding: const EdgeInsets.all(AppSpacing.md),
          backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.94),
          child: Column(
            children: [
              for (var index = 0; index < goals.length; index++) ...[
                _GoalRow(goal: goals[index]),
                if (index != goals.length - 1) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Divider(
                    height: 1,
                    color: AppColors.outlineVariant.withValues(alpha: 0.14),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.goal});

  final CollectorGoal goal;

  @override
  Widget build(BuildContext context) {
    final rewardBadge = _badgeForId(goal.rewardBadgeId);
    final accentColor = rewardBadge?.accentColor ?? AppColors.primary;
    final progressValue = goal.progressValue;
    final primaryTitle = rewardBadge?.title ?? goal.title;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GoalRewardMedal(
            badge: rewardBadge,
            accentColor: accentColor,
            compact: true,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primaryTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    height: 1.1,
                    color: accentColor,
                  ),
                ),
                if (progressValue != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progressValue,
                            minHeight: 8,
                            backgroundColor: accentColor.withValues(
                              alpha: 0.16,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              accentColor,
                            ),
                          ),
                        ),
                      ),
                      if (goal.progressLabel != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          goal.progressLabel!,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: accentColor,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text(
                  goal.title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurface,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalRewardMedal extends StatelessWidget {
  const _GoalRewardMedal({
    required this.badge,
    required this.accentColor,
    required this.compact,
  });

  final CollectorBadgeDefinition? badge;
  final Color accentColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 48.0 : 58.0;
    final iconSize = compact ? 20.0 : 24.0;

    return SizedBox(
      width: size,
      height: size,
      child: badge == null
          ? Icon(Icons.auto_awesome_rounded, color: accentColor, size: iconSize)
          : Image.asset(badge!.assetPath, fit: BoxFit.contain),
    );
  }
}

CollectorBadgeDefinition? _badgeForId(CollectorBadgeId? id) {
  if (id == null) {
    return null;
  }

  for (final badge in collectorBadgeDefinitions) {
    if (badge.id == id) {
      return badge;
    }
  }
  return null;
}
