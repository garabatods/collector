import 'package:flutter/material.dart';

import '../core/data/archive_repository.dart';
import '../core/data/archive_types.dart';
import '../features/wishlist/data/models/wishlist_item_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/archive_bootstrap_gate.dart';
import '../widgets/collector_button.dart';
import '../widgets/collector_chip.dart';
import '../widgets/collector_loading_overlay.dart';
import '../widgets/collector_panel.dart';

class CollectionWishlistScreen extends StatefulWidget {
  const CollectionWishlistScreen({
    super.key,
    required this.refreshSeed,
  });

  final int refreshSeed;

  @override
  State<CollectionWishlistScreen> createState() =>
      _CollectionWishlistScreenState();
}

class _CollectionWishlistScreenState extends State<CollectionWishlistScreen> {
  final _archiveRepository = ArchiveRepository.instance;

  @override
  void didUpdateWidget(covariant CollectionWishlistScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSeed != widget.refreshSeed) {
      _archiveRepository.syncIfNeeded(force: true);
    }
  }

  Future<void> _reload() async {
    await _archiveRepository.syncIfNeeded(force: true);
  }

  @override
  Widget build(BuildContext context) {
    return ArchiveBootstrapGate(
      loadingLabel: 'Loading wishlist...',
      child: StreamBuilder<ArchiveWishlistSummary>(
        stream: _archiveRepository.watchWishlistSummary(),
        builder: (context, snapshot) {
          final data = snapshot.data;

          if (snapshot.hasError && data == null) {
            return _WishlistErrorState(onRetry: _reload);
          }

          if (data == null) {
            return const CollectorLoadingOverlay(label: 'Loading wishlist...');
          }

          if (data.items.isEmpty) {
            return const _WishlistEmptyState();
          }

          final items = [...data.items]..sort((a, b) {
              final aDate = a.createdAt ??
                  a.updatedAt ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final bDate = b.createdAt ??
                  b.updatedAt ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              return bDate.compareTo(aDate);
            });

          return RefreshIndicator(
            onRefresh: _reload,
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wishlist',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${items.length} wanted item${items.length == 1 ? '' : 's'} saved for later.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    140,
                  ),
                  sliver: SliverList.separated(
                    itemBuilder: (context, index) {
                      return _WishlistCard(item: items[index]);
                    },
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemCount: items.length,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WishlistCard extends StatelessWidget {
  const _WishlistCard({required this.item});

  final WishlistItemModel item;

  @override
  Widget build(BuildContext context) {
    final detailLine = <String>[
      if ((item.brand ?? '').trim().isNotEmpty) item.brand!.trim(),
      if ((item.series ?? item.lineOrSeries ?? '').trim().isNotEmpty)
        (item.series ?? item.lineOrSeries)!.trim(),
      if (item.releaseYear != null) '${item.releaseYear}',
    ];

    return CollectorPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.94),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.category,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                  ],
                ),
              ),
              CollectorChip(
                label: _priorityLabel(item.priority),
                tone: _priorityTone(item.priority),
              ),
            ],
          ),
          if (detailLine.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              detailLine.join(' • '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          ],
          if ((item.notes ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              item.notes!.trim(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.45,
                  ),
            ),
          ],
          if (item.targetPrice != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Target: ${_formatCurrency(item.targetPrice)}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.onSurface,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WishlistEmptyState extends StatelessWidget {
  const _WishlistEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: CollectorPanel(
          padding: const EdgeInsets.all(AppSpacing.xl),
          backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.94),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite_outline_rounded,
                size: 42,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No wishlist items yet.',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Once you start saving wanted pieces, they will stay available here even when you are offline.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WishlistErrorState extends StatelessWidget {
  const _WishlistErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: CollectorPanel(
          padding: const EdgeInsets.all(AppSpacing.xl),
          backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.94),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 42,
                color: AppColors.secondary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Could not load your wishlist.',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'The local archive is unavailable right now. Try syncing again.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              CollectorButton(label: 'Retry', onPressed: () => onRetry()),
            ],
          ),
        ),
      ),
    );
  }
}

CollectorChipTone _priorityTone(String priority) {
  switch (priority.trim().toLowerCase()) {
    case 'high':
      return CollectorChipTone.secondary;
    case 'low':
      return CollectorChipTone.tertiary;
    default:
      return CollectorChipTone.primary;
  }
}

String _priorityLabel(String priority) {
  final normalized = priority.trim().toLowerCase();
  if (normalized.isEmpty) {
    return 'Priority';
  }

  return '${normalized[0].toUpperCase()}${normalized.substring(1)} Priority';
}

String _formatCurrency(double? value) {
  if (value == null) {
    return '--';
  }
  return '\$${value.toStringAsFixed(2)}';
}
