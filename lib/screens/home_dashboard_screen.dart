import 'package:flutter/material.dart';

import '../core/collector_haptics.dart';
import '../core/data/archive_repository.dart';
import '../features/collection/data/repositories/collection_vocabulary_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../widgets/add_item_method_sheet.dart';
import '../widgets/category_icon.dart';
import '../widgets/collector_button.dart';
import '../widgets/archive_sync_status_banner.dart';
import '../widgets/collector_bottom_sheet.dart';
import '../widgets/collector_bottom_bar.dart';
import '../widgets/collector_text_field.dart';
import 'ai_photo_identification_screen.dart';
import 'collection_home_screen.dart';
import 'collection_library_screen.dart';
import 'collection_profile_screen.dart';
import 'collection_wishlist_screen.dart';
import 'manual_add_collectible_screen.dart';
import 'scanner_flow_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({
    super.key,
    required this.isSupabaseConfigured,
    required this.onSignOut,
  });

  final bool isSupabaseConfigured;
  final Future<void> Function() onSignOut;

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

enum _DashboardTab { home, library, wishlist, profile }

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  static const _fixedCategoryOptions = [
    'Action Figures',
    'Board Games',
    'Statues',
    'Vinyl Figures',
    'Trading Cards',
    'Comics',
    'Memorabilia',
    'Die-cast',
    'Other',
  ];
  static String? _lastAddCategory;

  final _archiveRepository = ArchiveRepository.instance;
  final _vocabularyRepository = CollectionVocabularyRepository();
  var _selectedTab = _DashboardTab.home;
  var _refreshSeed = 0;
  final _librarySearchFocusRequest = 0;
  var _librarySelectionDismissRequest = 0;
  var _librarySelectionMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    _archiveRepository.initializeForCurrentUser();
  }

  late final WidgetsBindingObserver _lifecycleObserver =
      _DashboardLifecycleObserver(
        onResumed: () => _archiveRepository.handleAppResumed(),
      );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  void _selectTab(_DashboardTab tab) {
    if (_selectedTab != tab) {
      CollectorHaptics.selection();
    }
    setState(() {
      _selectedTab = tab;
    });
  }

  void _refreshCollectionViews() {
    setState(() {
      _refreshSeed++;
    });
  }

  void _dismissLibrarySelectionMode() {
    setState(() {
      _librarySelectionDismissRequest++;
    });
  }

  void _handleRootBackNavigation() {
    if (_selectedTab == _DashboardTab.library && _librarySelectionMode) {
      _dismissLibrarySelectionMode();
      return;
    }

    if (_selectedTab != _DashboardTab.home) {
      _selectTab(_DashboardTab.home);
    }
  }

  Future<void> _openAddEntrySheet() async {
    final categoryOptions = await _loadAddCategoryOptions();
    if (!mounted) {
      return;
    }

    CollectorHaptics.light();
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AddToCollectionSheet(
          categoryOptions: categoryOptions,
          initialCategory: _lastAddCategory,
          onScanBarcode: (category) {
            Navigator.of(context).pop();
            _openScannerFlow(initialCategory: category);
          },
          onIdentifyWithAi: (category) {
            Navigator.of(context).pop();
            _openAiPhotoIdFlow(initialCategory: category);
          },
          onAddManually: (category) {
            Navigator.of(context).pop();
            _openManualAddFlow(initialCategory: category);
          },
        );
      },
    );
  }

  Future<List<String>> _loadAddCategoryOptions() async {
    try {
      final vocabulary = await _vocabularyRepository.fetch();
      return _mergeCategoryOptions(vocabulary.categories);
    } catch (_) {
      return _mergeCategoryOptions(const []);
    }
  }

  List<String> _mergeCategoryOptions(Iterable<String> savedCategories) {
    final categories = <String>[];
    final seen = <String>{};
    void add(String? value) {
      final category = value?.trim();
      if (category == null || category.isEmpty) {
        return;
      }
      if (seen.add(category.toLowerCase())) {
        categories.add(category);
      }
    }

    add(_lastAddCategory);
    for (final category in _fixedCategoryOptions) {
      add(category);
    }
    for (final category in savedCategories) {
      add(category);
    }
    return categories;
  }

  void _rememberAddCategory(String? category) {
    final trimmed = category?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      _lastAddCategory = trimmed;
    }
  }

  Future<void> _openScannerFlow({String? initialCategory}) async {
    _rememberAddCategory(initialCategory);
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ScannerFlowScreen(initialCategory: initialCategory),
      ),
    );

    if (created == true) {
      _refreshCollectionViews();
      _selectTab(_DashboardTab.library);
    }
  }

  Future<void> _openAiPhotoIdFlow({String? initialCategory}) async {
    _rememberAddCategory(initialCategory);
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            AiPhotoIdentificationScreen(initialCategory: initialCategory),
      ),
    );

    if (created == true) {
      _refreshCollectionViews();
      _selectTab(_DashboardTab.library);
    }
  }

  Future<void> _openManualAddFlow({String? initialCategory}) async {
    _rememberAddCategory(initialCategory);
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            ManualAddCollectibleScreen(initialCategory: initialCategory),
      ),
    );

    if (created == true) {
      _refreshCollectionViews();
      _selectTab(_DashboardTab.library);
    }
  }

  List<Widget> _buildTabs() {
    return [
      CollectionHomeScreen(
        isSupabaseConfigured: widget.isSupabaseConfigured,
        refreshSeed: _refreshSeed,
        onAddFirstItem: _openManualAddFlow,
        onScanItem: _openScannerFlow,
        onOpenLibrary: () => _selectTab(_DashboardTab.library),
        onOpenProfile: () => _selectTab(_DashboardTab.profile),
      ),
      SafeArea(
        bottom: false,
        child: CollectionLibraryScreen(
          refreshSeed: _refreshSeed,
          searchFocusRequest: _librarySearchFocusRequest,
          selectionDismissRequest: _librarySelectionDismissRequest,
          onSelectionModeChanged: (active) {
            if (_librarySelectionMode == active) {
              return;
            }
            setState(() {
              _librarySelectionMode = active;
            });
          },
        ),
      ),
      SafeArea(
        bottom: false,
        child: CollectionWishlistScreen(refreshSeed: _refreshSeed),
      ),
      SafeArea(
        bottom: false,
        child: CollectionProfileScreen(
          refreshSeed: _refreshSeed,
          onProfileChanged: _refreshCollectionViews,
          onAddItem: _openManualAddFlow,
          onSignOut: widget.onSignOut,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final canSystemPop =
        _selectedTab == _DashboardTab.home && !_librarySelectionMode;

    return PopScope<void>(
      canPop: canSystemPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        _handleRootBackNavigation();
      },
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.3,
                    colors: [AppColors.dashboardGlow, AppColors.background],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IndexedStack(
                index: _selectedTab.index,
                children: _buildTabs(),
              ),
            ),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(bottom: false, child: ArchiveSyncStatusBanner()),
            ),
          ],
        ),
        bottomNavigationBar:
            _selectedTab == _DashboardTab.library && _librarySelectionMode
            ? null
            : CollectorBottomBar(
                items: [
                  CollectorBottomBarItemData(
                    icon: Icons.home_outlined,
                    label: 'Home',
                    active: _selectedTab == _DashboardTab.home,
                    onTap: () => _selectTab(_DashboardTab.home),
                  ),
                  CollectorBottomBarItemData(
                    icon: Icons.grid_view_rounded,
                    label: 'Library',
                    active: _selectedTab == _DashboardTab.library,
                    onTap: () => _selectTab(_DashboardTab.library),
                  ),
                  CollectorBottomBarItemData(
                    icon: Icons.add_rounded,
                    label: 'Add',
                    isCenterAction: true,
                    onTap: _openAddEntrySheet,
                  ),
                  CollectorBottomBarItemData(
                    icon: Icons.favorite_outline_rounded,
                    label: 'Wishlist',
                    active: _selectedTab == _DashboardTab.wishlist,
                    onTap: () => _selectTab(_DashboardTab.wishlist),
                  ),
                  CollectorBottomBarItemData(
                    icon: Icons.person_outline_rounded,
                    label: 'Profile',
                    active: _selectedTab == _DashboardTab.profile,
                    onTap: () => _selectTab(_DashboardTab.profile),
                  ),
                ],
              ),
      ),
    );
  }
}

class _DashboardLifecycleObserver with WidgetsBindingObserver {
  _DashboardLifecycleObserver({required this.onResumed});

  final Future<void> Function() onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed();
    }
  }
}

class _AddToCollectionSheet extends StatefulWidget {
  const _AddToCollectionSheet({
    required this.categoryOptions,
    required this.initialCategory,
    required this.onScanBarcode,
    required this.onIdentifyWithAi,
    required this.onAddManually,
  });

  final List<String> categoryOptions;
  final String? initialCategory;
  final ValueChanged<String> onScanBarcode;
  final ValueChanged<String> onIdentifyWithAi;
  final ValueChanged<String> onAddManually;

  @override
  State<_AddToCollectionSheet> createState() => _AddToCollectionSheetState();
}

class _AddToCollectionSheetState extends State<_AddToCollectionSheet> {
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    final initialCategory = widget.initialCategory?.trim();
    _selectedCategory = initialCategory == null || initialCategory.isEmpty
        ? null
        : initialCategory;
  }

  Future<String?> _chooseCategory() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddCategoryChoiceSheet(
        options: widget.categoryOptions,
        selectedCategory: _selectedCategory,
      ),
    );

    if (!mounted || selected == null) {
      return null;
    }

    final category = selected.trim();
    if (category.isEmpty) {
      return null;
    }

    setState(() {
      _selectedCategory = category;
    });
    return category;
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = _selectedCategory?.trim();
    final hasCategory = selectedCategory != null && selectedCategory.isNotEmpty;

    return AddItemMethodSheet(
      title: hasCategory ? 'Add to $selectedCategory' : 'Add to Collection',
      description: hasCategory
          ? 'Items from this flow will start in this category.'
          : 'Pick how to add the item. Category comes first.',
      category: _selectedCategory,
      onChooseCategory: _chooseCategory,
      requireCategory: true,
      onScanBarcode: () => widget.onScanBarcode(selectedCategory!),
      onIdentifyWithAi: () => widget.onIdentifyWithAi(selectedCategory!),
      onAddManually: () => widget.onAddManually(selectedCategory!),
    );
  }
}

class _AddCategoryChoiceSheet extends StatefulWidget {
  const _AddCategoryChoiceSheet({
    required this.options,
    required this.selectedCategory,
  });

  final List<String> options;
  final String? selectedCategory;

  @override
  State<_AddCategoryChoiceSheet> createState() =>
      _AddCategoryChoiceSheetState();
}

class _AddCategoryChoiceSheetState extends State<_AddCategoryChoiceSheet> {
  final _searchController = TextEditingController();
  final _createController = TextEditingController();
  var _query = '';
  var _showCreate = false;
  String? _createErrorText;

  @override
  void dispose() {
    _searchController.dispose();
    _createController.dispose();
    super.dispose();
  }

  void _submitCreatedCategory() {
    final category = _createController.text.trim();
    if (category.isEmpty) {
      setState(() {
        _createErrorText = 'Category name is required.';
      });
      return;
    }

    final existingCategory = widget.options.cast<String?>().firstWhere(
      (option) => (option ?? '').trim().toLowerCase() == category.toLowerCase(),
      orElse: () => null,
    );
    Navigator.of(context).pop(existingCategory ?? category);
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.options
        .where(
          (option) =>
              _query.trim().isEmpty ||
              option.toLowerCase().contains(_query.trim().toLowerCase()),
        )
        .toList(growable: false);

    return CollectorBottomSheet(
      title: 'Choose category',
      description: 'This keeps the add flow anchored before scanning.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CollectorSearchField(
            hintText: 'Search categories',
            controller: _searchController,
            readOnly: false,
            onChanged: (value) {
              setState(() {
                _query = value;
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _SheetActionRow(
            label: 'Create category',
            icon: Icons.add_rounded,
            onTap: () {
              setState(() {
                _showCreate = true;
                _createErrorText = null;
                if (_createController.text.trim().isEmpty &&
                    _query.trim().isNotEmpty) {
                  _createController.text = _query.trim();
                }
              });
            },
          ),
          if (_showCreate) ...[
            const SizedBox(height: AppSpacing.sm),
            CollectorTextField(
              label: 'Category name',
              hintText: 'Car toy',
              controller: _createController,
              errorText: _createErrorText,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: CollectorButton(
                label: 'Use category',
                onPressed: _submitCreatedCategory,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: options.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      'No saved categories match yet.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final isSelected =
                          widget.selectedCategory?.trim().toLowerCase() ==
                          option.trim().toLowerCase();
                      return _SheetCategoryRow(
                        label: option,
                        selected: isSelected,
                        onTap: () => Navigator.of(context).pop(option),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SheetActionRow extends StatelessWidget {
  const _SheetActionRow({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SheetCategoryRow(
      label: label,
      selected: false,
      leadingIcon: icon,
      onTap: onTap,
    );
  }
}

class _SheetCategoryRow extends StatelessWidget {
  const _SheetCategoryRow({
    required this.label,
    required this.selected,
    required this.onTap,
    this.leadingIcon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.medium,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.surfaceContainer,
            borderRadius: AppRadii.medium,
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AppColors.outlineVariant.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, color: AppColors.primary, size: 18),
                const SizedBox(width: AppSpacing.sm),
              ] else ...[
                CategoryIcon(
                  category: label,
                  size: 28,
                  fallbackColor: selected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
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
