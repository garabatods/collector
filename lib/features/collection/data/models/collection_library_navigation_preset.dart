class CollectionLibraryNavigationPreset {
  const CollectionLibraryNavigationPreset({
    this.query = '',
    this.category,
    this.favoritesOnly = false,
    this.hasPhotoOnly = false,
    this.missingPhotoOnly = false,
  });

  final String query;
  final String? category;
  final bool favoritesOnly;
  final bool hasPhotoOnly;
  final bool missingPhotoOnly;

  bool get isEmpty =>
      query.trim().isEmpty &&
      (category ?? '').trim().isEmpty &&
      !favoritesOnly &&
      !hasPhotoOnly &&
      !missingPhotoOnly;
}
