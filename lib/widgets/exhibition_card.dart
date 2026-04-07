import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import 'collector_chip.dart';

class ExhibitionHeroCard extends StatelessWidget {
  const ExhibitionHeroCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        borderRadius: AppRadii.large,
        gradient: AppColors.exhibitionHeroGradient,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -20,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.18),
              ),
            ),
          ),
          Positioned(
            bottom: 70,
            left: -10,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.14),
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              borderRadius: AppRadii.large,
              gradient: AppColors.heroGradient,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CollectorChip(
                  label: eyebrow,
                  tone: CollectorChipTone.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
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

class ExhibitionGridCard extends StatelessWidget {
  const ExhibitionGridCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.delta,
  });

  final String title;
  final String subtitle;
  final String value;
  final String delta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 172,
            decoration: BoxDecoration(
              borderRadius: AppRadii.medium,
              gradient: AppColors.exhibitionGridGradient,
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome,
                color: AppColors.onBackground,
                size: 42,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Icon(
                Icons.favorite,
                color: AppColors.secondary,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.1),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                    ),
              ),
              const Spacer(),
              Text(
                delta,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.success,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
