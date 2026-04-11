import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/collection/data/models/collectible_model.dart';
import '../../features/collection/data/models/collectible_photo_model.dart';
import '../../features/collection/data/models/tag_model.dart';
import '../../features/profile/data/models/profile_model.dart';
import '../../features/wishlist/data/models/wishlist_item_model.dart';
import 'archive_types.dart';
import 'local_archive_database.dart';
import 'photo_cache_store.dart';

class ArchiveSyncCoordinator {
  ArchiveSyncCoordinator._({
    required LocalArchiveDatabase database,
    required PhotoCacheStore photoCacheStore,
    SupabaseClient? client,
  }) : _database = database,
       _photoCacheStore = photoCacheStore,
       _client = client ?? Supabase.instance.client;

  static final ArchiveSyncCoordinator instance = ArchiveSyncCoordinator._(
    database: LocalArchiveDatabase.instance,
    photoCacheStore: PhotoCacheStore.instance,
  );

  static const syncCheckCooldown = Duration(seconds: 30);
  static const _photoCacheRepairCooldown = Duration(minutes: 5);

  final LocalArchiveDatabase _database;
  final PhotoCacheStore _photoCacheStore;
  final SupabaseClient _client;

  final ValueNotifier<SyncStatus> status = ValueNotifier(const SyncStatus());

  String? _activeUserId;
  Future<void>? _inFlightSync;
  final Map<String, DateTime> _lastPhotoCacheRepairAt = {};

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<void> initializeForCurrentUser() async {
    final userId = currentUserId;
    if (userId == null || userId.isEmpty) {
      _activeUserId = null;
      _lastPhotoCacheRepairAt.clear();
      status.value = const SyncStatus();
      return;
    }

    if (_activeUserId == userId) {
      await syncIfNeeded();
      return;
    }

    _activeUserId = userId;
    final hasLocalData = await _database.hasAnyLocalBrowseData(userId);
    final syncState = await _database.getSyncState(userId);
    status.value = SyncStatus(
      isSyncing: !(syncState?.hasCompletedInitialSync ?? false),
      hasLocalData: hasLocalData,
      hasCompletedInitialSync: syncState?.hasCompletedInitialSync ?? false,
      lastSyncAt: syncState?.lastSyncAt,
      message: !(syncState?.hasCompletedInitialSync ?? false)
          ? (hasLocalData ? 'Refreshing archive…' : 'Loading your archive…')
          : null,
    );
    await syncIfNeeded();
  }

  Future<void> handleAppResumed() async {
    await syncIfNeeded();
  }

  Future<void> syncIfNeeded({bool force = false}) {
    final existingSync = _inFlightSync;
    if (existingSync != null) {
      return existingSync;
    }

    final future = _runSync(force: force);
    _inFlightSync = future;
    return future.whenComplete(() {
      if (identical(_inFlightSync, future)) {
        _inFlightSync = null;
      }
    });
  }

  Future<void> _runSync({required bool force}) async {
    final userId = _activeUserId ?? currentUserId;
    if (userId == null || userId.isEmpty) {
      return;
    }

    final hasLocalData = await _database.hasAnyLocalBrowseData(userId);
    final syncState = await _database.getSyncState(userId);
    final lastCheck = syncState?.lastSyncCheckAt;
    if (!force &&
        lastCheck != null &&
        DateTime.now().difference(lastCheck) < syncCheckCooldown) {
      _reconcileLocalPrimaryPhotoCache(userId);
      return;
    }

    status.value = status.value.copyWith(
      isSyncing: true,
      isOffline: false,
      hasLocalData: hasLocalData,
      hasCompletedInitialSync: syncState?.hasCompletedInitialSync ?? false,
      message: hasLocalData ? 'Refreshing archive…' : 'Loading your archive…',
    );

    try {
      String? remoteSyncStamp;
      try {
        remoteSyncStamp = await _fetchRemoteSyncStamp();
      } catch (error) {
        if (kDebugMode) {
          debugPrint(
            'Archive sync stamp unavailable, falling back to snapshot sync: $error',
          );
        }
        remoteSyncStamp = null;
      }

      final shouldFullSync =
          force ||
          !hasLocalData ||
          remoteSyncStamp == null ||
          syncState?.remoteSyncStamp != remoteSyncStamp ||
          !(syncState?.hasCompletedInitialSync ?? false);

      if (!shouldFullSync) {
        await _database.updateSyncCheck(
          userId,
          remoteSyncStamp: remoteSyncStamp,
          checkedAt: DateTime.now(),
          lastSyncAt: syncState?.lastSyncAt,
          hasCompletedInitialSync: syncState?.hasCompletedInitialSync ?? false,
        );
        status.value = SyncStatus(
          hasLocalData: hasLocalData,
          hasCompletedInitialSync: syncState?.hasCompletedInitialSync ?? false,
          lastSyncAt: syncState?.lastSyncAt,
        );
        _reconcileLocalPrimaryPhotoCache(userId);
        return;
      }

      final snapshot = await _fetchFullSnapshot(userId, remoteSyncStamp);
      await _database.replaceSnapshot(snapshot);
      _lastPhotoCacheRepairAt[userId] = DateTime.now();
      unawaited(
        _photoCacheStore.reconcilePrimaryPhotos(userId, snapshot.photos),
      );
      final refreshedHasLocalData =
          snapshot.collectibles.isNotEmpty || snapshot.wishlistItems.isNotEmpty;
      status.value = SyncStatus(
        hasLocalData: refreshedHasLocalData,
        hasCompletedInitialSync: true,
        lastSyncAt: DateTime.now(),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Archive sync failed: $error');
      }
      final connectivity = await Connectivity().checkConnectivity();
      final isOffline = connectivity.every(
        (result) => result == ConnectivityResult.none,
      );
      await _database.updateSyncCheck(
        userId,
        remoteSyncStamp: syncState?.remoteSyncStamp,
        checkedAt: DateTime.now(),
        lastSyncAt: syncState?.lastSyncAt,
        hasCompletedInitialSync: syncState?.hasCompletedInitialSync ?? false,
      );
      status.value = SyncStatus(
        hasLocalData: hasLocalData,
        isOffline: isOffline,
        hasCompletedInitialSync: syncState?.hasCompletedInitialSync ?? false,
        lastSyncAt: syncState?.lastSyncAt,
        message: isOffline
            ? (hasLocalData
                  ? 'Showing saved archive while sync is unavailable.'
                  : 'Offline. Connect once to download your archive.')
            : (hasLocalData
                  ? 'Could not refresh your archive right now.'
                  : 'Could not download your archive right now.'),
      );
    }
  }

  void _reconcileLocalPrimaryPhotoCache(String userId) {
    final now = DateTime.now();
    final lastRepairAt = _lastPhotoCacheRepairAt[userId];
    if (lastRepairAt != null &&
        now.difference(lastRepairAt) < _photoCacheRepairCooldown) {
      return;
    }
    _lastPhotoCacheRepairAt[userId] = now;

    unawaited(() async {
      try {
        final photos = await _database.getPhotos(userId);
        if (photos.isEmpty) {
          return;
        }
        await _photoCacheStore.reconcilePrimaryPhotos(userId, photos);
      } catch (error) {
        if (kDebugMode) {
          debugPrint('Photo cache repair skipped: $error');
        }
      }
    }());
  }

  Future<String?> _fetchRemoteSyncStamp() async {
    final response = await _client.rpc('get_current_user_sync_stamp');
    if (response == null) {
      return null;
    }
    if (response is String) {
      return response.trim().isEmpty ? null : response.trim();
    }
    if (response is Map) {
      final value = response['sync_stamp'] ?? response['updated_at'];
      if (value is String) {
        return value.trim().isEmpty ? null : value.trim();
      }
    }
    return '$response';
  }

  Future<ArchiveSyncSnapshot> _fetchFullSnapshot(
    String userId,
    String? remoteSyncStamp,
  ) async {
    final profileFuture = _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    final collectiblesFuture = _client
        .from('collectibles')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    final wishlistFuture = _client
        .from('wishlist_items')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    final tagsFuture = _client
        .from('tags')
        .select()
        .eq('user_id', userId)
        .order('name');

    final results = await Future.wait([
      profileFuture,
      collectiblesFuture,
      wishlistFuture,
      tagsFuture,
    ]);

    final profile = results[0] == null
        ? null
        : ProfileModel.fromJson(Map<String, Object?>.from(results[0] as Map));
    final collectibles = (results[1] as List)
        .map(
          (row) =>
              CollectibleModel.fromJson(Map<String, Object?>.from(row as Map)),
        )
        .toList(growable: false);
    final wishlistItems = (results[2] as List)
        .map(
          (row) =>
              WishlistItemModel.fromJson(Map<String, Object?>.from(row as Map)),
        )
        .toList(growable: false);
    final tags = (results[3] as List)
        .map((row) => TagModel.fromJson(Map<String, Object?>.from(row as Map)))
        .toList(growable: false);

    final collectibleIds = collectibles
        .map((item) => item.id)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList(growable: false);

    final photos = collectibleIds.isEmpty
        ? const <CollectiblePhotoModel>[]
        : (await _client
                  .from('collectible_photos')
                  .select()
                  .inFilter('collectible_id', collectibleIds))
              .map<CollectiblePhotoModel>(
                (row) => CollectiblePhotoModel.fromJson(
                  Map<String, Object?>.from(row as Map),
                ),
              )
              .toList(growable: false);

    final tagLinks = collectibleIds.isEmpty
        ? const <ArchiveTagLinkRecord>[]
        : (await _client
                  .from('collectible_tags')
                  .select('collectible_id, tag_id, created_at')
                  .inFilter('collectible_id', collectibleIds))
              .map<ArchiveTagLinkRecord>((row) {
                final map = Map<String, Object?>.from(row as Map);
                return ArchiveTagLinkRecord(
                  userId: userId,
                  collectibleId: map['collectible_id'] as String,
                  tagId: map['tag_id'] as String,
                  createdAt: DateTime.tryParse('${map['created_at'] ?? ''}'),
                );
              })
              .toList(growable: false);

    return ArchiveSyncSnapshot(
      userId: userId,
      remoteSyncStamp: remoteSyncStamp,
      profile: profile,
      collectibles: collectibles,
      photos: photos,
      wishlistItems: wishlistItems,
      tags: tags,
      tagLinks: tagLinks,
    );
  }
}
