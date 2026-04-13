import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import 'category_icon.dart';
import 'collector_bottom_sheet.dart';

class AddItemMethodSheet extends StatelessWidget {
  const AddItemMethodSheet({
    super.key,
    required this.title,
    required this.description,
    required this.category,
    required this.onScanBarcode,
    required this.onIdentifyWithAi,
    required this.onAddManually,
    this.onChooseCategory,
    this.requireCategory = false,
    this.showCategoryContext = true,
  });

  final String title;
  final String description;
  final String? category;
  final VoidCallback onScanBarcode;
  final VoidCallback onIdentifyWithAi;
  final VoidCallback onAddManually;
  final VoidCallback? onChooseCategory;
  final bool requireCategory;
  final bool showCategoryContext;

  @override
  Widget build(BuildContext context) {
    final selectedCategory = category?.trim();
    final hasCategory = selectedCategory != null && selectedCategory.isNotEmpty;
    final actionsEnabled = !requireCategory || hasCategory;

    return CollectorBottomSheet(
      title: title,
      description: description,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showCategoryContext) ...[
            _AddItemCategoryContextRow(
              category: selectedCategory,
              isRequired: requireCategory && !hasCategory,
              onTap: onChooseCategory,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          _AddItemActionButton(
            label: 'Scan barcode',
            helperText: 'Best for boxed items with a visible UPC or EAN.',
            icon: Icons.qr_code_scanner_rounded,
            tone: AppColors.primary,
            onPressed: actionsEnabled ? onScanBarcode : null,
          ),
          const SizedBox(height: AppSpacing.md),
          _AddItemActionButton(
            label: 'Identify with AI',
            helperText: 'Use a photo for loose, rare, or barcode-less pieces.',
            icon: Icons.auto_awesome_rounded,
            tone: AppColors.tertiary,
            onPressed: actionsEnabled ? onIdentifyWithAi : null,
          ),
          const SizedBox(height: AppSpacing.md),
          _AddItemActionButton(
            label: 'Add manually',
            helperText:
                'Start from a clean form when you already know the item.',
            icon: Icons.add_photo_alternate_outlined,
            tone: AppColors.secondary,
            onPressed: actionsEnabled ? onAddManually : null,
          ),
        ],
      ),
    );
  }
}

class _AddItemActionButton extends StatelessWidget {
  const _AddItemActionButton({
    required this.label,
    required this.helperText,
    required this.icon,
    required this.tone,
    required this.onPressed,
  });

  final String label;
  final String helperText;
  final IconData icon;
  final Color tone;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final effectiveTone = enabled ? tone : AppColors.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadii.large,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer.withValues(
              alpha: enabled ? 1 : 0.54,
            ),
            borderRadius: AppRadii.large,
            border: Border.all(
              color: effectiveTone.withValues(alpha: enabled ? 0.28 : 0.14),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: effectiveTone.withValues(alpha: enabled ? 0.14 : 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: effectiveTone, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: enabled
                            ? AppColors.onSurface
                            : AppColors.onSurfaceVariant.withValues(
                                alpha: 0.62,
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      helperText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant.withValues(
                          alpha: enabled ? 1 : 0.58,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.arrow_forward_rounded,
                color: effectiveTone.withValues(alpha: enabled ? 1 : 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddItemCategoryContextRow extends StatelessWidget {
  const _AddItemCategoryContextRow({
    required this.category,
    required this.isRequired,
    required this.onTap,
  });

  final String? category;
  final bool isRequired;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasCategory = category != null && category!.isNotEmpty;
    const requiredTone = AppColors.categoryAmberForeground;
    final foreground = isRequired ? requiredTone : AppColors.onSurface;
    final accent = isRequired ? requiredTone : AppColors.primary;
    final border = isRequired
        ? requiredTone.withValues(alpha: 0.42)
        : AppColors.outlineVariant.withValues(alpha: 0.18);
    final trailingLabel = hasCategory
        ? (onTap == null ? 'Selected' : 'Change')
        : 'Choose';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.medium,
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: AppRadii.medium,
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              CategoryIcon(category: category, size: 30, fallbackColor: accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  hasCategory ? 'Adding to $category' : 'Category',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: foreground),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    trailingLabel,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isRequired
                          ? requiredTone
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: AppSpacing.xxs),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isRequired
                          ? requiredTone
                          : AppColors.onSurfaceVariant,
                      size: 18,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
