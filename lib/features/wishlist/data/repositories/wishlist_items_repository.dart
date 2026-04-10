import '../../../../core/data/json_map.dart';
import '../../../../core/data/local_archive_database.dart';
import '../../../../core/data/supabase_repository.dart';
import '../models/wishlist_item_model.dart';

class WishlistItemsRepository extends SupabaseRepository {
  WishlistItemsRepository({super.client});

  static final LocalArchiveDatabase _localDatabase =
      LocalArchiveDatabase.instance;

  Future<List<WishlistItemModel>> fetchAll() async {
    final data = await client
        .from('wishlist_items')
        .select()
        .eq('user_id', currentUserId)
        .order('created_at', ascending: false);

    return asJsonList(data)
        .map(WishlistItemModel.fromJson)
        .toList(growable: false);
  }

  Future<WishlistItemModel?> fetchById(String id) async {
    final data = await client
        .from('wishlist_items')
        .select()
        .eq('id', id)
        .eq('user_id', currentUserId)
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return WishlistItemModel.fromJson(asJsonMap(data));
  }

  Future<WishlistItemModel> create(WishlistItemModel item) async {
    await ensureOnlineForWrite();
    final data = await client
        .from('wishlist_items')
        .insert(item.toInsertJson(userId: currentUserId))
        .select()
        .single();

    final created = WishlistItemModel.fromJson(asJsonMap(data));
    await _localDatabase.upsertWishlistItem(created, currentUserId);
    return created;
  }

  Future<WishlistItemModel> update(WishlistItemModel item) async {
    await ensureOnlineForWrite();
    final id = item.id;
    if (id == null) {
      throw ArgumentError('Wishlist item id is required for updates.');
    }

    final data = await client
        .from('wishlist_items')
        .update(item.toUpdateJson())
        .eq('id', id)
        .eq('user_id', currentUserId)
        .select()
        .single();

    final updated = WishlistItemModel.fromJson(asJsonMap(data));
    await _localDatabase.upsertWishlistItem(updated, currentUserId);
    return updated;
  }

  Future<void> delete(String id) async {
    await ensureOnlineForWrite();
    await client
        .from('wishlist_items')
        .delete()
        .eq('id', id)
        .eq('user_id', currentUserId);
    await _localDatabase.deleteWishlistItem(currentUserId, id);
  }
}
