import 'collectible_model.dart';

enum CollectibleDetailSource { library, category, homeRecent, homeFavorites }

class CollectibleDetailNavigationContext {
  const CollectibleDetailNavigationContext({
    required this.source,
    required this.collectibleIds,
    required this.initialIndex,
    this.categoryLabel,
  });

  final CollectibleDetailSource source;
  final List<String> collectibleIds;
  final int initialIndex;
  final String? categoryLabel;

  bool get canSwipe => collectibleIds.length > 1;

  String get sourceLabel => switch (source) {
    CollectibleDetailSource.library => 'Library',
    CollectibleDetailSource.category =>
      (categoryLabel?.trim().isNotEmpty ?? false)
          ? categoryLabel!.trim()
          : 'Category',
    CollectibleDetailSource.homeRecent => 'Recently Added',
    CollectibleDetailSource.homeFavorites => 'Favorites',
  };

  static CollectibleDetailNavigationContext? fromCollectibles({
    required CollectibleDetailSource source,
    required List<CollectibleModel> collectibles,
    required CollectibleModel currentCollectible,
    String? categoryLabel,
  }) {
    final currentId = currentCollectible.id;
    if (currentId == null || currentId.isEmpty) {
      return null;
    }

    final collectibleIds = collectibles
        .map((item) => item.id)
        .whereType<String>()
        .where((id) => id.trim().isNotEmpty)
        .toList(growable: false);

    final initialIndex = collectibleIds.indexOf(currentId);
    if (initialIndex == -1 || collectibleIds.length < 2) {
      return null;
    }

    return CollectibleDetailNavigationContext(
      source: source,
      collectibleIds: collectibleIds,
      initialIndex: initialIndex,
      categoryLabel: categoryLabel,
    );
  }
}
