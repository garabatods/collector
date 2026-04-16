import 'package:flutter/material.dart';

import '../core/collector_haptics.dart';
import '../core/data/archive_types.dart';
import '../features/collection/data/models/collectible_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/archive_photo_view.dart';
import '../widgets/collector_chip.dart';
import '../widgets/collector_panel.dart';
import '../widgets/collector_sticky_back_button.dart';
import 'manual_add_collectible_screen.dart';

const _detailHeaderBottomSpacing = AppSpacing.xl;
const _detailSectionSpacing = 20.0;

class CollectibleDetailScreen extends StatefulWidget {
  const CollectibleDetailScreen({
    super.key,
    required this.collectible,
    this.photoRef,
  });

  final CollectibleModel collectible;
  final ArchivePhotoRef? photoRef;

  @override
  State<CollectibleDetailScreen> createState() =>
      _CollectibleDetailScreenState();
}

class _CollectibleDetailScreenState extends State<CollectibleDetailScreen> {
  Future<void> _editItem() async {
    CollectorHaptics.light();
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ManualAddCollectibleScreen(
          collectible: widget.collectible,
          existingPhotoUrl:
              widget.photoRef?.remoteUrl ?? widget.photoRef?.localPath,
        ),
      ),
    );

    if (!mounted || changed != true) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final collectible = widget.collectible;
    final isComic = _isComicCollectible(collectible);
    final purchasePriceText = _formatCurrency(collectible.purchasePrice);
    final identityFields = <_DetailField>[
      ...?_fieldAsList('Brand', _normalizedText(collectible.brand)),
      ...?_fieldAsList(
        'Line or series',
        _normalizedText(collectible.lineOrSeries ?? collectible.series),
      ),
      ...?_fieldAsList(
        'Character or subject',
        _normalizedText(collectible.characterOrSubject),
      ),
      ...?_fieldAsList(
        'Release year',
        collectible.releaseYear == null ? null : '${collectible.releaseYear}',
      ),
    ];
    final collectorFields = <_DetailField>[
      ...?_fieldAsList(
        'Condition',
        _collectorStatusText(collectible.itemCondition),
      ),
      if (!isComic)
        ...?_fieldAsList(
          'Box status',
          _collectorStatusText(collectible.boxStatus),
        ),
      ...?_fieldAsList('Cost', purchasePriceText),
      ...?_fieldAsList('Acquired', _formatDate(collectible.acquiredOn)),
    ];
    final catalogFields = <_DetailField>[
      ...?_fieldAsList('Item number', _normalizedText(collectible.itemNumber)),
      ...?_fieldAsList('Barcode', _normalizedText(collectible.barcode)),
      ...?_fieldAsList(
        'Estimated value',
        _formatCurrency(collectible.estimatedValue),
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.15,
                  colors: [AppColors.featureGlow, AppColors.background],
                ),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      _detailHeaderBottomSpacing,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const SizedBox(width: 48, height: 48),
                            const Spacer(),
                            SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: _editItem,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: BorderSide(
                                    color: AppColors.outlineVariant.withValues(
                                      alpha: 0.28,
                                    ),
                                  ),
                                  backgroundColor:
                                      AppColors.surfaceContainerHighest,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: const Text('Edit'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _DetailHero(
                          collectible: collectible,
                          photoRef: widget.photoRef,
                          isComic: isComic,
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
                    120,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (collectible.tags.isNotEmpty) ...[
                        _DetailSection(
                          title: 'Tags',
                          child: Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              for (final tag in collectible.tags)
                                CollectorChip(
                                  label: tag.name,
                                  tone: CollectorChipTone.primary,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: _detailSectionSpacing),
                      ],
                      _DetailSection(
                        title: 'Collector Snapshot',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                CollectorChip(label: collectible.category),
                                if (collectible.isFavorite)
                                  const CollectorChip(
                                    label: 'Favorite',
                                    tone: CollectorChipTone.primary,
                                  ),
                                if (collectible.isGrail)
                                  const CollectorChip(
                                    label: 'Grail',
                                    tone: CollectorChipTone.secondary,
                                  ),
                                if (collectible.isDuplicate)
                                  const CollectorChip(
                                    label: 'Duplicate',
                                    tone: CollectorChipTone.tertiary,
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _SnapshotMetricsGrid(
                              collectible: collectible,
                              isComic: isComic,
                            ),
                          ],
                        ),
                      ),
                      if (identityFields.isNotEmpty) ...[
                        const SizedBox(height: _detailSectionSpacing),
                        _DetailSection(
                          title: 'Identity',
                          child: _DetailFactGrid(fields: identityFields),
                        ),
                      ],
                      if (collectorFields.isNotEmpty) ...[
                        const SizedBox(height: _detailSectionSpacing),
                        _DetailSection(
                          title: 'Collector Data',
                          child: _DetailFactGrid(fields: collectorFields),
                        ),
                      ],
                      if (catalogFields.isNotEmpty) ...[
                        const SizedBox(height: _detailSectionSpacing),
                        _DetailSection(
                          title: 'Value & Catalog',
                          child: _DetailFactGrid(fields: catalogFields),
                        ),
                      ],
                      if ((collectible.notes ?? '').isNotEmpty) ...[
                        const SizedBox(height: _detailSectionSpacing),
                        _DetailSection(
                          title: 'Notes',
                          child: Text(
                            collectible.notes!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 14,
                                  height: 1.55,
                                ),
                          ),
                        ),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
          ),
          CollectorStickyBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _DetailHero extends StatelessWidget {
  const _DetailHero({
    required this.collectible,
    required this.photoRef,
    required this.isComic,
  });

  final CollectibleModel collectible;
  final ArchivePhotoRef? photoRef;
  final bool isComic;

  @override
  Widget build(BuildContext context) {
    final accentColor = _accentColorFor(collectible);
    final secondaryAccent = collectible.isGrail
        ? AppColors.tertiary
        : AppColors.secondary;
    final subtitleParts = _distinctNonEmptyText([collectible.brand]);
    final heroTag =
        'detail-photo-${photoRef?.remoteUrl ?? photoRef?.localPath ?? collectible.id ?? collectible.title}';
    return CollectorPanel(
      padding: const EdgeInsets.all(AppSpacing.sm),
      backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.94),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 380,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.16),
                  blurRadius: 42,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: heroTag,
                    child: ArchivePhotoView(
                      photoRef: photoRef,
                      fit: BoxFit.cover,
                      placeholder: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor.withValues(alpha: 0.34),
                              secondaryAccent.withValues(alpha: 0.24),
                              AppColors.surfaceContainerHighest,
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.photo_outlined,
                            color: AppColors.onSurfaceVariant,
                            size: 54,
                          ),
                        ),
                      ),
                      error: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor.withValues(alpha: 0.34),
                              secondaryAccent.withValues(alpha: 0.24),
                              AppColors.surfaceContainerHighest,
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.onSurfaceVariant,
                            size: 54,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_hasArchivePhoto(photoRef))
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            CollectorHaptics.light();
                            Navigator.of(context).push(
                              PageRouteBuilder<void>(
                                opaque: false,
                                pageBuilder: (_, _, _) =>
                                    _FullscreenPhotoScreen(
                                      photoRef: photoRef,
                                      heroTag: heroTag,
                                    ),
                              ),
                            );
                          },
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.background.withValues(alpha: 0.28),
                            AppColors.background.withValues(alpha: 0.92),
                          ],
                          stops: const [0.0, 0.56, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.md,
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    child: IgnorePointer(
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          CollectorChip(label: collectible.category),
                          if (collectible.isFavorite)
                            const CollectorChip(
                              label: 'Favorite',
                              tone: CollectorChipTone.primary,
                            ),
                          if (collectible.isGrail)
                            const CollectorChip(
                              label: 'Grail',
                              tone: CollectorChipTone.secondary,
                            ),
                          if (collectible.isDuplicate)
                            const CollectorChip(
                              label: 'Duplicate',
                              tone: CollectorChipTone.tertiary,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const Positioned(
                    top: AppSpacing.md,
                    right: AppSpacing.md,
                    child: IgnorePointer(child: _HeroExpandHint()),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.background.withValues(alpha: 0.18),
                              AppColors.background.withValues(alpha: 0.88),
                            ],
                            stops: const [0.0, 0.22, 1.0],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.xl,
                            AppSpacing.lg,
                            AppSpacing.lg,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (subtitleParts.isNotEmpty)
                                Text(
                                  subtitleParts.join(' • ').toUpperCase(),
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: accentColor.withValues(
                                          alpha: 0.98,
                                        ),
                                        fontSize: 10.5,
                                        letterSpacing: 1.2,
                                      ),
                                ),
                              if (subtitleParts.isNotEmpty)
                                const SizedBox(height: AppSpacing.xs),
                              Text(
                                collectible.title,
                                style: Theme.of(context).textTheme.headlineLarge
                                    ?.copyWith(
                                      fontSize: 20,
                                      height: 1.16,
                                      letterSpacing: 0,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.26,
                                          ),
                                          blurRadius: 12,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                _buildHeroSummary(collectible),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.onSurface.withValues(
                                        alpha: 0.72,
                                      ),
                                      fontSize: 13.5,
                                      height: 1.4,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              if (isComic) {
                return Row(
                  children: [
                    SizedBox(
                      width: 88,
                      child: _HeroMetricCard(
                        label: 'Issue',
                        value:
                            _normalizedText(collectible.itemNumber) ??
                            'Unknown',
                        accentColor: accentColor,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _HeroMetricCard(
                        label: 'Publisher',
                        value: _normalizedText(collectible.brand) ?? 'Unknown',
                        accentColor: secondaryAccent,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SizedBox(
                      width: 88,
                      child: _HeroMetricCard(
                        label: 'Year',
                        value: collectible.releaseYear?.toString() ?? 'Unknown',
                        accentColor: AppColors.primary,
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _HeroMetricCard(
                      label: 'Condition',
                      value:
                          _collectorStatusText(collectible.itemCondition) ??
                          'Unrated',
                      accentColor: accentColor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: _HeroMetricCard(
                      label: 'Box',
                      value:
                          _collectorStatusText(collectible.boxStatus) ??
                          'Unknown',
                      accentColor: secondaryAccent,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 3,
                    child: _HeroMetricCard(
                      label: 'Cost',
                      value:
                          _formatCurrency(collectible.purchasePrice) ??
                          'Not tracked',
                      accentColor: AppColors.primary,
                    ),
                  ),
                ],
              );
            },
          ),
          if (collectible.purchasePrice != null ||
              collectible.estimatedValue != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _HeroValueStrip(
              purchasePrice: collectible.purchasePrice,
              estimatedValue: collectible.estimatedValue,
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CollectorPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.94),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontSize: 18),
          ),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
  }
}

class _SnapshotMetricsGrid extends StatelessWidget {
  const _SnapshotMetricsGrid({
    required this.collectible,
    required this.isComic,
  });

  final CollectibleModel collectible;
  final bool isComic;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _DetailField(
        label: 'Condition',
        value: _collectorStatusText(collectible.itemCondition) ?? 'Unrated',
      ),
      if (!isComic)
        _DetailField(
          label: 'Box status',
          value: _collectorStatusText(collectible.boxStatus) ?? 'Unknown',
        ),
      _DetailField(
        label: 'Cost',
        value: _formatCurrency(collectible.purchasePrice) ?? 'Not tracked',
      ),
      _DetailField(
        label: 'Estimated value',
        value: _formatCurrency(collectible.estimatedValue) ?? 'Not tracked',
      ),
    ];

    return _DetailFactGrid(
      fields: metrics,
      preferredColumns: 2,
      minColumnWidth: 132,
      horizontalSpacing: AppSpacing.sm,
      verticalSpacing: AppSpacing.xs,
    );
  }
}

class _DetailFactGrid extends StatelessWidget {
  const _DetailFactGrid({
    required this.fields,
    this.preferredColumns = 2,
    this.minColumnWidth = 144,
    this.horizontalSpacing = AppSpacing.md,
    this.verticalSpacing = AppSpacing.sm,
  });

  final List<_DetailField> fields;
  final int preferredColumns;
  final double minColumnWidth;
  final double horizontalSpacing;
  final double verticalSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final supportsPreferredColumns =
            preferredColumns > 1 &&
            maxWidth >=
                (preferredColumns * minColumnWidth) +
                    ((preferredColumns - 1) * horizontalSpacing);
        final columnCount = supportsPreferredColumns ? preferredColumns : 1;
        final itemWidth = columnCount == 1
            ? maxWidth
            : (maxWidth - ((columnCount - 1) * horizontalSpacing)) /
                  columnCount;

        return Wrap(
          spacing: horizontalSpacing,
          runSpacing: verticalSpacing,
          children: [
            for (final field in fields)
              SizedBox(
                width: itemWidth,
                child: _DetailFactTile(field: field),
              ),
          ],
        );
      },
    );
  }
}

class _DetailFactTile extends StatelessWidget {
  const _DetailFactTile({required this.field});

  final _DetailField field;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            field.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 10,
              letterSpacing: 1.35,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            field.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontSize: 15, height: 1.08),
          ),
        ],
      ),
    );
  }
}

class _HeroMetricCard extends StatelessWidget {
  const _HeroMetricCard({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.18),
            AppColors.surfaceContainerHighest.withValues(alpha: 0.76),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 14,
              height: 1.05,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroExpandHint extends StatelessWidget {
  const _HeroExpandHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.24),
        ),
      ),
      child: const Icon(
        Icons.open_in_full_rounded,
        size: 18,
        color: AppColors.onSurface,
      ),
    );
  }
}

class _HeroValueStrip extends StatelessWidget {
  const _HeroValueStrip({
    required this.purchasePrice,
    required this.estimatedValue,
  });

  final double? purchasePrice;
  final double? estimatedValue;

  @override
  Widget build(BuildContext context) {
    final purchase = _formatCurrency(purchasePrice);
    final estimated = _formatCurrency(estimatedValue);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.tertiary.withValues(alpha: 0.1),
            AppColors.surfaceContainerHighest.withValues(alpha: 0.78),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          if (purchase != null)
            Expanded(
              child: _ValueMetric(
                label: 'Purchase',
                value: purchase,
                accentColor: AppColors.onSurface,
              ),
            ),
          if (purchase != null && estimated != null)
            Container(
              width: 1,
              height: 40,
              color: AppColors.outlineVariant.withValues(alpha: 0.35),
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            ),
          if (estimated != null)
            Expanded(
              child: _ValueMetric(
                label: 'Estimated',
                value: estimated,
                accentColor: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}

class _FullscreenPhotoScreen extends StatelessWidget {
  const _FullscreenPhotoScreen({required this.photoRef, required this.heroTag});

  final ArchivePhotoRef? photoRef;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: SafeArea(
          child: Center(
            child: Hero(
              tag: heroTag,
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: ArchivePhotoView(
                  photoRef: photoRef,
                  fit: BoxFit.contain,
                  placeholder: const SizedBox.shrink(),
                  error: const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ValueMetric extends StatelessWidget {
  const _ValueMetric({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontSize: 17, color: accentColor),
        ),
      ],
    );
  }
}

class _DetailField {
  const _DetailField({required this.label, required this.value});

  final String label;
  final String value;
}

_DetailField? _fieldIfValue(String label, String? value) {
  if (value == null) {
    return null;
  }

  return _DetailField(label: label, value: value);
}

List<_DetailField>? _fieldAsList(String label, String? value) {
  final field = _fieldIfValue(label, value);
  return field == null ? null : [field];
}

String? _normalizedText(String? value) {
  if (value == null) {
    return null;
  }

  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String? _collectorStatusText(String? value) {
  final normalized = _normalizedText(value);
  if (normalized == null) {
    return null;
  }

  return _toTitleCase(normalized);
}

String? _formatCurrency(double? value) {
  if (value == null) {
    return null;
  }

  final hasDecimals = value % 1 != 0;
  final amount = hasDecimals
      ? value.toStringAsFixed(2)
      : value.toStringAsFixed(0);
  return '\$$amount';
}

String? _formatDate(DateTime? value) {
  if (value == null) {
    return null;
  }

  const monthNames = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${monthNames[value.month - 1]} ${value.day}, ${value.year}';
}

Color _accentColorFor(CollectibleModel collectible) {
  if (collectible.isGrail) {
    return AppColors.secondary;
  }
  if (collectible.isFavorite) {
    return AppColors.tertiary;
  }
  if (collectible.isDuplicate) {
    return AppColors.warning;
  }
  return AppColors.primary;
}

String _buildHeroSummary(CollectibleModel collectible) {
  final parts = <String>[
    ..._distinctNonEmptyText([
      collectible.category,
      collectible.lineOrSeries ?? collectible.series,
      collectible.characterOrSubject,
    ]),
  ];

  if (parts.isEmpty) {
    return 'Catalog this piece with richer details to make the page feel even more complete.';
  }

  return parts.join(' • ');
}

bool _isComicCollectible(CollectibleModel collectible) {
  return collectible.category.trim().toLowerCase() == 'comics' ||
      (collectible.itemNumber ?? '').trim().isNotEmpty;
}

bool _hasArchivePhoto(ArchivePhotoRef? photoRef) {
  final localPath = photoRef?.localPath?.trim();
  if (localPath != null && localPath.isNotEmpty) {
    return true;
  }

  final remoteUrl = photoRef?.remoteUrl?.trim();
  return remoteUrl != null && remoteUrl.isNotEmpty;
}

List<String> _distinctNonEmptyText(Iterable<String?> values) {
  final seen = <String>{};
  final result = <String>[];

  for (final value in values) {
    final normalized = _normalizedText(value);
    if (normalized == null) {
      continue;
    }

    final key = normalized.toLowerCase();
    if (seen.add(key)) {
      result.add(normalized);
    }
  }

  return result;
}

String _toTitleCase(String value) {
  final compact = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (compact.isEmpty) {
    return value;
  }

  return compact
      .split(' ')
      .map((word) {
        if (word.isEmpty) {
          return word;
        }

        if (word.toUpperCase() == word && word.length <= 4) {
          return word;
        }

        final first = word.substring(0, 1).toUpperCase();
        final rest = word.substring(1).toLowerCase();
        return '$first$rest';
      })
      .join(' ');
}
