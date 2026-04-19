import 'package:flutter/material.dart';

import '../core/collector_haptics.dart';
import '../core/data/archive_repository.dart';
import '../core/data/archive_types.dart';
import '../features/collection/data/models/collectible_model.dart';
import '../features/collection/data/models/collection_library_navigation_preset.dart';
import '../features/home/data/models/home_collection_insight.dart';
import '../features/home/data/services/home_collection_insight_engine.dart';
import '../features/home/data/services/home_collection_insight_history_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../theme/app_spacing.dart';
import '../widgets/archive_bootstrap_gate.dart';
import '../widgets/collector_button.dart';
import '../widgets/collector_loading_overlay.dart';
import '../widgets/collector_panel.dart';
import '../widgets/home_collection_insight_card.dart';
import 'category_collection_screen.dart';

class CollectionInsightsScreen extends StatefulWidget {
  const CollectionInsightsScreen({
    super.key,
    required this.refreshSeed,
    this.activationRequest = 0,
    required this.onAddFirstItem,
    required this.onOpenLibrary,
    required this.onOpenRecent,
    required this.onOpenFavorites,
  });

  final int refreshSeed;
  final int activationRequest;
  final VoidCallback onAddFirstItem;
  final ValueChanged<CollectionLibraryNavigationPreset?> onOpenLibrary;
  final VoidCallback onOpenRecent;
  final VoidCallback onOpenFavorites;

  @override
  State<CollectionInsightsScreen> createState() =>
      _CollectionInsightsScreenState();
}

class _CollectionInsightsScreenState extends State<CollectionInsightsScreen> {
  final _archiveRepository = ArchiveRepository.instance;
  final _historyStore = HomeCollectionInsightHistoryStore.instance;
  final _scrollController = ScrollController();

  HomeCollectionInsightHistory _history = HomeCollectionInsightHistory.empty;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void didUpdateWidget(covariant CollectionInsightsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSeed != widget.refreshSeed) {
      _archiveRepository.syncIfNeeded(force: true);
    }
    if (oldWidget.activationRequest != widget.activationRequest) {
      _scrollToTop();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await _historyStore.read();
    if (!mounted) {
      return;
    }
    setState(() {
      _history = history;
    });
  }

  Future<void> _reload() async {
    await _archiveRepository.syncIfNeeded(force: true);
    await _loadHistory();
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ArchiveBootstrapGate(
      loadingLabel: 'Loading insights...',
      child: StreamBuilder<ArchiveHomeSummary>(
        stream: _archiveRepository.watchHomeSummary(),
        builder: (context, snapshot) {
          final data = snapshot.data;

          if (snapshot.hasError && data == null) {
            return _InsightsErrorState(onRetry: _reload);
          }

          if (data == null) {
            return const CollectorLoadingOverlay(label: 'Loading insights...');
          }

          if (data.collectibles.isEmpty) {
            return _InsightsEmptyState(onAddFirstItem: widget.onAddFirstItem);
          }

          final rankedInsights = HomeCollectionInsightEngine.rankInsights(
            summary: data,
            history: _history,
          );
          final heroInsight = rankedInsights.isNotEmpty
              ? rankedInsights.first
              : _fallbackInsight(data);
          final supportingInsights = _buildSupportingInsights(
            allInsights: rankedInsights,
            heroInsight: heroInsight,
            totalItems: data.collectibles.length,
          );
          final categoryCount = data.collectibles
              .map((item) => item.category.trim().toLowerCase())
              .where((value) => value.isNotEmpty)
              .toSet()
              .length;

          return RefreshIndicator(
            onRefresh: _reload,
            color: AppColors.primary,
            child: CustomScrollView(
              controller: _scrollController,
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
                          'Insights',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Here is what your collection is showing right now.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.onSurfaceVariant,
                                height: 1.45,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _InsightsSummaryStrip(
                          totalItems: data.collectibles.length,
                          categoryCount: categoryCount,
                        ),
                      ],
                    ),
                  ),
                ),
                if (heroInsight != null) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      child: _HeroInsightSectionLabel(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: HomeCollectionInsightCard(
                        insight: heroInsight,
                        onPressed: heroInsight.action == null
                            ? null
                            : () => _handleInsightAction(heroInsight.action!),
                      ),
                    ),
                  ),
                ],
                if (supportingInsights.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.section,
                        AppSpacing.md,
                        AppSpacing.md,
                      ),
                      child: _InsightsSectionLabel(),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      140,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          for (
                            var index = 0;
                            index < supportingInsights.length;
                            index++
                          ) ...[
                            _CompactInsightCard(
                              insight: supportingInsights[index],
                              onPressed:
                                  supportingInsights[index].action == null
                                  ? null
                                  : () => _handleInsightAction(
                                      supportingInsights[index].action!,
                                    ),
                            ),
                            if (index != supportingInsights.length - 1)
                              const SizedBox(height: AppSpacing.md),
                          ],
                        ],
                      ),
                    ),
                  ),
                ] else
                  const SliverToBoxAdapter(child: SizedBox(height: 140)),
              ],
            ),
          );
        },
      ),
    );
  }

  List<HomeCollectionInsight> _buildSupportingInsights({
    required List<HomeCollectionInsight> allInsights,
    required HomeCollectionInsight? heroInsight,
    required int totalItems,
  }) {
    final maxCards = totalItems >= 10
        ? 6
        : totalItems >= 5
        ? 4
        : totalItems >= 3
        ? 2
        : 0;
    if (maxCards == 0) {
      return const [];
    }

    final remaining = allInsights
        .where((insight) => insight.id != heroInsight?.id)
        .toList(growable: false);
    final selected = <HomeCollectionInsight>[];
    final usedFamilies = <HomeCollectionInsightFamily>{};
    final usedEntities = <String>{};

    for (final insight in remaining) {
      if (selected.length >= maxCards) {
        break;
      }

      final entity = insight.primaryEntityKey?.trim().toLowerCase();
      final isFavoriteFallback =
          insight.action?.type ==
          HomeCollectionInsightActionType.scrollToFavorites;
      if (usedFamilies.contains(insight.family)) {
        continue;
      }
      if (isFavoriteFallback) {
        continue;
      }
      if (entity != null &&
          entity.isNotEmpty &&
          usedEntities.contains(entity)) {
        continue;
      }

      selected.add(insight);
      usedFamilies.add(insight.family);
      if (entity != null && entity.isNotEmpty) {
        usedEntities.add(entity);
      }
    }

    for (final insight in remaining) {
      if (selected.length >= maxCards) {
        break;
      }
      if (selected.any((item) => item.id == insight.id)) {
        continue;
      }
      final entity = insight.primaryEntityKey?.trim().toLowerCase();
      if (entity != null &&
          entity.isNotEmpty &&
          usedEntities.contains(entity)) {
        continue;
      }
      selected.add(insight);
      if (entity != null && entity.isNotEmpty) {
        usedEntities.add(entity);
      }
    }

    return selected;
  }

  HomeCollectionInsight? _fallbackInsight(ArchiveHomeSummary summary) {
    final items = summary.collectibles;
    if (items.isEmpty) {
      return null;
    }

    final topCategory = _topCategoryName(items);
    if (items.length <= 2 && topCategory != null) {
      return HomeCollectionInsight(
        id: 'fallback-small-collection:$topCategory',
        family: HomeCollectionInsightFamily.milestone,
        accent: HomeCollectionInsightAccent.warm,
        headline: '$topCategory are taking shape',
        supportingText:
            'Your first few items are already giving the archive a clear direction.',
        score: 1,
      );
    }

    return HomeCollectionInsight(
      id: 'fallback-small-collection',
      family: HomeCollectionInsightFamily.milestone,
      accent: HomeCollectionInsightAccent.warm,
      headline: 'Your shelf is taking shape',
      supportingText:
          'As your collection grows, this screen will start surfacing stronger signals about what defines it.',
      score: 1,
    );
  }

  String? _topCategoryName(List<CollectibleModel> collectibles) {
    final counts = <String, int>{};
    for (final item in collectibles) {
      final category = item.category.trim();
      if (category.isEmpty) {
        continue;
      }
      counts.update(category, (value) => value + 1, ifAbsent: () => 1);
    }
    if (counts.isEmpty) {
      return null;
    }

    final entries = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount == 0 ? a.key.compareTo(b.key) : byCount;
      });
    return entries.first.key;
  }

  Future<void> _handleInsightAction(HomeCollectionInsightAction action) async {
    switch (action.type) {
      case HomeCollectionInsightActionType.openLibrary:
        CollectorHaptics.light();
        widget.onOpenLibrary(action.toLibraryNavigationPreset());
        return;
      case HomeCollectionInsightActionType.openCategory:
        final category = action.category;
        if (category == null || category.trim().isEmpty) {
          CollectorHaptics.light();
          widget.onOpenLibrary(null);
          return;
        }
        CollectorHaptics.light();
        final changed = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => CategoryCollectionScreen(category: category),
          ),
        );
        if (changed == true) {
          await _reload();
        }
        return;
      case HomeCollectionInsightActionType.scrollToRecent:
        CollectorHaptics.light();
        widget.onOpenRecent();
        return;
      case HomeCollectionInsightActionType.scrollToFavorites:
        CollectorHaptics.light();
        widget.onOpenFavorites();
        return;
    }
  }
}

class _InsightsSectionLabel extends StatelessWidget {
  const _InsightsSectionLabel();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Collection Signals'.toUpperCase(),
      style: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(color: AppColors.outline),
    );
  }
}

class _HeroInsightSectionLabel extends StatelessWidget {
  const _HeroInsightSectionLabel();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Collection Insight'.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: AppColors.onSurfaceVariant.withValues(alpha: 0.88),
        letterSpacing: 1.2,
      ),
    );
  }
}

class _InsightsSummaryStrip extends StatelessWidget {
  const _InsightsSummaryStrip({
    required this.totalItems,
    required this.categoryCount,
  });

  final int totalItems;
  final int categoryCount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        _InsightsSummaryStat(
          label: 'Items',
          value: '$totalItems',
          accentColor: AppColors.primary,
        ),
        _InsightsSummaryStat(
          label: categoryCount == 1 ? 'Category' : 'Categories',
          value: '$categoryCount',
          accentColor: AppColors.categoryAzureForeground,
        ),
      ],
    );
  }
}

class _InsightsSummaryStat extends StatelessWidget {
  const _InsightsSummaryStat({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth == double.infinity
            ? MediaQuery.sizeOf(context).width - (AppSpacing.md * 2)
            : constraints.maxWidth;
        final width = (availableWidth - AppSpacing.md) / 2;

        return SizedBox(
          width: width,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.surfaceContainerHigh.withValues(alpha: 0.94),
              border: Border.all(color: accentColor.withValues(alpha: 0.34)),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.12),
                  blurRadius: 22,
                  spreadRadius: 0.5,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontFamily: AppFonts.plusJakartaSans,
                    height: 1,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CompactInsightCard extends StatelessWidget {
  const _CompactInsightCard({required this.insight, required this.onPressed});

  final HomeCollectionInsight insight;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = resolveHomeCollectionInsightAccentStyle(insight.accent);
    final compactEyebrow = insight.compactEyebrow ?? 'Collection Signal';
    final compactValue = insight.compactValue ?? insight.headline;
    final compactSupportingText =
        insight.compactSupportingText ?? insight.supportingText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: accent.borderColor.withValues(alpha: 0.82),
            ),
            color: AppColors.surfaceContainerHigh.withValues(alpha: 0.96),
            boxShadow: [
              BoxShadow(
                color: accent.glowColor,
                blurRadius: 20,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        compactEyebrow.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: accent.foregroundColor.withValues(alpha: 0.88),
                          letterSpacing: 0.9,
                        ),
                      ),
                    ),
                    if (insight.action != null)
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: accent.foregroundColor,
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  compactValue,
                  style: () {
                    final baseStyle = Theme.of(
                      context,
                    ).textTheme.headlineMedium;
                    return baseStyle?.copyWith(
                      fontFamily: AppFonts.plusJakartaSans,
                      color: AppColors.onSurface,
                      height: 1.02,
                      fontSize: baseStyle.fontSize == null
                          ? null
                          : baseStyle.fontSize! * 0.75,
                    );
                  }(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  compactSupportingText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.32,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InsightsEmptyState extends StatelessWidget {
  const _InsightsEmptyState({required this.onAddFirstItem});

  final VoidCallback onAddFirstItem;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: CollectorPanel(
            padding: const EdgeInsets.all(AppSpacing.xl),
            backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.94),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.insights_rounded,
                  size: 42,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Insights will grow with your shelf.',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Once you add a few pieces, this screen will start surfacing patterns about the categories, brands, favorites, and photo coverage shaping your collection.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: CollectorButton(
                    label: 'Add Your First Item',
                    onPressed: onAddFirstItem,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InsightsErrorState extends StatelessWidget {
  const _InsightsErrorState({required this.onRetry});

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
                'Could not load your insights.',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'The archive is unavailable right now. Try syncing again and your collection signals will come back.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.45,
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
