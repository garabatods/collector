import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

class CollectorBottomSheet extends StatelessWidget {
  const CollectorBottomSheet({
    super.key,
    required this.title,
    required this.description,
    required this.child,
    this.footer,
    this.maxHeightFactor = 0.88,
  });

  final String title;
  final String description;
  final Widget child;
  final Widget? footer;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxSheetHeight = mediaQuery.size.height * maxHeightFactor;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: _CollectorBottomSheetHeader(
                  onClose: () => Navigator.of(context).pop(),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    footer == null ? AppSpacing.lg : AppSpacing.md,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      child,
                    ],
                  ),
                ),
              ),
              if (footer != null)
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    border: Border(
                      top: BorderSide(
                        color: AppColors.outlineVariant.withValues(alpha: 0.18),
                      ),
                    ),
                  ),
                  child: footer,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectorBottomSheetHeader extends StatelessWidget {
  const _CollectorBottomSheetHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Tooltip(
              message: 'Close',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onClose,
                  borderRadius: AppRadii.medium,
                  child: Ink(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest.withValues(
                        alpha: 0.38,
                      ),
                      borderRadius: AppRadii.medium,
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.onSurfaceVariant,
                      size: 19,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
