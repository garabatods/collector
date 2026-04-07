import 'package:flutter/material.dart';

import '../features/collection/data/models/collectible_model.dart';
import '../features/collection/data/repositories/collectible_photos_repository.dart';
import '../features/collection/data/repositories/collectibles_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/collectible_grid_card.dart';
import '../widgets/collector_button.dart';
import '../widgets/collector_loading_overlay.dart';
import '../widgets/collector_panel.dart';

class CategoryCollectionScreen extends StatefulWidget {
  const CategoryCollectionScreen({
    super.key,
    required this.category,
  });

  final String category;

  @override
  State<CategoryCollectionScreen> createState() =>
      _CategoryCollectionScreenState();
}

enum _CategorySortOption {
  newest,
  oldest,
  titleAscending,
  titleDescending,
}

class _CategoryCollectionScreenState extends State<CategoryCollectionScreen> {
  final _collectiblesRepository = CollectiblesRepository();
  final _photosRepository = CollectiblePhotosRepository();

  late Future<_CategoryCollectionData> _future;
  var _didChangeCollection = false;
  var _favoritesOnly = false;
  var _grailsOnly = false;
  var _duplicatesOnly = false;
  var _sort = _CategorySortOption.newest;
  final Map<String, bool> _favoriteOverrides = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_CategoryCollectionData> _load() async {
    final normalizedCategory = widget.category.trim().toLowerCase();
    final collectibles = (await _collectiblesRepository.fetchAll())
        .where((item) => item.category.trim().toLowerCase() == normalizedCategory)
        .toList(growable: false);

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

    return _CategoryCollectionData(
      collectibles: collectibles,
      photoUrlsByCollectibleId: urls,
    );
  }

  Future<void> _reload() async {
    _didChangeCollection = true;
    _favoriteOverrides.clear();
    setState(() {
      _future = _load();
    });
    await _future;
  }

  void _handleBack() {
    Navigator.of(context).pop(_didChangeCollection);
  }

  List<CollectibleModel> _applyBrowseState(List<CollectibleModel> items) {
    final filtered = items.map(_applyFavoriteOverride).where((item) {
      if (_favoritesOnly && !item.isFavorite) {
        return false;
      }
      if (_grailsOnly && !item.isGrail) {
        return false;
      }
      if (_duplicatesOnly && !item.isDuplicate) {
        return false;
      }
      return true;
    }).toList(growable: false);

    filtered.sort((a, b) {
      switch (_sort) {
        case _CategorySortOption.newest:
          return _compareDateDesc(a, b);
        case _CategorySortOption.oldest:
          return _compareDateAsc(a, b);
        case _CategorySortOption.titleAscending:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case _CategorySortOption.titleDescending:
          return b.title.toLowerCase().compareTo(a.title.toLowerCase());
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

  Future<void> _openSortSheet() async {
    final nextSort = await showModalBottomSheet<_CategorySortOption>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CategorySortSheet(
          selected: _sort,
        );
      },
    );

    if (!mounted || nextSort == null || nextSort == _sort) {
      return;
    }

    setState(() {
      _sort = nextSort;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    AppColors.featureGlow,
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: FutureBuilder<_CategoryCollectionData>(
              future: _future,
              builder: (context, snapshot) {
                final data = snapshot.data;
                final isRefreshing = snapshot.connectionState != ConnectionState.done;

                if (snapshot.hasError && data == null) {
                  return _CategoryCollectionErrorState(
                    category: widget.category,
                    onRetry: _reload,
                    onBack: _handleBack,
                  );
                }

                if (data == null) {
                  return const CollectorLoadingOverlay();
                }

                if (data.collectibles.isEmpty) {
                  return _CategoryCollectionEmptyState(
                    category: widget.category,
                    onBack: _handleBack,
                  );
                }

                final visibleItems = _applyBrowseState(data.collectibles);

                return Stack(
                  children: [
                    CustomScrollView(
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
                                CollectorButton(
                                  label: 'Back',
                                  onPressed: _handleBack,
                                  variant: CollectorButtonVariant.icon,
                                  icon: Icons.arrow_back_rounded,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Text(
                                  widget.category,
                                  style: Theme.of(context).textTheme.headlineLarge,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  '${visibleItems.length} of ${data.collectibles.length} item${data.collectibles.length == 1 ? '' : 's'}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                _CategoryBrowseControls(
                                  sortLabel: _sort.label,
                                  favoritesOnly: _favoritesOnly,
                                  grailsOnly: _grailsOnly,
                                  duplicatesOnly: _duplicatesOnly,
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
                                ),
                                if (visibleItems.isEmpty) ...[
                                  const SizedBox(height: AppSpacing.lg),
                                  _EmptyFilterResultsPanel(
                                    onClearFilters: () {
                                      setState(() {
                                        _favoritesOnly = false;
                                        _grailsOnly = false;
                                        _duplicatesOnly = false;
                                      });
                                    },
                                  ),
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
                              AppSpacing.xxl,
                            ),
                            sliver: SliverGrid(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final collectible = visibleItems[index];
                                  final id = collectible.id;
                                  final photoUrl = id == null
                                      ? null
                                      : data.photoUrlsByCollectibleId[id];

                                  return CollectibleGridCard(
                                    collectible: collectible,
                                    photoUrl: photoUrl,
                                    onCollectionChanged: _reload,
                                    onCollectibleUpdated: _handleCollectibleUpdated,
                                  );
                                },
                                childCount: visibleItems.length,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: AppSpacing.md,
                                mainAxisSpacing: AppSpacing.md,
                                childAspectRatio: 0.72,
                              ),
                            ),
                          ),
                      ],
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
            ),
          ),
        ],
      ),
    );
  }
}

extension on _CategorySortOption {
  String get label => switch (this) {
        _CategorySortOption.newest => 'Newest',
        _CategorySortOption.oldest => 'Oldest',
        _CategorySortOption.titleAscending => 'Title A-Z',
        _CategorySortOption.titleDescending => 'Title Z-A',
      };
}

class _CategoryBrowseControls extends StatelessWidget {
  const _CategoryBrowseControls({
    required this.sortLabel,
    required this.favoritesOnly,
    required this.grailsOnly,
    required this.duplicatesOnly,
    required this.onSortTap,
    required this.onFavoritesTap,
    required this.onGrailsTap,
    required this.onDuplicatesTap,
  });

  final String sortLabel;
  final bool favoritesOnly;
  final bool grailsOnly;
  final bool duplicatesOnly;
  final VoidCallback onSortTap;
  final VoidCallback onFavoritesTap;
  final VoidCallback onGrailsTap;
  final VoidCallback onDuplicatesTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _BrowseControlChip(
            label: 'Sort: $sortLabel',
            active: true,
            icon: Icons.swap_vert_rounded,
            onTap: onSortTap,
          ),
          const SizedBox(width: AppSpacing.sm),
          _BrowseControlChip(
            label: 'Favorites',
            active: favoritesOnly,
            icon: Icons.favorite_outline_rounded,
            onTap: onFavoritesTap,
          ),
          const SizedBox(width: AppSpacing.sm),
          _BrowseControlChip(
            label: 'Grails',
            active: grailsOnly,
            icon: Icons.workspace_premium_outlined,
            onTap: onGrailsTap,
          ),
          const SizedBox(width: AppSpacing.sm),
          _BrowseControlChip(
            label: 'Duplicates',
            active: duplicatesOnly,
            icon: Icons.copy_all_rounded,
            onTap: onDuplicatesTap,
          ),
        ],
      ),
    );
  }
}

class _BrowseControlChip extends StatelessWidget {
  const _BrowseControlChip({
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
                      color:
                          active ? AppColors.primary : AppColors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySortSheet extends StatelessWidget {
  const _CategorySortSheet({
    required this.selected,
  });

  final _CategorySortOption selected;

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
                'Sort Category',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Choose how this category should be ordered.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final option in _CategorySortOption.values)
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

class _EmptyFilterResultsPanel extends StatelessWidget {
  const _EmptyFilterResultsPanel({
    required this.onClearFilters,
  });

  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return CollectorPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.94),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No items match the current filters.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Try clearing one or more filters to see the full category again.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          CollectorButton(
            label: 'Clear Filters',
            onPressed: onClearFilters,
            variant: CollectorButtonVariant.secondary,
          ),
        ],
      ),
    );
  }
}

class _CategoryCollectionEmptyState extends StatelessWidget {
  const _CategoryCollectionEmptyState({
    required this.category,
    required this.onBack,
  });

  final String category;
  final VoidCallback onBack;

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
              CollectorButton(
                label: 'Back',
                onPressed: onBack,
                variant: CollectorButtonVariant.icon,
                icon: Icons.arrow_back_rounded,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'No $category yet.',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Once you add collectibles in this category, they will show up here.',
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

class _CategoryCollectionErrorState extends StatelessWidget {
  const _CategoryCollectionErrorState({
    required this.category,
    required this.onRetry,
    required this.onBack,
  });

  final String category;
  final Future<void> Function() onRetry;
  final VoidCallback onBack;

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
                'Could not load $category.',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Give it another try and we will pull the latest items in this category.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CollectorButton(
                    label: 'Back',
                    onPressed: onBack,
                    variant: CollectorButtonVariant.secondary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  CollectorButton(
                    label: 'Retry',
                    onPressed: () => onRetry(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCollectionData {
  const _CategoryCollectionData({
    required this.collectibles,
    required this.photoUrlsByCollectibleId,
  });

  final List<CollectibleModel> collectibles;
  final Map<String, String> photoUrlsByCollectibleId;
}
