import '../../../../core/data/json_map.dart';

class ProfileModel {
  const ProfileModel({
    this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ProfileModel.fromJson(JsonMap json) {
    return ProfileModel(
      id: asNullableString(json['id']),
      username: asNullableString(json['username']),
      displayName: asNullableString(json['display_name']),
      avatarUrl: asNullableString(json['avatar_url']),
      bio: asNullableString(json['bio']),
      createdAt: asNullableDateTime(json['created_at']),
      updatedAt: asNullableDateTime(json['updated_at']),
    );
  }

  JsonMap toUpsertJson({required String userId}) {
    return {
      'id': userId,
      'username': normalizeNullableString(username),
      'display_name': normalizeNullableString(displayName),
      'avatar_url': normalizeNullableString(avatarUrl),
      'bio': normalizeNullableString(bio),
    };
  }
}
