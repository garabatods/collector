import 'package:flutter/material.dart';

import '../core/data/archive_repository.dart';
import '../core/data/archive_types.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/archive_bootstrap_gate.dart';
import '../widgets/collectible_grid_card.dart';
import '../widgets/collector_button.dart';
import '../widgets/collector_loading_overlay.dart';
import '../widgets/collector_panel.dart';
import '../widgets/collector_text_field.dart';

class CollectionSearchScreen extends StatefulWidget {
  const CollectionSearchScreen({
    super.key,
    this.screenTitle = 'Search Collection',
    this.emptyPrompt = 'Search by title, brand, category, series, or tag.',
    this.initialQuery = '',
    this.initialFavoritesOnly = false,
    this.initialGrailsOnly = false,
    this.initialDuplicatesOnly = false,
    this.autofocus = true,
  });

  final String screenTitle;
  final String emptyPrompt;
  final String initialQuery;
  final bool initialFavoritesOnly;
  final bool initialGrailsOnly;
  final bool initialDuplicatesOnly;
  final bool autofocus;

  @override
  State<CollectionSearchScreen> createState() => _CollectionSearchScreenState();
}

enum _CollectionSearchSortOption {
  relevance,
  newest,
  oldest,
  titleAscending,
  titleDescending,
}

class _CollectionSearchScreenState extends State<CollectionSearchScreen> {
  final _archiveRepository = ArchiveRepository.instance;
  final _queryController = TextEditingController();

  var _didChangeCollection = false;
  late bool _favoritesOnly;
  late bool _grailsOnly;
  late bool _duplicatesOnly;
  var _sort = _CollectionSearchSortOption.relevance;

  String get _query => _queryController.text.trim();

  @override
  void initState() {
    super.initState();
    _queryController.text = widget.initialQuery;
    _favoritesOnly = widget.initialFavoritesOnly;
    _grailsOnly = widget.initialGrailsOnly;
    _duplicatesOnly = widget.initialDuplicatesOnly;
    _queryController.addListener(_handleQueryChanged);
  }

  @override
  void dispose() {
    _queryController
      ..removeListener(_handleQueryChanged)
      ..dispose();
    super.dispose();
  }

  void _handleQueryChanged() {
    setState(() {});
  }

  Future<void> _reload() async {
    _didChangeCollection = true;
    await _archiveRepository.syncIfNeeded(force: true);
  }

  void _handleBack() {
    Navigator.of(context).pop(_didChangeCollection);
  }

  Future<void> _openSortSheet() async {
    final nextSort = await showModalBottomSheet<_CollectionSearchSortOption>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CollectionSearchSortSheet(selected: _sort);
      },
    );

    if (!mounted || nextSort == null || nextSort == _sort) {
      return;
    }

    setState(() {
      _sort = nextSort;
    });
  }

  void _clearQuery() {
    _queryController.clear();
  }

  ArchiveLibrarySort get _archiveSort => switch (_sort) {
        _CollectionSearchSortOption.relevance => ArchiveLibrarySort.relevance,
        _CollectionSearchSortOption.newest => ArchiveLibrarySort.newest,
        _CollectionSearchSortOption.oldest => ArchiveLibrarySort.oldest,
        _CollectionSearchSortOption.titleAscending =>
          ArchiveLibrarySort.titleAscending,
        _CollectionSearchSortOption.titleDescending =>
          ArchiveLibrarySort.titleDescending,
      };

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
            child: ArchiveBootstrapGate(
              child: StreamBuilder<ArchiveSearchResults>(
                stream: _archiveRepository.watchSearchResults(
                  query: _query,
                  favoritesOnly: _favoritesOnly,
                  grailsOnly: _grailsOnly,
                  duplicatesOnly: _duplicatesOnly,
                  sort: _archiveSort,
                ),
                builder: (context, snapshot) {
                  final data = snapshot.data;

                  if (snapshot.hasError && data == null) {
                    return _CollectionSearchErrorState(
                      onRetry: _reload,
                      onBack: _handleBack,
                    );
                  }

                  if (data == null) {
                    return const CollectorLoadingOverlay();
                  }

                  if (data.collectibles.isEmpty) {
                    return _CollectionSearchEmptyState(onBack: _handleBack);
                  }

                  final visibleItems = data.collectibles;

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
                              CollectorButton(
                                label: 'Back',
                                onPressed: _handleBack,
                                variant: CollectorButtonVariant.icon,
                                icon: Icons.arrow_back_rounded,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                widget.screenTitle,
                                style:
                                    Theme.of(context).textTheme.headlineLarge,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                _query.isEmpty
                                    ? widget.emptyPrompt
                                    : '${visibleItems.length} match${visibleItems.length == 1 ? '' : 'es'} in your collection',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              CollectorSearchField(
                                hintText: 'Search your collection...',
                                fillColor: AppColors.surfaceContainerHighest
                                    .withValues(alpha: 0.78),
                                controller: _queryController,
                                readOnly: false,
                                autofocus: widget.autofocus,
                                onChanged: (_) {},
                                suffixIcon: _query.isEmpty
                                    ? null
                                    : IconButton(
                                        onPressed: _clearQuery,
                                        icon:
                                            const Icon(Icons.close_rounded),
                                        color: AppColors.onSurfaceVariant,
                                      ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              _CollectionSearchBrowseControls(
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
                              const SizedBox(height: AppSpacing.md),
                              _SearchHintPanel(query: _query),
                              if (visibleItems.isEmpty) ...[
                                const SizedBox(height: AppSpacing.lg),
                                _CollectionSearchNoResultsPanel(
                                  hasQuery: _query.isNotEmpty,
                                  onClearQuery: _clearQuery,
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
                                final photoRef = id == null
                                    ? null
                                    : data.photoRefsByCollectibleId[id];

                                return CollectibleGridCard(
                                  collectible: collectible,
                                  photoRef: photoRef,
                                  onCollectionChanged: _reload,
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
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension on _CollectionSearchSortOption {
  String get label => switch (this) {
        _CollectionSearchSortOption.relevance => 'Best Match',
        _CollectionSearchSortOption.newest => 'Newest',
        _CollectionSearchSortOption.oldest => 'Oldest',
        _CollectionSearchSortOption.titleAscending => 'Title A-Z',
        _CollectionSearchSortOption.titleDescending => 'Title Z-A',
      };
}

class _CollectionSearchBrowseControls extends StatelessWidget {
  const _CollectionSearchBrowseControls({
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
          _SearchBrowseControlChip(
            label: 'Sort: $sortLabel',
            active: true,
            icon: Icons.swap_vert_rounded,
            onTap: onSortTap,
          ),
          const SizedBox(width: AppSpacing.sm),
          _SearchBrowseControlChip(
            label: 'Favorites',
            active: favoritesOnly,
            icon: Icons.favorite_outline_rounded,
            onTap: onFavoritesTap,
          ),
          const SizedBox(width: AppSpacing.sm),
          _SearchBrowseControlChip(
            label: 'Grails',
            active: grailsOnly,
            icon: Icons.workspace_premium_outlined,
            onTap: onGrailsTap,
          ),
          const SizedBox(width: AppSpacing.sm),
          _SearchBrowseControlChip(
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

class _SearchBrowseControlChip extends StatelessWidget {
  const _SearchBrowseControlChip({
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

class _CollectionSearchSortSheet extends StatelessWidget {
  const _CollectionSearchSortSheet({
    required this.selected,
  });

  final _CollectionSearchSortOption selected;

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
                  'Sort Results',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Choose how search results should be ordered.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final option in _CollectionSearchSortOption.values)
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

class _SearchHintPanel extends StatelessWidget {
  const _SearchHintPanel({
    required this.query,
  });

  final String query;

  @override
  Widget build(BuildContext context) {
    return CollectorPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.88),
      child: Text(
        query.isEmpty
            ? 'Start with a title, then try brand, series, category, or tags to narrow things down fast.'
            : 'Best Match favors title hits first, then brand, series, category, and tags.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _CollectionSearchNoResultsPanel extends StatelessWidget {
  const _CollectionSearchNoResultsPanel({
    required this.hasQuery,
    required this.onClearQuery,
    required this.onClearFilters,
  });

  final bool hasQuery;
  final VoidCallback onClearQuery;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return CollectorPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No matches yet.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hasQuery
                ? 'Try a broader term, or clear your filters to widen the search.'
                : 'The current filters are hiding everything. Clear them to browse the full collection again.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (hasQuery)
                CollectorButton(
                  label: 'Clear Search',
                  onPressed: onClearQuery,
                  variant: CollectorButtonVariant.secondary,
                ),
              CollectorButton(
                label: 'Clear Filters',
                onPressed: onClearFilters,
                variant: CollectorButtonVariant.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollectionSearchEmptyState extends StatelessWidget {
  const _CollectionSearchEmptyState({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CollectorButton(
            label: 'Back',
            onPressed: onBack,
            variant: CollectorButtonVariant.icon,
            icon: Icons.arrow_back_rounded,
          ),
          const Expanded(
            child: Center(
              child: _SearchMessagePanel(
                title: 'No collection to search yet.',
                description:
                    'Add your first collectible and search will become the fastest way to find anything in your archive.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionSearchErrorState extends StatelessWidget {
  const _CollectionSearchErrorState({
    required this.onRetry,
    required this.onBack,
  });

  final Future<void> Function() onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CollectorButton(
            label: 'Back',
            onPressed: onBack,
            variant: CollectorButtonVariant.icon,
            icon: Icons.arrow_back_rounded,
          ),
          const Expanded(
            child: Center(
              child: _SearchMessagePanel(
                title: 'Search is unavailable right now.',
                description:
                    'We could not load your collection for search. Try again in a moment.',
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: CollectorButton(
              label: 'Try Again',
              onPressed: onRetry,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchMessagePanel extends StatelessWidget {
  const _SearchMessagePanel({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return CollectorPanel(
      padding: const EdgeInsets.all(AppSpacing.xl),
      backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.92),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
    );
  }
}
