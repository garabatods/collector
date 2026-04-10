import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/collection/data/models/collectible_model.dart';
import '../../features/collection/data/models/collectible_photo_model.dart';
import '../../features/collection/data/models/tag_model.dart';
import '../../features/profile/data/models/profile_model.dart';
import '../../features/wishlist/data/models/wishlist_item_model.dart';
import 'json_map.dart';

part 'local_archive_database.g.dart';

class ProfilesLocal extends Table {
  TextColumn get userId => text()();
  TextColumn get username => text().nullable()();
  TextColumn get displayName => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get bio => text().nullable()();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {userId};
}

class CollectiblesLocal extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get barcode => text().nullable()();
  TextColumn get title => text()();
  TextColumn get category => text()();
  TextColumn get description => text().nullable()();
  TextColumn get brand => text().nullable()();
  TextColumn get series => text().nullable()();
  TextColumn get franchise => text().nullable()();
  TextColumn get lineOrSeries => text().nullable()();
  TextColumn get characterOrSubject => text().nullable()();
  IntColumn get releaseYear => integer().nullable()();
  TextColumn get boxStatus => text().nullable()();
  TextColumn get itemNumber => text().nullable()();
  TextColumn get itemCondition => text().nullable()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  RealColumn get purchasePrice => real().nullable()();
  RealColumn get estimatedValue => real().nullable()();
  TextColumn get acquiredOn => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isGrail => boolean().withDefault(const Constant(false))();
  BoolColumn get isDuplicate => boolean().withDefault(const Constant(false))();
  BoolColumn get openToTrade => boolean().withDefault(const Constant(false))();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CollectiblePhotosLocal extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get collectibleId => text()();
  TextColumn get storageBucket => text()();
  TextColumn get storagePath => text()();
  TextColumn get caption => text().nullable()();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class WishlistItemsLocal extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get category => text()();
  TextColumn get description => text().nullable()();
  TextColumn get brand => text().nullable()();
  TextColumn get series => text().nullable()();
  TextColumn get franchise => text().nullable()();
  TextColumn get lineOrSeries => text().nullable()();
  TextColumn get characterOrSubject => text().nullable()();
  IntColumn get releaseYear => integer().nullable()();
  TextColumn get boxStatus => text().nullable()();
  TextColumn get priority => text().nullable()();
  RealColumn get targetPrice => real().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class TagsLocal extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get createdAt => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CollectibleTagLinksLocal extends Table {
  TextColumn get userId => text()();
  TextColumn get collectibleId => text()();
  TextColumn get tagId => text()();
  TextColumn get createdAt => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {userId, collectibleId, tagId};
}

class ArchiveSyncStates extends Table {
  TextColumn get userId => text()();
  TextColumn get remoteSyncStamp => text().nullable()();
  TextColumn get lastSyncAt => text().nullable()();
  TextColumn get lastSyncCheckAt => text().nullable()();
  BoolColumn get hasCompletedInitialSync =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {userId};
}

class PhotoCacheEntries extends Table {
  TextColumn get photoId => text()();
  TextColumn get userId => text()();
  TextColumn get collectibleId => text()();
  TextColumn get storagePath => text()();
  TextColumn get localPath => text().nullable()();
  TextColumn get remoteUrl => text().nullable()();
  TextColumn get remoteUrlExpiresAt => text().nullable()();
  IntColumn get byteSize => integer().nullable()();
  TextColumn get photoUpdatedAt => text().nullable()();
  TextColumn get lastTouchedAt => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {photoId};
}

class ArchiveSyncSnapshot {
  const ArchiveSyncSnapshot({
    required this.userId,
    required this.remoteSyncStamp,
    required this.profile,
    required this.collectibles,
    required this.photos,
    required this.wishlistItems,
    required this.tags,
    required this.tagLinks,
  });

  final String userId;
  final String? remoteSyncStamp;
  final ProfileModel? profile;
  final List<CollectibleModel> collectibles;
  final List<CollectiblePhotoModel> photos;
  final List<WishlistItemModel> wishlistItems;
  final List<TagModel> tags;
  final List<ArchiveTagLinkRecord> tagLinks;
}

class ArchiveTagLinkRecord {
  const ArchiveTagLinkRecord({
    required this.userId,
    required this.collectibleId,
    required this.tagId,
    this.createdAt,
  });

  final String userId;
  final String collectibleId;
  final String tagId;
  final DateTime? createdAt;
}

class ArchiveLocalSyncState {
  const ArchiveLocalSyncState({
    required this.userId,
    this.remoteSyncStamp,
    this.lastSyncAt,
    this.lastSyncCheckAt,
    this.hasCompletedInitialSync = false,
  });

  final String userId;
  final String? remoteSyncStamp;
  final DateTime? lastSyncAt;
  final DateTime? lastSyncCheckAt;
  final bool hasCompletedInitialSync;
}

class LocalPhotoCacheEntry {
  const LocalPhotoCacheEntry({
    required this.photoId,
    required this.userId,
    required this.collectibleId,
    required this.storagePath,
    this.localPath,
    this.remoteUrl,
    this.remoteUrlExpiresAt,
    this.byteSize,
    this.photoUpdatedAt,
    this.lastTouchedAt,
  });

  final String photoId;
  final String userId;
  final String collectibleId;
  final String storagePath;
  final String? localPath;
  final String? remoteUrl;
  final DateTime? remoteUrlExpiresAt;
  final int? byteSize;
  final DateTime? photoUpdatedAt;
  final DateTime? lastTouchedAt;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationSupportDirectory();
    final file = File(p.join(directory.path, 'collector_archive.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

@DriftDatabase(
  tables: [
    ProfilesLocal,
    CollectiblesLocal,
    CollectiblePhotosLocal,
    WishlistItemsLocal,
    TagsLocal,
    CollectibleTagLinksLocal,
    ArchiveSyncStates,
    PhotoCacheEntries,
  ],
)
class LocalArchiveDatabase extends _$LocalArchiveDatabase {
  LocalArchiveDatabase._() : super(_openConnection());

  static final LocalArchiveDatabase instance = LocalArchiveDatabase._();

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            for (final table in allTables.toList().reversed) {
              await m.deleteTable(table.actualTableName);
            }
            await m.createAll();
          }
        },
      );

  Stream<ProfileModel?> watchProfile(String userId) {
    final query = select(profilesLocal)..where((tbl) => tbl.userId.equals(userId));
    return query.watchSingleOrNull().map((row) {
      if (row == null) {
        return null;
      }
      return ProfileModel.fromJson({
        'id': row.userId,
        'username': row.username,
        'display_name': row.displayName,
        'avatar_url': row.avatarUrl,
        'bio': row.bio,
        'created_at': row.createdAt,
        'updated_at': row.updatedAt,
      });
    });
  }

  Future<ProfileModel?> getProfile(String userId) async {
    final row = await (select(profilesLocal)
          ..where((tbl) => tbl.userId.equals(userId)))
        .getSingleOrNull();
    if (row == null) {
      return null;
    }
    return ProfileModel.fromJson({
      'id': row.userId,
      'username': row.username,
      'display_name': row.displayName,
      'avatar_url': row.avatarUrl,
      'bio': row.bio,
      'created_at': row.createdAt,
      'updated_at': row.updatedAt,
    });
  }

  Stream<List<CollectibleModel>> watchCollectibles(String userId) {
    final query = select(collectiblesLocal)
      ..where((tbl) => tbl.userId.equals(userId))
      ..orderBy([
        (tbl) => OrderingTerm.desc(tbl.createdAt),
      ]);
    return query.watch().map(
          (rows) => rows
              .map(
                (row) => CollectibleModel.fromJson({
                  'id': row.id,
                  'user_id': row.userId,
                  'barcode': row.barcode,
                  'title': row.title,
                  'category': row.category,
                  'description': row.description,
                  'brand': row.brand,
                  'series': row.series,
                  'franchise': row.franchise,
                  'line_or_series': row.lineOrSeries,
                  'character_or_subject': row.characterOrSubject,
                  'release_year': row.releaseYear,
                  'box_status': row.boxStatus,
                  'item_number': row.itemNumber,
                  'item_condition': row.itemCondition,
                  'quantity': row.quantity,
                  'purchase_price': row.purchasePrice,
                  'estimated_value': row.estimatedValue,
                  'acquired_on': row.acquiredOn,
                  'notes': row.notes,
                  'is_favorite': row.isFavorite,
                  'is_grail': row.isGrail,
                  'is_duplicate': row.isDuplicate,
                  'open_to_trade': row.openToTrade,
                  'created_at': row.createdAt,
                  'updated_at': row.updatedAt,
                  'collectible_tags': _decodeCollectibleTagsJson(row.tagsJson),
                }),
              )
              .toList(growable: false),
        );
  }

  Future<List<CollectibleModel>> getCollectibles(String userId) async {
    return watchCollectibles(userId).first;
  }

  Stream<CollectibleModel?> watchCollectibleById(String userId, String id) {
    return watchCollectibles(userId).map(
      (items) => items.cast<CollectibleModel?>().firstWhere(
            (item) => item?.id == id,
            orElse: () => null,
          ),
    );
  }

  Stream<List<WishlistItemModel>> watchWishlistItems(String userId) {
    final query = select(wishlistItemsLocal)
      ..where((tbl) => tbl.userId.equals(userId))
      ..orderBy([
        (tbl) => OrderingTerm.desc(tbl.createdAt),
      ]);
    return query.watch().map(
          (rows) => rows
              .map(
                (row) => WishlistItemModel.fromJson({
                  'id': row.id,
                  'user_id': row.userId,
                  'title': row.title,
                  'category': row.category,
                  'description': row.description,
                  'brand': row.brand,
                  'series': row.series,
                  'franchise': row.franchise,
                  'line_or_series': row.lineOrSeries,
                  'character_or_subject': row.characterOrSubject,
                  'release_year': row.releaseYear,
                  'box_status': row.boxStatus,
                  'priority': row.priority,
                  'target_price': row.targetPrice,
                  'notes': row.notes,
                  'created_at': row.createdAt,
                  'updated_at': row.updatedAt,
                }),
              )
              .toList(growable: false),
        );
  }

  Future<List<WishlistItemModel>> getWishlistItems(String userId) async {
    return watchWishlistItems(userId).first;
  }

  Stream<List<CollectiblePhotoModel>> watchPhotos(String userId) {
    final query = select(collectiblePhotosLocal)
      ..where((tbl) => tbl.userId.equals(userId))
      ..orderBy([
        (tbl) => OrderingTerm.desc(tbl.isPrimary),
        (tbl) => OrderingTerm.asc(tbl.displayOrder),
        (tbl) => OrderingTerm.asc(tbl.createdAt),
      ]);
    return query.watch().map(
          (rows) => rows
              .map(
                (row) => CollectiblePhotoModel.fromJson({
                  'id': row.id,
                  'collectible_id': row.collectibleId,
                  'storage_bucket': row.storageBucket,
                  'storage_path': row.storagePath,
                  'caption': row.caption,
                  'is_primary': row.isPrimary,
                  'display_order': row.displayOrder,
                  'created_at': row.createdAt,
                  'updated_at': row.updatedAt,
                }),
              )
              .toList(growable: false),
        );
  }

  Stream<List<TagModel>> watchTags(String userId) {
    final query = select(tagsLocal)
      ..where((tbl) => tbl.userId.equals(userId))
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.name),
      ]);
    return query.watch().map(
          (rows) => rows
              .map(
                (row) => TagModel.fromJson({
                  'id': row.id,
                  'user_id': row.userId,
                  'name': row.name,
                  'created_at': row.createdAt,
                }),
              )
              .toList(growable: false),
        );
  }

  Future<List<TagModel>> getTags(String userId) async {
    return watchTags(userId).first;
  }

  Stream<List<ArchiveTagLinkRecord>> watchTagLinks(String userId) {
    final query = select(collectibleTagLinksLocal)
      ..where((tbl) => tbl.userId.equals(userId));
    return query.watch().map(
          (rows) => rows
              .map(
                (row) => ArchiveTagLinkRecord(
                  userId: row.userId,
                  collectibleId: row.collectibleId,
                  tagId: row.tagId,
                  createdAt: _parseDateTime(row.createdAt),
                ),
              )
              .toList(growable: false),
        );
  }

  Stream<ArchiveLocalSyncState?> watchSyncState(String userId) {
    final query = select(archiveSyncStates)
      ..where((tbl) => tbl.userId.equals(userId));
    return query.watchSingleOrNull().map(_mapSyncStateRow);
  }

  Future<ArchiveLocalSyncState?> getSyncState(String userId) async {
    final row = await (select(archiveSyncStates)
          ..where((tbl) => tbl.userId.equals(userId)))
        .getSingleOrNull();
    return _mapSyncStateRow(row);
  }

  Stream<List<LocalPhotoCacheEntry>> watchPhotoCacheEntries(String userId) {
    final query = select(photoCacheEntries)
      ..where((tbl) => tbl.userId.equals(userId));
    return query.watch().map(
          (rows) => rows
              .map(
                (row) => LocalPhotoCacheEntry(
                  photoId: row.photoId,
                  userId: row.userId,
                  collectibleId: row.collectibleId,
                  storagePath: row.storagePath,
                  localPath: row.localPath,
                  remoteUrl: row.remoteUrl,
                  remoteUrlExpiresAt: _parseDateTime(row.remoteUrlExpiresAt),
                  byteSize: row.byteSize,
                  photoUpdatedAt: _parseDateTime(row.photoUpdatedAt),
                  lastTouchedAt: _parseDateTime(row.lastTouchedAt),
                ),
              )
              .toList(growable: false),
        );
  }

  Future<List<LocalPhotoCacheEntry>> getPhotoCacheEntries(String userId) async {
    return watchPhotoCacheEntries(userId).first;
  }

  Future<bool> hasAnyLocalBrowseData(String userId) async {
    final collectibleCount = await customSelect(
      'select count(*) as count from collectibles_local where user_id = ?',
      variables: [Variable.withString(userId)],
      readsFrom: {collectiblesLocal},
    ).getSingle();
    final wishlistCount = await customSelect(
      'select count(*) as count from wishlist_items_local where user_id = ?',
      variables: [Variable.withString(userId)],
      readsFrom: {wishlistItemsLocal},
    ).getSingle();
    final collectibleValue = collectibleCount.data['count'] as int? ?? 0;
    final wishlistValue = wishlistCount.data['count'] as int? ?? 0;
    return collectibleValue > 0 || wishlistValue > 0;
  }

  Future<void> replaceSnapshot(ArchiveSyncSnapshot snapshot) async {
    final tagMap = <String, TagModel>{
      for (final tag in snapshot.tags)
        if ((tag.id ?? '').isNotEmpty) tag.id!: tag,
    };
    final tagsByCollectibleId = <String, List<TagModel>>{};
    for (final link in snapshot.tagLinks) {
      final tag = tagMap[link.tagId];
      if (tag == null) {
        continue;
      }
      tagsByCollectibleId.putIfAbsent(link.collectibleId, () => <TagModel>[]).add(tag);
    }

    await transaction(() async {
      await (delete(profilesLocal)..where((tbl) => tbl.userId.equals(snapshot.userId))).go();
      await (delete(collectiblesLocal)..where((tbl) => tbl.userId.equals(snapshot.userId))).go();
      await (delete(collectiblePhotosLocal)..where((tbl) => tbl.userId.equals(snapshot.userId))).go();
      await (delete(wishlistItemsLocal)..where((tbl) => tbl.userId.equals(snapshot.userId))).go();
      await (delete(tagsLocal)..where((tbl) => tbl.userId.equals(snapshot.userId))).go();
      await (delete(collectibleTagLinksLocal)..where((tbl) => tbl.userId.equals(snapshot.userId))).go();

      if (snapshot.profile != null) {
        await into(profilesLocal).insertOnConflictUpdate(
          ProfilesLocalCompanion.insert(
            userId: snapshot.userId,
            username: Value(snapshot.profile!.username),
            displayName: Value(snapshot.profile!.displayName),
            avatarUrl: Value(snapshot.profile!.avatarUrl),
            bio: Value(snapshot.profile!.bio),
            createdAt: Value(_dateTimeString(snapshot.profile!.createdAt)),
            updatedAt: Value(_dateTimeString(snapshot.profile!.updatedAt)),
          ),
        );
      }

      if (snapshot.collectibles.isNotEmpty) {
        await batch((batch) {
          batch.insertAllOnConflictUpdate(
            collectiblesLocal,
            snapshot.collectibles
                .map(
                  (item) => CollectiblesLocalCompanion.insert(
                    id: item.id!,
                    userId: item.userId ?? snapshot.userId,
                    barcode: Value(item.barcode),
                    title: item.title,
                    category: item.category,
                    description: Value(item.description),
                    brand: Value(item.brand),
                    series: Value(item.series),
                    franchise: Value(item.franchise),
                    lineOrSeries: Value(item.lineOrSeries),
                    characterOrSubject: Value(item.characterOrSubject),
                    releaseYear: Value(item.releaseYear),
                    boxStatus: Value(item.boxStatus),
                    itemNumber: Value(item.itemNumber),
                    itemCondition: Value(item.itemCondition),
                    quantity: Value(item.quantity),
                    purchasePrice: Value(item.purchasePrice),
                    estimatedValue: Value(item.estimatedValue),
                    acquiredOn: Value(_dateTimeString(item.acquiredOn)),
                    notes: Value(item.notes),
                    isFavorite: Value(item.isFavorite),
                    isGrail: Value(item.isGrail),
                    isDuplicate: Value(item.isDuplicate),
                    openToTrade: Value(item.openToTrade),
                    tagsJson: Value(
                      jsonEncode(
                        (tagsByCollectibleId[item.id] ?? const <TagModel>[])
                            .map(_tagToJson)
                            .toList(growable: false),
                      ),
                    ),
                    createdAt: Value(_dateTimeString(item.createdAt)),
                    updatedAt: Value(_dateTimeString(item.updatedAt)),
                  ),
                )
                .toList(growable: false),
          );
        });
      }

      if (snapshot.photos.isNotEmpty) {
        await batch((batch) {
          batch.insertAllOnConflictUpdate(
            collectiblePhotosLocal,
            snapshot.photos
                .map(
                  (photo) => CollectiblePhotosLocalCompanion.insert(
                    id: photo.id!,
                    userId: snapshot.userId,
                    collectibleId: photo.collectibleId,
                    storageBucket: photo.storageBucket,
                    storagePath: photo.storagePath,
                    caption: Value(photo.caption),
                    isPrimary: Value(photo.isPrimary),
                    displayOrder: Value(photo.displayOrder),
                    createdAt: Value(_dateTimeString(photo.createdAt)),
                    updatedAt: Value(_dateTimeString(photo.updatedAt)),
                  ),
                )
                .toList(growable: false),
          );
        });
      }

      if (snapshot.wishlistItems.isNotEmpty) {
        await batch((batch) {
          batch.insertAllOnConflictUpdate(
            wishlistItemsLocal,
            snapshot.wishlistItems
                .map(
                  (item) => WishlistItemsLocalCompanion.insert(
                    id: item.id!,
                    userId: item.userId ?? snapshot.userId,
                    title: item.title,
                    category: item.category,
                    description: Value(item.description),
                    brand: Value(item.brand),
                    series: Value(item.series),
                    franchise: Value(item.franchise),
                    lineOrSeries: Value(item.lineOrSeries),
                    characterOrSubject: Value(item.characterOrSubject),
                    releaseYear: Value(item.releaseYear),
                    boxStatus: Value(item.boxStatus),
                    priority: Value(item.priority),
                    targetPrice: Value(item.targetPrice),
                    notes: Value(item.notes),
                    createdAt: Value(_dateTimeString(item.createdAt)),
                    updatedAt: Value(_dateTimeString(item.updatedAt)),
                  ),
                )
                .toList(growable: false),
          );
        });
      }

      if (snapshot.tags.isNotEmpty) {
        await batch((batch) {
          batch.insertAllOnConflictUpdate(
            tagsLocal,
            snapshot.tags
                .map(
                  (tag) => TagsLocalCompanion.insert(
                    id: tag.id!,
                    userId: tag.userId ?? snapshot.userId,
                    name: tag.name,
                    createdAt: Value(_dateTimeString(tag.createdAt)),
                  ),
                )
                .toList(growable: false),
          );
        });
      }

      if (snapshot.tagLinks.isNotEmpty) {
        await batch((batch) {
          batch.insertAllOnConflictUpdate(
            collectibleTagLinksLocal,
            snapshot.tagLinks
                .map(
                  (link) => CollectibleTagLinksLocalCompanion.insert(
                    userId: link.userId,
                    collectibleId: link.collectibleId,
                    tagId: link.tagId,
                    createdAt: Value(_dateTimeString(link.createdAt)),
                  ),
                )
                .toList(growable: false),
          );
        });
      }

      await into(archiveSyncStates).insertOnConflictUpdate(
        ArchiveSyncStatesCompanion.insert(
          userId: snapshot.userId,
          remoteSyncStamp: Value(snapshot.remoteSyncStamp),
          lastSyncAt: Value(DateTime.now().toIso8601String()),
          lastSyncCheckAt: Value(DateTime.now().toIso8601String()),
          hasCompletedInitialSync: const Value(true),
        ),
      );
    });
  }

  Future<void> updateSyncCheck(
    String userId, {
    String? remoteSyncStamp,
    DateTime? checkedAt,
    DateTime? lastSyncAt,
    bool? hasCompletedInitialSync,
  }) async {
    await into(archiveSyncStates).insertOnConflictUpdate(
      ArchiveSyncStatesCompanion.insert(
        userId: userId,
        remoteSyncStamp: Value(remoteSyncStamp),
        lastSyncAt: Value(_dateTimeString(lastSyncAt)),
        lastSyncCheckAt: Value(_dateTimeString(checkedAt ?? DateTime.now())),
        hasCompletedInitialSync: Value(hasCompletedInitialSync ?? false),
      ),
    );
  }

  Future<void> upsertProfile(ProfileModel profile, String userId) async {
    await into(profilesLocal).insertOnConflictUpdate(
      ProfilesLocalCompanion.insert(
        userId: userId,
        username: Value(profile.username),
        displayName: Value(profile.displayName),
        avatarUrl: Value(profile.avatarUrl),
        bio: Value(profile.bio),
        createdAt: Value(_dateTimeString(profile.createdAt)),
        updatedAt: Value(_dateTimeString(profile.updatedAt)),
      ),
    );
  }

  Future<void> upsertCollectible(CollectibleModel collectible, String userId) async {
    final collectibleId = collectible.id;
    if (collectibleId == null || collectibleId.isEmpty) {
      return;
    }
    await into(collectiblesLocal).insertOnConflictUpdate(
      CollectiblesLocalCompanion.insert(
        id: collectibleId,
        userId: collectible.userId ?? userId,
        barcode: Value(collectible.barcode),
        title: collectible.title,
        category: collectible.category,
        description: Value(collectible.description),
        brand: Value(collectible.brand),
        series: Value(collectible.series),
        franchise: Value(collectible.franchise),
        lineOrSeries: Value(collectible.lineOrSeries),
        characterOrSubject: Value(collectible.characterOrSubject),
        releaseYear: Value(collectible.releaseYear),
        boxStatus: Value(collectible.boxStatus),
        itemNumber: Value(collectible.itemNumber),
        itemCondition: Value(collectible.itemCondition),
        quantity: Value(collectible.quantity),
        purchasePrice: Value(collectible.purchasePrice),
        estimatedValue: Value(collectible.estimatedValue),
        acquiredOn: Value(_dateTimeString(collectible.acquiredOn)),
        notes: Value(collectible.notes),
        isFavorite: Value(collectible.isFavorite),
        isGrail: Value(collectible.isGrail),
        isDuplicate: Value(collectible.isDuplicate),
        openToTrade: Value(collectible.openToTrade),
        tagsJson: Value(jsonEncode(collectible.tags.map(_tagToJson).toList(growable: false))),
        createdAt: Value(_dateTimeString(collectible.createdAt)),
        updatedAt: Value(_dateTimeString(collectible.updatedAt)),
      ),
    );
  }

  Future<void> replaceCollectibleTags({
    required String userId,
    required String collectibleId,
    required List<TagModel> tags,
  }) async {
    await transaction(() async {
      await (delete(collectibleTagLinksLocal)
            ..where((tbl) =>
                tbl.userId.equals(userId) & tbl.collectibleId.equals(collectibleId)))
          .go();
      if (tags.isNotEmpty) {
        await batch((batch) {
          batch.insertAllOnConflictUpdate(
            tagsLocal,
            tags
                .where((tag) => (tag.id ?? '').isNotEmpty)
                .map(
                  (tag) => TagsLocalCompanion.insert(
                    id: tag.id!,
                    userId: tag.userId ?? userId,
                    name: tag.name,
                    createdAt: Value(_dateTimeString(tag.createdAt)),
                  ),
                )
                .toList(growable: false),
          );
          batch.insertAllOnConflictUpdate(
            collectibleTagLinksLocal,
            tags
                .where((tag) => (tag.id ?? '').isNotEmpty)
                .map(
                  (tag) => CollectibleTagLinksLocalCompanion.insert(
                    userId: userId,
                    collectibleId: collectibleId,
                    tagId: tag.id!,
                    createdAt: Value(DateTime.now().toIso8601String()),
                  ),
                )
                .toList(growable: false),
          );
        });
      }

      final collectible = await (select(collectiblesLocal)
            ..where((tbl) => tbl.id.equals(collectibleId)))
          .getSingleOrNull();
      if (collectible != null) {
        await (update(collectiblesLocal)..where((tbl) => tbl.id.equals(collectibleId))).write(
          CollectiblesLocalCompanion(
            tagsJson: Value(jsonEncode(tags.map(_tagToJson).toList(growable: false))),
          ),
        );
      }
    });
  }

  Future<void> deleteCollectible(String userId, String collectibleId) async {
    await transaction(() async {
      await (delete(collectiblesLocal)
            ..where((tbl) => tbl.userId.equals(userId) & tbl.id.equals(collectibleId)))
          .go();
      await (delete(collectiblePhotosLocal)
            ..where((tbl) =>
                tbl.userId.equals(userId) & tbl.collectibleId.equals(collectibleId)))
          .go();
      await (delete(collectibleTagLinksLocal)
            ..where((tbl) =>
                tbl.userId.equals(userId) & tbl.collectibleId.equals(collectibleId)))
          .go();
      await (delete(photoCacheEntries)
            ..where((tbl) =>
                tbl.userId.equals(userId) & tbl.collectibleId.equals(collectibleId)))
          .go();
    });
  }

  Future<void> upsertWishlistItem(WishlistItemModel item, String userId) async {
    final itemId = item.id;
    if (itemId == null || itemId.isEmpty) {
      return;
    }
    await into(wishlistItemsLocal).insertOnConflictUpdate(
      WishlistItemsLocalCompanion.insert(
        id: itemId,
        userId: item.userId ?? userId,
        title: item.title,
        category: item.category,
        description: Value(item.description),
        brand: Value(item.brand),
        series: Value(item.series),
        franchise: Value(item.franchise),
        lineOrSeries: Value(item.lineOrSeries),
        characterOrSubject: Value(item.characterOrSubject),
        releaseYear: Value(item.releaseYear),
        boxStatus: Value(item.boxStatus),
        priority: Value(item.priority),
        targetPrice: Value(item.targetPrice),
        notes: Value(item.notes),
        createdAt: Value(_dateTimeString(item.createdAt)),
        updatedAt: Value(_dateTimeString(item.updatedAt)),
      ),
    );
  }

  Future<void> upsertTag(TagModel tag, String userId) async {
    final tagId = tag.id;
    if (tagId == null || tagId.isEmpty) {
      return;
    }
    await into(tagsLocal).insertOnConflictUpdate(
      TagsLocalCompanion.insert(
        id: tagId,
        userId: tag.userId ?? userId,
        name: tag.name,
        createdAt: Value(_dateTimeString(tag.createdAt)),
      ),
    );
  }

  Future<void> deleteWishlistItem(String userId, String itemId) async {
    await (delete(wishlistItemsLocal)
          ..where((tbl) => tbl.userId.equals(userId) & tbl.id.equals(itemId)))
        .go();
  }

  Future<void> upsertPhoto(CollectiblePhotoModel photo, String userId) async {
    final photoId = photo.id;
    if (photoId == null || photoId.isEmpty) {
      return;
    }
    await into(collectiblePhotosLocal).insertOnConflictUpdate(
      CollectiblePhotosLocalCompanion.insert(
        id: photoId,
        userId: userId,
        collectibleId: photo.collectibleId,
        storageBucket: photo.storageBucket,
        storagePath: photo.storagePath,
        caption: Value(photo.caption),
        isPrimary: Value(photo.isPrimary),
        displayOrder: Value(photo.displayOrder),
        createdAt: Value(_dateTimeString(photo.createdAt)),
        updatedAt: Value(_dateTimeString(photo.updatedAt)),
      ),
    );
  }

  Future<void> replacePhotosForCollectible(
    String userId,
    String collectibleId,
    List<CollectiblePhotoModel> photos,
  ) async {
    await transaction(() async {
      await (delete(collectiblePhotosLocal)
            ..where((tbl) =>
                tbl.userId.equals(userId) & tbl.collectibleId.equals(collectibleId)))
          .go();
      if (photos.isNotEmpty) {
        await batch((batch) {
          batch.insertAllOnConflictUpdate(
            collectiblePhotosLocal,
            photos
                .where((photo) => (photo.id ?? '').isNotEmpty)
                .map(
                  (photo) => CollectiblePhotosLocalCompanion.insert(
                    id: photo.id!,
                    userId: userId,
                    collectibleId: collectibleId,
                    storageBucket: photo.storageBucket,
                    storagePath: photo.storagePath,
                    caption: Value(photo.caption),
                    isPrimary: Value(photo.isPrimary),
                    displayOrder: Value(photo.displayOrder),
                    createdAt: Value(_dateTimeString(photo.createdAt)),
                    updatedAt: Value(_dateTimeString(photo.updatedAt)),
                  ),
                )
                .toList(growable: false),
          );
        });
      }
    });
  }

  Future<void> upsertPhotoCacheEntry(LocalPhotoCacheEntry entry) async {
    await into(photoCacheEntries).insertOnConflictUpdate(
      PhotoCacheEntriesCompanion.insert(
        photoId: entry.photoId,
        userId: entry.userId,
        collectibleId: entry.collectibleId,
        storagePath: entry.storagePath,
        localPath: Value(entry.localPath),
        remoteUrl: Value(entry.remoteUrl),
        remoteUrlExpiresAt: Value(_dateTimeString(entry.remoteUrlExpiresAt)),
        byteSize: Value(entry.byteSize),
        photoUpdatedAt: Value(_dateTimeString(entry.photoUpdatedAt)),
        lastTouchedAt: Value(_dateTimeString(entry.lastTouchedAt ?? DateTime.now())),
      ),
    );
  }

  Future<void> deletePhotoCacheEntry(String photoId) async {
    await (delete(photoCacheEntries)..where((tbl) => tbl.photoId.equals(photoId))).go();
  }

  Future<void> deletePhotoCacheEntriesForCollectible(
    String userId,
    String collectibleId,
  ) async {
    await (delete(photoCacheEntries)
          ..where((tbl) =>
              tbl.userId.equals(userId) & tbl.collectibleId.equals(collectibleId)))
        .go();
  }

  List<JsonMap> _decodeCollectibleTagsJson(String rawJson) {
    try {
      final parsed = jsonDecode(rawJson);
      if (parsed is! List) {
        return const <JsonMap>[];
      }
      return parsed
          .whereType<Map>()
          .map((entry) => entry.cast<String, Object?>())
          .map((tagJson) => {'tag': tagJson})
          .toList(growable: false);
    } catch (_) {
      return const <JsonMap>[];
    }
  }

  ArchiveLocalSyncState? _mapSyncStateRow(ArchiveSyncState? row) {
    if (row == null) {
      return null;
    }
    return ArchiveLocalSyncState(
      userId: row.userId,
      remoteSyncStamp: row.remoteSyncStamp,
      lastSyncAt: _parseDateTime(row.lastSyncAt),
      lastSyncCheckAt: _parseDateTime(row.lastSyncCheckAt),
      hasCompletedInitialSync: row.hasCompletedInitialSync,
    );
  }

  Map<String, Object?> _tagToJson(TagModel tag) {
    return {
      'id': tag.id,
      'user_id': tag.userId,
      'name': tag.name,
      'created_at': _dateTimeString(tag.createdAt),
    };
  }
}

String? _dateTimeString(DateTime? value) => value?.toIso8601String();

DateTime? _parseDateTime(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return DateTime.tryParse(normalized);
}
