import '../../features/collection/data/models/collectible_model.dart';
import '../../features/profile/data/models/profile_model.dart';
import '../../features/wishlist/data/models/wishlist_item_model.dart';

class SyncStatus {
  const SyncStatus({
    this.isSyncing = false,
    this.isOffline = false,
    this.hasLocalData = false,
    this.hasCompletedInitialSync = false,
    this.lastSyncAt,
    this.message,
  });

  final bool isSyncing;
  final bool isOffline;
  final bool hasLocalData;
  final bool hasCompletedInitialSync;
  final DateTime? lastSyncAt;
  final String? message;

  SyncStatus copyWith({
    bool? isSyncing,
    bool? isOffline,
    bool? hasLocalData,
    bool? hasCompletedInitialSync,
    DateTime? lastSyncAt,
    String? message,
  }) {
    return SyncStatus(
      isSyncing: isSyncing ?? this.isSyncing,
      isOffline: isOffline ?? this.isOffline,
      hasLocalData: hasLocalData ?? this.hasLocalData,
      hasCompletedInitialSync:
          hasCompletedInitialSync ?? this.hasCompletedInitialSync,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      message: message ?? this.message,
    );
  }
}

class ArchivePhotoRef {
  const ArchivePhotoRef({
    this.localPath,
    this.remoteUrl,
    this.hasPhotoRecord = false,
  });

  final String? localPath;
  final String? remoteUrl;
  final bool hasPhotoRecord;

  bool get hasImage =>
      (localPath ?? '').trim().isNotEmpty ||
      (remoteUrl ?? '').trim().isNotEmpty;
}

class ArchiveHomeSummary {
  const ArchiveHomeSummary({
    required this.profile,
    required this.collectibles,
    required this.wishlistCount,
    required this.recentItems,
    required this.favoriteItems,
    required this.photoRefsByCollectibleId,
  });

  final ProfileModel? profile;
  final List<CollectibleModel> collectibles;
  final int wishlistCount;
  final List<CollectibleModel> recentItems;
  final List<CollectibleModel> favoriteItems;
  final Map<String, ArchivePhotoRef> photoRefsByCollectibleId;
}

class ArchiveLibraryCategoryStat {
  const ArchiveLibraryCategoryStat({
    required this.category,
    required this.count,
  });

  final String category;
  final int count;
}

class ArchiveLibraryFilters {
  const ArchiveLibraryFilters({
    this.query = '',
    this.favoritesOnly = false,
    this.grailsOnly = false,
    this.duplicatesOnly = false,
    this.hasPhotoOnly = false,
    this.missingPhotoOnly = false,
    this.category,
  });

  final String query;
  final bool favoritesOnly;
  final bool grailsOnly;
  final bool duplicatesOnly;
  final bool hasPhotoOnly;
  final bool missingPhotoOnly;
  final String? category;
}

enum ArchiveLibrarySort {
  newest,
  oldest,
  titleAscending,
  titleDescending,
  category,
  relevance,
}

class ArchiveLibraryPage {
  const ArchiveLibraryPage({
    required this.items,
    required this.photoRefsByCollectibleId,
    required this.categoryStats,
    required this.totalCount,
    required this.nextOffset,
    required this.hasMore,
  });

  final List<CollectibleModel> items;
  final Map<String, ArchivePhotoRef> photoRefsByCollectibleId;
  final List<ArchiveLibraryCategoryStat> categoryStats;
  final int totalCount;
  final int nextOffset;
  final bool hasMore;
}

class ArchiveSearchResults {
  const ArchiveSearchResults({
    required this.collectibles,
    required this.photoRefsByCollectibleId,
  });

  final List<CollectibleModel> collectibles;
  final Map<String, ArchivePhotoRef> photoRefsByCollectibleId;
}

class ArchiveCategoryCollection {
  const ArchiveCategoryCollection({
    required this.collectibles,
    required this.photoRefsByCollectibleId,
  });

  final List<CollectibleModel> collectibles;
  final Map<String, ArchivePhotoRef> photoRefsByCollectibleId;
}

class ArchiveCollectibleDetail {
  const ArchiveCollectibleDetail({
    required this.collectible,
    required this.photoRef,
  });

  final CollectibleModel collectible;
  final ArchivePhotoRef? photoRef;
}

class ArchiveProfileSummary {
  const ArchiveProfileSummary({
    required this.profile,
    required this.email,
    required this.totalItems,
    required this.categoryCount,
    required this.favoriteCount,
    required this.photoCount,
    required this.topCategoryItemCount,
    required this.topFranchiseItemCount,
    required this.wishlistCount,
    required this.latestItem,
    required this.featuredItem,
    required this.featuredPhotoRef,
    required this.favoriteCategory,
  });

  final ProfileModel? profile;
  final String? email;
  final int totalItems;
  final int categoryCount;
  final int favoriteCount;
  final int photoCount;
  final int topCategoryItemCount;
  final int topFranchiseItemCount;
  final int wishlistCount;
  final CollectibleModel? latestItem;
  final CollectibleModel? featuredItem;
  final ArchivePhotoRef? featuredPhotoRef;
  final String? favoriteCategory;
}

class ArchiveWishlistSummary {
  const ArchiveWishlistSummary({required this.items});

  final List<WishlistItemModel> items;
}
