import '../../../../core/data/json_map.dart';
import '../../../../core/data/supabase_repository.dart';
import '../models/wishlist_item_model.dart';

class WishlistItemsRepository extends SupabaseRepository {
  WishlistItemsRepository({super.client});

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
    final data = await client
        .from('wishlist_items')
        .insert(item.toInsertJson(userId: currentUserId))
        .select()
        .single();

    return WishlistItemModel.fromJson(asJsonMap(data));
  }

  Future<WishlistItemModel> update(WishlistItemModel item) async {
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

    return WishlistItemModel.fromJson(asJsonMap(data));
  }

  Future<void> delete(String id) async {
    await client
        .from('wishlist_items')
        .delete()
        .eq('id', id)
        .eq('user_id', currentUserId);
  }
}
