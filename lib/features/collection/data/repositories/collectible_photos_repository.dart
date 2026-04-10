import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/json_map.dart';
import '../../../../core/data/local_archive_database.dart';
import '../../../../core/data/photo_cache_store.dart';
import '../../../../core/data/supabase_repository.dart';
import '../models/collectible_photo_model.dart';

class CollectiblePhotosRepository extends SupabaseRepository {
  CollectiblePhotosRepository({super.client});

  static final LocalArchiveDatabase _localDatabase =
      LocalArchiveDatabase.instance;
  static final PhotoCacheStore _photoCacheStore = PhotoCacheStore.instance;

  Future<CollectiblePhotoModel> uploadPrimaryPhoto({
    required String collectibleId,
    required String localImagePath,
    required String originalFileName,
    String? caption,
  }) async {
    await ensureOnlineForWrite();
    final storagePath = buildPrimaryStoragePath(
      userId: currentUserId,
      collectibleId: collectibleId,
      originalFileName: originalFileName,
    );

    await client.storage.from(CollectiblePhotoModel.defaultStorageBucket).upload(
          storagePath,
          File(localImagePath),
          fileOptions: FileOptions(
            upsert: false,
            contentType: contentTypeForFileName(originalFileName),
          ),
        );

    try {
      final created = await create(
        CollectiblePhotoModel(
          collectibleId: collectibleId,
          storagePath: storagePath,
          caption: caption,
          isPrimary: true,
          displayOrder: 0,
        ),
      );
      await _photoCacheStore.seedPrimaryPhotoFromFile(
        userId: currentUserId,
        photo: created,
        sourcePath: localImagePath,
      );
      return created;
    } catch (_) {
      await _removeUploadedObject(storagePath);
      rethrow;
    }
  }

  Future<CollectiblePhotoModel> replacePrimaryPhoto({
    required String collectibleId,
    required String localImagePath,
    required String originalFileName,
    String? caption,
  }) async {
    await ensureOnlineForWrite();
    await deleteAllForCollectible(collectibleId);

    return uploadPrimaryPhoto(
      collectibleId: collectibleId,
      localImagePath: localImagePath,
      originalFileName: originalFileName,
      caption: caption,
    );
  }

  Future<CollectiblePhotoModel> uploadPrimaryPhotoFromRemoteImage({
    required String collectibleId,
    required String imageUrl,
    required String fallbackFileName,
    String? caption,
  }) async {
    await ensureOnlineForWrite();
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const StorageException('Could not download the suggested image.');
    }

    final contentTypeHeader = response.headers['content-type'] ?? '';
    final contentType = _normalizedRemoteContentType(contentTypeHeader);
    final fileName = _remoteFileName(
      imageUrl: imageUrl,
      fallbackFileName: fallbackFileName,
      contentType: contentType,
    );

    final created = await uploadPrimaryPhotoBytes(
      collectibleId: collectibleId,
      imageBytes: response.bodyBytes,
      originalFileName: fileName,
      contentType: contentType,
      caption: caption,
    );
    await _photoCacheStore.seedPrimaryPhotoFromBytes(
      userId: currentUserId,
      photo: created,
      bytes: response.bodyBytes,
    );
    return created;
  }

  Future<CollectiblePhotoModel> uploadPrimaryPhotoBytes({
    required String collectibleId,
    required Uint8List imageBytes,
    required String originalFileName,
    String? contentType,
    String? caption,
  }) async {
    await ensureOnlineForWrite();
    final storagePath = buildPrimaryStoragePath(
      userId: currentUserId,
      collectibleId: collectibleId,
      originalFileName: originalFileName,
    );

    await client.storage
        .from(CollectiblePhotoModel.defaultStorageBucket)
        .uploadBinary(
          storagePath,
          imageBytes,
          fileOptions: FileOptions(
            upsert: false,
            contentType: contentType ?? contentTypeForFileName(originalFileName),
          ),
        );

    try {
      final created = await create(
        CollectiblePhotoModel(
          collectibleId: collectibleId,
          storagePath: storagePath,
          caption: caption,
          isPrimary: true,
          displayOrder: 0,
        ),
      );
      await _photoCacheStore.seedPrimaryPhotoFromBytes(
        userId: currentUserId,
        photo: created,
        bytes: imageBytes,
      );
      return created;
    } catch (_) {
      await _removeUploadedObject(storagePath);
      rethrow;
    }
  }

  static String buildPrimaryStoragePath({
    required String userId,
    required String collectibleId,
    required String originalFileName,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = _normalizedImageExtension(originalFileName);
    return '$userId/$collectibleId/primary-$timestamp$extension';
  }

  static String contentTypeForFileName(String fileName) {
    final extension = _fileExtension(fileName);

    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  Future<Map<String, CollectiblePhotoModel>> fetchPrimaryPhotoMap(
    List<String> collectibleIds,
  ) async {
    if (collectibleIds.isEmpty) {
      return const {};
    }

    final data = await client
        .from('collectible_photos')
        .select()
        .inFilter('collectible_id', collectibleIds)
        .order('is_primary', ascending: false)
        .order('display_order')
        .order('created_at');

    final photos = asJsonList(data)
        .map(CollectiblePhotoModel.fromJson)
        .toList(growable: false);

    final primaryByCollectible = <String, CollectiblePhotoModel>{};
    for (final photo in photos) {
      primaryByCollectible.putIfAbsent(photo.collectibleId, () => photo);
    }

    return primaryByCollectible;
  }

  Future<String?> createSignedPhotoUrl(
    CollectiblePhotoModel photo, {
    int expiresInSeconds = 60 * 60,
  }) async {
    if (photo.storagePath.isEmpty) {
      return null;
    }

    return client.storage
        .from(photo.storageBucket)
        .createSignedUrl(photo.storagePath, expiresInSeconds);
  }

  Future<List<CollectiblePhotoModel>> fetchByCollectibleId(
    String collectibleId,
  ) async {
    final data = await client
        .from('collectible_photos')
        .select()
        .eq('collectible_id', collectibleId)
        .order('is_primary', ascending: false)
        .order('display_order')
        .order('created_at');

    return asJsonList(data)
        .map(CollectiblePhotoModel.fromJson)
        .toList(growable: false);
  }

  Future<CollectiblePhotoModel?> fetchById(String id) async {
    final data = await client
        .from('collectible_photos')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return CollectiblePhotoModel.fromJson(asJsonMap(data));
  }

  Future<CollectiblePhotoModel> create(CollectiblePhotoModel photo) async {
    await ensureOnlineForWrite();
    final data = await client
        .from('collectible_photos')
        .insert(photo.toInsertJson())
        .select()
        .single();

    final created = CollectiblePhotoModel.fromJson(asJsonMap(data));
    await _localDatabase.upsertPhoto(created, currentUserId);
    return created;
  }

  Future<CollectiblePhotoModel> update(CollectiblePhotoModel photo) async {
    await ensureOnlineForWrite();
    final id = photo.id;
    if (id == null) {
      throw ArgumentError('Collectible photo id is required for updates.');
    }

    final data = await client
        .from('collectible_photos')
        .update(photo.toUpdateJson())
        .eq('id', id)
        .select()
        .single();

    final updated = CollectiblePhotoModel.fromJson(asJsonMap(data));
    await _localDatabase.upsertPhoto(updated, currentUserId);
    return updated;
  }

  Future<void> delete(String id) async {
    await ensureOnlineForWrite();
    await client.from('collectible_photos').delete().eq('id', id);
    await _localDatabase.deletePhotoCacheEntry(id);
  }

  Future<void> deleteAllForCollectible(String collectibleId) async {
    await ensureOnlineForWrite();
    final photos = await fetchByCollectibleId(collectibleId);
    if (photos.isEmpty) {
      return;
    }

    final storagePathsByBucket = <String, List<String>>{};
    for (final photo in photos) {
      if (photo.storagePath.isEmpty) {
        continue;
      }

      storagePathsByBucket
          .putIfAbsent(photo.storageBucket, () => <String>[])
          .add(photo.storagePath);
    }

    for (final entry in storagePathsByBucket.entries) {
      if (entry.value.isEmpty) {
        continue;
      }

      try {
        await client.storage.from(entry.key).remove(entry.value);
      } catch (_) {
        // Keep delete resilient even if some storage objects are already gone.
      }
    }

    await client
        .from('collectible_photos')
        .delete()
        .eq('collectible_id', collectibleId);
    await _localDatabase.replacePhotosForCollectible(
      currentUserId,
      collectibleId,
      const [],
    );
    await _photoCacheStore.removeForCollectible(currentUserId, collectibleId);
  }

  Future<void> _removeUploadedObject(String storagePath) async {
    try {
      await client.storage
          .from(CollectiblePhotoModel.defaultStorageBucket)
          .remove([storagePath]);
    } catch (_) {
      // Keep the original photo-linking error as the primary failure.
    }
  }

  static String _normalizedImageExtension(String fileName) {
    final extension = _fileExtension(fileName);

    switch (extension) {
      case 'png':
        return '.png';
      case 'webp':
        return '.webp';
      case 'heic':
        return '.heic';
      case 'heif':
        return '.heif';
      case 'jpg':
      case 'jpeg':
        return '.$extension';
      default:
        return '.jpg';
    }
  }

  static String _fileExtension(String fileName) {
    final normalized = fileName.trim().toLowerCase();
    final lastDot = normalized.lastIndexOf('.');
    if (lastDot == -1 || lastDot == normalized.length - 1) {
      return '';
    }

    return normalized.substring(lastDot + 1);
  }

  static String _normalizedRemoteContentType(String contentTypeHeader) {
    final normalized = contentTypeHeader.toLowerCase();
    if (normalized.contains('image/png')) {
      return 'image/png';
    }

    if (normalized.contains('image/webp')) {
      return 'image/webp';
    }

    if (normalized.contains('image/heic')) {
      return 'image/heic';
    }

    if (normalized.contains('image/heif')) {
      return 'image/heif';
    }

    return 'image/jpeg';
  }

  static String _remoteFileName({
    required String imageUrl,
    required String fallbackFileName,
    required String contentType,
  }) {
    final parsedUrl = Uri.tryParse(imageUrl);
    final pathSegment = parsedUrl?.pathSegments.isNotEmpty == true
        ? parsedUrl!.pathSegments.last
        : fallbackFileName;
    final extension = _fileExtension(pathSegment);
    if (extension.isNotEmpty) {
      return pathSegment;
    }

    final fallbackExtension = switch (contentType) {
      'image/png' => '.png',
      'image/webp' => '.webp',
      'image/heic' => '.heic',
      'image/heif' => '.heif',
      _ => '.jpg',
    };

    final trimmedFallback = fallbackFileName.trim();
    final normalizedFallback =
        trimmedFallback.isEmpty ? 'lookup-image' : trimmedFallback;
    return '$normalizedFallback$fallbackExtension';
  }
}
