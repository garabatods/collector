import '../../../../core/data/json_map.dart';

class TagModel {
  const TagModel({
    this.id,
    this.userId,
    required this.name,
    this.createdAt,
  });

  final String? id;
  final String? userId;
  final String name;
  final DateTime? createdAt;

  factory TagModel.fromJson(JsonMap json) {
    return TagModel(
      id: asNullableString(json['id']),
      userId: asNullableString(json['user_id']),
      name: asNullableString(json['name']) ?? '',
      createdAt: asNullableDateTime(json['created_at']),
    );
  }

  JsonMap toInsertJson({required String userId}) {
    return {
      'user_id': userId,
      'name': name.trim(),
    };
  }
}
