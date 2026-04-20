import 'package:flutter/material.dart';

import '../core/data/archive_types.dart';
import '../features/collection/data/models/collectible_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'archive_photo_view.dart';
import 'collector_button.dart';
import 'collector_chip.dart';
import 'collector_panel.dart';

class CollectorHighlightPanel extends StatelessWidget {
  const CollectorHighlightPanel({
    super.key,
    required this.totalItems,
    required this.featuredItem,
    required this.featuredPhotoRef,
    required this.favoriteCategory,
    required this.onOpenFeaturedItem,
    required this.onAddItem,
  });

  final int totalItems;
  final CollectibleModel? featuredItem;
  final ArchivePhotoRef? featuredPhotoRef;
  final String? favoriteCategory;
  final VoidCallback onOpenFeaturedItem;
  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    if (totalItems == 0) {
      return CollectorPanel(
        padding: const EdgeInsets.all(AppSpacing.lg),
        backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.94),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start building your shelf',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Once you add your first collectible, this space can spotlight a favorite piece, the category you collect most, or the latest addition worth showing off.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            CollectorButton(label: 'Add First Item', onPressed: onAddItem),
          ],
        ),
      );
    }

    final featured = featuredItem;
    if (featured == null) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenFeaturedItem,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.16),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ArchivePhotoView(
                          photoRef: featuredPhotoRef,
                          fit: BoxFit.cover,
                          placeholder: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.22),
                                  AppColors.surfaceContainerHighest,
                                  AppColors.surfaceContainerLow,
                                ],
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.collections_bookmark_outlined,
                                size: 42,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          error: const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 36,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x0D0B0E14), Color(0xE60B0E14)],
                            ),
                          ),
                        ),
                        Positioned(
                          left: AppSpacing.md,
                          right: AppSpacing.md,
                          bottom: AppSpacing.md,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                favoriteCategory != null &&
                                        featured.category
                                                .trim()
                                                .toLowerCase() ==
                                            favoriteCategory!
                                                .trim()
                                                .toLowerCase()
                                    ? 'Spotlight from your top category'
                                    : featured.isFavorite
                                    ? 'Featured on your shelf'
                                    : 'Latest shelf addition',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(color: AppColors.primary),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                featured.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                [
                                  featured.category,
                                  if (featured.brand?.trim().isNotEmpty == true)
                                    featured.brand!.trim(),
                                ].join(' • '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if (favoriteCategory != null)
                      CollectorChip(label: 'Top category: $favoriteCategory'),
                    if (featured.isFavorite)
                      const CollectorChip(label: 'Favorited piece'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
