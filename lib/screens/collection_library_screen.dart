import 'package:flutter/material.dart';

import '../core/collector_haptics.dart';
import '../core/data/archive_repository.dart';
import '../core/data/archive_types.dart';
import '../features/collection/data/repositories/collectible_photos_repository.dart';
import '../features/collection/data/repositories/collectibles_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/archive_bootstrap_gate.dart';
import '../widgets/category_icon.dart';
import '../widgets/collector_button.dart';
import '../widgets/collector_bottom_sheet.dart';
import '../widgets/collectible_grid_card.dart';
import '../widgets/collector_panel.dart';
import '../widgets/collector_snack_bar.dart';
import '../widgets/collector_skeleton.dart';
import '../widgets/collector_text_field.dart';

class CollectionLibraryScreen extends StatefulWidget {
  const CollectionLibraryScreen({
    super.key,
    required this.refreshSeed,
    this.searchFocusRequest = 0,
    this.onSelectionModeChanged,
  });

  final int refreshSeed;
  final int searchFocusRequest;
  final ValueChanged<bool>? onSelectionModeChanged;

  @override
  State<CollectionLibraryScreen> createState() =>
      _CollectionLibraryScreenState();
}

class _CollectionLibraryScreenState extends State<CollectionLibraryScreen> {
  final _archiveRepository = ArchiveRepository.instance;

  @override
  void didUpdateWidget(covariant CollectionLibraryScreen oldWidget) {
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
      child: _CollectionLibraryLoadedState(
        searchFocusRequest: widget.searchFocusRequest,
        onCollectionChanged: _reload,
        onSelectionModeChanged: widget.onSelectionModeChanged,
      ),
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

enum _LibraryViewMode { grid, list }

class _CollectionLibraryLoadedState extends StatefulWidget {
  const _CollectionLibraryLoadedState({
    required this.searchFocusRequest,
    required this.onCollectionChanged,
    this.onSelectionModeChanged,
  });

  final int searchFocusRequest;
  final Future<void> Function() onCollectionChanged;
  final ValueChanged<bool>? onSelectionModeChanged;

  @override
  State<_CollectionLibraryLoadedState> createState() =>
      _CollectionLibraryLoadedStateState();
}

class _CollectionLibraryLoadedStateState
    extends State<_CollectionLibraryLoadedState> {
  static const _pageSize = 24;

  final _archiveRepository = ArchiveRepository.instance;
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
  var _viewMode = _LibraryViewMode.grid;
  var _visibleItemCount = _pageSize;
  var _knownResultCount = 0;
  var _isExpandingVisibleItems = false;
  var _isDeletingSelection = false;
  final Set<String> _selectedCollectibleIds = <String>{};
  late Stream<ArchiveLibraryPage> _stream;
  bool? _lastReportedSelectionMode;

  String get _query => _searchController.text.trim();
  bool get _isSelectionMode => _selectedCollectibleIds.isNotEmpty;
  int get _selectedCount => _selectedCollectibleIds.length;

  @override
  void initState() {
    super.initState();
    _stream = _buildStream();
    _searchController.addListener(_handleQueryChanged);
    _scrollController.addListener(_handleScroll);
    _reportSelectionModeIfChanged();
  }

  @override
  void dispose() {
    widget.onSelectionModeChanged?.call(false);
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
    if (oldWidget.searchFocusRequest != widget.searchFocusRequest) {
      _focusSearchField();
    }
  }

  void _handleQueryChanged() {
    setState(() {
      _visibleItemCount = _pageSize;
      _stream = _buildStream();
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
    if (!_scrollController.hasClients) {
      return;
    }

    final threshold = _scrollController.position.maxScrollExtent - 420;
    if (_isExpandingVisibleItems ||
        (_knownResultCount > 0 && _visibleItemCount >= _knownResultCount)) {
      return;
    }

    if (_scrollController.position.pixels >= threshold) {
      final nextVisibleCount = _visibleItemCount + _pageSize;
      setState(() {
        _isExpandingVisibleItems = true;
        _visibleItemCount = _knownResultCount > 0
            ? nextVisibleCount.clamp(_pageSize, _knownResultCount).toInt()
            : nextVisibleCount;
        _stream = _buildStream();
      });
    }
  }

  void _resetVisibleItems() {
    _visibleItemCount = _pageSize;
    _knownResultCount = 0;
    _isExpandingVisibleItems = false;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _reportSelectionModeIfChanged() {
    final current = _isSelectionMode;
    if (_lastReportedSelectionMode == current) {
      return;
    }
    _lastReportedSelectionMode = current;
    widget.onSelectionModeChanged?.call(current);
  }

  Future<void> _openRefineSheet() async {
    final nextRefinement = await showModalBottomSheet<_LibraryRefineSelection>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _LibraryRefineSheet(
        sort: _sort,
        favoritesOnly: _favoritesOnly,
        grailsOnly: _grailsOnly,
        duplicatesOnly: _duplicatesOnly,
        hasPhotoOnly: _hasPhotoOnly,
      ),
    );

    if (!mounted || nextRefinement == null) {
      return;
    }

    if (nextRefinement.sort == _sort &&
        nextRefinement.favoritesOnly == _favoritesOnly &&
        nextRefinement.grailsOnly == _grailsOnly &&
        nextRefinement.duplicatesOnly == _duplicatesOnly &&
        nextRefinement.hasPhotoOnly == _hasPhotoOnly) {
      return;
    }

    setState(() {
      _sort = nextRefinement.sort;
      _favoritesOnly = nextRefinement.favoritesOnly;
      _grailsOnly = nextRefinement.grailsOnly;
      _duplicatesOnly = nextRefinement.duplicatesOnly;
      _hasPhotoOnly = nextRefinement.hasPhotoOnly;
      _resetVisibleItems();
      _stream = _buildStream();
    });
  }

  Future<void> _openScopeSheet({
    required List<_CategoryShelfStat> categories,
    required int totalCount,
  }) async {
    final nextScope = await showModalBottomSheet<_LibraryBrowseScope>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _LibraryScopeSheet(
        selectedCategory: _selectedCategory,
        categories: categories,
        totalCount: totalCount,
      ),
    );

    if (!mounted || nextScope == null) {
      return;
    }

    if (nextScope.category == _selectedCategory) {
      return;
    }

    setState(() {
      _selectedCategory = nextScope.category;
      _resetVisibleItems();
      _stream = _buildStream();
    });
  }

  Future<void> _clearAllBrowseState() async {
    _exitSelectionMode();
    setState(() {
      _favoritesOnly = false;
      _grailsOnly = false;
      _duplicatesOnly = false;
      _hasPhotoOnly = false;
      _selectedCategory = null;
      _searchController.clear();
      _sort = _LibrarySortOption.newest;
      _resetVisibleItems();
      _stream = _buildStream();
    });
  }

  void _enterSelectionMode(String collectibleId) {
    CollectorHaptics.medium();
    setState(() {
      _selectedCollectibleIds
        ..clear()
        ..add(collectibleId);
    });
    _reportSelectionModeIfChanged();
  }

  void _toggleSelection(String collectibleId) {
    CollectorHaptics.selection();
    setState(() {
      if (_selectedCollectibleIds.contains(collectibleId)) {
        _selectedCollectibleIds.remove(collectibleId);
      } else {
        _selectedCollectibleIds.add(collectibleId);
      }
    });
    _reportSelectionModeIfChanged();
  }

  void _exitSelectionMode() {
    if (_selectedCollectibleIds.isEmpty && !_isDeletingSelection) {
      return;
    }
    setState(() {
      _selectedCollectibleIds.clear();
      _isDeletingSelection = false;
    });
    _reportSelectionModeIfChanged();
  }

  Future<void> _confirmDeleteSelection() async {
    if (_selectedCollectibleIds.isEmpty || _isDeletingSelection) {
      return;
    }

    final count = _selectedCollectibleIds.length;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(count == 1 ? 'Delete item?' : 'Delete $count items?'),
          content: Text(
            count == 1
                ? 'This removes it from your collection.'
                : 'This removes them from your collection.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldDelete != true) {
      return;
    }

    setState(() {
      _isDeletingSelection = true;
    });

    final idsToDelete = _selectedCollectibleIds.toList(growable: false);
    try {
      for (final collectibleId in idsToDelete) {
        await _photosRepository.deleteAllForCollectible(collectibleId);
        await _collectiblesRepository.delete(collectibleId);
      }
      if (!mounted) {
        return;
      }
      CollectorHaptics.heavy();
      CollectorSnackBar.show(
        context,
        message: count == 1
            ? 'Item deleted from your library.'
            : '$count items deleted from your library.',
        tone: CollectorSnackBarTone.success,
      );
      _exitSelectionMode();
      await widget.onCollectionChanged();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isDeletingSelection = false;
      });
      CollectorSnackBar.show(
        context,
        message: 'Could not delete those items right now.',
        tone: CollectorSnackBarTone.error,
      );
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

  ArchiveLibrarySort get _archiveSort => switch (_sort) {
    _LibrarySortOption.newest => ArchiveLibrarySort.newest,
    _LibrarySortOption.oldest => ArchiveLibrarySort.oldest,
    _LibrarySortOption.titleAscending => ArchiveLibrarySort.titleAscending,
    _LibrarySortOption.titleDescending => ArchiveLibrarySort.titleDescending,
    _LibrarySortOption.category => ArchiveLibrarySort.category,
  };

  Stream<ArchiveLibraryPage> _buildStream() {
    return _archiveRepository.watchLibraryPage(
      filters: ArchiveLibraryFilters(
        query: _query,
        favoritesOnly: _favoritesOnly,
        grailsOnly: _grailsOnly,
        duplicatesOnly: _duplicatesOnly,
        hasPhotoOnly: _hasPhotoOnly,
        category: _selectedCategory,
      ),
      sort: _archiveSort,
      limit: _visibleItemCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ArchiveLibraryPage>(
      stream: _stream,
      builder: (context, snapshot) {
        final data = snapshot.data;

        if (snapshot.hasError && data == null) {
          return _CollectionLibraryErrorState(
            onRetry: widget.onCollectionChanged,
          );
        }

        if (data == null) {
          return const _CollectionLibraryLoadingState();
        }

        _knownResultCount = data.totalCount;
        _isExpandingVisibleItems = false;

        final categories = data.categoryStats
            .map(
              (entry) => _CategoryShelfStat(
                category: entry.category,
                count: entry.count,
              ),
            )
            .toList(growable: false);
        final isCollectionEmpty =
            data.totalCount == 0 && _hasDefaultBrowseState;

        if (isCollectionEmpty) {
          return const _CollectionLibraryEmptyState();
        }

        final contentBottomPadding = _isSelectionMode ? 196.0 : 140.0;

        return Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: const _LibraryPageTitle(),
                  ),
                ),
                if (!_isSelectionMode)
                  SliverAppBar(
                    pinned: true,
                    primary: false,
                    automaticallyImplyLeading: false,
                    toolbarHeight: _LibraryStickySearchHeader.heightFor(
                      _hasActiveRefinementState,
                    ),
                    backgroundColor: AppColors.background.withValues(alpha: 0.98),
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.black.withValues(alpha: 0.22),
                    elevation: 8,
                    flexibleSpace: _LibraryStickySearchHeader(
                      searchControls: Row(
                        children: [
                          Expanded(
                                child: CollectorSearchField(
                                  hintText:
                                      'Search title, category, brand, series, or tags...',
                                  fillColor: AppColors.searchFieldFill,
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
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _LibraryUtilityIconButton(
                            icon: Icons.tune_rounded,
                            highlighted: _hasActiveRefinementState,
                            tooltip: 'Refine library',
                            onTap: _openRefineSheet,
                          ),
                        ],
                      ),
                      activeBrowseStrip: _hasActiveRefinementState
                          ? _ActiveBrowseStrip(
                              sortLabel: _sort.label,
                              showSortChip: _sort != _LibrarySortOption.newest,
                              favoritesOnly: _favoritesOnly,
                              grailsOnly: _grailsOnly,
                              duplicatesOnly: _duplicatesOnly,
                              hasPhotoOnly: _hasPhotoOnly,
                              onClearSort: () {
                                setState(() {
                                  _sort = _LibrarySortOption.newest;
                                  _resetVisibleItems();
                                  _stream = _buildStream();
                                });
                              },
                              onClearFavorites: () {
                                setState(() {
                                  _favoritesOnly = false;
                                  _resetVisibleItems();
                                  _stream = _buildStream();
                                });
                              },
                              onClearGrails: () {
                                setState(() {
                                  _grailsOnly = false;
                                  _resetVisibleItems();
                                  _stream = _buildStream();
                                });
                              },
                              onClearDuplicates: () {
                                setState(() {
                                  _duplicatesOnly = false;
                                  _resetVisibleItems();
                                  _stream = _buildStream();
                                });
                              },
                              onClearHasPhoto: () {
                                setState(() {
                                  _hasPhotoOnly = false;
                                  _resetVisibleItems();
                                  _stream = _buildStream();
                                });
                              },
                              onClearAll: _clearAllBrowseState,
                            )
                          : null,
                      browseControls: _LibraryBrowseControls(
                        categories: categories,
                        totalCount: data.totalCount,
                        selectedCategory: _selectedCategory,
                        viewMode: _viewMode,
                        onScopeTap: () => _openScopeSheet(
                          categories: categories,
                          totalCount: data.totalCount,
                        ),
                        onViewModeChanged: (viewMode) {
                          setState(() {
                            _viewMode = viewMode;
                          });
                        },
                      ),
                    ),
                  ),
                if (data.items.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        contentBottomPadding,
                      ),
                      child: _LibraryNoResultsPanel(
                        onClearAll: _clearAllBrowseState,
                      ),
                    ),
                  ),
                if (data.items.isNotEmpty)
                  if (_viewMode == _LibraryViewMode.grid)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        contentBottomPadding,
                      ),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final collectible = data.items[index];
                          final id = collectible.id;
                          final photoRef = id == null
                              ? null
                              : data.photoRefsByCollectibleId[id];

                          return CollectibleGridCard(
                            collectible: collectible,
                            photoRef: photoRef,
                            onCollectionChanged: widget.onCollectionChanged,
                            selectionMode: _isSelectionMode,
                            selected: id != null &&
                                _selectedCollectibleIds.contains(id),
                            onSelectionTap: id == null
                                ? null
                                : () => _toggleSelection(id),
                            onLongPressSelection: id == null
                                ? null
                                : () => _isSelectionMode
                                    ? _toggleSelection(id)
                                    : _enterSelectionMode(id),
                          );
                        }, childCount: data.items.length),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: AppSpacing.sm,
                              mainAxisSpacing: AppSpacing.md,
                              childAspectRatio: 0.72,
                            ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        contentBottomPadding,
                      ),
                      sliver: SliverList.separated(
                        itemCount: data.items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.xs),
                        itemBuilder: (context, index) {
                          final collectible = data.items[index];
                          final id = collectible.id;
                          final photoRef = id == null
                              ? null
                              : data.photoRefsByCollectibleId[id];

                          return CollectibleListCard(
                            collectible: collectible,
                            photoRef: photoRef,
                            onCollectionChanged: widget.onCollectionChanged,
                            selectionMode: _isSelectionMode,
                            selected: id != null &&
                                _selectedCollectibleIds.contains(id),
                            onSelectionTap: id == null
                                ? null
                                : () => _toggleSelection(id),
                            onLongPressSelection: id == null
                                ? null
                                : () => _isSelectionMode
                                    ? _toggleSelection(id)
                                    : _enterSelectionMode(id),
                          );
                        },
                      ),
                    ),
                if (data.items.isNotEmpty && data.hasMore)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        contentBottomPadding,
                      ),
                      child: const _InlineLibraryLoader(
                        label: 'Scroll to load more...',
                      ),
                    ),
                  ),
              ],
            ),
            if (_isSelectionMode)
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: _LibraryBulkDeleteBar(
                  selectedCount: _selectedCount,
                  isDeleting: _isDeletingSelection,
                  onClose: _exitSelectionMode,
                  onDelete: _confirmDeleteSelection,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LibraryBulkDeleteBar extends StatelessWidget {
  const _LibraryBulkDeleteBar({
    required this.selectedCount,
    required this.isDeleting,
    required this.onClose,
    required this.onDelete,
  });

  final int selectedCount;
  final bool isDeleting;
  final VoidCallback onClose;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final actionSize = isDeleting ? 44.0 : 48.0;

    return CollectorPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.96),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isDeleting ? null : onClose,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                width: actionSize,
                height: actionSize,
                decoration: BoxDecoration(
                  color: isDeleting
                      ? AppColors.surfaceContainerHighest.withValues(alpha: 0.28)
                      : AppColors.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDeleting
                        ? AppColors.outlineVariant.withValues(alpha: 0.18)
                        : AppColors.primary.withValues(alpha: 0.26),
                  ),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: isDeleting
                      ? AppColors.onSurfaceVariant
                      : AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              selectedCount == 1
                  ? '1 Item Selected'
                  : '$selectedCount Items Selected',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isDeleting ? null : onDelete,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                width: actionSize,
                height: actionSize,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: AppColors.onPrimary,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryPageTitle extends StatelessWidget {
  const _LibraryPageTitle();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          Positioned(
            right: AppSpacing.md,
            top: -8,
            child: Image.asset(
              'assets/icons/categories_v2/library_big.png',
              width: 86,
              height: 86,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Your Library',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
          ),
        ],
      ),
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

class _LibraryStickySearchHeader extends StatelessWidget {
  const _LibraryStickySearchHeader({
    required this.searchControls,
    required this.browseControls,
    this.activeBrowseStrip,
  });

  final Widget searchControls;
  final Widget browseControls;
  final Widget? activeBrowseStrip;

  static double heightFor(bool hasActiveRefinementState) {
    return hasActiveRefinementState ? 194 : 146;
  }

  @override
  Widget build(BuildContext context) {
    final activeBrowseStrip = this.activeBrowseStrip;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          searchControls,
          if (activeBrowseStrip != null) ...[
            const SizedBox(height: AppSpacing.sm),
            activeBrowseStrip,
          ],
          const SizedBox(height: AppSpacing.sm),
          browseControls,
        ],
      ),
    );
  }
}

class _LibraryBrowseControls extends StatelessWidget {
  const _LibraryBrowseControls({
    required this.categories,
    required this.totalCount,
    required this.selectedCategory,
    required this.viewMode,
    required this.onScopeTap,
    required this.onViewModeChanged,
  });

  final List<_CategoryShelfStat> categories;
  final int totalCount;
  final String? selectedCategory;
  final _LibraryViewMode viewMode;
  final VoidCallback onScopeTap;
  final ValueChanged<_LibraryViewMode> onViewModeChanged;

  @override
  Widget build(BuildContext context) {
    final selectedLabel = selectedCategory ?? 'All Items';
    final selectedCount = selectedCategory == null
        ? totalCount
        : _countForCategory(categories, selectedCategory!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _LibraryScopeButton(
                label: selectedLabel,
                count: selectedCount,
                onTap: onScopeTap,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _LibraryViewToggle(
              viewMode: viewMode,
              onChanged: onViewModeChanged,
            ),
          ],
        ),
      ],
    );
  }
}

class _LibraryScopeButton extends StatelessWidget {
  const _LibraryScopeButton({
    required this.label,
    required this.count,
    required this.onTap,
  });

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHighest.withValues(alpha: 0.36),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            children: [
              const CategoryIcon(
                category: 'Library',
                size: 22,
                fallbackColor: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: AppColors.onSurface),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '$count',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.onSurfaceVariant,
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

class _LibraryViewToggle extends StatelessWidget {
  const _LibraryViewToggle({required this.viewMode, required this.onChanged});

  final _LibraryViewMode viewMode;
  final ValueChanged<_LibraryViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LibraryViewToggleButton(
            icon: Icons.grid_view_rounded,
            selected: viewMode == _LibraryViewMode.grid,
            tooltip: 'Grid view',
            onTap: () => onChanged(_LibraryViewMode.grid),
          ),
          _LibraryViewToggleButton(
            icon: Icons.view_list_rounded,
            selected: viewMode == _LibraryViewMode.list,
            tooltip: 'List view',
            onTap: () => onChanged(_LibraryViewMode.list),
          ),
        ],
      ),
    );
  }
}

class _LibraryViewToggleButton extends StatelessWidget {
  const _LibraryViewToggleButton({
    required this.icon,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            size: 17,
            color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
        ),
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
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: 52,
            height: 52,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 24,
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

class _LibraryRefineSelection {
  const _LibraryRefineSelection({
    required this.sort,
    required this.favoritesOnly,
    required this.grailsOnly,
    required this.duplicatesOnly,
    required this.hasPhotoOnly,
  });

  final _LibrarySortOption sort;
  final bool favoritesOnly;
  final bool grailsOnly;
  final bool duplicatesOnly;
  final bool hasPhotoOnly;
}

class _LibraryBrowseScope {
  const _LibraryBrowseScope({required this.label, required this.category});

  final String label;
  final String? category;
}

const _libraryBrowseScopes = <_LibraryBrowseScope>[
  _LibraryBrowseScope(label: 'All Items', category: null),
  _LibraryBrowseScope(label: 'Action Figures', category: 'Action Figures'),
  _LibraryBrowseScope(label: 'Comics', category: 'Comics'),
  _LibraryBrowseScope(label: 'Board Games', category: 'Board Games'),
  _LibraryBrowseScope(label: 'Statues', category: 'Statues'),
  _LibraryBrowseScope(label: 'Vinyl Figures', category: 'Vinyl Figures'),
  _LibraryBrowseScope(label: 'Other', category: 'Other'),
];

List<_LibraryBrowseScope> _mergedLibraryBrowseScopes(
  List<_CategoryShelfStat> categories,
) {
  final scopes = <_LibraryBrowseScope>[..._libraryBrowseScopes];
  final knownCategories = <String>{
    for (final scope in scopes)
      if (scope.category != null) scope.category!.trim().toLowerCase(),
  };

  for (final stat in categories) {
    final category = stat.category.trim();
    if (category.isEmpty) {
      continue;
    }

    final normalizedCategory = category.toLowerCase();
    if (knownCategories.contains(normalizedCategory)) {
      continue;
    }

    scopes.add(_LibraryBrowseScope(label: category, category: category));
    knownCategories.add(normalizedCategory);
  }

  return scopes;
}

class _LibraryScopeSheet extends StatelessWidget {
  const _LibraryScopeSheet({
    required this.selectedCategory,
    required this.categories,
    required this.totalCount,
  });

  final String? selectedCategory;
  final List<_CategoryShelfStat> categories;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final scopes = _mergedLibraryBrowseScopes(categories);

    return CollectorBottomSheet(
      title: 'Browse Scope',
      description:
          'Choose the shelf you want to browse. Filters and sorting stay available above the collection.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final scope in scopes) ...[
            _LibraryScopeOptionRow(
              scope: scope,
              count: scope.category == null
                  ? totalCount
                  : _countForCategory(categories, scope.category!),
              selected: scope.category == selectedCategory,
              onTap: () => Navigator.of(context).pop(scope),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _LibraryScopeOptionRow extends StatelessWidget {
  const _LibraryScopeOptionRow({
    required this.scope,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final _LibraryBrowseScope scope;
  final int count;
  final bool selected;
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
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.surfaceContainerHighest.withValues(alpha: 0.34),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.28)
                  : AppColors.outlineVariant.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.16)
                      : AppColors.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: scope.category == null
                    ? CategoryIcon(
                        category: 'Library',
                        size: 30,
                        fallbackColor: selected
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                      )
                    : CategoryIcon(
                        category: scope.category,
                        size: 30,
                        fallbackColor: selected
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scope.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: selected
                            ? AppColors.primary
                            : AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count item${count == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
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

class _LibraryRefineSheet extends StatefulWidget {
  const _LibraryRefineSheet({
    required this.sort,
    required this.favoritesOnly,
    required this.grailsOnly,
    required this.duplicatesOnly,
    required this.hasPhotoOnly,
  });

  final _LibrarySortOption sort;
  final bool favoritesOnly;
  final bool grailsOnly;
  final bool duplicatesOnly;
  final bool hasPhotoOnly;

  @override
  State<_LibraryRefineSheet> createState() => _LibraryRefineSheetState();
}

class _LibraryRefineSheetState extends State<_LibraryRefineSheet> {
  late _LibrarySortOption _sort;
  late bool _favoritesOnly;
  late bool _grailsOnly;
  late bool _duplicatesOnly;
  late bool _hasPhotoOnly;

  @override
  void initState() {
    super.initState();
    _sort = widget.sort;
    _favoritesOnly = widget.favoritesOnly;
    _grailsOnly = widget.grailsOnly;
    _duplicatesOnly = widget.duplicatesOnly;
    _hasPhotoOnly = widget.hasPhotoOnly;
  }

  void _reset() {
    setState(() {
      _sort = _LibrarySortOption.newest;
      _favoritesOnly = false;
      _grailsOnly = false;
      _duplicatesOnly = false;
      _hasPhotoOnly = false;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      _LibraryRefineSelection(
        sort: _sort,
        favoritesOnly: _favoritesOnly,
        grailsOnly: _grailsOnly,
        duplicatesOnly: _duplicatesOnly,
        hasPhotoOnly: _hasPhotoOnly,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CollectorBottomSheet(
      title: 'Refine Library',
      description:
          'Choose the order and focus the shelf without crowding the main header.',
      footer: Row(
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sort', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final option in _LibrarySortOption.values) ...[
            _LibrarySortOptionRow(
              option: option,
              selected: option == _sort,
              onTap: () {
                setState(() {
                  _sort = option;
                });
              },
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text('Filters', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
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
        ],
      ),
    );
  }
}

class _LibrarySortOptionRow extends StatelessWidget {
  const _LibrarySortOptionRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _LibrarySortOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.surfaceContainerHighest.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.24)
                  : AppColors.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: selected ? AppColors.primary : AppColors.onSurface,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 20,
                color: selected
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
              ),
            ],
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
                AppSpacing.sm,
              ),
              child: SizedBox(
                height: 64,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: const [
                    Positioned(
                      right: AppSpacing.md,
                      top: -8,
                      child: CollectorSkeletonBlock(
                        width: 86,
                        height: 86,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 16,
                      child: CollectorSkeletonBlock(width: 214, height: 36),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                children: [
                  CollectorSearchFieldSkeleton(),
                  SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(child: CollectorSkeletonBlock(height: 70)),
                      SizedBox(width: AppSpacing.sm),
                      CollectorSkeletonBlock(width: 88, height: 70),
                    ],
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
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                return const CollectorGridCardSkeleton();
              }, childCount: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.72,
              ),
            ),
          ),
        ],
      ),
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
                child: const CategoryIcon(
                  category: 'Library',
                  size: 40,
                  fallbackColor: AppColors.primary,
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

class _CategoryShelfStat {
  const _CategoryShelfStat({required this.category, required this.count});

  final String category;
  final int count;
}

int _countForCategory(List<_CategoryShelfStat> categories, String category) {
  for (final stat in categories) {
    if (stat.category.trim().toLowerCase() == category.trim().toLowerCase()) {
      return stat.count;
    }
  }

  return 0;
}
