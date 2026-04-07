import '../../../../core/data/json_map.dart';

class WishlistItemModel {
  const WishlistItemModel({
    this.id,
    this.userId,
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
    this.priority = defaultPriority,
    this.targetPrice,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  static const defaultPriority = 'medium';

  final String? id;
  final String? userId;
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
  final String priority;
  final double? targetPrice;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory WishlistItemModel.fromJson(JsonMap json) {
    return WishlistItemModel(
      id: asNullableString(json['id']),
      userId: asNullableString(json['user_id']),
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
      priority: asNullableString(json['priority']) ?? defaultPriority,
      targetPrice: asNullableDouble(json['target_price']),
      notes: asNullableString(json['notes']),
      createdAt: asNullableDateTime(json['created_at']),
      updatedAt: asNullableDateTime(json['updated_at']),
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
      'priority': priority.trim(),
      'target_price': targetPrice,
      'notes': normalizeNullableString(notes),
    };
  }
}
