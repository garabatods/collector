import 'package:flutter/material.dart';

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
  });

  final int refreshSeed;

  @override
  State<CollectionLibraryScreen> createState() => _CollectionLibraryScreenState();
}

class _CollectionLibraryScreenState extends State<CollectionLibraryScreen> {
  final _collectiblesRepository = CollectiblesRepository();
  final _photosRepository = CollectiblePhotosRepository();

  late Future<_CollectionLibraryData> _future;

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

  Future<_CollectionLibraryData> _load() async {
    final collectibles = await _collectiblesRepository.fetchAll();
    final ids =
        collectibles.map((item) => item.id).whereType<String>().toList(growable: false);
    final primaryPhotos = await _photosRepository.fetchPrimaryPhotoMap(ids);

    final urls = <String, String>{};
    for (final entry in primaryPhotos.entries) {
      final signedUrl = await _photosRepository.createSignedPhotoUrl(entry.value);
      if (signedUrl != null) {
        urls[entry.key] = signedUrl;
      }
    }

    return _CollectionLibraryData(
      collectibles: collectibles,
      photoUrlsByCollectibleId: urls,
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
    return FutureBuilder<_CollectionLibraryData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final isRefreshing = snapshot.connectionState != ConnectionState.done;

        if (snapshot.hasError && data == null) {
          return _CollectionLibraryErrorState(
            onRetry: _reload,
          );
        }

        if (data == null) {
          return const _CollectionLibraryLoadingState();
        }

        if (data.collectibles.isEmpty) {
          return const _CollectionLibraryEmptyState();
        }

        return Stack(
          children: [
            _CollectionLibraryLoadedState(
              data: data,
              onCollectionChanged: _reload,
            ),
            if (isRefreshing)
              const Positioned.fill(
                child: IgnorePointer(
                  child: CollectorLoadingOverlay(
                    backdropOpacity: 0.12,
                  ),
                ),
              ),
          ],
        );
      },
    );
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
    required this.onCollectionChanged,
  });

  final _CollectionLibraryData data;
  final Future<void> Function() onCollectionChanged;

  @override
  State<_CollectionLibraryLoadedState> createState() =>
      _CollectionLibraryLoadedStateState();
}

class _CollectionLibraryLoadedStateState extends State<_CollectionLibraryLoadedState> {
  final _searchController = TextEditingController();
  final Map<String, bool> _favoriteOverrides = <String, bool>{};

  var _favoritesOnly = false;
  var _grailsOnly = false;
  var _duplicatesOnly = false;
  var _hasPhotoOnly = false;
  String? _selectedCategory;
  var _sort = _LibrarySortOption.newest;

  String get _query => _searchController.text.trim();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleQueryChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleQueryChanged)
      ..dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _CollectionLibraryLoadedState oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.data, widget.data)) {
      _favoriteOverrides.clear();
    }
  }

  void _handleQueryChanged() {
    setState(() {});
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
  }

  void _clearAllBrowseState() {
    setState(() {
      _favoritesOnly = false;
      _grailsOnly = false;
      _duplicatesOnly = false;
      _hasPhotoOnly = false;
      _selectedCategory = null;
      _searchController.clear();
      _sort = _LibrarySortOption.newest;
    });
  }

  List<_CategoryShelfStat> _buildCategoryStats() {
    final counts = <String, int>{};
    for (final item in widget.data.collectibles) {
      final category = item.category.trim();
      if (category.isEmpty) {
        continue;
      }
      counts.update(category, (value) => value + 1, ifAbsent: () => 1);
    }

    final entries = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount == 0 ? a.key.compareTo(b.key) : byCount;
      });

    return entries
        .map((entry) => _CategoryShelfStat(category: entry.key, count: entry.value))
        .toList(growable: false);
  }

  List<CollectibleModel> _applyBrowseState() {
    final query = _query.toLowerCase();
    final queryTerms = query.split(RegExp(r'\s+')).where((term) => term.isNotEmpty).toList();

    final filtered = widget.data.collectibles.map(_applyFavoriteOverride).where((item) {
      if (_favoritesOnly && !item.isFavorite) return false;
      if (_grailsOnly && !item.isGrail) return false;
      if (_duplicatesOnly && !item.isDuplicate) return false;
      if (_hasPhotoOnly &&
          (item.id == null || !widget.data.photoUrlsByCollectibleId.containsKey(item.id))) {
        return false;
      }
      if (_selectedCategory != null &&
          item.category.trim().toLowerCase() != _selectedCategory!.trim().toLowerCase()) {
        return false;
      }
      if (queryTerms.isEmpty) {
        return true;
      }

      final haystack = _buildSearchHaystack(item);
      return queryTerms.every(haystack.contains);
    }).toList(growable: false);

    filtered.sort((a, b) {
      switch (_sort) {
        case _LibrarySortOption.newest:
          return _compareDateDesc(a, b);
        case _LibrarySortOption.oldest:
          return _compareDateAsc(a, b);
        case _LibrarySortOption.titleAscending:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case _LibrarySortOption.titleDescending:
          return b.title.toLowerCase().compareTo(a.title.toLowerCase());
        case _LibrarySortOption.category:
          final byCategory =
              a.category.toLowerCase().compareTo(b.category.toLowerCase());
          return byCategory == 0
              ? a.title.toLowerCase().compareTo(b.title.toLowerCase())
              : byCategory;
      }
    });

    return filtered;
  }

  CollectibleModel _applyFavoriteOverride(CollectibleModel item) {
    final id = item.id;
    if (id == null) {
      return item;
    }

    final isFavorite = _favoriteOverrides[id];
    return isFavorite == null ? item : item.copyWith(isFavorite: isFavorite);
  }

  void _handleCollectibleUpdated(CollectibleModel collectible) {
    final id = collectible.id;
    if (id == null) {
      return;
    }

    setState(() {
      _favoriteOverrides[id] = collectible.isFavorite;
    });
  }

  String _buildSearchHaystack(CollectibleModel item) {
    final values = <String>[
      item.title,
      item.category,
      item.brand ?? '',
      item.series ?? '',
      item.lineOrSeries ?? '',
      item.characterOrSubject ?? '',
      item.itemNumber ?? '',
      item.boxStatus ?? '',
      item.itemCondition ?? '',
      for (final tag in item.tags) tag.name,
    ];

    return values.join(' ').toLowerCase();
  }

  int _compareDateDesc(CollectibleModel a, CollectibleModel b) {
    final aDate = a.createdAt ?? a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.createdAt ?? b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  }

  int _compareDateAsc(CollectibleModel a, CollectibleModel b) {
    final aDate = a.createdAt ?? a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.createdAt ?? b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return aDate.compareTo(bDate);
  }

  bool get _hasActiveBrowseState {
    return _query.isNotEmpty ||
        _favoritesOnly ||
        _grailsOnly ||
        _duplicatesOnly ||
        _hasPhotoOnly ||
        _selectedCategory != null ||
        _sort != _LibrarySortOption.newest;
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _applyBrowseState();
    final categoryStats = _buildCategoryStats();

    return CustomScrollView(
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
                  fillColor: AppColors.surfaceContainerHighest.withValues(alpha: 0.78),
                  controller: _searchController,
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
                const SizedBox(height: AppSpacing.md),
                _LibraryBrowseControls(
                  sortLabel: _sort.label,
                  favoritesOnly: _favoritesOnly,
                  grailsOnly: _grailsOnly,
                  duplicatesOnly: _duplicatesOnly,
                  hasPhotoOnly: _hasPhotoOnly,
                  onSortTap: _openSortSheet,
                  onFavoritesTap: () {
                    setState(() {
                      _favoritesOnly = !_favoritesOnly;
                    });
                  },
                  onGrailsTap: () {
                    setState(() {
                      _grailsOnly = !_grailsOnly;
                    });
                  },
                  onDuplicatesTap: () {
                    setState(() {
                      _duplicatesOnly = !_duplicatesOnly;
                    });
                  },
                  onHasPhotoTap: () {
                    setState(() {
                      _hasPhotoOnly = !_hasPhotoOnly;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _CategoryShelf(
                  categories: categoryStats,
                  selectedCategory: _selectedCategory,
                  onSelected: (category) {
                    setState(() {
                      _selectedCategory =
                          _selectedCategory == category ? null : category;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _LibraryResultsStrip(
                  visibleCount: visibleItems.length,
                  totalCount: widget.data.collectibles.length,
                  sortLabel: _sort.label,
                  hasActiveBrowseState: _hasActiveBrowseState,
                  onClearAll: _clearAllBrowseState,
                ),
                if (visibleItems.isEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _LibraryNoResultsPanel(onClearAll: _clearAllBrowseState),
                ],
              ],
            ),
          ),
        ),
        if (visibleItems.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              140,
            ),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final collectible = visibleItems[index];
                  final id = collectible.id;
                  final photoUrl =
                      id == null ? null : widget.data.photoUrlsByCollectibleId[id];

                  return CollectibleGridCard(
                    collectible: collectible,
                    photoUrl: photoUrl,
                    onCollectionChanged: widget.onCollectionChanged,
                    onCollectibleUpdated: _handleCollectibleUpdated,
                  );
                },
                childCount: visibleItems.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.72,
              ),
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

class _LibraryBrowseControls extends StatelessWidget {
  const _LibraryBrowseControls({
    required this.sortLabel,
    required this.favoritesOnly,
    required this.grailsOnly,
    required this.duplicatesOnly,
    required this.hasPhotoOnly,
    required this.onSortTap,
    required this.onFavoritesTap,
    required this.onGrailsTap,
    required this.onDuplicatesTap,
    required this.onHasPhotoTap,
  });

  final String sortLabel;
  final bool favoritesOnly;
  final bool grailsOnly;
  final bool duplicatesOnly;
  final bool hasPhotoOnly;
  final VoidCallback onSortTap;
  final VoidCallback onFavoritesTap;
  final VoidCallback onGrailsTap;
  final VoidCallback onDuplicatesTap;
  final VoidCallback onHasPhotoTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _BrowseChip(
            label: 'Sort: $sortLabel',
            active: true,
            icon: Icons.swap_vert_rounded,
            onTap: onSortTap,
          ),
          const SizedBox(width: AppSpacing.sm),
          _BrowseChip(
            label: 'Favorites',
            active: favoritesOnly,
            icon: Icons.favorite_outline_rounded,
            onTap: onFavoritesTap,
          ),
          const SizedBox(width: AppSpacing.sm),
          _BrowseChip(
            label: 'Grails',
            active: grailsOnly,
            icon: Icons.workspace_premium_outlined,
            onTap: onGrailsTap,
          ),
          const SizedBox(width: AppSpacing.sm),
          _BrowseChip(
            label: 'Duplicates',
            active: duplicatesOnly,
            icon: Icons.copy_all_rounded,
            onTap: onDuplicatesTap,
          ),
          const SizedBox(width: AppSpacing.sm),
          _BrowseChip(
            label: 'Has photo',
            active: hasPhotoOnly,
            icon: Icons.image_outlined,
            onTap: onHasPhotoTap,
          ),
        ],
      ),
    );
  }
}

class _CategoryShelf extends StatelessWidget {
  const _CategoryShelf({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<_CategoryShelfStat> categories;
  final String? selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Browse by category',
          style: Theme.of(context).textTheme.titleMedium,
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

class _LibraryResultsStrip extends StatelessWidget {
  const _LibraryResultsStrip({
    required this.visibleCount,
    required this.totalCount,
    required this.sortLabel,
    required this.hasActiveBrowseState,
    required this.onClearAll,
  });

  final int visibleCount;
  final int totalCount;
  final String sortLabel;
  final bool hasActiveBrowseState;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$visibleCount of $totalCount items',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                'Sorted by $sortLabel',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (hasActiveBrowseState)
          CollectorButton(
            label: 'Clear all',
            onPressed: onClearAll,
            variant: CollectorButtonVariant.tertiary,
          ),
      ],
    );
  }
}

class _LibraryNoResultsPanel extends StatelessWidget {
  const _LibraryNoResultsPanel({
    required this.onClearAll,
  });

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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
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

class _BrowseChip extends StatelessWidget {
  const _BrowseChip({
    required this.label,
    required this.active,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool active;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.withValues(alpha: 0.14)
                : AppColors.surfaceContainerHighest.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: active
                  ? AppColors.primary.withValues(alpha: 0.32)
                  : AppColors.outlineVariant.withValues(alpha: 0.24),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: active ? AppColors.primary : AppColors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibrarySortSheet extends StatelessWidget {
  const _LibrarySortSheet({
    required this.selected,
  });

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
    );
  }
}

class _CollectionLibraryLoadingState extends StatelessWidget {
  const _CollectionLibraryLoadingState();

  @override
  Widget build(BuildContext context) {
    return const CollectorLoadingOverlay(
    );
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
  const _CollectionLibraryErrorState({
    required this.onRetry,
  });

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
              CollectorButton(
                label: 'Retry',
                onPressed: () => onRetry(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectionLibraryData {
  const _CollectionLibraryData({
    required this.collectibles,
    required this.photoUrlsByCollectibleId,
  });

  final List<CollectibleModel> collectibles;
  final Map<String, String> photoUrlsByCollectibleId;
}

class _CategoryShelfStat {
  const _CategoryShelfStat({
    required this.category,
    required this.count,
  });

  final String category;
  final int count;
}
