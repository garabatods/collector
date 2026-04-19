import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'collector_bottom_sheet.dart';
import 'collector_button.dart';

class CollectorStatusIntroSheet extends StatelessWidget {
  const CollectorStatusIntroSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return CollectorBottomSheet(
      title: 'Start building your collector status',
      description:
          'Every item you add gets you closer to new Collector Goals. Unlock badges, grow your Collector Level, and make your profile feel more like your collection.',
      footer: CollectorButton(
        label: 'Got it',
        onPressed: () => Navigator.of(context).pop(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CollectorStatusShowcase(),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'This is your progress, your style, and your shelf in one place.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectorStatusShowcase extends StatelessWidget {
  const _CollectorStatusShowcase();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.14),
            AppColors.surfaceContainerHighest.withValues(alpha: 0.42),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR PATH',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              letterSpacing: 2.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Row(
            children: [
              Expanded(
                child: _CollectorStatusShowcaseTile(
                  assetPath: 'assets/badges/01_first_shelf.png',
                  label: 'Goals',
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _CollectorStatusShowcaseTile(
                  assetPath: 'assets/badges/07_photo_ready.png',
                  label: 'Badges',
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _CollectorStatusShowcaseTile(
                  assetPath: 'assets/collector_levels/collector_level_3.png',
                  label: 'Level',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollectorStatusShowcaseTile extends StatelessWidget {
  const _CollectorStatusShowcaseTile({
    required this.assetPath,
    required this.label,
  });

  final String assetPath;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 88,
          height: 88,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.16),
                AppColors.primary.withValues(alpha: 0.05),
                Colors.transparent,
              ],
            ),
          ),
          child: Image.asset(assetPath, fit: BoxFit.contain),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
