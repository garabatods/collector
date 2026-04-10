import 'package:flutter/material.dart';

import '../core/data/archive_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../widgets/archive_sync_status_banner.dart';
import '../widgets/collector_bottom_bar.dart';
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

enum _DashboardTab {
  home,
  library,
  wishlist,
  profile,
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final _archiveRepository = ArchiveRepository.instance;
  var _selectedTab = _DashboardTab.home;
  var _refreshSeed = 0;
  var _librarySearchFocusRequest = 0;

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
    setState(() {
      _selectedTab = tab;
    });
  }

  void _refreshCollectionViews() {
    setState(() {
      _refreshSeed++;
    });
  }

  void _openLibrarySearch() {
    setState(() {
      _selectedTab = _DashboardTab.library;
      _librarySearchFocusRequest++;
    });
  }

  Future<void> _openAddEntrySheet() async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AddToCollectionSheet(
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
        builder: (_) => const ScannerFlowScreen(),
      ),
    );

    if (created == true) {
      _refreshCollectionViews();
      _selectTab(_DashboardTab.library);
    }
  }

  Future<void> _openAiPhotoIdFlow() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const AiPhotoIdentificationScreen(),
      ),
    );

    if (created == true) {
      _refreshCollectionViews();
      _selectTab(_DashboardTab.library);
    }
  }

  Future<void> _openManualAddFlow() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const ManualAddCollectibleScreen(),
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
        onOpenSearch: _openLibrarySearch,
        onOpenProfile: () => _selectTab(_DashboardTab.profile),
      ),
      SafeArea(
        bottom: false,
        child: CollectionLibraryScreen(
          refreshSeed: _refreshSeed,
          searchFocusRequest: _librarySearchFocusRequest,
        ),
      ),
      SafeArea(
        bottom: false,
        child: CollectionWishlistScreen(
          refreshSeed: _refreshSeed,
        ),
      ),
      SafeArea(
        bottom: false,
        child: CollectionProfileScreen(
          refreshSeed: _refreshSeed,
          onProfileChanged: _refreshCollectionViews,
          onOpenHome: () => _selectTab(_DashboardTab.home),
          onOpenLibrary: () => _selectTab(_DashboardTab.library),
          onOpenWishlist: () => _selectTab(_DashboardTab.wishlist),
          onAddItem: _openManualAddFlow,
          onSignOut: widget.onSignOut,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.3,
                  colors: [
                    AppColors.dashboardGlow,
                    AppColors.background,
                  ],
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
            child: SafeArea(
              bottom: false,
              child: ArchiveSyncStatusBanner(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CollectorBottomBar(
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

class _AddToCollectionSheet extends StatelessWidget {
  const _AddToCollectionSheet({
    required this.onScanBarcode,
    required this.onIdentifyWithAi,
    required this.onAddManually,
  });

  final VoidCallback onScanBarcode;
  final VoidCallback onIdentifyWithAi;
  final VoidCallback onAddManually;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(32),
        ),
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
                'Add to Collection',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Choose the add flow that fits the item in front of you.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _AddEntryOptionTile(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Scan barcode',
                helperText: 'best for boxed items with a visible barcode',
                tone: AppColors.primary,
                onTap: onScanBarcode,
              ),
              const SizedBox(height: AppSpacing.md),
              _AddEntryOptionTile(
                icon: Icons.auto_awesome_rounded,
                title: 'Identify with AI',
                helperText:
                    'best for comics, loose items, rare pieces, and barcode-less collectibles',
                tone: AppColors.tertiary,
                premium: true,
                onTap: onIdentifyWithAi,
              ),
              const SizedBox(height: AppSpacing.md),
              _AddEntryOptionTile(
                icon: Icons.add_photo_alternate_outlined,
                title: 'Add manually',
                helperText:
                    'best for loose, vintage, custom, rare, or barcode-less collectibles',
                tone: AppColors.secondary,
                onTap: onAddManually,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddEntryOptionTile extends StatelessWidget {
  const _AddEntryOptionTile({
    required this.icon,
    required this.title,
    required this.helperText,
    required this.tone,
    required this.onTap,
    this.premium = false,
  });

  final IconData icon;
  final String title;
  final String helperText;
  final Color tone;
  final VoidCallback onTap;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.large,
        child: Ink(
          decoration: BoxDecoration(
            gradient: premium
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.18),
                      AppColors.surfaceContainer,
                      AppColors.tertiary.withValues(alpha: 0.16),
                    ],
                  )
                : null,
            color: premium ? null : AppColors.surfaceContainer,
            borderRadius: AppRadii.large,
            border: Border.all(
              color: tone.withValues(alpha: premium ? 0.34 : 0.22),
            ),
            boxShadow: premium
                ? [
                    BoxShadow(
                      color: AppColors.primaryShadow.withValues(alpha: 0.42),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    icon,
                    color: tone,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: premium ? AppColors.white : null,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        helperText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: premium
                                  ? AppColors.white.withValues(alpha: 0.82)
                                  : AppColors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: tone,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
