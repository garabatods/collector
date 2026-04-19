import '../../../collection/data/models/collection_library_navigation_preset.dart';

enum HomeCollectionInsightFamily {
  identity,
  momentum,
  curation,
  care,
  value,
  milestone,
}

enum HomeCollectionInsightAccent { violet, azure, emerald, amber, rose, warm }

enum HomeCollectionInsightActionType {
  openLibrary,
  openCategory,
  scrollToRecent,
  scrollToFavorites,
}

class HomeCollectionInsightAction {
  const HomeCollectionInsightAction({
    required this.type,
    required this.label,
    this.category,
    this.query,
    this.favoritesOnly = false,
    this.hasPhotoOnly = false,
    this.missingPhotoOnly = false,
  });

  final HomeCollectionInsightActionType type;
  final String label;
  final String? category;
  final String? query;
  final bool favoritesOnly;
  final bool hasPhotoOnly;
  final bool missingPhotoOnly;

  CollectionLibraryNavigationPreset toLibraryNavigationPreset() {
    return CollectionLibraryNavigationPreset(
      query: query ?? '',
      category: category,
      favoritesOnly: favoritesOnly,
      hasPhotoOnly: hasPhotoOnly,
      missingPhotoOnly: missingPhotoOnly,
    );
  }
}

class HomeCollectionInsight {
  const HomeCollectionInsight({
    required this.id,
    required this.family,
    required this.accent,
    required this.headline,
    required this.supportingText,
    required this.score,
    this.compactEyebrow,
    this.compactValue,
    this.compactSupportingText,
    this.primaryEntityKey,
    this.action,
  });

  final String id;
  final HomeCollectionInsightFamily family;
  final HomeCollectionInsightAccent accent;
  final String headline;
  final String supportingText;
  final int score;
  final String? compactEyebrow;
  final String? compactValue;
  final String? compactSupportingText;
  final String? primaryEntityKey;
  final HomeCollectionInsightAction? action;
}
