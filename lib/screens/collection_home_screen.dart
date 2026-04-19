import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/collector_haptics.dart';
import '../core/data/archive_repository.dart';
import '../core/data/archive_types.dart';
import '../core/data/session_cache.dart';
import '../features/collection/data/models/collectible_detail_navigation_context.dart';
import '../features/collection/data/models/collection_library_navigation_preset.dart';
import '../features/collection/data/models/collectible_model.dart';
import '../features/gamification/data/models/collector_badge.dart';
import '../features/gamification/data/models/collector_goal.dart';
import '../features/gamification/data/services/collector_badge_award_store.dart';
import '../features/gamification/data/services/collector_badge_engine.dart';
import '../features/gamification/data/services/collector_goal_engine.dart';
import '../features/home/data/models/home_collection_insight.dart';
import '../features/home/data/services/home_collection_insight_engine.dart';
import '../features/home/data/services/home_collection_insight_history_store.dart';
import '../features/profile/data/models/profile_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../theme/app_spacing.dart';
import '../widgets/archive_bootstrap_gate.dart';
import '../widgets/category_icon.dart';
import '../widgets/collector_badge_unlock_sheet.dart';
import '../widgets/collectible_grid_card.dart';
import '../widgets/collector_button.dart';
import '../widgets/collector_panel.dart';
import '../widgets/collector_section_header.dart';
import '../widgets/collector_skeleton.dart';
import '../widgets/home_collector_goals_panel.dart';
import '../widgets/home_collection_insight_card.dart';
import '../widgets/resolved_avatar_image.dart';
import 'all_categories_screen.dart';
import 'category_collection_screen.dart';

const _homeTopChromeColor = AppColors.dashboardGlow;
const _homeCollectionInsightSessionKey = 'home_collection_insight.selection';

enum CollectionHomeScrollTarget { recent, favorites }

class CollectionHomeScreen extends StatefulWidget {
  const CollectionHomeScreen({
    super.key,
    required this.isSupabaseConfigured,
    required this.refreshSeed,
    required this.onAddFirstItem,
    required this.onScanItem,
    required this.onOpenLibrary,
    required this.onOpenInsights,
    required this.onOpenProfile,
    this.scrollRequest,
    this.scrollTarget,
  });

  final bool isSupabaseConfigured;
  final int refreshSeed;
  final VoidCallback onAddFirstItem;
  final VoidCallback onScanItem;
  final ValueChanged<CollectionLibraryNavigationPreset?> onOpenLibrary;
  final VoidCallback onOpenInsights;
  final VoidCallback onOpenProfile;
  final int? scrollRequest;
  final CollectionHomeScrollTarget? scrollTarget;

  @override
  State<CollectionHomeScreen> createState() => _CollectionHomeScreenState();
}

class _CollectionHomeScreenState extends State<CollectionHomeScreen> {
  final _archiveRepository = ArchiveRepository.instance;

  late Stream<ArchiveHomeSummary> _stream;

  @override
  void initState() {
    super.initState();
    _stream = _archiveRepository.watchHomeSummary();
  }

  @override
  void didUpdateWidget(covariant CollectionHomeScreen oldWidget) {
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: _homeTopChromeColor,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: ArchiveBootstrapGate(
        child: StreamBuilder<ArchiveHomeSummary>(
          stream: _stream,
          builder: (context, snapshot) {
            final data = snapshot.data;

            if (snapshot.hasError && data == null) {
              return const _HomeMessageState(
                icon: Icons.cloud_off_rounded,
                title: 'Could not load your collection.',
                description:
                    'We could not reach your collection data. Check your connection and try again.',
                tone: AppColors.secondary,
              );
            }

            if (data == null) {
              return const _CollectionHomeLoadingState();
            }

            if (data.collectibles.isEmpty) {
              return _EmptyHomeState(
                wishlistCount: data.wishlistCount,
                onAddFirstItem: widget.onAddFirstItem,
                onScanItem: widget.onScanItem,
                onOpenProfile: widget.onOpenProfile,
              );
            }

            return Stack(
              children: [
                _LoadedHomeState(
                  data: data,
                  collectibles: data.collectibles,
                  onCollectionChanged: _reload,
                  onAddFirstItem: widget.onAddFirstItem,
                  onOpenLibrary: widget.onOpenLibrary,
                  onOpenInsights: widget.onOpenInsights,
                  onOpenProfile: widget.onOpenProfile,
                  scrollRequest: widget.scrollRequest,
                  scrollTarget: widget.scrollTarget,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoadedHomeState extends StatefulWidget {
  const _LoadedHomeState({
    required this.data,
    required this.collectibles,
    required this.onCollectionChanged,
    required this.onAddFirstItem,
    required this.onOpenLibrary,
    required this.onOpenInsights,
    required this.onOpenProfile,
    this.scrollRequest,
    required this.scrollTarget,
  });

  final ArchiveHomeSummary data;
  final List<CollectibleModel> collectibles;
  final Future<void> Function() onCollectionChanged;
  final VoidCallback onAddFirstItem;
  final ValueChanged<CollectionLibraryNavigationPreset?> onOpenLibrary;
  final VoidCallback onOpenInsights;
  final VoidCallback onOpenProfile;
  final int? scrollRequest;
  final CollectionHomeScrollTarget? scrollTarget;

  @override
  State<_LoadedHomeState> createState() => _LoadedHomeStateState();
}

class _LoadedHomeStateState extends State<_LoadedHomeState> {
  late final ScrollController _scrollController;
  final _historyStore = HomeCollectionInsightHistoryStore.instance;
  final _badgeAwardStore = CollectorBadgeAwardStore.instance;
  final _recentSectionKey = GlobalKey();
  final _favoritesSectionKey = GlobalKey();

  HomeCollectionInsightHistory? _insightHistory;
  HomeCollectionInsight? _selectedInsight;
  List<CollectorGoal> _collectorGoals = const [];
  bool _isResolvingInsight = true;
  String? _lastGamificationSignature;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadInsightHistory();
    _syncGamification();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _LoadedHomeState oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data && _insightHistory != null) {
      _resolveInsight();
    }
    if (oldWidget.data != widget.data) {
      _syncGamification();
    }
    if ((oldWidget.scrollRequest ?? 0) != (widget.scrollRequest ?? 0) &&
        widget.scrollTarget != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        final targetKey =
            widget.scrollTarget == CollectionHomeScrollTarget.recent
            ? _recentSectionKey
            : _favoritesSectionKey;
        _scrollToSection(targetKey);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final compactLayout = screenWidth < 380 || textScale > 1.1;
    final allCategoryHighlights = _buildCategoryHighlights(widget.collectibles);
    final categoryHighlights = allCategoryHighlights
        .take(6)
        .toList(growable: false);
    final recentItems = widget.data.recentItems;
    final favoriteItems = widget.data.favoriteItems;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: _HomeWelcomeHeader(
                profile: widget.data.profile,
                profileAvatarUrl: widget.data.profile?.avatarUrl?.trim(),
                onOpenProfile: widget.onOpenProfile,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                140,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CollectorSectionHeader(title: 'Categories'),
                  const SizedBox(height: AppSpacing.md),
                  if (categoryHighlights.isEmpty)
                    const _InlineMessagePanel(
                      title: 'No category matches yet.',
                      description:
                          'Try a broader search or add another collectible to grow the mix.',
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final availableWidth = constraints.maxWidth;
                        final cardHeight = compactLayout ? 76.0 : 84.0;
                        final twoColumnWidth =
                            (availableWidth - AppSpacing.md) / 2;

                        return Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.md,
                          children: [
                            for (
                              var index = 0;
                              index < categoryHighlights.length;
                              index++
                            )
                              _CategoryShowcaseTile(
                                width: _categoryCardWidthForIndex(
                                  index: index,
                                  itemCount: categoryHighlights.length,
                                  fullWidth: availableWidth,
                                  halfWidth: twoColumnWidth,
                                ),
                                alignToCenter:
                                    _categoryCardShouldCenterForIndex(
                                      index: index,
                                      itemCount: categoryHighlights.length,
                                    ),
                                child: _CategoryShowcaseCard(
                                  category: categoryHighlights[index],
                                  compactLayout: compactLayout,
                                  height: cardHeight,
                                  onTap: () async {
                                    await _openCategoryCollection(
                                      categoryHighlights[index].title,
                                    );
                                  },
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: allCategoryHighlights.isEmpty
                          ? () => widget.onOpenLibrary(null)
                          : _openAllCategoriesScreen,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceContainerHighest
                            .withValues(alpha: 0.36),
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: Image.asset(
                        'assets/icons/categories_v2/other2.png',
                        width: 30,
                        height: 30,
                        fit: BoxFit.contain,
                      ),
                      label: const Text('All Categories'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.section),
                  if (_collectorGoals.isNotEmpty) ...[
                    HomeCollectorGoalsPanel(goals: _collectorGoals),
                    const SizedBox(height: AppSpacing.section),
                  ],
                  if (_isResolvingInsight || _selectedInsight != null) ...[
                    Text(
                      'COLLECTION INSIGHT',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.onSurfaceVariant.withValues(
                          alpha: 0.88,
                        ),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  if (_isResolvingInsight)
                    const _HomeCollectionInsightSkeleton()
                  else if (_selectedInsight != null) ...[
                    HomeCollectionInsightCard(
                      insight: _selectedInsight!,
                      onPressed: _selectedInsight!.action == null
                          ? null
                          : () =>
                                _handleInsightAction(_selectedInsight!.action),
                    ),
                    const SizedBox(height: AppSpacing.section),
                  ],
                  KeyedSubtree(
                    key: _recentSectionKey,
                    child: CollectorSectionHeader(
                      title: 'Recently Added',
                      trailing: Text(
                        'Latest Arrivals',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (recentItems.isEmpty)
                    const _InlineMessagePanel(
                      title: 'No recent arrivals yet.',
                      description:
                          'New collectibles will appear here as soon as you start cataloging.',
                    )
                  else
                    SizedBox(
                      height: compactLayout ? 162 : 174,
                      child: ListView.separated(
                        clipBehavior: Clip.none,
                        scrollDirection: Axis.horizontal,
                        itemCount: recentItems.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final item = recentItems[index];
                          final photoRef = item.id == null
                              ? null
                              : widget.data.photoRefsByCollectibleId[item.id];
                          return SizedBox(
                            width: compactLayout ? 116 : 124,
                            child: CollectibleGridCard(
                              collectible: item,
                              photoRef: photoRef,
                              onCollectionChanged: widget.onCollectionChanged,
                              detailNavigationContext:
                                  CollectibleDetailNavigationContext.fromCollectibles(
                                    source: CollectibleDetailSource.homeRecent,
                                    collectibles: recentItems,
                                    currentCollectible: item,
                                  ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: AppSpacing.section),
                  KeyedSubtree(
                    key: _favoritesSectionKey,
                    child: CollectorSectionHeader(
                      title: 'Favorites',
                      trailing: Text(
                        'Collector Picks',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (favoriteItems.isEmpty)
                    const _InlineMessagePanel(
                      title: 'No favorites yet.',
                      description:
                          'Star the pieces you love most and they will live here for quick access.',
                    )
                  else
                    SizedBox(
                      height: compactLayout ? 162 : 174,
                      child: ListView.separated(
                        clipBehavior: Clip.none,
                        scrollDirection: Axis.horizontal,
                        itemCount: favoriteItems.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final item = favoriteItems[index];
                          final photoRef = item.id == null
                              ? null
                              : widget.data.photoRefsByCollectibleId[item.id];
                          return SizedBox(
                            width: compactLayout ? 116 : 124,
                            child: CollectibleGridCard(
                              collectible: item,
                              photoRef: photoRef,
                              onCollectionChanged: widget.onCollectionChanged,
                              detailNavigationContext:
                                  CollectibleDetailNavigationContext.fromCollectibles(
                                    source:
                                        CollectibleDetailSource.homeFavorites,
                                    collectibles: favoriteItems,
                                    currentCollectible: item,
                                  ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_CategoryHighlight> _buildCategoryHighlights(
    List<CollectibleModel> collectibles,
  ) {
    final counts = <String, int>{};

    for (final item in collectibles) {
      counts.update(item.category, (value) => value + 1, ifAbsent: () => 1);
    }

    final entries = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount == 0 ? a.key.compareTo(b.key) : byCount;
      });

    return entries
        .asMap()
        .entries
        .map((entry) {
          return _CategoryHighlight(
            title: entry.value.key,
            count: entry.value.value,
            style: _resolveCategoryCardStyle(entry.key),
          );
        })
        .toList(growable: false);
  }

  Future<void> _openAllCategoriesScreen() async {
    CollectorHaptics.light();
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const AllCategoriesScreen()),
    );

    if (changed == true) {
      await widget.onCollectionChanged();
    }
  }

  Future<void> _loadInsightHistory() async {
    final history = await _historyStore.read();
    if (!mounted) {
      return;
    }

    setState(() {
      _insightHistory = history;
    });
    await _resolveInsight();
  }

  Future<void> _syncGamification() async {
    final progress = CollectorProgressSnapshot.fromHomeSummary(widget.data);
    final signature = CollectorBadgeEngine.buildSignature(progress);
    if (_lastGamificationSignature == signature) {
      return;
    }

    final unlockedBadges = CollectorBadgeEngine.unlockedBadges(progress);
    final syncResult = await _badgeAwardStore.syncUnlocked(unlockedBadges);
    if (!mounted) {
      return;
    }

    final awards = syncResult.awards;
    final earnedBadgeIds = awards.map((award) => award.badge.id).toSet();
    final goals = CollectorGoalEngine.buildGoals(
      summary: widget.data,
      earnedBadgeIds: earnedBadgeIds,
    );

    setState(() {
      _lastGamificationSignature = signature;
      _collectorGoals = goals;
    });

    if (syncResult.newAwards.isNotEmpty) {
      CollectorHaptics.medium();
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => CollectorBadgeUnlockSheet(
          awards: syncResult.newAwards,
          primaryActionLabel: 'View Badges',
          onPrimaryAction: widget.onOpenProfile,
        ),
      );
    }
  }

  Future<void> _resolveInsight() async {
    final history = _insightHistory;
    if (history == null) {
      return;
    }

    final signature = HomeCollectionInsightEngine.buildSessionSignature(
      widget.data,
    );
    final cached = SessionCache.get<_HomeInsightSessionSelection>(
      _homeCollectionInsightSessionKey,
    );

    if (cached != null && cached.signature == signature) {
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedInsight = cached.insight;
        _isResolvingInsight = false;
      });
      return;
    }

    final insight = HomeCollectionInsightEngine.selectInsight(
      summary: widget.data,
      history: history,
    );

    var nextHistory = history;
    if (insight != null) {
      nextHistory = await _historyStore.recordShown(insight, history);
    }

    SessionCache.set(
      _homeCollectionInsightSessionKey,
      _HomeInsightSessionSelection(signature: signature, insight: insight),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedInsight = insight;
      _insightHistory = nextHistory;
      _isResolvingInsight = false;
    });
  }

  Future<void> _handleInsightAction(HomeCollectionInsightAction? action) async {
    if (action == null) {
      return;
    }

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
        await _openCategoryCollection(category);
        return;
      case HomeCollectionInsightActionType.scrollToRecent:
        CollectorHaptics.light();
        await _scrollToSection(_recentSectionKey);
        return;
      case HomeCollectionInsightActionType.scrollToFavorites:
        CollectorHaptics.light();
        await _scrollToSection(_favoritesSectionKey);
        return;
    }
  }

  Future<void> _openCategoryCollection(String category) async {
    CollectorHaptics.light();
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CategoryCollectionScreen(category: category),
      ),
    );

    if (changed == true) {
      await widget.onCollectionChanged();
    }
  }

  Future<void> _scrollToSection(GlobalKey key) async {
    final targetContext = key.currentContext;
    if (targetContext == null) {
      return;
    }

    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  _CategoryCardStyle _resolveCategoryCardStyle(int index) {
    const rotatingStyles = <_CategoryCardStyle>[
      _CategoryCardStyle.rose(),
      _CategoryCardStyle.violet(),
      _CategoryCardStyle.amber(),
      _CategoryCardStyle.azure(),
      _CategoryCardStyle.emerald(),
      _CategoryCardStyle.coral(),
    ];

    return rotatingStyles[index % rotatingStyles.length];
  }
}

class _HomeInsightSessionSelection {
  const _HomeInsightSessionSelection({
    required this.signature,
    required this.insight,
  });

  final String signature;
  final HomeCollectionInsight? insight;
}

class _EmptyHomeState extends StatelessWidget {
  const _EmptyHomeState({
    required this.wishlistCount,
    required this.onAddFirstItem,
    required this.onScanItem,
    required this.onOpenProfile,
  });

  final int wishlistCount;
  final VoidCallback onAddFirstItem;
  final VoidCallback onScanItem;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compactLayout =
        screenWidth < 380 || MediaQuery.textScalerOf(context).scale(1) > 1.1;

    return Column(
      children: [
        _HomeTopChrome(onOpenProfile: onOpenProfile),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  140,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - AppSpacing.md - 140,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: CollectorPanel(
                        padding: EdgeInsets.symmetric(
                          horizontal: compactLayout
                              ? AppSpacing.lg
                              : AppSpacing.xl,
                          vertical: compactLayout
                              ? AppSpacing.xl
                              : AppSpacing.xxl,
                        ),
                        backgroundColor: AppColors.surfaceContainer.withValues(
                          alpha: 0.92,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Your collection',
                              textAlign: TextAlign.center,
                              style: compactLayout
                                  ? Theme.of(context).textTheme.headlineMedium
                                  : Theme.of(context).textTheme.headlineLarge,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Container(
                              width: compactLayout ? 72 : 84,
                              height: 3,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.24,
                                    ),
                                    blurRadius: 18,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            _EmptyStateArtwork(compactLayout: compactLayout),
                            const SizedBox(height: AppSpacing.xl),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 320),
                              child: Text(
                                wishlistCount == 0
                                    ? 'Your archive is currently empty. Start cataloging your toys, board games, and comics to build your digital vault.'
                                    : 'Your archive is currently empty. Turn that wishlist momentum into a real collection and build your digital vault.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      height: 1.5,
                                    ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            SizedBox(
                              width: double.infinity,
                              child: CollectorButton(
                                label: 'Add Your First Item',
                                onPressed: onAddFirstItem,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SizedBox(
                              width: double.infinity,
                              child: CollectorButton(
                                label: 'Scan an Item',
                                onPressed: onScanItem,
                                variant: CollectorButtonVariant.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CollectionHomeLoadingState extends StatelessWidget {
  const _CollectionHomeLoadingState();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compactLayout =
        screenWidth < 380 || MediaQuery.textScalerOf(context).scale(1) > 1.1;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CollectorSkeletonBlock(width: 116, height: 14),
                        SizedBox(height: AppSpacing.sm),
                        CollectorSkeletonBlock(width: 188, height: 30),
                      ],
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  CollectorSkeletonBlock(
                    width: 52,
                    height: 52,
                    shape: BoxShape.circle,
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                140,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CollectorSectionHeaderSkeleton(),
                  const SizedBox(height: AppSpacing.md),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final availableWidth = constraints.maxWidth;
                      final halfWidth = (availableWidth - AppSpacing.md) / 2;
                      final cardHeight = compactLayout ? 76.0 : 84.0;

                      return Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.md,
                        children: [
                          SizedBox(
                            width: halfWidth,
                            child: CollectorCategoryCardSkeleton(
                              height: cardHeight,
                              compact: compactLayout,
                            ),
                          ),
                          SizedBox(
                            width: halfWidth,
                            child: CollectorCategoryCardSkeleton(
                              height: cardHeight,
                              compact: compactLayout,
                            ),
                          ),
                          SizedBox(
                            width: halfWidth,
                            child: CollectorCategoryCardSkeleton(
                              height: cardHeight,
                              compact: compactLayout,
                            ),
                          ),
                          SizedBox(
                            width: halfWidth,
                            child: CollectorCategoryCardSkeleton(
                              height: cardHeight,
                              compact: compactLayout,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.section),
                  const _HomeCollectionInsightSkeleton(),
                  const SizedBox(height: AppSpacing.section),
                  const CollectorSectionHeaderSkeleton(trailingWidth: 104),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: compactLayout ? 162 : 174,
                    child: const Row(
                      children: [
                        Expanded(child: CollectorGridCardSkeleton()),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(child: CollectorGridCardSkeleton()),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(child: CollectorGridCardSkeleton()),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.section),
                  const CollectorSectionHeaderSkeleton(trailingWidth: 98),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: compactLayout ? 162 : 174,
                    child: const Row(
                      children: [
                        Expanded(child: CollectorGridCardSkeleton()),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(child: CollectorGridCardSkeleton()),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(child: CollectorGridCardSkeleton()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeCollectionInsightSkeleton extends StatelessWidget {
  const _HomeCollectionInsightSkeleton();

  @override
  Widget build(BuildContext context) {
    return CollectorPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: AppColors.surfaceContainerHigh,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: CollectorSkeletonBlock(width: 132, height: 14)),
              SizedBox(width: AppSpacing.md),
              CollectorSkeletonBlock(
                width: 42,
                height: 42,
                shape: BoxShape.circle,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          CollectorSkeletonBlock(width: 240, height: 26),
          SizedBox(height: AppSpacing.sm),
          CollectorSkeletonBlock(width: double.infinity, height: 16),
          SizedBox(height: AppSpacing.xs),
          CollectorSkeletonBlock(width: 280, height: 16),
          SizedBox(height: AppSpacing.lg),
          CollectorSkeletonBlock(width: 156, height: 40),
        ],
      ),
    );
  }
}

class _HomeWelcomeHeader extends StatelessWidget {
  const _HomeWelcomeHeader({
    this.profile,
    this.profileAvatarUrl,
    required this.onOpenProfile,
  });

  final ProfileModel? profile;
  final String? profileAvatarUrl;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return _HomeHeaderBar(
      profile: profile,
      profileAvatarUrl: profileAvatarUrl,
      onOpenProfile: onOpenProfile,
    );
  }
}

class _HomeTopChrome extends StatelessWidget {
  const _HomeTopChrome({required this.onOpenProfile});

  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _HomeHeaderBar(onOpenProfile: onOpenProfile),
        ),
      ),
    );
  }
}

class _HomeHeaderBar extends StatelessWidget {
  const _HomeHeaderBar({
    this.profile,
    this.profileAvatarUrl,
    required this.onOpenProfile,
  });

  final ProfileModel? profile;
  final String? profileAvatarUrl;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(
      context,
    ).textTheme.headlineMedium?.copyWith(fontSize: 24, height: 1.05);
    final subtitleStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w500,
      color: AppColors.primary.withValues(alpha: 0.88),
      letterSpacing: -0.2,
    );

    return Column(
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
                    'Welcome, ${_homeGreetingName(profile)}!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'What\'s next for your collection?',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: subtitleStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _HomeProfilePlaceholder(
              profile: profile,
              profileAvatarUrl: profileAvatarUrl,
              onTap: onOpenProfile,
            ),
          ],
        ),
      ],
    );
  }
}

String _homeGreetingName(ProfileModel? profile) {
  final displayName = profile?.displayName?.trim();
  if (displayName != null && displayName.isNotEmpty) {
    return displayName;
  }

  final username = profile?.username?.trim();
  if (username != null && username.isNotEmpty) {
    return username;
  }

  return 'Collector';
}

class _HomeProfilePlaceholder extends StatelessWidget {
  const _HomeProfilePlaceholder({
    this.profile,
    this.profileAvatarUrl,
    required this.onTap,
  });

  final ProfileModel? profile;
  final String? profileAvatarUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayName = profile?.displayName?.trim();
    final username = profile?.username?.trim();
    final initialsSource = (displayName?.isNotEmpty == true
        ? displayName!
        : username?.isNotEmpty == true
        ? username!
        : 'Collector');

    final initials = initialsSource
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.characters.first.toUpperCase())
        .join();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.22),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: ResolvedAvatarImage(
              avatarSource: profileAvatarUrl,
              fit: BoxFit.cover,
              fallback: _HomeAvatarFallback(initials: initials),
              error: _HomeAvatarFallback(initials: initials),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeAvatarFallback extends StatelessWidget {
  const _HomeAvatarFallback({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.24),
            AppColors.tertiary.withValues(alpha: 0.24),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials.isEmpty ? 'C' : initials,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CategoryShowcaseCard extends StatelessWidget {
  const _CategoryShowcaseCard({
    required this.category,
    required this.compactLayout,
    required this.height,
    required this.onTap,
  });

  final _CategoryHighlight category;
  final bool compactLayout;
  final double height;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final denseCard = constraints.maxWidth < 220;
          final cardPadding = denseCard
              ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
              : EdgeInsets.symmetric(
                  horizontal: compactLayout ? AppSpacing.md : AppSpacing.lg,
                  vertical: compactLayout ? 8 : 10,
                );
          final cardRadius = denseCard ? 24.0 : 28.0;
          final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: denseCard
                ? 17
                : compactLayout
                ? 18
                : 20,
            height: denseCard ? 0.98 : 1.0,
            fontWeight: FontWeight.w700,
            letterSpacing: denseCard ? -0.65 : -0.45,
            color: category.style.titleColor,
          );
          final countStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: AppFonts.inter,
            fontSize: denseCard
                ? 12
                : compactLayout
                ? 12.5
                : 13,
            fontWeight: FontWeight.w500,
            height: 1.1,
            color: category.style.itemCountColor.withValues(alpha: 0.8),
          );
          final iconSize = denseCard
              ? 28.0
              : compactLayout
              ? 30.0
              : 34.0;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                onTap();
              },
              borderRadius: BorderRadius.circular(cardRadius),
              child: Ink(
                padding: cardPadding,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(cardRadius),
                  color: category.style.backgroundColor,
                  border: Border.all(color: category.style.borderColor),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: denseCard ? 32 : 36,
                      child: Row(
                        children: [
                          CategoryIcon(
                            category: category.title,
                            size: iconSize,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  category.title,
                                  maxLines: 1,
                                  softWrap: false,
                                  style: titleStyle,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${category.count} item${category.count == 1 ? '' : 's'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: countStyle,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryShowcaseTile extends StatelessWidget {
  const _CategoryShowcaseTile({
    required this.width,
    required this.alignToCenter,
    required this.child,
  });

  final double width;
  final bool alignToCenter;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final card = SizedBox(width: width, child: child);

    if (!alignToCenter) {
      return card;
    }

    return SizedBox(
      width: double.infinity,
      child: Align(alignment: Alignment.center, child: card),
    );
  }
}

double _categoryCardWidthForIndex({
  required int index,
  required int itemCount,
  required double fullWidth,
  required double halfWidth,
}) {
  if (itemCount == 1) {
    return fullWidth;
  }

  final isLastItem = index == itemCount - 1;
  final hasOddCount = itemCount.isOdd;
  if (isLastItem && hasOddCount) {
    return halfWidth;
  }

  return halfWidth;
}

bool _categoryCardShouldCenterForIndex({
  required int index,
  required int itemCount,
}) {
  return itemCount > 1 && itemCount.isOdd && index == itemCount - 1;
}

class _InlineMessagePanel extends StatelessWidget {
  const _InlineMessagePanel({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return CollectorPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateArtwork extends StatelessWidget {
  const _EmptyStateArtwork({required this.compactLayout});

  final bool compactLayout;

  @override
  Widget build(BuildContext context) {
    final boxSize = compactLayout ? 164.0 : 194.0;

    return SizedBox(
      width: boxSize,
      height: boxSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: boxSize,
            height: boxSize,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Icon(
                Icons.inventory_2_outlined,
                size: compactLayout ? 74 : 86,
                color: AppColors.primary.withValues(alpha: 0.42),
              ),
            ),
          ),
          Positioned(
            top: compactLayout ? 22 : 26,
            right: compactLayout ? 10 : 14,
            child: Transform.rotate(
              angle: 0.18,
              child: Container(
                width: compactLayout ? 56 : 64,
                height: compactLayout ? 56 : 64,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeMessageState extends StatelessWidget {
  const _HomeMessageState({
    required this.icon,
    required this.title,
    required this.description,
    required this.tone,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color tone;

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
              Icon(icon, color: tone, size: 34),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                description,
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

class _CategoryHighlight {
  const _CategoryHighlight({
    required this.title,
    required this.count,
    required this.style,
  });

  final String title;
  final int count;
  final _CategoryCardStyle style;
}

class _CategoryCardStyle {
  const _CategoryCardStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.titleColor,
    required this.itemCountColor,
  });

  const _CategoryCardStyle.rose()
    : backgroundColor = AppColors.categoryRoseBackground,
      borderColor = AppColors.categoryRoseBorder,
      titleColor = AppColors.categoryRoseForeground,
      itemCountColor = AppColors.categoryRoseForeground;

  const _CategoryCardStyle.violet()
    : backgroundColor = AppColors.categoryVioletBackground,
      borderColor = AppColors.categoryVioletBorder,
      titleColor = AppColors.categoryVioletForeground,
      itemCountColor = AppColors.categoryVioletForeground;

  const _CategoryCardStyle.amber()
    : backgroundColor = AppColors.categoryAmberBackground,
      borderColor = AppColors.categoryAmberBorder,
      titleColor = AppColors.categoryAmberForeground,
      itemCountColor = AppColors.categoryAmberForeground;

  const _CategoryCardStyle.azure()
    : backgroundColor = AppColors.categoryAzureBackground,
      borderColor = AppColors.categoryAzureBorder,
      titleColor = AppColors.categoryAzureForeground,
      itemCountColor = AppColors.categoryAzureForeground;

  const _CategoryCardStyle.emerald()
    : backgroundColor = AppColors.categoryEmeraldBackground,
      borderColor = AppColors.categoryEmeraldBorder,
      titleColor = AppColors.categoryEmeraldForeground,
      itemCountColor = AppColors.categoryEmeraldForeground;

  const _CategoryCardStyle.coral()
    : backgroundColor = AppColors.categoryCoralBackground,
      borderColor = AppColors.categoryCoralBorder,
      titleColor = AppColors.categoryCoralForeground,
      itemCountColor = AppColors.categoryCoralForeground;

  final Color backgroundColor;
  final Color borderColor;
  final Color titleColor;
  final Color itemCountColor;
}
