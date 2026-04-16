import 'package:flutter/material.dart';

import '../core/data/archive_repository.dart';
import '../core/data/archive_types.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/add_item_method_sheet.dart';
import '../widgets/archive_bootstrap_gate.dart';
import '../widgets/category_icon.dart';
import '../widgets/collectible_grid_card.dart';
import '../widgets/collector_bottom_sheet.dart';
import '../widgets/collector_button.dart';
import '../widgets/collector_panel.dart';
import '../widgets/collector_skeleton.dart';
import '../widgets/collector_sticky_back_button.dart';
import 'ai_photo_identification_screen.dart';
import 'manual_add_collectible_screen.dart';
import 'scanner_flow_screen.dart';

class CategoryCollectionScreen extends StatefulWidget {
  const CategoryCollectionScreen({super.key, required this.category});

  final String category;

  @override
  State<CategoryCollectionScreen> createState() =>
      _CategoryCollectionScreenState();
}

enum _CategorySortOption { newest, oldest, titleAscending, titleDescending }

enum _CategoryViewMode { grid, list }

class _CategoryCollectionScreenState extends State<CategoryCollectionScreen> {
  static const _pageSize = 24;

  final _archiveRepository = ArchiveRepository.instance;
  final _scrollController = ScrollController();

  var _didChangeCollection = false;
  var _favoritesOnly = false;
  var _grailsOnly = false;
  var _duplicatesOnly = false;
  var _sort = _CategorySortOption.newest;
  var _viewMode = _CategoryViewMode.grid;
  var _visibleItemCount = _pageSize;
  var _knownResultCount = 0;
  var _isExpandingVisibleItems = false;
  late Stream<ArchiveLibraryPage> _stream;

  @override
  void initState() {
    super.initState();
    _stream = _buildStream();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void didUpdateWidget(covariant CategoryCollectionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) {
      _resetVisibleItems();
      _stream = _buildStream();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  bool get _hasActiveRefinementState {
    return _favoritesOnly ||
        _grailsOnly ||
        _duplicatesOnly ||
        _sort != _CategorySortOption.newest;
  }

  Future<void> _reload() async {
    _didChangeCollection = true;
    await _archiveRepository.syncIfNeeded(force: true);
  }

  void _handleBack() {
    Navigator.of(context).pop(_didChangeCollection);
  }

  Stream<ArchiveLibraryPage> _buildStream() {
    return _archiveRepository.watchLibraryPage(
      filters: ArchiveLibraryFilters(
        category: widget.category,
        favoritesOnly: _favoritesOnly,
        grailsOnly: _grailsOnly,
        duplicatesOnly: _duplicatesOnly,
      ),
      sort: _sort.archiveSort,
      limit: _visibleItemCount,
    );
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

  void _clearRefinements() {
    setState(() {
      _favoritesOnly = false;
      _grailsOnly = false;
      _duplicatesOnly = false;
      _sort = _CategorySortOption.newest;
      _resetVisibleItems();
      _stream = _buildStream();
    });
  }

  Future<void> _openRefineSheet() async {
    final selection = await showModalBottomSheet<_CategoryRefineSelection>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CategoryRefineSheet(
          sort: _sort,
          favoritesOnly: _favoritesOnly,
          grailsOnly: _grailsOnly,
          duplicatesOnly: _duplicatesOnly,
        );
      },
    );

    if (!mounted || selection == null) {
      return;
    }

    setState(() {
      _sort = selection.sort;
      _favoritesOnly = selection.favoritesOnly;
      _grailsOnly = selection.grailsOnly;
      _duplicatesOnly = selection.duplicatesOnly;
      _resetVisibleItems();
      _stream = _buildStream();
    });
  }

  Future<void> _openAddItemSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CategoryAddItemSheet(
          category: widget.category,
          onScanBarcode: () {
            Navigator.of(context).pop();
            _openScannerFlow();
          },
          onIdentifyWithAi: () {
            Navigator.of(context).pop();
            _openAiPhotoIdFlow();
          },
          onAddManually: () {
            Navigator.of(context).pop();
            _openManualAddFlow();
          },
        );
      },
    );
  }

  Future<void> _openScannerFlow() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ScannerFlowScreen(initialCategory: widget.category),
      ),
    );
    if (created == true) {
      await _reload();
    }
  }

  Future<void> _openAiPhotoIdFlow() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            AiPhotoIdentificationScreen(initialCategory: widget.category),
      ),
    );
    if (created == true) {
      await _reload();
    }
  }

  Future<void> _openManualAddFlow() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            ManualAddCollectibleScreen(initialCategory: widget.category),
      ),
    );
    if (created == true) {
      await _reload();
    }
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
                  colors: [AppColors.featureGlow, AppColors.background],
                ),
              ),
            ),
          ),
          SafeArea(
            child: ArchiveBootstrapGate(
              child: StreamBuilder<ArchiveLibraryPage>(
                stream: _stream,
                builder: (context, snapshot) {
                  final data = snapshot.data;

                  if (snapshot.hasError && data == null) {
                    return _CategoryCollectionErrorState(
                      category: widget.category,
                      onRetry: _reload,
                    );
                  }

                  if (data == null) {
                    return const _CategoryCollectionLoadingState();
                  }

                  _knownResultCount = data.totalCount;
                  _isExpandingVisibleItems = false;

                  if (data.totalCount == 0 && !_hasActiveRefinementState) {
                    return Stack(
                      children: [
                        _CategoryCollectionEmptyState(
                          category: widget.category,
                        ),
                        _CategoryStickyAddButton(onTap: _openAddItemSheet),
                      ],
                    );
                  }

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
                                AppSpacing.lg,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 48),
                                  const SizedBox(height: AppSpacing.lg),
                                  _CategoryPageTitle(category: widget.category),
                                  const SizedBox(height: AppSpacing.lg),
                                  _CategoryBrowseControls(
                                    count: data.totalCount,
                                    totalCount: data.totalCount,
                                    viewMode: _viewMode,
                                    refineHighlighted:
                                        _hasActiveRefinementState,
                                    onViewModeChanged: (viewMode) {
                                      setState(() {
                                        _viewMode = viewMode;
                                      });
                                    },
                                    onRefineTap: _openRefineSheet,
                                  ),
                                  if (data.items.isEmpty) ...[
                                    const SizedBox(height: AppSpacing.lg),
                                    _EmptyFilterResultsPanel(
                                      onClearFilters: _clearRefinements,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (data.items.isNotEmpty)
                            if (_viewMode == _CategoryViewMode.grid)
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.md,
                                  0,
                                  AppSpacing.md,
                                  AppSpacing.lg,
                                ),
                                sliver: SliverGrid(
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final collectible = data.items[index];
                                    final id = collectible.id;
                                    final photoRef = id == null
                                        ? null
                                        : data.photoRefsByCollectibleId[id];

                                    return CollectibleGridCard(
                                      collectible: collectible,
                                      photoRef: photoRef,
                                      onCollectionChanged: _reload,
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
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.md,
                                  0,
                                  AppSpacing.md,
                                  AppSpacing.lg,
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
                                      onCollectionChanged: _reload,
                                    );
                                  },
                                ),
                              ),
                          if (data.items.isNotEmpty && data.hasMore)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  AppSpacing.md,
                                  AppSpacing.md,
                                  AppSpacing.md,
                                  AppSpacing.lg,
                                ),
                                child: _InlineCategoryLoader(
                                  label: 'Scroll to load more...',
                                ),
                              ),
                            ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 104),
                          ),
                        ],
                      ),
                      _CategoryStickyAddButton(onTap: _openAddItemSheet),
                    ],
                  );
                },
              ),
            ),
          ),
          CollectorStickyBackButton(onPressed: _handleBack),
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

  ArchiveLibrarySort get archiveSort => switch (this) {
    _CategorySortOption.newest => ArchiveLibrarySort.newest,
    _CategorySortOption.oldest => ArchiveLibrarySort.oldest,
    _CategorySortOption.titleAscending => ArchiveLibrarySort.titleAscending,
    _CategorySortOption.titleDescending => ArchiveLibrarySort.titleDescending,
  };
}

class _CategoryPageTitle extends StatelessWidget {
  const _CategoryPageTitle({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CategoryIcon(category: category, size: 46),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            category,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
        ),
      ],
    );
  }
}

class _CategoryAddItemSheet extends StatelessWidget {
  const _CategoryAddItemSheet({
    required this.category,
    required this.onScanBarcode,
    required this.onIdentifyWithAi,
    required this.onAddManually,
  });

  final String category;
  final VoidCallback onScanBarcode;
  final VoidCallback onIdentifyWithAi;
  final VoidCallback onAddManually;

  @override
  Widget build(BuildContext context) {
    return AddItemMethodSheet(
      title: 'Add to $category',
      description:
          'Items from this flow will start in this category. Choose how to identify the item.',
      category: category,
      onScanBarcode: onScanBarcode,
      onIdentifyWithAi: onIdentifyWithAi,
      onAddManually: onAddManually,
    );
  }
}

class _CategoryStickyAddButton extends StatelessWidget {
  const _CategoryStickyAddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: AppSpacing.md,
      right: AppSpacing.md,
      bottom: AppSpacing.md,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.background.withValues(alpha: 0.72),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: CollectorButton(
          label: 'Add item',
          icon: Icons.add_rounded,
          onPressed: onTap,
        ),
      ),
    );
  }
}

class _CategoryBrowseControls extends StatelessWidget {
  const _CategoryBrowseControls({
    required this.count,
    required this.totalCount,
    required this.viewMode,
    required this.refineHighlighted,
    required this.onViewModeChanged,
    required this.onRefineTap,
  });

  final int count;
  final int totalCount;
  final _CategoryViewMode viewMode;
  final bool refineHighlighted;
  final ValueChanged<_CategoryViewMode> onViewModeChanged;
  final VoidCallback onRefineTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CategoryScopeSummary(count: count, totalCount: totalCount),
        ),
        const SizedBox(width: AppSpacing.sm),
        _CategoryViewToggle(viewMode: viewMode, onChanged: onViewModeChanged),
        const SizedBox(width: AppSpacing.xs),
        _CategoryUtilityIconButton(
          icon: Icons.tune_rounded,
          highlighted: refineHighlighted,
          tooltip: 'Refine category',
          onTap: onRefineTap,
        ),
      ],
    );
  }
}

class _CategoryScopeSummary extends StatelessWidget {
  const _CategoryScopeSummary({required this.count, required this.totalCount});

  final int count;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final label = count == totalCount
        ? '$count item${count == 1 ? '' : 's'}'
        : '$count of $totalCount';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Showing',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: AppColors.onSurface),
          ),
        ],
      ),
    );
  }
}

class _CategoryViewToggle extends StatelessWidget {
  const _CategoryViewToggle({required this.viewMode, required this.onChanged});

  final _CategoryViewMode viewMode;
  final ValueChanged<_CategoryViewMode> onChanged;

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
          _CategoryViewToggleButton(
            icon: Icons.grid_view_rounded,
            selected: viewMode == _CategoryViewMode.grid,
            tooltip: 'Grid view',
            onTap: () => onChanged(_CategoryViewMode.grid),
          ),
          _CategoryViewToggleButton(
            icon: Icons.view_list_rounded,
            selected: viewMode == _CategoryViewMode.list,
            tooltip: 'List view',
            onTap: () => onChanged(_CategoryViewMode.list),
          ),
        ],
      ),
    );
  }
}

class _CategoryViewToggleButton extends StatelessWidget {
  const _CategoryViewToggleButton({
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

class _CategoryUtilityIconButton extends StatelessWidget {
  const _CategoryUtilityIconButton({
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

class _CategoryRefineSelection {
  const _CategoryRefineSelection({
    required this.sort,
    required this.favoritesOnly,
    required this.grailsOnly,
    required this.duplicatesOnly,
  });

  final _CategorySortOption sort;
  final bool favoritesOnly;
  final bool grailsOnly;
  final bool duplicatesOnly;
}

class _CategoryRefineSheet extends StatefulWidget {
  const _CategoryRefineSheet({
    required this.sort,
    required this.favoritesOnly,
    required this.grailsOnly,
    required this.duplicatesOnly,
  });

  final _CategorySortOption sort;
  final bool favoritesOnly;
  final bool grailsOnly;
  final bool duplicatesOnly;

  @override
  State<_CategoryRefineSheet> createState() => _CategoryRefineSheetState();
}

class _CategoryRefineSheetState extends State<_CategoryRefineSheet> {
  late _CategorySortOption _sort;
  late bool _favoritesOnly;
  late bool _grailsOnly;
  late bool _duplicatesOnly;

  @override
  void initState() {
    super.initState();
    _sort = widget.sort;
    _favoritesOnly = widget.favoritesOnly;
    _grailsOnly = widget.grailsOnly;
    _duplicatesOnly = widget.duplicatesOnly;
  }

  void _reset() {
    setState(() {
      _sort = _CategorySortOption.newest;
      _favoritesOnly = false;
      _grailsOnly = false;
      _duplicatesOnly = false;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      _CategoryRefineSelection(
        sort: _sort,
        favoritesOnly: _favoritesOnly,
        grailsOnly: _grailsOnly,
        duplicatesOnly: _duplicatesOnly,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CollectorBottomSheet(
      title: 'Refine Category',
      description:
          'Choose the order and focus this category without crowding the header.',
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
          for (final option in _CategorySortOption.values) ...[
            _CategorySortOptionRow(
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
          _CategoryFilterOption(
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
          _CategoryFilterOption(
            label: 'Grails',
            description: 'Focus on your most important pieces.',
            active: _grailsOnly,
            icon: Icons.workspace_premium_outlined,
            onTap: () {
              setState(() {
                _grailsOnly = !_grailsOnly;
              });
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _CategoryFilterOption(
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
        ],
      ),
    );
  }
}

class _CategorySortOptionRow extends StatelessWidget {
  const _CategorySortOptionRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _CategorySortOption option;
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

class _CategoryFilterOption extends StatelessWidget {
  const _CategoryFilterOption({
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

class _EmptyFilterResultsPanel extends StatelessWidget {
  const _EmptyFilterResultsPanel({required this.onClearFilters});

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
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
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

class _InlineCategoryLoader extends StatelessWidget {
  const _InlineCategoryLoader({required this.label});

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

class _CategoryCollectionLoadingState extends StatelessWidget {
  const _CategoryCollectionLoadingState();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          physics: const NeverScrollableScrollPhysics(),
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
                  children: const [
                    SizedBox(height: 48),
                    SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        CollectorSkeletonBlock(
                          width: 44,
                          height: 44,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: CollectorSkeletonBlock(height: 34),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.lg),
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
                AppSpacing.lg,
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
        CollectorStickyBackButton(onPressed: () => Navigator.of(context).pop()),
        _CategoryStickyAddButton(onTap: () {}),
      ],
    );
  }
}

class _CategoryCollectionEmptyState extends StatelessWidget {
  const _CategoryCollectionEmptyState({required this.category});

  final String category;

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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CategoryIcon(category: category, size: 38),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      'No $category yet.',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
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
  });

  final String category;
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
                  CollectorButton(label: 'Retry', onPressed: () => onRetry()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
