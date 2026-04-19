import 'package:flutter/material.dart';

import '../features/gamification/data/models/collector_badge.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'collector_bottom_sheet.dart';
import 'collector_button.dart';

class CollectorBadgeUnlockSheet extends StatelessWidget {
  const CollectorBadgeUnlockSheet({
    super.key,
    required this.awards,
    this.primaryActionLabel,
    this.onPrimaryAction,
  });

  final List<CollectorBadgeAward> awards;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final singleAward = awards.length == 1 ? awards.first : null;

    return CollectorBottomSheet(
      title: awards.length == 1 ? 'Badge Unlocked' : 'New Badges Unlocked',
      description: awards.length == 1
          ? 'Your archive just unlocked a new milestone.'
          : 'Your archive just unlocked ${awards.length} new milestones.',
      footer: CollectorButton(
        label: primaryActionLabel ?? 'Nice',
        onPressed: () {
          Navigator.of(context).pop();
          onPrimaryAction?.call();
        },
      ),
      child: singleAward != null
          ? _SingleBadgeUnlockBody(award: singleAward)
          : _MultiBadgeUnlockBody(awards: awards),
    );
  }
}

class _SingleBadgeUnlockBody extends StatelessWidget {
  const _SingleBadgeUnlockBody({required this.award});

  final CollectorBadgeAward award;

  @override
  Widget build(BuildContext context) {
    final badge = award.badge;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 168,
            height: 168,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  badge.accentColor.withValues(alpha: 0.18),
                  badge.accentColor.withValues(alpha: 0.07),
                  Colors.transparent,
                ],
              ),
              border: Border.all(
                color: badge.accentColor.withValues(alpha: 0.16),
              ),
              boxShadow: [
                BoxShadow(
                  color: badge.accentColor.withValues(alpha: 0.14),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Image.asset(badge.assetPath, fit: BoxFit.contain),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.onSurface,
              height: 1.05,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              badge.description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MultiBadgeUnlockBody extends StatelessWidget {
  const _MultiBadgeUnlockBody({required this.awards});

  final List<CollectorBadgeAward> awards;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final award in awards.take(4))
              _CelebrationBadgeTile(award: award),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          awards.map((award) => award.badge.title).join(' • '),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _CelebrationBadgeTile extends StatelessWidget {
  const _CelebrationBadgeTile({required this.award});

  final CollectorBadgeAward award;

  @override
  Widget build(BuildContext context) {
    final badge = award.badge;

    return SizedBox(
      width: 112,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  badge.accentColor.withValues(alpha: 0.18),
                  badge.accentColor.withValues(alpha: 0.06),
                  Colors.transparent,
                ],
              ),
            ),
            child: Image.asset(badge.assetPath, fit: BoxFit.contain),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.onSurface,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
