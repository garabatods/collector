import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/collection/data/models/collectible_model.dart';
import '../features/collection/data/repositories/collectible_photos_repository.dart';
import '../features/collection/data/repositories/collectibles_repository.dart';
import '../features/profile/data/models/profile_model.dart';
import '../features/profile/data/repositories/profile_avatar_repository.dart';
import '../features/profile/data/repositories/profile_repository.dart';
import '../features/wishlist/data/repositories/wishlist_items_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../theme/app_spacing.dart';
import '../widgets/collector_button.dart';
import '../widgets/collector_loading_overlay.dart';
import '../widgets/collector_panel.dart';
import '../widgets/collector_section_header.dart';
import '../widgets/collector_text_field.dart';
import 'collection_search_screen.dart';
import 'category_collection_screen.dart';
import 'collectible_detail_screen.dart';

const _homeTopChromeColor = AppColors.dashboardGlow;
const _homeSearchFillColor = AppColors.searchFieldFill;
const _homeSearchForegroundColor = AppColors.searchFieldForeground;

class CollectionHomeScreen extends StatefulWidget {
  const CollectionHomeScreen({
    super.key,
    required this.isSupabaseConfigured,
    required this.refreshSeed,
    required this.onAddFirstItem,
    required this.onScanItem,
    required this.onOpenProfile,
  });

  final bool isSupabaseConfigured;
  final int refreshSeed;
  final VoidCallback onAddFirstItem;
  final VoidCallback onScanItem;
  final VoidCallback onOpenProfile;

  @override
  State<CollectionHomeScreen> createState() => _CollectionHomeScreenState();
}

class _CollectionHomeScreenState extends State<CollectionHomeScreen> {
  final _collectiblesRepository = CollectiblesRepository();
  final _photosRepository = CollectiblePhotosRepository();
  final _wishlistRepository = WishlistItemsRepository();
  final _profileRepository = ProfileRepository();
  final _profileAvatarRepository = ProfileAvatarRepository();

  late Future<_CollectionHomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant CollectionHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSeed != widget.refreshSeed) {
      _future = _load();
    }
  }

  Future<_CollectionHomeData> _load() async {
    final collectibles = await _collectiblesRepository.fetchAll();
    final wishlistItems = await _wishlistRepository.fetchAll();
    final profile = await _profileRepository.fetchCurrentProfile();
    final recentItems = collectibles.take(6).toList(growable: false);
    final recentIds =
        recentItems.map((item) => item.id).whereType<String>().toList(growable: false);
    final primaryPhotos = await _photosRepository.fetchPrimaryPhotoMap(recentIds);

    final recentPhotoUrls = <String, String>{};
    for (final entry in primaryPhotos.entries) {
      final signedUrl = await _photosRepository.createSignedPhotoUrl(entry.value);
      if (signedUrl != null) {
        recentPhotoUrls[entry.key] = signedUrl;
      }
    }

    final profileAvatarUrl = await _profileAvatarRepository.resolveAvatarUrl(
      profile?.avatarUrl,
    );

    return _CollectionHomeData(
      profile: profile,
      profileAvatarUrl: profileAvatarUrl,
      collectibles: collectibles,
      wishlistCount: wishlistItems.length,
      recentItems: recentItems,
      recentPhotoUrls: recentPhotoUrls,
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: _homeTopChromeColor,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: FutureBuilder<_CollectionHomeData>(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final isRefreshing = snapshot.connectionState != ConnectionState.done;

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
            return const CollectorLoadingOverlay(
              label: 'Refreshing home...',
            );
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
                onOpenProfile: widget.onOpenProfile,
              ),
              if (isRefreshing)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: CollectorLoadingOverlay(
                      label: 'Refreshing home...',
                      backdropOpacity: 0.12,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LoadedHomeState extends StatefulWidget {
  const _LoadedHomeState({
    required this.data,
    required this.collectibles,
    required this.onCollectionChanged,
    required this.onOpenProfile,
  });

  final _CollectionHomeData data;
  final List<CollectibleModel> collectibles;
  final Future<void> Function() onCollectionChanged;
  final VoidCallback onOpenProfile;

  @override
  State<_LoadedHomeState> createState() => _LoadedHomeStateState();
}

class _LoadedHomeStateState extends State<_LoadedHomeState> {
  static const _collapseThreshold = 24.0;

  late final ScrollController _scrollController;
  var _showSearchOnly = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final shouldCollapse = _scrollController.offset > _collapseThreshold;
    if (shouldCollapse == _showSearchOnly) return;
    setState(() {
      _showSearchOnly = shouldCollapse;
    });
  }

  Future<void> _openSearch() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const CollectionSearchScreen(),
      ),
    );

    if (!mounted || changed != true) {
      return;
    }

    await widget.onCollectionChanged();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final compactLayout = screenWidth < 380 || textScale > 1.1;
    final categoryHighlights = _buildCategoryHighlights(widget.collectibles);
    final recentItems = widget.data.recentItems;

    return Column(
      children: [
        _HomeTopChrome(
          searchOnly: _showSearchOnly,
          onSearchTap: _openSearch,
          profile: widget.data.profile,
          profileAvatarUrl: widget.data.profileAvatarUrl,
          onOpenProfile: widget.onOpenProfile,
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.md,
              140,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CollectorSectionHeader(
                  title: 'Categories',
                  trailing: Text(
                    'From Your Collection',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                ),
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
                      final cardHeight = compactLayout ? 128.0 : 136.0;
                      final twoColumnWidth =
                          (availableWidth - AppSpacing.md) / 2;

                      return Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.md,
                        children: [
                          for (var index = 0;
                              index < categoryHighlights.length;
                              index++)
                            SizedBox(
                              width: _categoryCardWidthForIndex(
                                index: index,
                                itemCount: categoryHighlights.length,
                                fullWidth: availableWidth,
                                halfWidth: twoColumnWidth,
                              ),
                              child: _CategoryShowcaseCard(
                                category: categoryHighlights[index],
                                compactLayout: compactLayout,
                                height: cardHeight,
                                onTap: () async {
                                  await Navigator.of(context).push<bool>(
                                    MaterialPageRoute<bool>(
                                      builder: (_) => CategoryCollectionScreen(
                                        category: categoryHighlights[index].title,
                                      ),
                                    ),
                                  );

                                  await widget.onCollectionChanged();
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                const SizedBox(height: AppSpacing.section),
                CollectorSectionHeader(
                  title: 'Recently Added',
                  trailing: Text(
                    'Latest Arrivals',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
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
                    height: compactLayout ? 216 : 244,
                    child: ListView.separated(
                      clipBehavior: Clip.none,
                      scrollDirection: Axis.horizontal,
                      itemCount: recentItems.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final item = recentItems[index];
                        final photoUrl =
                            item.id == null ? null : widget.data.recentPhotoUrls[item.id];
                        return _RecentCollectibleCard(
                          collectible: item,
                          photoUrl: photoUrl,
                          compactLayout: compactLayout,
                          onCollectionChanged: widget.onCollectionChanged,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
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

    return entries.take(6).toList().asMap().entries.map((entry) {
      return _CategoryHighlight(
        title: entry.value.key,
        count: entry.value.value,
        style: _resolveCategoryCardStyle(entry.key),
      );
    }).toList(growable: false);
  }

  _CategoryCardStyle _resolveCategoryCardStyle(int index) {
    const rotatingStyles = <_CategoryCardStyle>[
      _CategoryCardStyle.rose(),
      _CategoryCardStyle.violet(),
      _CategoryCardStyle.amber(),
      _CategoryCardStyle.azure(),
      _CategoryCardStyle.emerald(),
      _CategoryCardStyle.slate(),
    ];

    return rotatingStyles[index % rotatingStyles.length];
  }
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
        _HomeTopChrome(
          onSearchTap: _noopSearchTap,
          onOpenProfile: onOpenProfile,
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xl,
                  AppSpacing.md,
                  140,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - AppSpacing.xl - 140,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: CollectorPanel(
                        padding: EdgeInsets.symmetric(
                          horizontal: compactLayout ? AppSpacing.lg : AppSpacing.xl,
                          vertical: compactLayout ? AppSpacing.xl : AppSpacing.xxl,
                        ),
                        backgroundColor:
                            AppColors.surfaceContainer.withValues(alpha: 0.92),
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
                                    color: AppColors.primary.withValues(alpha: 0.24),
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
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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

void _noopSearchTap() {}

class _HomeTopChrome extends StatelessWidget {
  const _HomeTopChrome({
    this.searchOnly = false,
    required this.onSearchTap,
    this.profile,
    this.profileAvatarUrl,
    required this.onOpenProfile,
  });

  final bool searchOnly;
  final VoidCallback onSearchTap;
  final ProfileModel? profile;
  final String? profileAvatarUrl;
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
          child: _HomeHeaderBar(
            searchOnly: searchOnly,
            onSearchTap: onSearchTap,
            profile: profile,
            profileAvatarUrl: profileAvatarUrl,
            onOpenProfile: onOpenProfile,
          ),
        ),
      ),
    );
  }
}

class _HomeHeaderBar extends StatelessWidget {
  const _HomeHeaderBar({
    this.searchOnly = false,
    required this.onSearchTap,
    this.profile,
    this.profileAvatarUrl,
    required this.onOpenProfile,
  });

  final bool searchOnly;
  final VoidCallback onSearchTap;
  final ProfileModel? profile;
  final String? profileAvatarUrl;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    if (searchOnly) {
      return CollectorSearchField(
        hintText: 'Search your collection...',
        fillColor: _homeSearchFillColor,
        iconColor: _homeSearchForegroundColor,
        hintColor: _homeSearchForegroundColor,
        onTap: onSearchTap,
      );
    }

    final titleStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: 24,
          height: 1.05,
        );
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
        const SizedBox(height: AppSpacing.lg),
        CollectorSearchField(
          hintText: 'Search your collection...',
          fillColor: _homeSearchFillColor,
          iconColor: _homeSearchForegroundColor,
          hintColor: _homeSearchForegroundColor,
          onTap: onSearchTap,
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
            child: profileAvatarUrl?.trim().isNotEmpty == true
                ? Image.network(
                    profileAvatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _HomeAvatarFallback(initials: initials),
                  )
                : _HomeAvatarFallback(initials: initials),
          ),
        ),
      ),
    );
  }
}

class _HomeAvatarFallback extends StatelessWidget {
  const _HomeAvatarFallback({
    required this.initials,
  });

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
              ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
              : EdgeInsets.all(compactLayout ? AppSpacing.md : AppSpacing.lg);
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
                  border: Border.all(
                    color: category.style.borderColor,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: denseCard ? 24 : 28,
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
                    const SizedBox(height: AppSpacing.sm),
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
    return fullWidth;
  }

  return halfWidth;
}

class _RecentCollectibleCard extends StatelessWidget {
  const _RecentCollectibleCard({
    required this.collectible,
    required this.photoUrl,
    required this.compactLayout,
    required this.onCollectionChanged,
  });

  final CollectibleModel collectible;
  final String? photoUrl;
  final bool compactLayout;
  final Future<void> Function() onCollectionChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compactLayout ? 164 : 188,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () async {
            final changed = await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(
                builder: (_) => CollectibleDetailScreen(
                  collectible: collectible,
                  photoUrl: photoUrl,
                ),
              ),
            );

            if (changed == true) {
              await onCollectionChanged();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.18),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (photoUrl != null)
                    Image.network(
                      photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    )
                  else
                    Container(
                      color: AppColors.surfaceContainerHighest,
                      child: const Center(
                        child: Icon(
                          Icons.photo_outlined,
                          color: AppColors.onSurfaceVariant,
                          size: 40,
                        ),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.background.withValues(alpha: 0.82),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: compactLayout ? AppSpacing.xs : AppSpacing.sm,
                    right: compactLayout ? AppSpacing.xs : AppSpacing.sm,
                    bottom: compactLayout ? AppSpacing.xs : AppSpacing.sm,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          collectible.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: compactLayout
                              ? Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontSize: 15,
                                    height: 1.1,
                                  )
                              : Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontSize: 17,
                                    height: 1.1,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          collectible.category,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: compactLayout ? 11 : 12,
                                height: 1.2,
                                color: AppColors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineMessagePanel extends StatelessWidget {
  const _InlineMessagePanel({
    required this.title,
    required this.description,
  });

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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateArtwork extends StatelessWidget {
  const _EmptyStateArtwork({
    required this.compactLayout,
  });

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

class _CollectionHomeData {
  const _CollectionHomeData({
    required this.profile,
    required this.profileAvatarUrl,
    required this.collectibles,
    required this.wishlistCount,
    required this.recentItems,
    required this.recentPhotoUrls,
  });

  final ProfileModel? profile;
  final String? profileAvatarUrl;
  final List<CollectibleModel> collectibles;
  final int wishlistCount;
  final List<CollectibleModel> recentItems;
  final Map<String, String> recentPhotoUrls;
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

  const _CategoryCardStyle.slate()
      : backgroundColor = AppColors.categorySlateBackground,
        borderColor = AppColors.categorySlateBorder,
        titleColor = AppColors.categorySlateForeground,
        itemCountColor = AppColors.categorySlateForeground;

  final Color backgroundColor;
  final Color borderColor;
  final Color titleColor;
  final Color itemCountColor;
}
