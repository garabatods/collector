import '../../../../core/data/json_map.dart';
import 'tag_model.dart';

class CollectibleModel {
  const CollectibleModel({
    this.id,
    this.userId,
    this.barcode,
    required this.title,
    required this.category,
    this.description,
    this.brand,
    this.series,
    this.franchise,
    this.lineOrSeries,
    this.characterOrSubject,
    this.releaseYear,
    this.boxStatus,
    this.itemNumber,
    this.itemCondition,
    this.quantity = 1,
    this.purchasePrice,
    this.estimatedValue,
    this.acquiredOn,
    this.notes,
    this.isFavorite = false,
    this.isGrail = false,
    this.isDuplicate = false,
    this.openToTrade = false,
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String? userId;
  final String? barcode;
  final String title;
  final String category;
  final String? description;
  final String? brand;
  final String? series;
  final String? franchise;
  final String? lineOrSeries;
  final String? characterOrSubject;
  final int? releaseYear;
  final String? boxStatus;
  final String? itemNumber;
  final String? itemCondition;
  final int quantity;
  final double? purchasePrice;
  final double? estimatedValue;
  final DateTime? acquiredOn;
  final String? notes;
  final bool isFavorite;
  final bool isGrail;
  final bool isDuplicate;
  final bool openToTrade;
  final List<TagModel> tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CollectibleModel.fromJson(JsonMap json) {
    return CollectibleModel(
      id: asNullableString(json['id']),
      userId: asNullableString(json['user_id']),
      barcode: asNullableString(json['barcode']),
      title: asNullableString(json['title']) ?? '',
      category: asNullableString(json['category']) ?? '',
      description: asNullableString(json['description']),
      brand: asNullableString(json['brand']),
      series: asNullableString(json['series']),
      franchise: asNullableString(json['franchise']),
      lineOrSeries: asNullableString(json['line_or_series']),
      characterOrSubject: asNullableString(json['character_or_subject']),
      releaseYear: asNullableInt(json['release_year']),
      boxStatus: asNullableString(json['box_status']),
      itemNumber: asNullableString(json['item_number']),
      itemCondition: asNullableString(json['item_condition']),
      quantity: asNullableInt(json['quantity']) ?? 1,
      purchasePrice: asNullableDouble(json['purchase_price']),
      estimatedValue: asNullableDouble(json['estimated_value']),
      acquiredOn: asNullableDateTime(json['acquired_on']),
      notes: asNullableString(json['notes']),
      isFavorite: asNullableBool(json['is_favorite']) ?? false,
      isGrail: asNullableBool(json['is_grail']) ?? false,
      isDuplicate: asNullableBool(json['is_duplicate']) ?? false,
      openToTrade: asNullableBool(json['open_to_trade']) ?? false,
      tags: _tagsFromJson(json),
      createdAt: asNullableDateTime(json['created_at']),
      updatedAt: asNullableDateTime(json['updated_at']),
    );
  }

  CollectibleModel copyWith({
    String? id,
    String? userId,
    String? barcode,
    String? title,
    String? category,
    String? description,
    String? brand,
    String? series,
    String? franchise,
    String? lineOrSeries,
    String? characterOrSubject,
    int? releaseYear,
    String? boxStatus,
    String? itemNumber,
    String? itemCondition,
    int? quantity,
    double? purchasePrice,
    double? estimatedValue,
    DateTime? acquiredOn,
    String? notes,
    bool? isFavorite,
    bool? isGrail,
    bool? isDuplicate,
    bool? openToTrade,
    List<TagModel>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CollectibleModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      barcode: barcode ?? this.barcode,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      brand: brand ?? this.brand,
      series: series ?? this.series,
      franchise: franchise ?? this.franchise,
      lineOrSeries: lineOrSeries ?? this.lineOrSeries,
      characterOrSubject: characterOrSubject ?? this.characterOrSubject,
      releaseYear: releaseYear ?? this.releaseYear,
      boxStatus: boxStatus ?? this.boxStatus,
      itemNumber: itemNumber ?? this.itemNumber,
      itemCondition: itemCondition ?? this.itemCondition,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      acquiredOn: acquiredOn ?? this.acquiredOn,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
      isGrail: isGrail ?? this.isGrail,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      openToTrade: openToTrade ?? this.openToTrade,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  JsonMap toInsertJson({required String userId}) {
    return _toWriteJson(includeUserId: true, userId: userId);
  }

  JsonMap toUpdateJson() {
    return _toWriteJson();
  }

  JsonMap _toWriteJson({
    bool includeUserId = false,
    String? userId,
  }) {
    final normalizedSeries = normalizeNullableString(series);
    final normalizedLineOrSeries = normalizeNullableString(lineOrSeries);

    return {
      if (includeUserId) 'user_id': userId,
      'barcode': normalizeNullableString(barcode),
      'title': title.trim(),
      'category': category.trim(),
      'description': normalizeNullableString(description),
      'brand': normalizeNullableString(brand),
      'series': normalizedSeries ?? normalizedLineOrSeries,
      'franchise': normalizeNullableString(franchise),
      'line_or_series': normalizedLineOrSeries ?? normalizedSeries,
      'character_or_subject': normalizeNullableString(characterOrSubject),
      'release_year': releaseYear,
      'box_status': normalizeNullableString(boxStatus),
      'item_number': normalizeNullableString(itemNumber),
      'item_condition': normalizeNullableString(itemCondition),
      'quantity': quantity,
      'purchase_price': purchasePrice,
      'estimated_value': estimatedValue,
      'acquired_on': asDateOnlyString(acquiredOn),
      'notes': normalizeNullableString(notes),
      'is_favorite': isFavorite,
      'is_grail': isGrail,
      'is_duplicate': isDuplicate,
      'open_to_trade': openToTrade,
    };
  }

  static List<TagModel> _tagsFromJson(JsonMap json) {
    final rawCollectibleTags = json['collectible_tags'];
    if (rawCollectibleTags is! List) {
      return const [];
    }

    return rawCollectibleTags
        .map((entry) => entry is JsonMap ? entry : asJsonMap(entry))
        .map((entry) => entry['tag'])
        .where((tag) => tag != null)
        .map((tag) => tag is JsonMap ? tag : asJsonMap(tag))
        .map(TagModel.fromJson)
        .toList(growable: false);
  }
}
