import '../../../../core/data/json_map.dart';
import '../../../../core/data/local_archive_database.dart';
import '../../../../core/data/supabase_repository.dart';
import '../models/collectible_model.dart';
import 'tags_repository.dart';

class CollectiblesRepository extends SupabaseRepository {
  CollectiblesRepository({super.client});

  static const libraryDefaultPageSize = 24;
  static final LocalArchiveDatabase _localDatabase =
      LocalArchiveDatabase.instance;

  TagsRepository get _tagsRepository => TagsRepository(client: client);

  Future<List<CollectibleModel>> fetchAll() async {
    final data = await client
        .from('collectibles')
        .select()
        .eq('user_id', currentUserId)
        .order('created_at', ascending: false);

    return _withTags(
      asJsonList(data).map(CollectibleModel.fromJson).toList(growable: false),
    );
  }

  Future<List<CollectibleModel>> fetchRecent({int limit = 6}) async {
    final data = await client
        .from('collectibles')
        .select()
        .eq('user_id', currentUserId)
        .order('created_at', ascending: false)
        .limit(limit);

    return _withTags(
      asJsonList(data).map(CollectibleModel.fromJson).toList(growable: false),
    );
  }

  Future<CollectiblePageResult> fetchPage({
    int offset = 0,
    int limit = libraryDefaultPageSize,
    String query = '',
    bool favoritesOnly = false,
    bool grailsOnly = false,
    bool duplicatesOnly = false,
    bool hasPhotoOnly = false,
    String? category,
    CollectiblePageSort sort = CollectiblePageSort.newest,
  }) async {
    final params = _librarySearchParams(
      query: query,
      favoritesOnly: favoritesOnly,
      grailsOnly: grailsOnly,
      duplicatesOnly: duplicatesOnly,
      hasPhotoOnly: hasPhotoOnly,
      category: category,
    );

    final totalCountRaw = await client.rpc(
      'library_search_collectibles_count',
      params: params,
    );
    final totalCount = asNullableInt(totalCountRaw) ?? 0;

    final data = await client.rpc(
      'library_search_collectibles_page',
      params: {
        ...params,
        'sort_key': _sortKey(sort),
        'page_limit': limit,
        'page_offset': offset,
      },
    );
    final items = await _withTags(
      asJsonList(data).map(CollectibleModel.fromJson).toList(growable: false),
    );

    return CollectiblePageResult(
      items: items,
      totalCount: totalCount,
      nextOffset: offset + items.length,
      hasMore: offset + items.length < totalCount,
    );
  }

  Future<List<CollectibleCategorySummary>> fetchCategoryCounts({
    String query = '',
    bool favoritesOnly = false,
    bool grailsOnly = false,
    bool duplicatesOnly = false,
    bool hasPhotoOnly = false,
  }) async {
    final rows = await client.rpc(
      'library_search_collectible_category_counts',
      params: _librarySearchParams(
        query: query,
        favoritesOnly: favoritesOnly,
        grailsOnly: grailsOnly,
        duplicatesOnly: duplicatesOnly,
        hasPhotoOnly: hasPhotoOnly,
        includeCategory: false,
      ),
    );

    return asJsonList(rows)
        .map(
          (row) => CollectibleCategorySummary(
            category: (asNullableString(row['category']) ?? '').trim(),
            count: asNullableInt(row['item_count']) ?? 0,
          ),
        )
        .where((summary) => summary.category.isNotEmpty)
        .toList(growable: false);
  }

  Future<CollectibleModel?> fetchById(String id) async {
    final data = await client
        .from('collectibles')
        .select()
        .eq('id', id)
        .eq('user_id', currentUserId)
        .maybeSingle();

    if (data == null) {
      return null;
    }

    final collectible = CollectibleModel.fromJson(asJsonMap(data));
    final taggedCollectibles = await _withTags([collectible]);
    return taggedCollectibles.isEmpty ? collectible : taggedCollectibles.first;
  }

  Future<CollectibleModel> create(
    CollectibleModel collectible, {
    Iterable<String>? tagIds,
    Iterable<String>? newTagNames,
  }) async {
    await ensureOnlineForWrite();
    final data = await client
        .from('collectibles')
        .insert(collectible.toInsertJson(userId: currentUserId))
        .select()
        .single();

    final created = CollectibleModel.fromJson(asJsonMap(data));
    final createdId = created.id;
    if (createdId == null) {
      return created;
    }

    if (tagIds == null && newTagNames == null) {
      await _localDatabase.upsertCollectible(created, currentUserId);
      return created;
    }

    final tags = await _tagsRepository.syncCollectibleTags(
      collectibleId: createdId,
      tagIds: tagIds ?? const [],
      newTagNames: newTagNames ?? const [],
    );

    final hydrated = created.copyWith(tags: tags);
    await _localDatabase.upsertCollectible(hydrated, currentUserId);
    await _localDatabase.replaceCollectibleTags(
      userId: currentUserId,
      collectibleId: createdId,
      tags: tags,
    );
    return hydrated;
  }

  Future<CollectibleModel> update(
    CollectibleModel collectible, {
    Iterable<String>? tagIds,
    Iterable<String>? newTagNames,
  }) async {
    await ensureOnlineForWrite();
    final id = collectible.id;
    if (id == null) {
      throw ArgumentError('Collectible id is required for updates.');
    }

    final data = await client
        .from('collectibles')
        .update(collectible.toUpdateJson())
        .eq('id', id)
        .eq('user_id', currentUserId)
        .select()
        .single();

    final updated = CollectibleModel.fromJson(asJsonMap(data));
    if (tagIds == null && newTagNames == null) {
      final hydrated = updated.copyWith(tags: collectible.tags);
      await _localDatabase.upsertCollectible(hydrated, currentUserId);
      return hydrated;
    }

    final tags = await _tagsRepository.syncCollectibleTags(
      collectibleId: id,
      tagIds: tagIds ?? const [],
      newTagNames: newTagNames ?? const [],
    );

    final hydrated = updated.copyWith(tags: tags);
    await _localDatabase.upsertCollectible(hydrated, currentUserId);
    await _localDatabase.replaceCollectibleTags(
      userId: currentUserId,
      collectibleId: id,
      tags: tags,
    );
    return hydrated;
  }

  Future<void> delete(String id) async {
    await ensureOnlineForWrite();
    await client
        .from('collectibles')
        .delete()
        .eq('id', id)
        .eq('user_id', currentUserId);
    await _localDatabase.deleteCollectible(currentUserId, id);
  }

  Future<List<CollectibleModel>> _withTags(
    List<CollectibleModel> collectibles,
  ) async {
    if (collectibles.isEmpty) {
      return collectibles;
    }

    final collectibleIds = collectibles
        .map((collectible) => collectible.id)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList(growable: false);

    final tagMap = await _tagsRepository.fetchTagMapForCollectibleIds(
      collectibleIds,
    );

    return collectibles
        .map(
          (collectible) => collectible.copyWith(
            tags: collectible.id == null
                ? const []
                : (tagMap[collectible.id!] ?? const []),
          ),
        )
        .toList(growable: false);
  }

  Map<String, Object?> _librarySearchParams({
    required String query,
    required bool favoritesOnly,
    required bool grailsOnly,
    required bool duplicatesOnly,
    required bool hasPhotoOnly,
    String? category,
    bool includeCategory = true,
  }) {
    final normalizedQuery = query.trim();
    final normalizedCategory = category?.trim();

    return {
      'search_text': normalizedQuery.isEmpty ? null : normalizedQuery,
      'favorites_only': favoritesOnly,
      'grails_only': grailsOnly,
      'duplicates_only': duplicatesOnly,
      'has_photo_only': hasPhotoOnly,
      if (includeCategory)
        'selected_category':
            normalizedCategory == null || normalizedCategory.isEmpty
                ? null
                : normalizedCategory,
    };
  }

  String _sortKey(CollectiblePageSort sort) {
    return switch (sort) {
      CollectiblePageSort.newest => 'newest',
      CollectiblePageSort.oldest => 'oldest',
      CollectiblePageSort.titleAscending => 'titleAscending',
      CollectiblePageSort.titleDescending => 'titleDescending',
      CollectiblePageSort.category => 'category',
    };
  }
}

enum CollectiblePageSort {
  newest,
  oldest,
  titleAscending,
  titleDescending,
  category,
}

class CollectiblePageResult {
  const CollectiblePageResult({
    required this.items,
    required this.totalCount,
    required this.nextOffset,
    required this.hasMore,
  });

  final List<CollectibleModel> items;
  final int totalCount;
  final int nextOffset;
  final bool hasMore;
}

class CollectibleCategorySummary {
  const CollectibleCategorySummary({
    required this.category,
    required this.count,
  });

  final String category;
  final int count;
}
