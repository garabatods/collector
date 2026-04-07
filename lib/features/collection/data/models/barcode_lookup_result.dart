class BarcodeLookupResult {
  const BarcodeLookupResult({
    required this.barcode,
    required this.title,
    this.suggestedCategory,
    this.imageUrl,
    this.description,
    this.brand,
    this.rawCategory,
  });

  final String barcode;
  final String title;
  final String? suggestedCategory;
  final String? imageUrl;
  final String? description;
  final String? brand;
  final String? rawCategory;
}
