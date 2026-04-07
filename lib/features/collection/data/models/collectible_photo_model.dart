import '../../../../core/data/json_map.dart';

class CollectiblePhotoModel {
  const CollectiblePhotoModel({
    this.id,
    required this.collectibleId,
    this.storageBucket = defaultStorageBucket,
    required this.storagePath,
    this.caption,
    this.isPrimary = false,
    this.displayOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  static const defaultStorageBucket = 'collectible-photos';

  final String? id;
  final String collectibleId;
  final String storageBucket;
  final String storagePath;
  final String? caption;
  final bool isPrimary;
  final int displayOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CollectiblePhotoModel.fromJson(JsonMap json) {
    return CollectiblePhotoModel(
      id: asNullableString(json['id']),
      collectibleId: asNullableString(json['collectible_id']) ?? '',
      storageBucket:
          asNullableString(json['storage_bucket']) ?? defaultStorageBucket,
      storagePath: asNullableString(json['storage_path']) ?? '',
      caption: asNullableString(json['caption']),
      isPrimary: asNullableBool(json['is_primary']) ?? false,
      displayOrder: asNullableInt(json['display_order']) ?? 0,
      createdAt: asNullableDateTime(json['created_at']),
      updatedAt: asNullableDateTime(json['updated_at']),
    );
  }

  JsonMap toInsertJson() {
    return {
      'collectible_id': collectibleId,
      'storage_bucket': storageBucket,
      'storage_path': storagePath.trim(),
      'caption': normalizeNullableString(caption),
      'is_primary': isPrimary,
      'display_order': displayOrder,
    };
  }

  JsonMap toUpdateJson() {
    return {
      'storage_bucket': storageBucket,
      'storage_path': storagePath.trim(),
      'caption': normalizeNullableString(caption),
      'is_primary': isPrimary,
      'display_order': displayOrder,
    };
  }
}
