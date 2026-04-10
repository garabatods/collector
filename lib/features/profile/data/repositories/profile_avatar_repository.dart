import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/supabase_repository.dart';
import '../../../collection/data/repositories/collectible_photos_repository.dart';

class ProfileAvatarRepository extends SupabaseRepository {
  ProfileAvatarRepository({super.client});

  static const storageBucket = 'collectible-photos';

  Future<String> uploadAvatar({
    required String localImagePath,
    required String originalFileName,
    String? previousStoragePath,
  }) async {
    await ensureOnlineForWrite();
    final storagePath = _buildAvatarStoragePath(
      userId: currentUserId,
      originalFileName: originalFileName,
    );

    await client.storage.from(storageBucket).upload(
          storagePath,
          File(localImagePath),
          fileOptions: FileOptions(
            upsert: false,
            contentType: CollectiblePhotosRepository.contentTypeForFileName(
              originalFileName,
            ),
          ),
        );

    if (_isStoragePath(previousStoragePath) && previousStoragePath != storagePath) {
      try {
        await client.storage.from(storageBucket).remove([previousStoragePath!]);
      } catch (_) {
        // Keep avatar replacement resilient if the old object is already gone.
      }
    }

    return storagePath;
  }

  Future<String?> resolveAvatarUrl(
    String? avatarUrlOrPath, {
    int expiresInSeconds = 60 * 60,
  }) async {
    final value = avatarUrlOrPath?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    if (_isRemoteUrl(value)) {
      return value;
    }

    return client.storage
        .from(storageBucket)
        .createSignedUrl(value, expiresInSeconds);
  }

  static String _buildAvatarStoragePath({
    required String userId,
    required String originalFileName,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = _normalizedImageExtension(originalFileName);
    return '$userId/profile/avatar-$timestamp$extension';
  }

  static bool _isRemoteUrl(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return false;
    }

    final uri = Uri.tryParse(trimmed);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  static bool _isStoragePath(String? value) => !_isRemoteUrl(value) && (value?.trim().isNotEmpty ?? false);

  static String _normalizedImageExtension(String fileName) {
    final normalized = fileName.trim().toLowerCase();
    final lastDot = normalized.lastIndexOf('.');
    if (lastDot == -1 || lastDot == normalized.length - 1) {
      return '.jpg';
    }

    final extension = normalized.substring(lastDot);
    return switch (extension) {
      '.png' => '.png',
      '.webp' => '.webp',
      '.heic' => '.heic',
      '.heif' => '.heif',
      '.jpeg' => '.jpeg',
      '.jpg' => '.jpg',
      _ => '.jpg',
    };
  }
}
