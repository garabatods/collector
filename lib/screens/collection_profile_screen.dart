import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/data/archive_repository.dart';
import '../core/data/archive_types.dart';
import '../features/collection/data/models/collectible_model.dart';
import '../features/profile/data/models/profile_model.dart';
import '../features/profile/data/repositories/profile_avatar_repository.dart';
import '../features/profile/data/repositories/profile_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/archive_bootstrap_gate.dart';
import '../widgets/archive_photo_view.dart';
import '../widgets/collector_button.dart';
import '../widgets/collector_chip.dart';
import '../widgets/collector_loading_overlay.dart';
import '../widgets/collector_panel.dart';
import '../widgets/collector_text_field.dart';
import '../widgets/resolved_avatar_image.dart';
import 'collectible_detail_screen.dart';
import 'collection_search_screen.dart';

class CollectionProfileScreen extends StatefulWidget {
  const CollectionProfileScreen({
    super.key,
    required this.refreshSeed,
    required this.onProfileChanged,
    required this.onOpenHome,
    required this.onOpenLibrary,
    required this.onOpenWishlist,
    required this.onAddItem,
    required this.onSignOut,
  });

  final int refreshSeed;
  final VoidCallback onProfileChanged;
  final VoidCallback onOpenHome;
  final VoidCallback onOpenLibrary;
  final VoidCallback onOpenWishlist;
  final VoidCallback onAddItem;
  final Future<void> Function() onSignOut;

  @override
  State<CollectionProfileScreen> createState() => _CollectionProfileScreenState();
}

class _CollectionProfileScreenState extends State<CollectionProfileScreen> {
  final _archiveRepository = ArchiveRepository.instance;
  final _profileRepository = ProfileRepository();
  final _profileAvatarRepository = ProfileAvatarRepository();
  final _imagePicker = ImagePicker();

  var _isSigningOut = false;
  var _isUploadingAvatar = false;

  @override
  void didUpdateWidget(covariant CollectionProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSeed != widget.refreshSeed) {
      _archiveRepository.syncIfNeeded(force: true);
    }
  }

  _ProfileScreenData _toProfileScreenData(ArchiveProfileSummary summary) {
    return _ProfileScreenData(
      profile: summary.profile,
      avatarImageUrl: summary.profile?.avatarUrl?.trim(),
      email: summary.email,
      totalItems: summary.totalItems,
      categoryCount: summary.categoryCount,
      favoriteCount: summary.favoriteCount,
      wishlistCount: summary.wishlistCount,
      latestItem: summary.latestItem,
      featuredItem: summary.featuredItem,
      featuredPhotoRef: summary.featuredPhotoRef,
      favoriteCategory: summary.favoriteCategory,
    );
  }

  Future<void> _reload() async {
    await _archiveRepository.syncIfNeeded(force: true);
  }

  Future<void> _openFeaturedItem(_ProfileScreenData data) async {
    final featuredItem = data.featuredItem;
    if (featuredItem == null) return;

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CollectibleDetailScreen(
          collectible: featuredItem,
          photoRef: data.featuredPhotoRef,
        ),
      ),
    );

    if (changed == true) {
      widget.onProfileChanged();
      await _reload();
    }
  }

  Future<void> _openFavorites() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const CollectionSearchScreen(
          screenTitle: 'Favorites',
          emptyPrompt: 'Browse the pieces you have starred across your collection.',
          initialFavoritesOnly: true,
          autofocus: false,
        ),
      ),
    );

    if (changed == true) {
      await _reload();
    }
  }

  Future<void> _openRecentlyAdded() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const CollectionSearchScreen(
          screenTitle: 'Recently Added',
          emptyPrompt: 'Your newest additions collect here first.',
          autofocus: false,
        ),
      ),
    );

    if (changed == true) {
      await _reload();
    }
  }

  Future<void> _openAvatarPhotoSheet(ProfileModel? profile) async {
    if (_isUploadingAvatar) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AvatarPhotoSheet(
          onCamera: () {
            Navigator.of(context).pop();
            _pickAndSaveAvatar(ImageSource.camera, profile);
          },
          onGallery: () {
            Navigator.of(context).pop();
            _pickAndSaveAvatar(ImageSource.gallery, profile);
          },
        );
      },
    );
  }

  Future<void> _pickAndSaveAvatar(ImageSource source, ProfileModel? profile) async {
    if (_isUploadingAvatar) {
      return;
    }

    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1600,
    );

    if (!mounted || image == null) {
      return;
    }

    setState(() {
      _isUploadingAvatar = true;
    });

    try {
      final avatarStoragePath = await _profileAvatarRepository.uploadAvatar(
        localImagePath: image.path,
        originalFileName: image.name,
        previousStoragePath: profile?.avatarUrl,
      );

      await _profileRepository.save(
        ProfileModel(
          id: profile?.id,
          username: profile?.username,
          displayName: profile?.displayName,
          avatarUrl: avatarStoragePath,
          bio: profile?.bio,
          createdAt: profile?.createdAt,
          updatedAt: profile?.updatedAt,
        ),
      );

      if (!mounted) {
        return;
      }

      widget.onProfileChanged();
      await _reload();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated.'),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update the profile photo right now.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _openEditProfileSheet(ProfileModel? profile) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditProfileSheet(
        profile: profile,
        onSave: _profileRepository.save,
      ),
    );

    if (changed == true) {
      await _reload();
    }
  }

  Future<void> _confirmSignOut() async {
    if (_isSigningOut) {
      return;
    }

    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: const Text('Sign Out'),
        content: const Text(
          'You will return to the login screen and can sign back in anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldSignOut != true) {
      return;
    }

    setState(() {
      _isSigningOut = true;
    });

    try {
      await widget.onSignOut();
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ArchiveBootstrapGate(
      child: StreamBuilder<ArchiveProfileSummary>(
        stream: _archiveRepository.watchProfileSummary(),
        builder: (context, snapshot) {
          final data = snapshot.data == null
              ? null
              : _toProfileScreenData(snapshot.data!);

          if (snapshot.hasError && data == null) {
            return _ProfileErrorState(onRetry: _reload);
          }

          if (data == null) {
            return const CollectorLoadingOverlay();
          }

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
                        140,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ProfileHeader(
                            data: data,
                            onEditProfile: () =>
                                _openEditProfileSheet(data.profile),
                            onAvatarTap: () =>
                                _openAvatarPhotoSheet(data.profile),
                            isUploadingAvatar: _isUploadingAvatar,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _CollectorSummary(data: data),
                          const SizedBox(height: AppSpacing.lg),
                          const _ProfileSectionTitle(
                            title: 'Collector Highlight',
                            subtitle:
                                'A quick read on what defines your shelf right now.',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _CollectorHighlightPanel(
                            data: data,
                            onOpenFeaturedItem: () => _openFeaturedItem(data),
                            onAddItem: widget.onAddItem,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const _ProfileSectionTitle(
                            title: 'Quick Actions',
                            subtitle:
                                'Jump to the parts of the app collectors reach for most.',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _QuickActionsGrid(
                            data: data,
                            onOpenFavorites: _openFavorites,
                            onOpenLibrary: widget.onOpenLibrary,
                            onOpenWishlist: widget.onOpenWishlist,
                            onOpenRecentlyAdded: _openRecentlyAdded,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const _ProfileSectionTitle(
                            title: 'Account',
                            subtitle:
                                'Keep the essentials nearby without crowding the top of the screen.',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _AccountSection(
                            data: data,
                            isSigningOut: _isSigningOut,
                            onEditProfile: () =>
                                _openEditProfileSheet(data.profile),
                            onSignOut: _confirmSignOut,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.data,
    required this.onEditProfile,
    required this.onAvatarTap,
    required this.isUploadingAvatar,
  });

  final _ProfileScreenData data;
  final VoidCallback onEditProfile;
  final VoidCallback onAvatarTap;
  final bool isUploadingAvatar;

  @override
  Widget build(BuildContext context) {
    final displayName = data.displayName;
    final username = data.username;
    final identityLine = username != null && username.isNotEmpty
        ? '@$username'
        : data.email ?? 'Collector archive';
    final bio = data.bio;

    return CollectorPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.94),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileAvatar(
                avatarUrl: data.avatarImageUrl,
                initials: _profileInitials(displayName, data.email),
                onTap: onAvatarTap,
                isUploading: isUploadingAvatar,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      identityLine,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                  ],
                ),
              ),
              CollectorButton(
                label: 'Edit',
                onPressed: onEditProfile,
                variant: CollectorButtonVariant.secondary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            bio?.trim().isNotEmpty == true
                ? bio!.trim()
                : 'Add a display name, photo, and short bio to make this shelf feel unmistakably yours.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: bio?.trim().isNotEmpty == true
                      ? AppColors.onSurfaceVariant
                      : AppColors.onSurface,
                ),
          ),
          if (data.profile?.createdAt != null) ...[
            const SizedBox(height: AppSpacing.md),
            CollectorChip(label: 'Member since ${_formatMemberSince(data.profile!.createdAt!)}'),
          ],
        ],
      ),
    );
  }
}

class _CollectorSummary extends StatelessWidget {
  const _CollectorSummary({
    required this.data,
  });

  final _ProfileScreenData data;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _SummaryStat(label: 'Items', value: '${data.totalItems}'),
      _SummaryStat(label: 'Categories', value: '${data.categoryCount}'),
      _SummaryStat(label: 'Favorites', value: '${data.favoriteCount}'),
      _SummaryStat(label: 'Wishlist', value: '${data.wishlistCount}'),
    ];

    return CollectorPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.9),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
          return Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final stat in stats)
                SizedBox(
                  width: cellWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stat.value,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            stat.label,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
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

class _CollectorHighlightPanel extends StatelessWidget {
  const _CollectorHighlightPanel({
    required this.data,
    required this.onOpenFeaturedItem,
    required this.onAddItem,
  });

  final _ProfileScreenData data;
  final VoidCallback onOpenFeaturedItem;
  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    if (data.totalItems == 0) {
      return CollectorPanel(
        padding: const EdgeInsets.all(AppSpacing.lg),
        backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.94),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start building your shelf',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Once you add your first collectible, this space can spotlight a favorite piece, the category you collect most, or the latest addition worth showing off.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            CollectorButton(
              label: 'Add First Item',
              onPressed: onAddItem,
            ),
          ],
        ),
      );
    }

    final featured = data.featuredItem;
    if (featured == null) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenFeaturedItem,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.16),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ArchivePhotoView(
                          photoRef: data.featuredPhotoRef,
                          fit: BoxFit.cover,
                          placeholder: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.22),
                                  AppColors.surfaceContainerHighest,
                                  AppColors.surfaceContainerLow,
                                ],
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.collections_bookmark_outlined,
                                size: 42,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          error: const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 36,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x0D0B0E14),
                                Color(0xE60B0E14),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: AppSpacing.md,
                          right: AppSpacing.md,
                          bottom: AppSpacing.md,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.favoriteCategory != null &&
                                        featured.category.trim().toLowerCase() ==
                                            data.favoriteCategory!.trim().toLowerCase()
                                    ? 'Spotlight from your top category'
                                    : featured.isFavorite
                                        ? 'Featured on your shelf'
                                        : 'Latest shelf addition',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: AppColors.primary,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                featured.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                [
                                  featured.category,
                                  if (featured.brand?.trim().isNotEmpty == true)
                                    featured.brand!.trim(),
                                ].join(' • '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if (data.favoriteCategory != null)
                      CollectorChip(label: 'Top category: ${data.favoriteCategory}'),
                    if (featured.isFavorite) const CollectorChip(label: 'Favorited piece'),
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

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({
    required this.data,
    required this.onOpenFavorites,
    required this.onOpenLibrary,
    required this.onOpenWishlist,
    required this.onOpenRecentlyAdded,
  });

  final _ProfileScreenData data;
  final VoidCallback onOpenFavorites;
  final VoidCallback onOpenLibrary;
  final VoidCallback onOpenWishlist;
  final VoidCallback onOpenRecentlyAdded;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickActionData(
        title: 'Favorites',
        helper: data.favoriteCount == 0
            ? 'Pick your first favorite to give this shortcut some gravity.'
            : 'Open the pieces you have already starred.',
        icon: Icons.favorite_rounded,
        tone: AppColors.tertiary,
        onTap: onOpenFavorites,
      ),
      _QuickActionData(
        title: 'Wishlist',
        helper: data.wishlistCount == 0
            ? 'Nothing is waiting there yet, but the wish list is ready.'
            : 'Jump back to the items you still want to hunt down.',
        icon: Icons.bookmark_border_rounded,
        tone: AppColors.secondary,
        onTap: onOpenWishlist,
      ),
      _QuickActionData(
        title: 'Categories',
        helper: data.categoryCount == 0
            ? 'Your shelves will sort themselves once the collection starts.'
            : 'Browse the library and move by category faster.',
        icon: Icons.grid_view_rounded,
        tone: AppColors.primary,
        onTap: onOpenLibrary,
      ),
      _QuickActionData(
        title: 'Recently Added',
        helper: data.latestItem == null
            ? 'New arrivals will start appearing here once you add something.'
            : 'Jump straight to the newest pieces in your collection.',
        icon: Icons.schedule_rounded,
        tone: AppColors.warning,
        onTap: onOpenRecentlyAdded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final action in actions)
              SizedBox(
                width: tileWidth,
                child: _QuickActionTile(data: action),
              ),
          ],
        );
      },
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({
    required this.data,
    required this.isSigningOut,
    required this.onEditProfile,
    required this.onSignOut,
  });

  final _ProfileScreenData data;
  final bool isSigningOut;
  final VoidCallback onEditProfile;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CollectorPanel(
          padding: const EdgeInsets.all(AppSpacing.md),
          backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.9),
          child: Column(
            children: [
              _AccountRow(
                icon: Icons.edit_outlined,
                title: 'Edit Profile',
                subtitle: 'Update your display name, username, and collector bio.',
                onTap: onEditProfile,
              ),
              const _AccountDivider(),
              _AccountRow(
                icon: Icons.alternate_email_rounded,
                title: 'Connected Account',
                subtitle: data.email ?? 'No account email available',
              ),
              const _AccountDivider(),
              const _AccountRow(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'Collector alerts are planned next.',
              ),
              const _AccountDivider(),
              const _AccountRow(
                icon: Icons.palette_outlined,
                title: 'Appearance',
                subtitle: 'The app is currently using the collector dark theme.',
              ),
              const _AccountDivider(),
              const _AccountRow(
                icon: Icons.help_outline_rounded,
                title: 'Help and Support',
                subtitle: 'Support links and collector help are coming soon.',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isSigningOut ? null : onSignOut,
            borderRadius: BorderRadius.circular(24),
            child: Ink(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.18),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: AppColors.error.withValues(alpha: 0.92),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Sign Out',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.error.withValues(alpha: 0.92),
                            ),
                      ),
                    ),
                    if (isSigningOut)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.error.withValues(alpha: 0.92),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileSectionTitle extends StatelessWidget {
  const _ProfileSectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.avatarUrl,
    required this.initials,
    required this.onTap,
    required this.isUploading,
  });

  final String? avatarUrl;
  final String initials;
  final VoidCallback onTap;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.primaryShadow,
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceContainerHigh,
                  ),
                  child: ClipOval(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ResolvedAvatarImage(
                          avatarSource: avatarUrl,
                          fit: BoxFit.cover,
                          fallback: _AvatarFallback(initials: initials),
                          error: _AvatarFallback(initials: initials),
                        ),
                        if (isUploading)
                          ColoredBox(
                            color: AppColors.background.withValues(alpha: 0.56),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: -4,
          bottom: -2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.28),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.photo_camera_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({
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
            AppColors.tertiary.withValues(alpha: 0.28),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.onSurface,
              ),
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.data,
  });

  final _QuickActionData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: data.tone.withValues(alpha: 0.16),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: data.tone.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    data.icon,
                    color: data.tone,
                    size: 20,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  data.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  data.helper,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarPhotoSheet extends StatelessWidget {
  const _AvatarPhotoSheet({
    required this.onCamera,
    required this.onGallery,
  });

  final VoidCallback onCamera;
  final VoidCallback onGallery;

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
                'Profile Photo',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Choose a fresh photo for your collector identity.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _AvatarPhotoOption(
                icon: Icons.photo_camera_outlined,
                title: 'Take photo',
                helperText: 'Capture a profile shot with the camera',
                onTap: onCamera,
              ),
              const SizedBox(height: AppSpacing.md),
              _AvatarPhotoOption(
                icon: Icons.photo_library_outlined,
                title: 'Photo library',
                helperText: 'Pick a photo that already lives on this device',
                onTap: onGallery,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarPhotoOption extends StatelessWidget {
  const _AvatarPhotoOption({
    required this.icon,
    required this.title,
    required this.helperText,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String helperText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.22),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        helperText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: onTap == null ? AppColors.onSurfaceVariant : AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountDivider extends StatelessWidget {
  const _AccountDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: AppColors.outlineVariant.withValues(alpha: 0.16),
      height: 1,
    );
  }
}

class _ProfileErrorState extends StatelessWidget {
  const _ProfileErrorState({
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
          backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.92),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person_off_outlined,
                size: 34,
                color: AppColors.secondary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Profile is unavailable right now.',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Try again and we will pull your latest profile and collection summary.',
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

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.profile,
    required this.onSave,
  });

  final ProfileModel? profile;
  final Future<ProfileModel> Function(ProfileModel profile) onSave;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.profile?.displayName ?? '');
    _usernameController = TextEditingController(text: widget.profile?.username ?? '');
    _bioController = TextEditingController(text: widget.profile?.bio ?? '');
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSave(
        ProfileModel(
          id: widget.profile?.id,
          displayName: _displayNameController.text.trim().isEmpty
              ? null
              : _displayNameController.text.trim(),
          username: _usernameController.text.trim().isEmpty
              ? null
              : _usernameController.text.trim(),
          bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
          avatarUrl: widget.profile?.avatarUrl,
          createdAt: widget.profile?.createdAt,
          updatedAt: widget.profile?.updatedAt,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your profile right now.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
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
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
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
                'Edit Profile',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Keep it simple for now: name, username, and a short line about what you collect.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              CollectorTextField(
                label: 'Display Name',
                hintText: 'How your shelf should introduce you',
                controller: _displayNameController,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              CollectorTextField(
                label: 'Username',
                hintText: 'collector_handle',
                controller: _usernameController,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'BIO',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _bioController,
                minLines: 3,
                maxLines: 5,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'Action figures, games, comics, or whatever makes your shelf feel alive.',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    borderSide: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: CollectorButton(
                  label: 'Save Profile',
                  onPressed: _save,
                  isLoading: _isSaving,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryStat {
  const _SummaryStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class _QuickActionData {
  const _QuickActionData({
    required this.title,
    required this.helper,
    required this.icon,
    required this.tone,
    required this.onTap,
  });

  final String title;
  final String helper;
  final IconData icon;
  final Color tone;
  final VoidCallback onTap;
}

class _ProfileScreenData {
  const _ProfileScreenData({
    required this.profile,
    required this.avatarImageUrl,
    required this.email,
    required this.totalItems,
    required this.categoryCount,
    required this.favoriteCount,
    required this.wishlistCount,
    required this.latestItem,
    required this.featuredItem,
    required this.featuredPhotoRef,
    required this.favoriteCategory,
  });

  final ProfileModel? profile;
  final String? avatarImageUrl;
  final String? email;
  final int totalItems;
  final int categoryCount;
  final int favoriteCount;
  final int wishlistCount;
  final CollectibleModel? latestItem;
  final CollectibleModel? featuredItem;
  final ArchivePhotoRef? featuredPhotoRef;
  final String? favoriteCategory;

  String get displayName {
    final profileName = profile?.displayName?.trim();
    if (profileName != null && profileName.isNotEmpty) return profileName;

    final usernameValue = profile?.username?.trim();
    if (usernameValue != null && usernameValue.isNotEmpty) return usernameValue;

    final emailPrefix = email?.split('@').first.trim();
    if (emailPrefix != null && emailPrefix.isNotEmpty) return emailPrefix;

    return 'Collector';
  }

  String? get username {
    final value = profile?.username?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  String? get bio {
    final value = profile?.bio?.trim();
    return value == null || value.isEmpty ? null : value;
  }
}

String _profileInitials(String displayName, String? email) {
  final source = displayName.trim().isNotEmpty
      ? displayName.trim()
      : (email?.split('@').first.trim() ?? 'Collector');
  final parts = source
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList(growable: false);

  if (parts.isEmpty) {
    return 'C';
  }

  return parts.map((part) => part.characters.first.toUpperCase()).join();
}

String _formatMemberSince(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.year}';
}
