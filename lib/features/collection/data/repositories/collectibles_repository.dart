import '../../../../core/data/json_map.dart';
import '../../../../core/data/supabase_repository.dart';
import '../models/collectible_model.dart';
import 'tags_repository.dart';

class CollectiblesRepository extends SupabaseRepository {
  CollectiblesRepository({super.client});

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
      return created;
    }

    final tags = await _tagsRepository.syncCollectibleTags(
      collectibleId: createdId,
      tagIds: tagIds ?? const [],
      newTagNames: newTagNames ?? const [],
    );

    return created.copyWith(tags: tags);
  }

  Future<CollectibleModel> update(
    CollectibleModel collectible, {
    Iterable<String>? tagIds,
    Iterable<String>? newTagNames,
  }) async {
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
      return updated.copyWith(tags: collectible.tags);
    }

    final tags = await _tagsRepository.syncCollectibleTags(
      collectibleId: id,
      tagIds: tagIds ?? const [],
      newTagNames: newTagNames ?? const [],
    );

    return updated.copyWith(tags: tags);
  }

  Future<void> delete(String id) async {
    await client
        .from('collectibles')
        .delete()
        .eq('id', id)
        .eq('user_id', currentUserId);
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
}
