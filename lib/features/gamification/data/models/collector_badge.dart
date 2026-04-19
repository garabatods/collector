import 'package:flutter/material.dart';

import '../../../../core/data/archive_types.dart';
import '../../../../theme/app_colors.dart';

enum CollectorBadgeId {
  firstShelf,
  archiveStarter,
  shelfExpander,
  deepArchive,
  centuryShelf,
  photoReady,
  photoKeeper,
  fullyFramed,
  favoriteFinder,
  curatedEye,
  categoryBuilder,
  focusedCollector,
  universeBuilder,
}

class CollectorBadgeDefinition {
  const CollectorBadgeDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.assetPath,
    required this.accentColor,
  });

  final CollectorBadgeId id;
  final String title;
  final String description;
  final IconData icon;
  final String assetPath;
  final Color accentColor;
}

class CollectorBadgeAward {
  const CollectorBadgeAward({required this.badge, required this.awardedAt});

  final CollectorBadgeDefinition badge;
  final DateTime awardedAt;
}

class CollectorProgressSnapshot {
  const CollectorProgressSnapshot({
    required this.totalItems,
    required this.categoryCount,
    required this.favoriteCount,
    required this.photoCount,
    required this.topCategoryItemCount,
    required this.topFranchiseItemCount,
  });

  final int totalItems;
  final int categoryCount;
  final int favoriteCount;
  final int photoCount;
  final int topCategoryItemCount;
  final int topFranchiseItemCount;

  double get photoCoverageRatio =>
      totalItems == 0 ? 0 : photoCount / totalItems;

  static CollectorProgressSnapshot fromHomeSummary(ArchiveHomeSummary summary) {
    final categoryCount = summary.collectibles
        .map((item) => item.category.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet()
        .length;
    final categoryCounts = <String, int>{};
    final franchiseCounts = <String, int>{};
    final photoCount = summary.collectibles
        .where(
          (item) =>
              item.id != null &&
              (summary.photoRefsByCollectibleId[item.id!]?.hasImage ?? false),
        )
        .length;
    for (final item in summary.collectibles) {
      final category = item.category.trim();
      if (category.isNotEmpty) {
        categoryCounts.update(
          category,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }

      final franchise = (item.franchise ?? '').trim();
      if (franchise.isNotEmpty) {
        franchiseCounts.update(
          franchise,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }

    return CollectorProgressSnapshot(
      totalItems: summary.collectibles.length,
      categoryCount: categoryCount,
      favoriteCount: summary.favoriteItems.length,
      photoCount: photoCount,
      topCategoryItemCount: _highestCount(categoryCounts),
      topFranchiseItemCount: _highestCount(franchiseCounts),
    );
  }

  static CollectorProgressSnapshot fromProfileSummary(
    ArchiveProfileSummary summary,
  ) {
    return CollectorProgressSnapshot(
      totalItems: summary.totalItems,
      categoryCount: summary.categoryCount,
      favoriteCount: summary.favoriteCount,
      photoCount: summary.photoCount,
      topCategoryItemCount: summary.topCategoryItemCount,
      topFranchiseItemCount: summary.topFranchiseItemCount,
    );
  }

  static int _highestCount(Map<String, int> counts) {
    if (counts.isEmpty) {
      return 0;
    }
    return counts.values.reduce(
      (current, next) => current > next ? current : next,
    );
  }
}

const collectorBadgeDefinitions = <CollectorBadgeDefinition>[
  CollectorBadgeDefinition(
    id: CollectorBadgeId.firstShelf,
    title: 'First Shelf',
    description: 'Added your first collectible.',
    icon: Icons.auto_awesome_rounded,
    assetPath: 'assets/badges/01_first_shelf.png',
    accentColor: AppColors.primary,
  ),
  CollectorBadgeDefinition(
    id: CollectorBadgeId.archiveStarter,
    title: 'Archive Starter',
    description: 'Reached 10 items in the archive.',
    icon: Icons.inventory_2_rounded,
    assetPath: 'assets/badges/02_archive_starter.png',
    accentColor: AppColors.categoryAzureForeground,
  ),
  CollectorBadgeDefinition(
    id: CollectorBadgeId.shelfExpander,
    title: 'Shelf Expander',
    description: 'Reached 25 items in the archive.',
    icon: Icons.view_cozy_rounded,
    assetPath: 'assets/badges/03_shelf_expander.png',
    accentColor: AppColors.categoryAzureForeground,
  ),
  CollectorBadgeDefinition(
    id: CollectorBadgeId.deepArchive,
    title: 'Deep Archive',
    description: 'Reached 50 items in the archive.',
    icon: Icons.layers_rounded,
    assetPath: 'assets/badges/04_deep_archive.png',
    accentColor: AppColors.primary,
  ),
  CollectorBadgeDefinition(
    id: CollectorBadgeId.centuryShelf,
    title: 'Century Shelf',
    description: 'Reached 100 items in the archive.',
    icon: Icons.auto_awesome_motion_rounded,
    assetPath: 'assets/badges/06_century_shelf.png',
    accentColor: AppColors.categoryRoseForeground,
  ),
  CollectorBadgeDefinition(
    id: CollectorBadgeId.photoReady,
    title: 'Photo Ready',
    description: 'Built strong photo coverage across the shelf.',
    icon: Icons.add_a_photo_outlined,
    assetPath: 'assets/badges/07_photo_ready.png',
    accentColor: AppColors.categoryEmeraldForeground,
  ),
  CollectorBadgeDefinition(
    id: CollectorBadgeId.photoKeeper,
    title: 'Photo Keeper',
    description: 'Reached 90% photo coverage across the archive.',
    icon: Icons.photo_library_outlined,
    assetPath: 'assets/badges/08_photo_keeper.png',
    accentColor: AppColors.categoryEmeraldForeground,
  ),
  CollectorBadgeDefinition(
    id: CollectorBadgeId.fullyFramed,
    title: 'Fully Framed',
    description: 'Every item in the archive has a photo.',
    icon: Icons.image_rounded,
    assetPath: 'assets/badges/09_fully_framed.png',
    accentColor: AppColors.categoryEmeraldForeground,
  ),
  CollectorBadgeDefinition(
    id: CollectorBadgeId.favoriteFinder,
    title: 'Favorite Finder',
    description: 'Picked the first favorite collectible.',
    icon: Icons.favorite_rounded,
    assetPath: 'assets/badges/10_favorite_finder.png',
    accentColor: AppColors.categoryRoseForeground,
  ),
  CollectorBadgeDefinition(
    id: CollectorBadgeId.curatedEye,
    title: 'Curated Eye',
    description: 'Marked 10 pieces as favorites.',
    icon: Icons.favorite_outline_rounded,
    assetPath: 'assets/badges/12_curated_eye.png',
    accentColor: AppColors.categoryRoseForeground,
  ),
  CollectorBadgeDefinition(
    id: CollectorBadgeId.categoryBuilder,
    title: 'Category Builder',
    description: 'Collected across four different categories.',
    icon: Icons.grid_view_rounded,
    assetPath: 'assets/badges/13_category_builder.png',
    accentColor: AppColors.categoryAmberForeground,
  ),
  CollectorBadgeDefinition(
    id: CollectorBadgeId.focusedCollector,
    title: 'Focused Collector',
    description: 'Built one category to 10 items.',
    icon: Icons.category_rounded,
    assetPath: 'assets/badges/14_focused_collector.png',
    accentColor: AppColors.categoryAmberForeground,
  ),
  CollectorBadgeDefinition(
    id: CollectorBadgeId.universeBuilder,
    title: 'Universe Builder',
    description: 'Built one franchise to 10 items.',
    icon: Icons.bubble_chart_rounded,
    assetPath: 'assets/badges/15_universe_builder.png',
    accentColor: AppColors.categoryCoralForeground,
  ),
];
