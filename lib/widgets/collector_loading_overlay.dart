import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'collector_panel.dart';

class CollectorLoadingOverlay extends StatelessWidget {
  const CollectorLoadingOverlay({
    super.key,
    this.label,
    this.backdropOpacity = 0.18,
  });

  final String? label;
  final double backdropOpacity;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background.withValues(alpha: backdropOpacity),
      child: Center(
        child: CollectorPanel(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          backgroundColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.92),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              if (label != null && label!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  label!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
