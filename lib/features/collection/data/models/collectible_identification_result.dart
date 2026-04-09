import '../../../../core/data/json_map.dart';

enum CollectibleIdentificationSource { barcode, aiPhoto }

enum CollectibleIdentificationStatus {
  matched,
  enriched,
  partial,
  notFound,
  failed;

  static CollectibleIdentificationStatus fromWire(String? value) {
    return switch (value) {
      'matched' => CollectibleIdentificationStatus.matched,
      'enriched' => CollectibleIdentificationStatus.enriched,
      'partial' => CollectibleIdentificationStatus.partial,
      'failed' => CollectibleIdentificationStatus.failed,
      _ => CollectibleIdentificationStatus.notFound,
    };
  }
}

enum CollectibleIdentificationProviderStage {
  cache,
  upcitemdb,
  goupc,
  openai,
  comicvine;

  static CollectibleIdentificationProviderStage fromWire(String? value) {
    return switch (value) {
      'cache' => CollectibleIdentificationProviderStage.cache,
      'goupc' => CollectibleIdentificationProviderStage.goupc,
      'openai' => CollectibleIdentificationProviderStage.openai,
      'comicvine' => CollectibleIdentificationProviderStage.comicvine,
      _ => CollectibleIdentificationProviderStage.upcitemdb,
    };
  }
}

class CollectibleIdentificationComicContext {
  const CollectibleIdentificationComicContext({
    this.issueNumber,
    this.volumeName,
    this.publisher,
  });

  final String? issueNumber;
  final String? volumeName;
  final String? publisher;

  factory CollectibleIdentificationComicContext.fromJson(JsonMap json) {
    return CollectibleIdentificationComicContext(
      issueNumber: asNullableString(
        json['issue_number'] ?? json['issueNumber'],
      ),
      volumeName: asNullableString(json['volume_name'] ?? json['volumeName']),
      publisher: asNullableString(json['publisher']),
    );
  }
}

class CollectibleIdentificationResult {
  const CollectibleIdentificationResult({
    required this.status,
    required this.providerStage,
    required this.source,
    required this.title,
    required this.sourceBadge,
    this.suggestedCategory,
    this.imageUrl,
    this.description,
    this.brand,
    this.franchise,
    this.series,
    this.characterOrSubject,
    this.releaseYear,
    this.barcode,
    this.confidence,
    this.comicContext,
  });

  final CollectibleIdentificationStatus status;
  final CollectibleIdentificationProviderStage providerStage;
  final CollectibleIdentificationSource source;
  final String title;
  final String sourceBadge;
  final String? suggestedCategory;
  final String? imageUrl;
  final String? description;
  final String? brand;
  final String? franchise;
  final String? series;
  final String? characterOrSubject;
  final int? releaseYear;
  final String? barcode;
  final double? confidence;
  final CollectibleIdentificationComicContext? comicContext;

  bool get hasCatalogMatch =>
      status == CollectibleIdentificationStatus.matched ||
      status == CollectibleIdentificationStatus.enriched ||
      status == CollectibleIdentificationStatus.partial;

  bool get isNotFound => status == CollectibleIdentificationStatus.notFound;

  bool get isFailure => status == CollectibleIdentificationStatus.failed;

  bool get hasPrefillData =>
      title.trim().isNotEmpty ||
      (suggestedCategory ?? '').trim().isNotEmpty ||
      (brand ?? '').trim().isNotEmpty;

  bool get isComicLike =>
      (suggestedCategory ?? '').trim().toLowerCase() == 'comics' ||
      comicContext != null ||
      providerStage == CollectibleIdentificationProviderStage.comicvine;

  String? get publisherCandidate => comicContext?.publisher ?? brand;

  String? get volumeCandidate => comicContext?.volumeName ?? series;

  String? get issueNumber => comicContext?.issueNumber;

  factory CollectibleIdentificationResult.fromJson(
    JsonMap json, {
    required CollectibleIdentificationSource source,
  }) {
    final rawComicContext = json['comic_context'] ?? json['comicContext'];
    return CollectibleIdentificationResult(
      status: CollectibleIdentificationStatus.fromWire(
        asNullableString(json['status']),
      ),
      providerStage: CollectibleIdentificationProviderStage.fromWire(
        asNullableString(json['provider_stage'] ?? json['providerStage']),
      ),
      source: source,
      title: asNullableString(json['title']) ?? '',
      sourceBadge:
          asNullableString(json['source_badge'] ?? json['sourceBadge']) ??
          'Catalog match',
      suggestedCategory: asNullableString(
        json['suggested_category'] ?? json['suggestedCategory'],
      ),
      imageUrl: asNullableString(json['image_url'] ?? json['imageUrl']),
      description: asNullableString(json['description']),
      brand: asNullableString(json['brand']),
      franchise: asNullableString(json['franchise']),
      series: asNullableString(json['series']),
      characterOrSubject: asNullableString(
        json['character_or_subject'] ?? json['characterOrSubject'],
      ),
      releaseYear: asNullableInt(json['release_year'] ?? json['releaseYear']),
      barcode: asNullableString(json['barcode']),
      confidence: asNullableDouble(json['confidence']),
      comicContext: rawComicContext == null
          ? null
          : CollectibleIdentificationComicContext.fromJson(
              asJsonMap(rawComicContext),
            ),
    );
  }
}
