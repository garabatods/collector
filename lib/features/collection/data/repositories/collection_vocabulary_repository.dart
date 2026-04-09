import '../../../../core/data/json_map.dart';
import '../../../../core/data/session_cache.dart';
import '../../../../core/data/supabase_repository.dart';
import '../models/tag_model.dart';
import '../models/user_collection_vocabulary.dart';
import 'tags_repository.dart';

class CollectionVocabularyRepository extends SupabaseRepository {
  CollectionVocabularyRepository({super.client});

  static const _cachePrefix = 'collection-vocabulary:';

  TagsRepository get _tagsRepository => TagsRepository(client: client);

  Future<UserCollectionVocabulary> fetch({bool useCache = true}) async {
    final cacheKey = '$_cachePrefix$currentUserId';
    if (useCache) {
      final cached = SessionCache.get<UserCollectionVocabulary>(cacheKey);
      if (cached != null) {
        return cached;
      }
    }

    final collectiblesFuture = client
        .from('collectibles')
        .select('category, brand, franchise, series, line_or_series')
        .eq('user_id', currentUserId);
    final tagsFuture = _tagsRepository.fetchAll();

    final results = await Future.wait<Object>([collectiblesFuture, tagsFuture]);

    final collectibleRows = asJsonList(results[0]);
    final tags = results[1] as List<TagModel>;

    final vocabulary = UserCollectionVocabulary(
      categories: _sortedUniqueStrings(
        collectibleRows.map((row) => asNullableString(row['category'])),
      ),
      brands: _sortedUniqueStrings(
        collectibleRows.map((row) => asNullableString(row['brand'])),
      ),
      franchises: _sortedUniqueStrings(
        collectibleRows.map((row) => asNullableString(row['franchise'])),
      ),
      series: _sortedUniqueStrings(
        collectibleRows.expand(
          (row) => [
            asNullableString(row['series']),
            asNullableString(row['line_or_series']),
          ],
        ),
      ),
      tags: List<TagModel>.from(tags),
    );

    SessionCache.set(cacheKey, vocabulary);
    return vocabulary;
  }

  static void invalidateCache() {
    SessionCache.removeWherePrefix(_cachePrefix);
  }

  List<String> _sortedUniqueStrings(Iterable<String?> values) {
    final unique = values
        .map((value) => normalizeNullableString(value))
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
    unique.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return unique;
  }
}
