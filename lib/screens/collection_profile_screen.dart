import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/collector_haptics.dart';
import '../core/data/archive_repository.dart';
import '../core/data/archive_types.dart';
import '../core/data/feature_announcement_store.dart';
import '../features/collection/data/models/collectible_model.dart';
import '../features/gamification/data/models/collector_badge.dart';
import '../features/gamification/data/models/collector_level.dart';
import '../features/gamification/data/services/collector_badge_award_store.dart';
import '../features/gamification/data/services/collector_badge_engine.dart';
import '../features/profile/data/models/profile_model.dart';
import '../features/profile/data/repositories/profile_avatar_repository.dart';
import '../features/profile/data/repositories/profile_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/archive_bootstrap_gate.dart';
import '../widgets/collector_badge_unlock_sheet.dart';
import '../widgets/collector_bottom_sheet.dart';
import '../widgets/collector_button.dart';
import '../widgets/collector_loading_overlay.dart';
import '../widgets/collector_panel.dart';
import '../widgets/collector_snack_bar.dart';
import '../widgets/collector_status_intro_sheet.dart';
import '../widgets/collector_text_field.dart';
import '../widgets/resolved_avatar_image.dart';
import 'all_categories_screen.dart';

class CollectionProfileScreen extends StatefulWidget {
  const CollectionProfileScreen({
    super.key,
    required this.isActive,
    required this.refreshSeed,
    required this.onProfileChanged,
    required this.onAddItem,
    required this.onOpenRecent,
    required this.onOpenFavorites,
    required this.onOpenInsights,
    required this.onSignOut,
  });

  final bool isActive;
  final int refreshSeed;
  final VoidCallback onProfileChanged;
  final VoidCallback onAddItem;
  final VoidCallback onOpenRecent;
  final VoidCallback onOpenFavorites;
  final VoidCallback onOpenInsights;
  final Future<void> Function() onSignOut;

  @override
  State<CollectionProfileScreen> createState() =>
      _CollectionProfileScreenState();
}

class _CollectionProfileScreenState extends State<CollectionProfileScreen> {
  final _archiveRepository = ArchiveRepository.instance;
  final _profileRepository = ProfileRepository();
  final _profileAvatarRepository = ProfileAvatarRepository();
  final _imagePicker = ImagePicker();
  final _badgeAwardStore = CollectorBadgeAwardStore.instance;

  var _isSigningOut = false;
  var _isUploadingAvatar = false;
  var _badgeFilter = _BadgeGalleryFilter.unlocked;
  List<CollectorBadgeAward> _badgeAwards = const [];
  String? _lastBadgeSignature;
  var _hasAttemptedCollectorStatusIntro = false;

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
      photoCount: summary.photoCount,
      latestItem: summary.latestItem,
      featuredItem: summary.featuredItem,
      featuredPhotoRef: summary.featuredPhotoRef,
      favoriteCategory: summary.favoriteCategory,
    );
  }

  Future<void> _reload() async {
    await _archiveRepository.syncIfNeeded(force: true);
  }

  Future<void> _openAllCategories() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const AllCategoriesScreen()),
    );

    if (changed == true) {
      widget.onProfileChanged();
      await _reload();
    }
  }

  Future<void> _openBadgeDetail(
    _BadgeGalleryEntry entry,
    CollectorProgressSnapshot progress,
  ) async {
    CollectorHaptics.light();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BadgeDetailSheet(entry: entry, progress: progress),
    );
  }

  Future<void> _openCollectorLevelSheet(int unlockedBadgeCount) async {
    CollectorHaptics.light();
    final level = resolveCollectorLevel(
      unlockedBadgesCount: unlockedBadgeCount,
      totalBadgesCount: collectorBadgeDefinitions.length,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CollectorLevelSheet(level: level),
    );
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

  Future<void> _pickAndSaveAvatar(
    ImageSource source,
    ProfileModel? profile,
  ) async {
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

      CollectorSnackBar.show(
        context,
        message: 'Profile photo updated.',
        tone: CollectorSnackBarTone.success,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      CollectorSnackBar.show(
        context,
        message: 'Could not update the profile photo right now.',
        tone: CollectorSnackBarTone.error,
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
      builder: (context) =>
          _EditProfileSheet(profile: profile, onSave: _profileRepository.save),
    );

    if (changed == true) {
      await _reload();
      if (!mounted) {
        return;
      }
      CollectorSnackBar.show(
        context,
        message: 'Profile updated.',
        tone: CollectorSnackBarTone.success,
      );
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

          if (widget.isActive) {
            _scheduleBadgeSync(snapshot.data!);
          }
          final badgeProgress = CollectorProgressSnapshot.fromProfileSummary(
            snapshot.data!,
          );

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
                            unlockedBadgeCount: _badgeAwards.length,
                            onLevelTap: () =>
                                _openCollectorLevelSheet(_badgeAwards.length),
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
                            title: 'Quick Access',
                            subtitle:
                                'Jump into the parts of your collection you are most likely to revisit.',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _QuickAccessSection(
                            onOpenFavorites: widget.onOpenFavorites,
                            onOpenRecent: widget.onOpenRecent,
                            onOpenInsights: widget.onOpenInsights,
                            onOpenCategories: _openAllCategories,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const _ProfileSectionTitle(
                            title: 'Badges',
                            subtitle:
                                'Unlocked and upcoming milestones across your archive.',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _BadgesSection(
                            awards: _badgeAwards,
                            progress: badgeProgress,
                            filter: _badgeFilter,
                            onFilterChanged: (filter) {
                              setState(() {
                                _badgeFilter = filter;
                              });
                            },
                            onBadgeTap: (entry) =>
                                _openBadgeDetail(entry, badgeProgress),
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

  void _scheduleBadgeSync(ArchiveProfileSummary summary) {
    final progress = CollectorProgressSnapshot.fromProfileSummary(summary);
    final signature = CollectorBadgeEngine.buildSignature(progress);
    if (_lastBadgeSignature == signature) {
      return;
    }
    _lastBadgeSignature = signature;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final unlocked = CollectorBadgeEngine.unlockedBadges(progress);
      final syncResult = await _badgeAwardStore.syncUnlocked(unlocked);
      if (!mounted) {
        return;
      }
      setState(() {
        _badgeAwards = syncResult.awards;
      });
      if (!widget.isActive) {
        return;
      }
      if (syncResult.newAwards.isNotEmpty) {
        CollectorHaptics.medium();
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) =>
              CollectorBadgeUnlockSheet(awards: syncResult.newAwards),
        );
        return;
      }

      await _maybeShowCollectorStatusIntro(summary);
    });
  }

  Future<void> _maybeShowCollectorStatusIntro(
    ArchiveProfileSummary summary,
  ) async {
    if (!widget.isActive ||
        _hasAttemptedCollectorStatusIntro ||
        summary.totalItems <= 0) {
      return;
    }

    final dismissed =
        await FeatureAnnouncementStore.isCollectorStatusIntroDismissed();
    if (!mounted) {
      return;
    }

    _hasAttemptedCollectorStatusIntro = true;
    if (dismissed) {
      return;
    }

    CollectorHaptics.light();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CollectorStatusIntroSheet(),
    );

    await FeatureAnnouncementStore.dismissCollectorStatusIntro();
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.data,
    required this.unlockedBadgeCount,
    required this.onLevelTap,
    required this.onEditProfile,
    required this.onAvatarTap,
    required this.isUploadingAvatar,
  });

  final _ProfileScreenData data;
  final int unlockedBadgeCount;
  final VoidCallback onLevelTap;
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
    final collectorLevel = resolveCollectorLevel(
      unlockedBadgesCount: unlockedBadgeCount,
      totalBadgesCount: collectorBadgeDefinitions.length,
    );

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
          const SizedBox(height: AppSpacing.md),
          Center(
            child: _CollectorLevelPill(
              level: collectorLevel,
              onTap: onLevelTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectorLevelPill extends StatelessWidget {
  const _CollectorLevelPill({required this.level, required this.onTap});

  final CollectorLevel level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0x33F0C977),
                AppColors.surfaceContainerHighest.withValues(alpha: 0.9),
              ],
            ),
            border: Border.all(color: const Color(0x4DBA9150)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14533D16),
                blurRadius: 18,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                level.assetPath,
                width: 44,
                height: 44,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  level.label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectorLevelSheet extends StatelessWidget {
  const _CollectorLevelSheet({required this.level});

  final CollectorLevel level;

  @override
  Widget build(BuildContext context) {
    final nextLevel = nextCollectorLevelDefinition(level);
    final badgesNeeded = nextLevel == null
        ? 0
        : (nextLevel.minBadges - level.unlockedBadgesCount).clamp(0, 999);

    return CollectorBottomSheet(
      title: level.label,
      description: level.description,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: _CollectorLevelPill(level: level, onTap: () {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          _LevelInfoRow(
            label: 'Badges unlocked',
            value: '${level.unlockedBadgesCount} of ${level.totalBadgesCount}',
          ),
          const SizedBox(height: AppSpacing.sm),
          _LevelInfoRow(label: 'Current standing', value: level.title),
          const SizedBox(height: AppSpacing.md),
          if (nextLevel != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Level',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Level ${nextLevel.level} · ${nextLevel.title}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    badgesNeeded == 1
                        ? 'Earn 1 more badge to reach the next level.'
                        : 'Earn $badgesNeeded more badges to reach the next level.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.16),
                ),
              ),
              child: Text(
                'You have reached the highest current collector level.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LevelInfoRow extends StatelessWidget {
  const _LevelInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: AppColors.onSurface),
        ),
      ],
    );
  }
}

class _CollectorSummary extends StatelessWidget {
  const _CollectorSummary({required this.data});

  final _ProfileScreenData data;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _SummaryStat(label: 'Items', value: '${data.totalItems}'),
      _SummaryStat(label: 'Categories', value: '${data.categoryCount}'),
      _SummaryStat(label: 'Favorites', value: '${data.favoriteCount}'),
      _SummaryStat(label: 'Photos', value: '${data.photoCount}'),
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
                      color: AppColors.surfaceContainerHighest.withValues(
                        alpha: 0.42,
                      ),
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
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.onSurfaceVariant),
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

class _QuickAccessSection extends StatelessWidget {
  const _QuickAccessSection({
    required this.onOpenFavorites,
    required this.onOpenRecent,
    required this.onOpenInsights,
    required this.onOpenCategories,
  });

  final VoidCallback onOpenFavorites;
  final VoidCallback onOpenRecent;
  final VoidCallback onOpenInsights;
  final VoidCallback onOpenCategories;

  @override
  Widget build(BuildContext context) {
    return CollectorPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.9),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
          final actions = [
            _ProfileQuickAction(
              title: 'Favorites',
              subtitle: 'Your starred pieces',
              icon: Icons.favorite_outline_rounded,
              onTap: onOpenFavorites,
            ),
            _ProfileQuickAction(
              title: 'Recently Added',
              subtitle: 'Latest arrivals',
              icon: Icons.history_rounded,
              onTap: onOpenRecent,
            ),
            _ProfileQuickAction(
              title: 'Insights',
              subtitle: 'Collection signals',
              icon: Icons.insights_rounded,
              onTap: onOpenInsights,
            ),
            _ProfileQuickAction(
              title: 'Categories',
              subtitle: 'Browse every shelf',
              icon: Icons.grid_view_rounded,
              onTap: onOpenCategories,
            ),
          ];

          return Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final action in actions)
                SizedBox(
                  width: cellWidth,
                  child: _QuickAccessTile(action: action),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BadgesSection extends StatelessWidget {
  const _BadgesSection({
    required this.awards,
    required this.progress,
    required this.filter,
    required this.onFilterChanged,
    required this.onBadgeTap,
  });

  final List<CollectorBadgeAward> awards;
  final CollectorProgressSnapshot progress;
  final _BadgeGalleryFilter filter;
  final ValueChanged<_BadgeGalleryFilter> onFilterChanged;
  final ValueChanged<_BadgeGalleryEntry> onBadgeTap;

  @override
  Widget build(BuildContext context) {
    final awardsById = {for (final award in awards) award.badge.id: award};
    final entries =
        [
          for (final badge in collectorBadgeDefinitions)
            _BadgeGalleryEntry(
              badge: badge,
              award: awardsById[badge.id],
              progress: _badgeUnlockStatus(badge.id, progress),
            ),
        ]..sort((a, b) {
          if (a.isUnlocked == b.isUnlocked) {
            return a.badge.id.index.compareTo(b.badge.id.index);
          }
          return a.isUnlocked ? -1 : 1;
        });
    final visibleEntries = entries
        .where(
          (entry) => switch (filter) {
            _BadgeGalleryFilter.unlocked => entry.isUnlocked,
            _BadgeGalleryFilter.locked => !entry.isUnlocked,
          },
        )
        .toList(growable: false);

    return CollectorPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BadgeFilterToggle(
            filter: filter,
            unlockedCount: entries.where((entry) => entry.isUnlocked).length,
            lockedCount: entries.where((entry) => !entry.isUnlocked).length,
            onChanged: onFilterChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          if (visibleEntries.isEmpty)
            _BadgeGalleryEmptyState(filter: filter)
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final cellWidth =
                    (constraints.maxWidth - (AppSpacing.sm * 2)) / 3;
                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final entry in visibleEntries)
                      SizedBox(
                        width: cellWidth,
                        child: _BadgeCard(
                          entry: entry,
                          onTap: () => onBadgeTap(entry),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
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
                subtitle:
                    'Update your display name, username, and collector bio.',
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
                icon: Icons.help_outline_rounded,
                title: 'Help and Support',
                subtitle: 'Collector help and support resources.',
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
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
  const _ProfileSectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
  const _AvatarFallback({required this.initials});

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
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(color: AppColors.onSurface),
        ),
      ),
    );
  }
}

class _AvatarPhotoSheet extends StatelessWidget {
  const _AvatarPhotoSheet({required this.onCamera, required this.onGallery});

  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return CollectorBottomSheet(
      title: 'Profile Photo',
      description: 'Choose a fresh photo for your collector identity.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                  child: Icon(icon, color: AppColors.primary, size: 22),
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

enum _BadgeGalleryFilter { unlocked, locked }

class _BadgeFilterToggle extends StatelessWidget {
  const _BadgeFilterToggle({
    required this.filter,
    required this.unlockedCount,
    required this.lockedCount,
    required this.onChanged,
  });

  final _BadgeGalleryFilter filter;
  final int unlockedCount;
  final int lockedCount;
  final ValueChanged<_BadgeGalleryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _BadgeFilterChip(
              label: 'Unlocked',
              count: unlockedCount,
              selected: filter == _BadgeGalleryFilter.unlocked,
              onTap: () => onChanged(_BadgeGalleryFilter.unlocked),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _BadgeFilterChip(
              label: 'Locked',
              count: lockedCount,
              selected: filter == _BadgeGalleryFilter.locked,
              onTap: () => onChanged(_BadgeGalleryFilter.locked),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeFilterChip extends StatelessWidget {
  const _BadgeFilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.22)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '$count',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeGalleryEmptyState extends StatelessWidget {
  const _BadgeGalleryEmptyState({required this.filter});

  final _BadgeGalleryFilter filter;

  @override
  Widget build(BuildContext context) {
    final title = switch (filter) {
      _BadgeGalleryFilter.unlocked => 'You have not unlocked any badges yet.',
      _BadgeGalleryFilter.locked => 'You have unlocked every current badge.',
    };
    final subtitle = switch (filter) {
      _BadgeGalleryFilter.unlocked =>
        'Keep adding to your archive and your first milestones will show up here.',
      _BadgeGalleryFilter.locked =>
        'Your shelf has cleared the current badge set. More milestones can be added later.',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileQuickAction {
  const _ProfileQuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.entry, required this.onTap});

  final _BadgeGalleryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badge = entry.badge;
    final isUnlocked = entry.isUnlocked;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxs,
            vertical: AppSpacing.xs,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Opacity(
                      opacity: isUnlocked ? 1 : 0.32,
                      child: SizedBox(
                        width: 84,
                        height: 84,
                        child: ColorFiltered(
                          colorFilter: isUnlocked
                              ? const ColorFilter.mode(
                                  Colors.transparent,
                                  BlendMode.dst,
                                )
                              : const ColorFilter.matrix(<double>[
                                  0.2126,
                                  0.7152,
                                  0.0722,
                                  0,
                                  0,
                                  0.2126,
                                  0.7152,
                                  0.0722,
                                  0,
                                  0,
                                  0.2126,
                                  0.7152,
                                  0.0722,
                                  0,
                                  0,
                                  0,
                                  0,
                                  0,
                                  1,
                                  0,
                                ]),
                          child: Image.asset(
                            badge.assetPath,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    if (!isUnlocked)
                      Positioned(
                        top: 2,
                        right: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHighest,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.outlineVariant.withValues(
                                alpha: 0.18,
                              ),
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            size: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  badge.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isUnlocked
                        ? AppColors.onSurface
                        : AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeDetailSheet extends StatelessWidget {
  const _BadgeDetailSheet({required this.entry, required this.progress});

  final _BadgeGalleryEntry entry;
  final CollectorProgressSnapshot progress;

  @override
  Widget build(BuildContext context) {
    final badge = entry.badge;
    final mediaQuery = MediaQuery.of(context);
    final unlock = entry.progress;
    final isUnlocked = entry.isUnlocked;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.84),
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
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 36,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.outlineVariant.withValues(
                              alpha: 0.6,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(12),
                            child: Ink(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHighest
                                    .withValues(alpha: 0.38),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.outlineVariant.withValues(
                                    alpha: 0.18,
                                  ),
                                ),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: AppColors.onSurfaceVariant,
                                size: 19,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: 168,
                  height: 168,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        badge.accentColor.withValues(alpha: 0.18),
                        badge.accentColor.withValues(alpha: 0.07),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(
                      color: badge.accentColor.withValues(alpha: 0.16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: badge.accentColor.withValues(alpha: 0.14),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Opacity(
                    opacity: isUnlocked ? 1 : 0.32,
                    child: ColorFiltered(
                      colorFilter: isUnlocked
                          ? const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.dst,
                            )
                          : const ColorFilter.matrix(<double>[
                              0.2126,
                              0.7152,
                              0.0722,
                              0,
                              0,
                              0.2126,
                              0.7152,
                              0.0722,
                              0,
                              0,
                              0.2126,
                              0.7152,
                              0.0722,
                              0,
                              0,
                              0,
                              0,
                              0,
                              1,
                              0,
                            ]),
                      child: Image.asset(badge.assetPath, fit: BoxFit.contain),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  badge.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.onSurface,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Column(
                    children: [
                      Text(
                        isUnlocked ? badge.description : unlock.requirement,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                      if (!isUnlocked && unlock.progressValue != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: unlock.progressValue,
                                  minHeight: 8,
                                  backgroundColor: badge.accentColor.withValues(
                                    alpha: 0.16,
                                  ),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    badge.accentColor,
                                  ),
                                ),
                              ),
                            ),
                            if (unlock.progressLabel != null) ...[
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                unlock.progressLabel!,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: badge.accentColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: badge.accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: badge.accentColor.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Text(
                            'Locked',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: badge.accentColor),
                          ),
                        ),
                      ],
                    ],
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

class _BadgeGalleryEntry {
  const _BadgeGalleryEntry({
    required this.badge,
    required this.award,
    required this.progress,
  });

  final CollectorBadgeDefinition badge;
  final CollectorBadgeAward? award;
  final _BadgeUnlockProgress progress;

  bool get isUnlocked => award != null;
}

class _BadgeUnlockProgress {
  const _BadgeUnlockProgress({
    required this.requirement,
    this.progressValue,
    this.progressLabel,
  });

  final String requirement;
  final double? progressValue;
  final String? progressLabel;
}

_BadgeUnlockProgress _badgeUnlockStatus(
  CollectorBadgeId id,
  CollectorProgressSnapshot progress,
) {
  switch (id) {
    case CollectorBadgeId.firstShelf:
      return _countBadgeProgress(
        requirement: 'Add your first collectible to the archive.',
        current: progress.totalItems,
        target: 1,
      );
    case CollectorBadgeId.archiveStarter:
      return _countBadgeProgress(
        requirement: 'Reach 10 items in the archive.',
        current: progress.totalItems,
        target: 10,
      );
    case CollectorBadgeId.shelfExpander:
      return _countBadgeProgress(
        requirement: 'Reach 25 items in the archive.',
        current: progress.totalItems,
        target: 25,
      );
    case CollectorBadgeId.deepArchive:
      return _countBadgeProgress(
        requirement: 'Reach 50 items in the archive.',
        current: progress.totalItems,
        target: 50,
      );
    case CollectorBadgeId.centuryShelf:
      return _countBadgeProgress(
        requirement: 'Reach 100 items in the archive.',
        current: progress.totalItems,
        target: 100,
      );
    case CollectorBadgeId.photoReady:
      return _ratioBadgeProgress(
        requirement: 'Reach at least 70% photo coverage with 5 or more items.',
        currentPercent: (progress.photoCoverageRatio * 100).round(),
        targetPercent: 70,
      );
    case CollectorBadgeId.photoKeeper:
      return _ratioBadgeProgress(
        requirement: 'Reach 90% photo coverage with 10 or more items.',
        currentPercent: (progress.photoCoverageRatio * 100).round(),
        targetPercent: 90,
      );
    case CollectorBadgeId.fullyFramed:
      return _countBadgeProgress(
        requirement: 'Add a photo for every item in the archive.',
        current: progress.photoCount,
        target: progress.totalItems == 0 ? 1 : progress.totalItems,
      );
    case CollectorBadgeId.favoriteFinder:
      return _countBadgeProgress(
        requirement: 'Mark your first favorite collectible.',
        current: progress.favoriteCount,
        target: 1,
      );
    case CollectorBadgeId.curatedEye:
      return _countBadgeProgress(
        requirement: 'Mark 10 collectibles as favorites.',
        current: progress.favoriteCount,
        target: 10,
      );
    case CollectorBadgeId.categoryBuilder:
      return _countBadgeProgress(
        requirement: 'Collect across 4 different categories.',
        current: progress.categoryCount,
        target: 4,
      );
    case CollectorBadgeId.focusedCollector:
      return _countBadgeProgress(
        requirement: 'Build one category to 10 items.',
        current: progress.topCategoryItemCount,
        target: 10,
      );
    case CollectorBadgeId.universeBuilder:
      return _countBadgeProgress(
        requirement: 'Build one franchise to 10 items.',
        current: progress.topFranchiseItemCount,
        target: 10,
      );
  }
}

_BadgeUnlockProgress _countBadgeProgress({
  required String requirement,
  required int current,
  required int target,
}) {
  final safeTarget = target <= 0 ? 1 : target;
  return _BadgeUnlockProgress(
    requirement: requirement,
    progressValue: (current / safeTarget).clamp(0, 1),
    progressLabel: '${current.clamp(0, safeTarget)} / $safeTarget',
  );
}

_BadgeUnlockProgress _ratioBadgeProgress({
  required String requirement,
  required int currentPercent,
  required int targetPercent,
}) {
  final clamped = currentPercent.clamp(0, 100);
  return _BadgeUnlockProgress(
    requirement: requirement,
    progressValue: (clamped / targetPercent).clamp(0, 1),
    progressLabel: '$clamped% / $targetPercent%',
  );
}

class _QuickAccessTile extends StatelessWidget {
  const _QuickAccessTile({required this.action});

  final _ProfileQuickAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHighest.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      action.icon,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.onSurfaceVariant,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                action.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                action.subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                  color: AppColors.surfaceContainerHighest.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: onTap == null
                      ? AppColors.onSurfaceVariant
                      : AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
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
  const _ProfileErrorState({required this.onRetry});

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
              CollectorButton(label: 'Retry', onPressed: () => onRetry()),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.profile, required this.onSave});

  final ProfileModel? profile;
  final Future<ProfileModel> Function(ProfileModel profile) onSave;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  late final FocusNode _bioFocusNode;
  var _isSaving = false;
  bool get _showBioClearButton =>
      _bioFocusNode.hasFocus && _bioController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.profile?.displayName ?? '',
    );
    _usernameController = TextEditingController(
      text: widget.profile?.username ?? '',
    );
    _bioController = TextEditingController(text: widget.profile?.bio ?? '');
    _bioFocusNode = FocusNode();
    _bioController.addListener(_handleBioInputStateChanged);
    _bioFocusNode.addListener(_handleBioInputStateChanged);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.removeListener(_handleBioInputStateChanged);
    _bioController.dispose();
    _bioFocusNode
      ..removeListener(_handleBioInputStateChanged)
      ..dispose();
    super.dispose();
  }

  void _handleBioInputStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _clearBio() {
    _bioController.clear();
    _bioFocusNode.requestFocus();
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
          bio: _bioController.text.trim().isEmpty
              ? null
              : _bioController.text.trim(),
          avatarUrl: widget.profile?.avatarUrl,
          createdAt: widget.profile?.createdAt,
          updatedAt: widget.profile?.updatedAt,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      CollectorSnackBar.show(
        context,
        message: 'Could not save your profile right now.',
        tone: CollectorSnackBarTone.error,
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
    return CollectorBottomSheet(
      title: 'Edit Profile',
      description:
          'Keep it simple for now: name, username, and a short line about what you collect.',
      footer: SizedBox(
        width: double.infinity,
        child: CollectorButton(
          label: 'Save Profile',
          onPressed: _save,
          isLoading: _isSaving,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Text('BIO', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _bioController,
            focusNode: _bioFocusNode,
            minLines: 3,
            maxLines: 5,
            textInputAction: TextInputAction.done,
            onTapOutside: (_) => _bioFocusNode.unfocus(),
            decoration: InputDecoration(
              hintText:
                  'Action figures, games, comics, or whatever makes your shelf feel alive.',
              suffixIcon: _showBioClearButton
                  ? IconButton(
                      tooltip: 'Clear',
                      onPressed: _clearBio,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: AppColors.onSurfaceVariant,
                    )
                  : null,
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
        ],
      ),
    );
  }
}

class _SummaryStat {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;
}

class _ProfileScreenData {
  const _ProfileScreenData({
    required this.profile,
    required this.avatarImageUrl,
    required this.email,
    required this.totalItems,
    required this.categoryCount,
    required this.favoriteCount,
    required this.photoCount,
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
  final int photoCount;
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
