import '../../../../core/data/json_map.dart';
import '../../../../core/data/local_archive_database.dart';
import '../../../../core/data/supabase_repository.dart';
import '../models/tag_model.dart';

class TagsRepository extends SupabaseRepository {
  TagsRepository({super.client});

  static final LocalArchiveDatabase _localDatabase =
      LocalArchiveDatabase.instance;

  Future<List<TagModel>> fetchAll() async {
    final data = await client
        .from('tags')
        .select()
        .eq('user_id', currentUserId)
        .order('name');

    return asJsonList(data).map(TagModel.fromJson).toList(growable: false);
  }

  Future<TagModel> create(String name) async {
    await ensureOnlineForWrite();
    final data = await client
        .from('tags')
        .insert(
          TagModel(
            name: name,
          ).toInsertJson(userId: currentUserId),
        )
        .select()
        .single();

    final tag = TagModel.fromJson(asJsonMap(data));
    await _localDatabase.upsertTag(tag, currentUserId);
    return tag;
  }

  Future<List<TagModel>> resolveUserTags({
    Iterable<String> tagIds = const [],
    Iterable<String> newTagNames = const [],
  }) async {
    final allTags = await fetchAll();
    final byId = {
      for (final tag in allTags)
        if ((tag.id ?? '').isNotEmpty) tag.id!: tag,
    };
    final byLowerName = {
      for (final tag in allTags) tag.name.trim().toLowerCase(): tag,
    };

    final resolved = <String, TagModel>{};

    for (final tagId in tagIds.map((id) => id.trim()).where((id) => id.isNotEmpty)) {
      final tag = byId[tagId];
      if (tag != null && (tag.id ?? '').isNotEmpty) {
        resolved[tag.id!] = tag;
      }
    }

    for (final tagName
        in newTagNames.map((name) => name.trim()).where((name) => name.isNotEmpty)) {
      final normalizedName = tagName.toLowerCase();
      final existing = byLowerName[normalizedName];
      if (existing != null && (existing.id ?? '').isNotEmpty) {
        resolved[existing.id!] = existing;
        continue;
      }

      final created = await create(tagName);
      final createdId = created.id;
      if (createdId != null && createdId.isNotEmpty) {
        resolved[createdId] = created;
        byLowerName[normalizedName] = created;
      }
    }

    return resolved.values.toList(growable: false);
  }

  Future<Map<String, List<TagModel>>> fetchTagMapForCollectibleIds(
    List<String> collectibleIds,
  ) async {
    if (collectibleIds.isEmpty) {
      return const {};
    }

    final data = await client
        .from('collectible_tags')
        .select('collectible_id, tag:tags(*)')
        .inFilter('collectible_id', collectibleIds)
        .order('created_at');

    final tagMap = <String, List<TagModel>>{};
    for (final row in asJsonList(data)) {
      final collectibleId = asNullableString(row['collectible_id']);
      final tagJson = row['tag'];
      if (collectibleId == null || tagJson == null) {
        continue;
      }

      tagMap
          .putIfAbsent(collectibleId, () => <TagModel>[])
          .add(TagModel.fromJson(asJsonMap(tagJson)));
    }

    return tagMap;
  }

  Future<List<TagModel>> syncCollectibleTags({
    required String collectibleId,
    Iterable<String> tagIds = const [],
    Iterable<String> newTagNames = const [],
  }) async {
    final resolvedTags = await resolveUserTags(
      tagIds: tagIds,
      newTagNames: newTagNames,
    );
    final resolvedTagIds = resolvedTags
        .map((tag) => tag.id)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    final existingRows = await client
        .from('collectible_tags')
        .select('tag_id')
        .eq('collectible_id', collectibleId);

    final existingTagIds = asJsonList(existingRows)
        .map((row) => asNullableString(row['tag_id']))
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    final tagIdsToDelete = existingTagIds.difference(resolvedTagIds);
    if (tagIdsToDelete.isNotEmpty) {
      await client
          .from('collectible_tags')
          .delete()
          .eq('collectible_id', collectibleId)
          .inFilter('tag_id', tagIdsToDelete.toList(growable: false));
    }

    final tagIdsToInsert = resolvedTagIds.difference(existingTagIds);
    if (tagIdsToInsert.isNotEmpty) {
      await client.from('collectible_tags').insert(
            tagIdsToInsert
                .map(
                  (tagId) => {
                    'collectible_id': collectibleId,
                    'tag_id': tagId,
                  },
                )
                .toList(growable: false),
          );
    }

    return resolvedTags;
  }
}
