import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

enum CollectorChipTone {
  primary,
  secondary,
  tertiary,
  neutral,
}

class CollectorChip extends StatelessWidget {
  const CollectorChip({
    super.key,
    required this.label,
    this.tone = CollectorChipTone.neutral,
  });

  final String label;
  final CollectorChipTone tone;

  @override
  Widget build(BuildContext context) {
    final style = switch (tone) {
      CollectorChipTone.primary => (
          background: AppColors.primaryContainer.withValues(alpha: 0.18),
          foreground: AppColors.primary,
          border: AppColors.primary.withValues(alpha: 0.2),
        ),
      CollectorChipTone.secondary => (
          background: AppColors.secondaryContainer.withValues(alpha: 0.18),
          foreground: AppColors.secondary,
          border: AppColors.secondary.withValues(alpha: 0.2),
        ),
      CollectorChipTone.tertiary => (
          background: AppColors.tertiaryContainer.withValues(alpha: 0.18),
          foreground: AppColors.tertiary,
          border: AppColors.tertiary.withValues(alpha: 0.2),
        ),
      CollectorChipTone.neutral => (
          background: AppColors.surfaceContainerHighest,
          foreground: AppColors.onSurfaceVariant,
          border: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: AppRadii.pill,
        border: Border.all(color: style.border),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: style.foreground,
              fontSize: 10,
            ),
      ),
    );
  }
}
