import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/collection/data/models/collectible_model.dart';
import '../../features/collection/data/models/collectible_photo_model.dart';
import '../../features/profile/data/models/profile_model.dart';
import '../../features/wishlist/data/models/wishlist_item_model.dart';
import 'archive_sync_coordinator.dart';
import 'archive_types.dart';
import 'local_archive_database.dart';

class ArchiveRepository {
  ArchiveRepository._({
    required LocalArchiveDatabase database,
    required ArchiveSyncCoordinator syncCoordinator,
  })  : _database = database,
        _syncCoordinator = syncCoordinator;

  static final ArchiveRepository instance = ArchiveRepository._(
    database: LocalArchiveDatabase.instance,
    syncCoordinator: ArchiveSyncCoordinator.instance,
  );

  final LocalArchiveDatabase _database;
  final ArchiveSyncCoordinator _syncCoordinator;

  ValueNotifier<SyncStatus> get syncStatus => _syncCoordinator.status;

  Future<void> initializeForCurrentUser() => _syncCoordinator.initializeForCurrentUser();

  Future<void> handleAppResumed() => _syncCoordinator.handleAppResumed();

  Future<void> syncIfNeeded({bool force = false}) =>
      _syncCoordinator.syncIfNeeded(force: force);

  Stream<ArchiveHomeSummary> watchHomeSummary() {
    final userId = _requireUserId();
    return Rx.combineLatest4(
      _database.watchProfile(userId),
      _database.watchCollectibles(userId),
      _database.watchWishlistItems(userId),
      _watchPrimaryPhotoRefs(userId),
      (
        ProfileModel? profile,
        List<CollectibleModel> collectibles,
        List<WishlistItemModel> wishlistItems,
        Map<String, ArchivePhotoRef> photoRefs,
      ) {
        final recentItems = collectibles.take(6).toList(growable: false);
        final favoriteItems = collectibles
            .where((item) => item.isFavorite)
            .take(6)
            .toList(growable: false);
        return ArchiveHomeSummary(
          profile: profile,
          collectibles: collectibles,
          wishlistCount: wishlistItems.length,
          recentItems: recentItems,
          favoriteItems: favoriteItems,
          photoRefsByCollectibleId: photoRefs,
        );
      },
    );
  }

  Stream<ArchiveLibraryPage> watchLibraryPage({
    ArchiveLibraryFilters filters = const ArchiveLibraryFilters(),
    ArchiveLibrarySort sort = ArchiveLibrarySort.newest,
    int offset = 0,
    int limit = 24,
  }) {
    final userId = _requireUserId();
    return Rx.combineLatest2(
      _database.watchCollectibles(userId),
      _watchPrimaryPhotoRefs(userId),
      (List<CollectibleModel> items, Map<String, ArchivePhotoRef> photoRefs) {
        final categoryStats = _buildCategoryStats(
          items,
          filters: ArchiveLibraryFilters(
            query: filters.query,
            favoritesOnly: filters.favoritesOnly,
            grailsOnly: filters.grailsOnly,
            duplicatesOnly: filters.duplicatesOnly,
            hasPhotoOnly: filters.hasPhotoOnly,
          ),
          photoRefs: photoRefs,
        );
        final filtered = _applyLibraryState(
          items,
          filters: filters,
          sort: sort,
          photoRefs: photoRefs,
        );
        final paged = filtered.skip(offset).take(limit).toList(growable: false);
        return ArchiveLibraryPage(
          items: paged,
          photoRefsByCollectibleId: photoRefs,
          categoryStats: categoryStats,
          totalCount: filtered.length,
          nextOffset: offset + paged.length,
          hasMore: offset + paged.length < filtered.length,
        );
      },
    );
  }

  Stream<ArchiveSearchResults> watchSearchResults({
    String query = '',
    bool favoritesOnly = false,
    bool grailsOnly = false,
    bool duplicatesOnly = false,
    ArchiveLibrarySort sort = ArchiveLibrarySort.relevance,
  }) {
    final userId = _requireUserId();
    return Rx.combineLatest2(
      _database.watchCollectibles(userId),
      _watchPrimaryPhotoRefs(userId),
      (List<CollectibleModel> items, Map<String, ArchivePhotoRef> photoRefs) {
        final filtered = _applyLibraryState(
          items,
          filters: ArchiveLibraryFilters(
            query: query,
            favoritesOnly: favoritesOnly,
            grailsOnly: grailsOnly,
            duplicatesOnly: duplicatesOnly,
          ),
          sort: sort,
          photoRefs: photoRefs,
        );
        return ArchiveSearchResults(
          collectibles: filtered,
          photoRefsByCollectibleId: photoRefs,
        );
      },
    );
  }

  Stream<ArchiveCategoryCollection> watchCategoryCollection(String category) {
    final userId = _requireUserId();
    return Rx.combineLatest2(
      _database.watchCollectibles(userId),
      _watchPrimaryPhotoRefs(userId),
      (List<CollectibleModel> items, Map<String, ArchivePhotoRef> photoRefs) {
        final normalizedCategory = category.trim().toLowerCase();
        final filtered = items
            .where(
              (item) => item.category.trim().toLowerCase() == normalizedCategory,
            )
            .toList(growable: false)
          ..sort(_compareDateDesc);
        return ArchiveCategoryCollection(
          collectibles: filtered,
          photoRefsByCollectibleId: photoRefs,
        );
      },
    );
  }

  Stream<ArchiveCollectibleDetail?> watchCollectibleDetail(String collectibleId) {
    final userId = _requireUserId();
    return Rx.combineLatest2(
      _database.watchCollectibleById(userId, collectibleId),
      _watchPrimaryPhotoRefs(userId),
      (CollectibleModel? collectible, Map<String, ArchivePhotoRef> photoRefs) {
        if (collectible == null) {
          return null;
        }
        return ArchiveCollectibleDetail(
          collectible: collectible,
          photoRef: collectible.id == null ? null : photoRefs[collectible.id!],
        );
      },
    );
  }

  Stream<ArchiveProfileSummary> watchProfileSummary() {
    final userId = _requireUserId();
    return Rx.combineLatest4(
      _database.watchProfile(userId),
      _database.watchCollectibles(userId),
      _database.watchWishlistItems(userId),
      _watchPrimaryPhotoRefs(userId),
      (
        ProfileModel? profile,
        List<CollectibleModel> collectibles,
        List<WishlistItemModel> wishlistItems,
        Map<String, ArchivePhotoRef> photoRefs,
      ) {
        final categoryCounts = <String, int>{};
        for (final item in collectibles) {
          final category = item.category.trim();
          if (category.isEmpty) {
            continue;
          }
          categoryCounts.update(category, (value) => value + 1, ifAbsent: () => 1);
        }

        final sortedCollectibles = [...collectibles]..sort(_compareDateDesc);
        final latestItem = sortedCollectibles.isEmpty ? null : sortedCollectibles.first;
        final favoriteCategory = _pickFavoriteCategory(categoryCounts);
        final featuredItem = _pickFeaturedItem(
          sortedCollectibles,
          topCategory: favoriteCategory,
        );

        final currentUser = Supabase.instance.client.auth.currentUser;
        return ArchiveProfileSummary(
          profile: profile,
          email: currentUser?.email,
          totalItems: collectibles.length,
          categoryCount: categoryCounts.length,
          favoriteCount: collectibles.where((item) => item.isFavorite).length,
          wishlistCount: wishlistItems.length,
          latestItem: latestItem,
          featuredItem: featuredItem,
          featuredPhotoRef:
              featuredItem?.id == null ? null : photoRefs[featuredItem!.id!],
          favoriteCategory: favoriteCategory,
        );
      },
    );
  }

  Stream<ArchiveWishlistSummary> watchWishlistSummary() {
    final userId = _requireUserId();
    return _database.watchWishlistItems(userId).map(
          (items) => ArchiveWishlistSummary(items: items),
        );
  }

  Stream<Map<String, ArchivePhotoRef>> _watchPrimaryPhotoRefs(String userId) {
    return Rx.combineLatest2(
      _database.watchPhotos(userId),
      _database.watchPhotoCacheEntries(userId),
      (
        List<CollectiblePhotoModel> photos,
        List<LocalPhotoCacheEntry> cacheEntries,
      ) {
        final primaryPhotos = <String, CollectiblePhotoModel>{};
        for (final photo in photos) {
          if (!photo.isPrimary) {
            continue;
          }
          primaryPhotos.putIfAbsent(photo.collectibleId, () => photo);
        }
        final cacheByPhotoId = {
          for (final entry in cacheEntries) entry.photoId: entry,
        };
        final result = <String, ArchivePhotoRef>{};
        for (final photo in primaryPhotos.values) {
          final cacheEntry = photo.id == null ? null : cacheByPhotoId[photo.id!];
          final remoteUrlExpiresAt = cacheEntry?.remoteUrlExpiresAt;
          final remoteUrl = remoteUrlExpiresAt != null &&
                  remoteUrlExpiresAt.isAfter(DateTime.now())
              ? cacheEntry?.remoteUrl
              : null;
          result[photo.collectibleId] = ArchivePhotoRef(
            localPath: cacheEntry?.localPath,
            remoteUrl: remoteUrl,
          );
        }
        return result;
      },
    );
  }

  List<ArchiveLibraryCategoryStat> _buildCategoryStats(
    List<CollectibleModel> items, {
    required ArchiveLibraryFilters filters,
    required Map<String, ArchivePhotoRef> photoRefs,
  }) {
    final filtered = _applyLibraryState(
      items,
      filters: filters,
      sort: ArchiveLibrarySort.newest,
      photoRefs: photoRefs,
    );
    final counts = <String, int>{};
    for (final item in filtered) {
      final category = item.category.trim();
      if (category.isEmpty) {
        continue;
      }
      counts.update(category, (value) => value + 1, ifAbsent: () => 1);
    }
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount == 0 ? a.key.compareTo(b.key) : byCount;
      });
    return entries
        .map(
          (entry) => ArchiveLibraryCategoryStat(
            category: entry.key,
            count: entry.value,
          ),
        )
        .toList(growable: false);
  }

  List<CollectibleModel> _applyLibraryState(
    List<CollectibleModel> items, {
    required ArchiveLibraryFilters filters,
    required ArchiveLibrarySort sort,
    required Map<String, ArchivePhotoRef> photoRefs,
  }) {
    final queryTerms = filters.query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList(growable: false);
    final normalizedCategory = filters.category?.trim().toLowerCase();

    final filtered = items.where((item) {
      if (filters.favoritesOnly && !item.isFavorite) {
        return false;
      }
      if (filters.grailsOnly && !item.isGrail) {
        return false;
      }
      if (filters.duplicatesOnly && !item.isDuplicate) {
        return false;
      }
      if (filters.hasPhotoOnly) {
        final photoRef = item.id == null ? null : photoRefs[item.id!];
        if (!(photoRef?.hasImage ?? false)) {
          return false;
        }
      }
      if (normalizedCategory != null &&
          normalizedCategory.isNotEmpty &&
          item.category.trim().toLowerCase() != normalizedCategory) {
        return false;
      }
      if (queryTerms.isEmpty) {
        return true;
      }
      return _matchesQuery(item, queryTerms);
    }).toList(growable: false);

    filtered.sort((a, b) {
      switch (sort) {
        case ArchiveLibrarySort.oldest:
          return _compareDateAsc(a, b);
        case ArchiveLibrarySort.titleAscending:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case ArchiveLibrarySort.titleDescending:
          return b.title.toLowerCase().compareTo(a.title.toLowerCase());
        case ArchiveLibrarySort.category:
          final byCategory = a.category.toLowerCase().compareTo(b.category.toLowerCase());
          return byCategory == 0 ? _compareDateDesc(a, b) : byCategory;
        case ArchiveLibrarySort.relevance:
          if (queryTerms.isEmpty) {
            return _compareDateDesc(a, b);
          }
          final scoreDelta = _scoreItem(b, queryTerms) - _scoreItem(a, queryTerms);
          return scoreDelta == 0 ? _compareDateDesc(a, b) : scoreDelta;
        case ArchiveLibrarySort.newest:
          return _compareDateDesc(a, b);
      }
    });

    return filtered;
  }

  bool _matchesQuery(CollectibleModel item, List<String> queryTerms) {
    final haystack = [
      item.title,
      item.category,
      item.brand,
      item.series,
      item.lineOrSeries,
      item.franchise,
      item.characterOrSubject,
      item.itemNumber,
      item.notes,
      item.barcode,
      ...item.tags.map((tag) => tag.name),
    ].whereType<String>().map((value) => value.toLowerCase()).join(' ');

    return queryTerms.every(haystack.contains);
  }

  int _scoreItem(CollectibleModel item, List<String> queryTerms) {
    var score = 0;
    final title = item.title.toLowerCase();
    final category = item.category.toLowerCase();
    final brand = (item.brand ?? '').toLowerCase();
    final series = (item.lineOrSeries ?? item.series ?? '').toLowerCase();
    final franchise = (item.franchise ?? '').toLowerCase();
    final tagNames = item.tags.map((tag) => tag.name.toLowerCase()).toList(growable: false);

    for (final term in queryTerms) {
      if (title.contains(term)) score += 60;
      if (brand.contains(term)) score += 26;
      if (franchise.contains(term)) score += 22;
      if (series.contains(term)) score += 20;
      if (category.contains(term)) score += 14;
      if (tagNames.any((tag) => tag.contains(term))) score += 18;
      if (title.startsWith(term)) score += 24;
      if (item.barcode?.toLowerCase().contains(term) ?? false) score += 52;
    }

    return score;
  }

  int _compareDateDesc(CollectibleModel a, CollectibleModel b) {
    final aDate = a.createdAt ?? a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.createdAt ?? b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  }

  int _compareDateAsc(CollectibleModel a, CollectibleModel b) {
    final aDate = a.createdAt ?? a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.createdAt ?? b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return aDate.compareTo(bDate);
  }

  String? _pickFavoriteCategory(Map<String, int> categoryCounts) {
    if (categoryCounts.isEmpty) {
      return null;
    }
    final entries = categoryCounts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount == 0 ? a.key.compareTo(b.key) : byCount;
      });
    return entries.first.key;
  }

  CollectibleModel? _pickFeaturedItem(
    List<CollectibleModel> items, {
    String? topCategory,
  }) {
    if (items.isEmpty) {
      return null;
    }
    if (topCategory != null && topCategory.trim().isNotEmpty) {
      final normalizedTopCategory = topCategory.trim().toLowerCase();
      final topCategoryItems = items
          .where((item) => item.category.trim().toLowerCase() == normalizedTopCategory)
          .toList(growable: false);
      for (final item in topCategoryItems) {
        if (item.isFavorite) {
          return item;
        }
      }
      if (topCategoryItems.isNotEmpty) {
        return topCategoryItems.first;
      }
    }
    for (final item in items) {
      if (item.isFavorite) {
        return item;
      }
    }
    return items.first;
  }

  String _requireUserId() {
    final userId = _syncCoordinator.currentUserId;
    if (userId == null || userId.isEmpty) {
      throw StateError('No authenticated user is available for archive reads.');
    }
    return userId;
  }
}
