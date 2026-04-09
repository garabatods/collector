import 'dart:async';

import 'package:flutter/material.dart';

import '../core/data/session_cache.dart';
import '../features/collection/data/models/collectible_model.dart';
import '../features/collection/data/repositories/collectible_photos_repository.dart';
import '../features/collection/data/repositories/collectibles_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/collector_button.dart';
import '../widgets/collectible_grid_card.dart';
import '../widgets/collector_loading_overlay.dart';
import '../widgets/collector_panel.dart';
import '../widgets/collector_text_field.dart';

class CollectionLibraryScreen extends StatefulWidget {
  const CollectionLibraryScreen({
    super.key,
    required this.refreshSeed,
    this.searchFocusRequest = 0,
  });

  final int refreshSeed;
  final int searchFocusRequest;

  @override
  State<CollectionLibraryScreen> createState() =>
      _CollectionLibraryScreenState();
}

class _CollectionLibraryScreenState extends State<CollectionLibraryScreen> {
  final _collectiblesRepository = CollectiblesRepository();
  final _photosRepository = CollectiblePhotosRepository();

  late Future<_CollectionLibraryBootstrapData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant CollectionLibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSeed != widget.refreshSeed) {
      _future = _load();
    }
  }

  Future<_CollectionLibraryBootstrapData> _load() async {
    final page = await _collectiblesRepository.fetchPage(
      limit: CollectiblesRepository.libraryDefaultPageSize,
    );
    final categorySummaries = await _collectiblesRepository
        .fetchCategoryCounts();

    return _CollectionLibraryBootstrapData(
      initialPage: page,
      initialPhotoUrls: await _resolvePhotoUrls(page.items),
      categoryStats: categorySummaries
          .map(
            (summary) => _CategoryShelfStat(
              category: summary.category,
              count: summary.count,
            ),
          )
          .toList(growable: false),
    );
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CollectionLibraryBootstrapData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final isRefreshing = snapshot.connectionState != ConnectionState.done;

        if (snapshot.hasError && data == null) {
          return _CollectionLibraryErrorState(onRetry: _reload);
        }

        if (data == null) {
          return const _CollectionLibraryLoadingState();
        }

        if (data.initialPage.totalCount == 0) {
          return const _CollectionLibraryEmptyState();
        }

        return Stack(
          children: [
            _CollectionLibraryLoadedState(
              data: data,
              searchFocusRequest: widget.searchFocusRequest,
              onCollectionChanged: _reload,
            ),
            if (isRefreshing)
              const Positioned.fill(
                child: IgnorePointer(
                  child: CollectorLoadingOverlay(backdropOpacity: 0.12),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<Map<String, String>> _resolvePhotoUrls(
    List<CollectibleModel> collectibles,
  ) async {
    final ids = collectibles
        .map((item) => item.id)
        .whereType<String>()
        .toList(growable: false);
    final primaryPhotos = await _photosRepository.fetchPrimaryPhotoMap(ids);

    final urls = <String, String>{};
    for (final entry in primaryPhotos.entries) {
      final signedUrl = await _photosRepository.createSignedPhotoUrl(
        entry.value,
      );
      if (signedUrl != null) {
        urls[entry.key] = signedUrl;
      }
    }
    return urls;
  }
}

enum _LibrarySortOption {
  newest,
  oldest,
  titleAscending,
  titleDescending,
  category,
}

class _CollectionLibraryLoadedState extends StatefulWidget {
  const _CollectionLibraryLoadedState({
    required this.data,
    required this.searchFocusRequest,
    required this.onCollectionChanged,
  });

  final _CollectionLibraryBootstrapData data;
  final int searchFocusRequest;
  final Future<void> Function() onCollectionChanged;

  @override
  State<_CollectionLibraryLoadedState> createState() =>
      _CollectionLibraryLoadedStateState();
}

class _CollectionLibraryLoadedStateState
    extends State<_CollectionLibraryLoadedState> {
  static const _cachePrefix = 'library:browse:';
  static const _photoCacheMaxAge = Duration(minutes: 45);

  final _collectiblesRepository = CollectiblesRepository();
  final _photosRepository = CollectiblePhotosRepository();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _scrollController = ScrollController();

  var _favoritesOnly = false;
  var _grailsOnly = false;
  var _duplicatesOnly = false;
  var _hasPhotoOnly = false;
  String? _selectedCategory;
  var _sort = _LibrarySortOption.newest;
  Timer? _searchDebounce;
  List<CollectibleModel> _items = const [];
  Map<String, String> _photoUrlsByCollectibleId = const {};
  List<_CategoryShelfStat> _categoryStats = const [];
  var _totalCount = 0;
  var _nextOffset = 0;
  var _hasMore = false;
  var _isRefreshingResults = false;
  var _isLoadingMore = false;

  String get _query => _searchController.text.trim();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleQueryChanged);
    _scrollController.addListener(_handleScroll);
    _syncFromBootstrap(widget.data);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _searchFocusNode.dispose();
    _searchController
      ..removeListener(_handleQueryChanged)
      ..dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _CollectionLibraryLoadedState oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.data, widget.data)) {
      SessionCache.removeWherePrefix(_cachePrefix);
      if (_hasDefaultBrowseState) {
        _syncFromBootstrap(widget.data);
      } else {
        unawaited(_refreshResults(resetScroll: false, forceNetwork: true));
      }
    }
    if (oldWidget.searchFocusRequest != widget.searchFocusRequest) {
      _focusSearchField();
    }
  }

  void _handleQueryChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _refreshResults(resetScroll: true);
    });
  }

  void _focusSearchField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _searchFocusNode.requestFocus();
    });
  }

  void _handleScroll() {
    if (!_scrollController.hasClients ||
        _isLoadingMore ||
        !_hasMore ||
        _isRefreshingResults) {
      return;
    }

    final threshold = _scrollController.position.maxScrollExtent - 420;
    if (_scrollController.position.pixels >= threshold) {
      _loadNextPage();
    }
  }

  void _syncFromBootstrap(_CollectionLibraryBootstrapData data) {
    _items = data.initialPage.items;
    _photoUrlsByCollectibleId = data.initialPhotoUrls;
    _categoryStats = data.categoryStats;
    _totalCount = data.initialPage.totalCount;
    _nextOffset = data.initialPage.nextOffset;
    _hasMore = data.initialPage.hasMore;
    _isRefreshingResults = false;
    _isLoadingMore = false;
    _persistCurrentBrowseState();
  }

  Future<void> _openSortSheet() async {
    final nextSort = await showModalBottomSheet<_LibrarySortOption>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LibrarySortSheet(selected: _sort),
    );

    if (!mounted || nextSort == null || nextSort == _sort) {
      return;
    }

    setState(() {
      _sort = nextSort;
    });
    await _refreshResults(resetScroll: true);
  }

  Future<void> _openFilterSheet() async {
    final nextFilters = await showModalBottomSheet<_LibraryFilterSelection>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _LibraryFilterSheet(
        favoritesOnly: _favoritesOnly,
        grailsOnly: _grailsOnly,
        duplicatesOnly: _duplicatesOnly,
        hasPhotoOnly: _hasPhotoOnly,
      ),
    );

    if (!mounted || nextFilters == null) {
      return;
    }

    setState(() {
      _favoritesOnly = nextFilters.favoritesOnly;
      _grailsOnly = nextFilters.grailsOnly;
      _duplicatesOnly = nextFilters.duplicatesOnly;
      _hasPhotoOnly = nextFilters.hasPhotoOnly;
    });
    await _refreshResults(resetScroll: true);
  }

  Future<void> _clearAllBrowseState() async {
    _searchDebounce?.cancel();
    setState(() {
      _favoritesOnly = false;
      _grailsOnly = false;
      _duplicatesOnly = false;
      _hasPhotoOnly = false;
      _selectedCategory = null;
      _searchController.clear();
      _sort = _LibrarySortOption.newest;
    });
    await _refreshResults(resetScroll: true);
  }

  void _handleCollectibleUpdated(CollectibleModel collectible) {
    final id = collectible.id;
    if (id == null) {
      return;
    }

    setState(() {
      _items = _items
          .map((item) => item.id == id ? collectible : item)
          .toList(growable: false);
    });

    if (_favoritesOnly && !collectible.isFavorite) {
      _refreshResults(resetScroll: false);
    }
  }

  bool get _hasActiveRefinementState {
    return _favoritesOnly ||
        _grailsOnly ||
        _duplicatesOnly ||
        _hasPhotoOnly ||
        _sort != _LibrarySortOption.newest;
  }

  bool get _hasDefaultBrowseState {
    return _query.isEmpty &&
        !_favoritesOnly &&
        !_grailsOnly &&
        !_duplicatesOnly &&
        !_hasPhotoOnly &&
        _selectedCategory == null &&
        _sort == _LibrarySortOption.newest;
  }

  int get _activeFilterCount {
    var count = 0;
    if (_favoritesOnly) count++;
    if (_grailsOnly) count++;
    if (_duplicatesOnly) count++;
    if (_hasPhotoOnly) count++;
    return count;
  }

  Future<void> _refreshResults({
    required bool resetScroll,
    bool forceNetwork = false,
  }) async {
    if (!forceNetwork) {
      final cached = SessionCache.get<_CachedLibraryBrowseState>(_cacheKey);
      if (cached != null && !cached.hasExpiredPhotoUrls(_photoCacheMaxAge)) {
        if (mounted) {
          setState(() {
            _applyCachedBrowseState(cached);
          });
        } else {
          _applyCachedBrowseState(cached);
        }
        if (resetScroll && _scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          );
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isRefreshingResults = true;
      });
    }

    try {
      final page = await _collectiblesRepository.fetchPage(
        offset: 0,
        limit: CollectiblesRepository.libraryDefaultPageSize,
        query: _query,
        favoritesOnly: _favoritesOnly,
        grailsOnly: _grailsOnly,
        duplicatesOnly: _duplicatesOnly,
        hasPhotoOnly: _hasPhotoOnly,
        category: _selectedCategory,
        sort: _currentSort,
      );
      final categorySummaries = await _collectiblesRepository
          .fetchCategoryCounts(
            query: _query,
            favoritesOnly: _favoritesOnly,
            grailsOnly: _grailsOnly,
            duplicatesOnly: _duplicatesOnly,
            hasPhotoOnly: _hasPhotoOnly,
          );
      final photoUrls = await _resolvePhotoUrls(page.items);

      if (!mounted) {
        return;
      }

      setState(() {
        _items = page.items;
        _photoUrlsByCollectibleId = photoUrls;
        _categoryStats = categorySummaries
            .map(
              (summary) => _CategoryShelfStat(
                category: summary.category,
                count: summary.count,
              ),
            )
            .toList(growable: false);
        _totalCount = page.totalCount;
        _nextOffset = page.nextOffset;
        _hasMore = page.hasMore;
        _isRefreshingResults = false;
      });
      _persistCurrentBrowseState();

      if (resetScroll && _scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isRefreshingResults = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not refresh the library right now.'),
        ),
      );
    }
  }

  Future<void> _loadNextPage() async {
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final page = await _collectiblesRepository.fetchPage(
        offset: _nextOffset,
        limit: CollectiblesRepository.libraryDefaultPageSize,
        query: _query,
        favoritesOnly: _favoritesOnly,
        grailsOnly: _grailsOnly,
        duplicatesOnly: _duplicatesOnly,
        hasPhotoOnly: _hasPhotoOnly,
        category: _selectedCategory,
        sort: _currentSort,
      );
      final photoUrls = await _resolvePhotoUrls(page.items);

      if (!mounted) {
        return;
      }

      setState(() {
        _items = [..._items, ...page.items];
        _photoUrlsByCollectibleId = {
          ..._photoUrlsByCollectibleId,
          ...photoUrls,
        };
        _nextOffset = page.nextOffset;
        _hasMore = page.hasMore;
        _isLoadingMore = false;
      });
      _persistCurrentBrowseState();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<Map<String, String>> _resolvePhotoUrls(
    List<CollectibleModel> collectibles,
  ) async {
    final ids = collectibles
        .map((item) => item.id)
        .whereType<String>()
        .toList(growable: false);
    final primaryPhotos = await _photosRepository.fetchPrimaryPhotoMap(ids);

    final urls = <String, String>{};
    for (final entry in primaryPhotos.entries) {
      final signedUrl = await _photosRepository.createSignedPhotoUrl(
        entry.value,
      );
      if (signedUrl != null) {
        urls[entry.key] = signedUrl;
      }
    }

    return urls;
  }

  CollectiblePageSort get _currentSort => switch (_sort) {
    _LibrarySortOption.newest => CollectiblePageSort.newest,
    _LibrarySortOption.oldest => CollectiblePageSort.oldest,
    _LibrarySortOption.titleAscending => CollectiblePageSort.titleAscending,
    _LibrarySortOption.titleDescending => CollectiblePageSort.titleDescending,
    _LibrarySortOption.category => CollectiblePageSort.category,
  };

  String get _cacheKey {
    return [
      _cachePrefix,
      _query.toLowerCase(),
      _favoritesOnly,
      _grailsOnly,
      _duplicatesOnly,
      _hasPhotoOnly,
      _selectedCategory?.toLowerCase() ?? '',
      _sort.name,
    ].join('|');
  }

  void _persistCurrentBrowseState() {
    SessionCache.set(
      _cacheKey,
      _CachedLibraryBrowseState(
        items: _items,
        photoUrlsByCollectibleId: _photoUrlsByCollectibleId,
        categoryStats: _categoryStats,
        totalCount: _totalCount,
        nextOffset: _nextOffset,
        hasMore: _hasMore,
      ),
    );
  }

  void _applyCachedBrowseState(_CachedLibraryBrowseState cached) {
    _items = cached.items;
    _photoUrlsByCollectibleId = cached.photoUrlsByCollectibleId;
    _categoryStats = cached.categoryStats;
    _totalCount = cached.totalCount;
    _nextOffset = cached.nextOffset;
    _hasMore = cached.hasMore;
    _isRefreshingResults = false;
    _isLoadingMore = false;
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: _scrollController,
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
                  'Your Library',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                CollectorSearchField(
                  hintText: 'Search title, category, brand, series, or tags...',
                  fillColor: AppColors.surfaceContainerHighest.withValues(
                    alpha: 0.78,
                  ),
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  readOnly: false,
                  onChanged: (_) {},
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () => _searchController.clear(),
                          icon: const Icon(Icons.close_rounded),
                          color: AppColors.onSurfaceVariant,
                        ),
                ),
                if (_hasActiveRefinementState) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ActiveBrowseStrip(
                    sortLabel: _sort.label,
                    showSortChip: _sort != _LibrarySortOption.newest,
                    favoritesOnly: _favoritesOnly,
                    grailsOnly: _grailsOnly,
                    duplicatesOnly: _duplicatesOnly,
                    hasPhotoOnly: _hasPhotoOnly,
                    onClearSort: () {
                      setState(() {
                        _sort = _LibrarySortOption.newest;
                      });
                      _refreshResults(resetScroll: true);
                    },
                    onClearFavorites: () {
                      setState(() {
                        _favoritesOnly = false;
                      });
                      _refreshResults(resetScroll: true);
                    },
                    onClearGrails: () {
                      setState(() {
                        _grailsOnly = false;
                      });
                      _refreshResults(resetScroll: true);
                    },
                    onClearDuplicates: () {
                      setState(() {
                        _duplicatesOnly = false;
                      });
                      _refreshResults(resetScroll: true);
                    },
                    onClearHasPhoto: () {
                      setState(() {
                        _hasPhotoOnly = false;
                      });
                      _refreshResults(resetScroll: true);
                    },
                    onClearAll: _clearAllBrowseState,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _CategoryShelf(
                  categories: _categoryStats,
                  selectedCategory: _selectedCategory,
                  sortHighlighted: _sort != _LibrarySortOption.newest,
                  filterHighlighted: _activeFilterCount > 0,
                  onSortTap: _openSortSheet,
                  onFilterTap: _openFilterSheet,
                  onSelected: (category) {
                    setState(() {
                      _selectedCategory = _selectedCategory == category
                          ? null
                          : category;
                    });
                    _refreshResults(resetScroll: true);
                  },
                ),
                if (_isRefreshingResults) ...[
                  const SizedBox(height: AppSpacing.md),
                  const _InlineLibraryLoader(label: 'Refreshing library...'),
                ] else if (_items.isEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _LibraryNoResultsPanel(onClearAll: _clearAllBrowseState),
                ],
              ],
            ),
          ),
        ),
        if (_items.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              140,
            ),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                final collectible = _items[index];
                final id = collectible.id;
                final photoUrl = id == null
                    ? null
                    : _photoUrlsByCollectibleId[id];

                return CollectibleGridCard(
                  collectible: collectible,
                  photoUrl: photoUrl,
                  onCollectionChanged: widget.onCollectionChanged,
                  onCollectibleUpdated: _handleCollectibleUpdated,
                );
              }, childCount: _items.length),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.72,
              ),
            ),
          ),
        if (_items.isNotEmpty && _isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                140,
              ),
              child: _InlineLibraryLoader(label: 'Loading more...'),
            ),
          ),
      ],
    );
  }
}

extension on _LibrarySortOption {
  String get label => switch (this) {
    _LibrarySortOption.newest => 'Newest',
    _LibrarySortOption.oldest => 'Oldest',
    _LibrarySortOption.titleAscending => 'Title A-Z',
    _LibrarySortOption.titleDescending => 'Title Z-A',
    _LibrarySortOption.category => 'Category',
  };
}

class _CategoryShelf extends StatelessWidget {
  const _CategoryShelf({
    required this.categories,
    required this.selectedCategory,
    required this.sortHighlighted,
    required this.filterHighlighted,
    required this.onSortTap,
    required this.onFilterTap,
    required this.onSelected,
  });

  final List<_CategoryShelfStat> categories;
  final String? selectedCategory;
  final bool sortHighlighted;
  final bool filterHighlighted;
  final VoidCallback onSortTap;
  final VoidCallback onFilterTap;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Browse by category',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            _LibraryUtilityIconButton(
              icon: Icons.swap_vert_rounded,
              highlighted: sortHighlighted,
              tooltip: 'Sort library',
              onTap: onSortTap,
            ),
            const SizedBox(width: AppSpacing.xs),
            _LibraryUtilityIconButton(
              icon: Icons.tune_rounded,
              highlighted: filterHighlighted,
              tooltip: 'Filter library',
              onTap: onFilterTap,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final category in categories.take(8)) ...[
                _CategoryShelfChip(
                  category: category.category,
                  count: category.count,
                  active: selectedCategory == category.category,
                  onTap: () => onSelected(category.category),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryShelfChip extends StatelessWidget {
  const _CategoryShelfChip({
    required this.category,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final String category;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.withValues(alpha: 0.14)
                : AppColors.surfaceContainerHighest.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? AppColors.primary.withValues(alpha: 0.28)
                  : AppColors.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: active ? AppColors.primary : AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count item${count == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveBrowseStrip extends StatelessWidget {
  const _ActiveBrowseStrip({
    required this.sortLabel,
    required this.showSortChip,
    required this.favoritesOnly,
    required this.grailsOnly,
    required this.duplicatesOnly,
    required this.hasPhotoOnly,
    required this.onClearSort,
    required this.onClearFavorites,
    required this.onClearGrails,
    required this.onClearDuplicates,
    required this.onClearHasPhoto,
    required this.onClearAll,
  });

  final String sortLabel;
  final bool showSortChip;
  final bool favoritesOnly;
  final bool grailsOnly;
  final bool duplicatesOnly;
  final bool hasPhotoOnly;
  final VoidCallback onClearSort;
  final VoidCallback onClearFavorites;
  final VoidCallback onClearGrails;
  final VoidCallback onClearDuplicates;
  final VoidCallback onClearHasPhoto;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (showSortChip) ...[
            _AppliedBrowseChip(label: 'Sort: $sortLabel', onTap: onClearSort),
            const SizedBox(width: AppSpacing.sm),
          ],
          if (favoritesOnly) ...[
            _AppliedBrowseChip(label: 'Favorites', onTap: onClearFavorites),
            const SizedBox(width: AppSpacing.sm),
          ],
          if (grailsOnly) ...[
            _AppliedBrowseChip(label: 'Grails', onTap: onClearGrails),
            const SizedBox(width: AppSpacing.sm),
          ],
          if (duplicatesOnly) ...[
            _AppliedBrowseChip(label: 'Duplicates', onTap: onClearDuplicates),
            const SizedBox(width: AppSpacing.sm),
          ],
          if (hasPhotoOnly) ...[
            _AppliedBrowseChip(label: 'Has photo', onTap: onClearHasPhoto),
            const SizedBox(width: AppSpacing.sm),
          ],
          _AppliedBrowseChip(
            label: 'Clear all',
            emphasized: true,
            onTap: onClearAll,
          ),
        ],
      ),
    );
  }
}

class _LibraryNoResultsPanel extends StatelessWidget {
  const _LibraryNoResultsPanel({required this.onClearAll});

  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return CollectorPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No matches right now.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Try a broader search, switch categories, or clear the browse controls to reopen the full shelf.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          CollectorButton(
            label: 'Reset Library View',
            onPressed: onClearAll,
            variant: CollectorButtonVariant.secondary,
          ),
        ],
      ),
    );
  }
}

class _LibraryUtilityIconButton extends StatelessWidget {
  const _LibraryUtilityIconButton({
    required this.highlighted,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final bool highlighted;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: highlighted
                  ? AppColors.primary.withValues(alpha: 0.14)
                  : AppColors.surfaceContainerHighest.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: highlighted
                    ? AppColors.primary.withValues(alpha: 0.32)
                    : AppColors.outlineVariant.withValues(alpha: 0.24),
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: highlighted
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryFilterSelection {
  const _LibraryFilterSelection({
    required this.favoritesOnly,
    required this.grailsOnly,
    required this.duplicatesOnly,
    required this.hasPhotoOnly,
  });

  final bool favoritesOnly;
  final bool grailsOnly;
  final bool duplicatesOnly;
  final bool hasPhotoOnly;
}

class _AppliedBrowseChip extends StatelessWidget {
  const _AppliedBrowseChip({
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final foreground = emphasized ? AppColors.primary : AppColors.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: emphasized
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.surfaceContainerHighest.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: emphasized
                  ? AppColors.primary.withValues(alpha: 0.24)
                  : AppColors.outlineVariant.withValues(alpha: 0.24),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: foreground),
              ),
              const SizedBox(width: 6),
              Icon(
                emphasized ? Icons.restart_alt_rounded : Icons.close_rounded,
                size: 14,
                color: foreground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryFilterSheet extends StatefulWidget {
  const _LibraryFilterSheet({
    required this.favoritesOnly,
    required this.grailsOnly,
    required this.duplicatesOnly,
    required this.hasPhotoOnly,
  });

  final bool favoritesOnly;
  final bool grailsOnly;
  final bool duplicatesOnly;
  final bool hasPhotoOnly;

  @override
  State<_LibraryFilterSheet> createState() => _LibraryFilterSheetState();
}

class _LibraryFilterSheetState extends State<_LibraryFilterSheet> {
  late bool _favoritesOnly;
  late bool _grailsOnly;
  late bool _duplicatesOnly;
  late bool _hasPhotoOnly;

  @override
  void initState() {
    super.initState();
    _favoritesOnly = widget.favoritesOnly;
    _grailsOnly = widget.grailsOnly;
    _duplicatesOnly = widget.duplicatesOnly;
    _hasPhotoOnly = widget.hasPhotoOnly;
  }

  void _reset() {
    setState(() {
      _favoritesOnly = false;
      _grailsOnly = false;
      _duplicatesOnly = false;
      _hasPhotoOnly = false;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      _LibraryFilterSelection(
        favoritesOnly: _favoritesOnly,
        grailsOnly: _grailsOnly,
        duplicatesOnly: _duplicatesOnly,
        hasPhotoOnly: _hasPhotoOnly,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Library Filters',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Refine the shelf without crowding the main header.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _LibraryFilterOption(
                  label: 'Favorites',
                  description: 'Only show items you have starred.',
                  active: _favoritesOnly,
                  icon: Icons.favorite_outline_rounded,
                  onTap: () {
                    setState(() {
                      _favoritesOnly = !_favoritesOnly;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                _LibraryFilterOption(
                  label: 'Grails',
                  description: 'Focus on your most sought-after pieces.',
                  active: _grailsOnly,
                  icon: Icons.workspace_premium_outlined,
                  onTap: () {
                    setState(() {
                      _grailsOnly = !_grailsOnly;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                _LibraryFilterOption(
                  label: 'Duplicates',
                  description: 'Surface items you own more than once.',
                  active: _duplicatesOnly,
                  icon: Icons.copy_all_rounded,
                  onTap: () {
                    setState(() {
                      _duplicatesOnly = !_duplicatesOnly;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                _LibraryFilterOption(
                  label: 'Has photo',
                  description: 'Only include collectibles with images.',
                  active: _hasPhotoOnly,
                  icon: Icons.image_outlined,
                  onTap: () {
                    setState(() {
                      _hasPhotoOnly = !_hasPhotoOnly;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: CollectorButton(
                        label: 'Clear',
                        onPressed: _reset,
                        variant: CollectorButtonVariant.secondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: CollectorButton(label: 'Apply', onPressed: _apply),
                    ),
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

class _LibraryFilterOption extends StatelessWidget {
  const _LibraryFilterOption({
    required this.label,
    required this.description,
    required this.active,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String description;
  final bool active;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.surfaceContainerHighest.withValues(alpha: 0.36),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: active
                  ? AppColors.primary.withValues(alpha: 0.24)
                  : AppColors.outlineVariant.withValues(alpha: 0.24),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary.withValues(alpha: 0.16)
                      : AppColors.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: active
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: active ? AppColors.primary : AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                active ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: active ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibrarySortSheet extends StatelessWidget {
  const _LibrarySortSheet({required this.selected});

  final _LibrarySortOption selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Sort Library',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Choose how the shelf should be ordered.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final option in _LibrarySortOption.values)
                  ListTile(
                    onTap: () => Navigator.of(context).pop(option),
                    contentPadding: EdgeInsets.zero,
                    title: Text(option.label),
                    trailing: option == selected
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.primary,
                          )
                        : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineLibraryLoader extends StatelessWidget {
  const _InlineLibraryLoader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _CollectionLibraryLoadingState extends StatelessWidget {
  const _CollectionLibraryLoadingState();

  @override
  Widget build(BuildContext context) {
    return const CollectorLoadingOverlay();
  }
}

class _CollectionLibraryEmptyState extends StatelessWidget {
  const _CollectionLibraryEmptyState();

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
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryContainer.withValues(alpha: 0.18),
                ),
                child: const Icon(
                  Icons.collections_bookmark_outlined,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Your collection starts here.',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Add your first collectible and this library will turn into your personal archive.',
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

class _CollectionLibraryErrorState extends StatelessWidget {
  const _CollectionLibraryErrorState({required this.onRetry});

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
                color: AppColors.secondary,
                size: 34,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Could not load your library.',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Give it another try and we will pull your latest collection from Supabase.',
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

class _CollectionLibraryBootstrapData {
  const _CollectionLibraryBootstrapData({
    required this.initialPage,
    required this.initialPhotoUrls,
    required this.categoryStats,
  });

  final CollectiblePageResult initialPage;
  final Map<String, String> initialPhotoUrls;
  final List<_CategoryShelfStat> categoryStats;
}

class _CachedLibraryBrowseState {
  _CachedLibraryBrowseState({
    required this.items,
    required this.photoUrlsByCollectibleId,
    required this.categoryStats,
    required this.totalCount,
    required this.nextOffset,
    required this.hasMore,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final List<CollectibleModel> items;
  final Map<String, String> photoUrlsByCollectibleId;
  final List<_CategoryShelfStat> categoryStats;
  final int totalCount;
  final int nextOffset;
  final bool hasMore;
  final DateTime createdAt;

  bool hasExpiredPhotoUrls(Duration maxAge) {
    return DateTime.now().difference(createdAt) > maxAge;
  }
}

class _CategoryShelfStat {
  const _CategoryShelfStat({required this.category, required this.count});

  final String category;
  final int count;
}
