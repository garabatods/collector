import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

enum CollectorButtonVariant {
  primary,
  secondary,
  tertiary,
  icon,
  floating,
}

class CollectorButton extends StatelessWidget {
  const CollectorButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = CollectorButtonVariant.primary,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final CollectorButtonVariant variant;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case CollectorButtonVariant.primary:
        return DecoratedBox(
          decoration: const BoxDecoration(
            borderRadius: AppRadii.medium,
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryShadow,
                blurRadius: 32,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: FilledButton(
            onPressed: isLoading ? null : onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.onPrimary,
              shadowColor: Colors.transparent,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadii.medium,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(label),
          ),
        );
      case CollectorButtonVariant.secondary:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.onSurface,
            side: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadii.medium,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
          ),
          child: Text(label),
        );
      case CollectorButtonVariant.tertiary:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.secondary,
            textStyle: Theme.of(context).textTheme.labelLarge,
          ),
          child: Text(label),
        );
      case CollectorButtonVariant.icon:
        return SizedBox(
          width: 48,
          height: 48,
          child: IconButton.filledTonal(
            onPressed: onPressed,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceContainerHighest,
              foregroundColor: AppColors.primary,
              side: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            icon: Icon(icon ?? Icons.add),
          ),
        );
      case CollectorButtonVariant.floating:
        return DecoratedBox(
          decoration: const BoxDecoration(
            borderRadius: AppRadii.medium,
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryShadowStrong,
                blurRadius: 32,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: SizedBox(
            width: 56,
            height: 56,
            child: IconButton(
              onPressed: isLoading ? null : onPressed,
              color: AppColors.onPrimary,
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(icon ?? Icons.add),
            ),
          ),
        );
    }
  }
}
