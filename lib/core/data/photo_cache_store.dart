import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/collection/data/models/collectible_photo_model.dart';
import 'local_archive_database.dart';

class PhotoCacheStore {
  PhotoCacheStore._({
    required LocalArchiveDatabase database,
    SupabaseClient? client,
  })  : _database = database,
        _client = client ?? Supabase.instance.client;

  static final PhotoCacheStore instance = PhotoCacheStore._(
    database: LocalArchiveDatabase.instance,
  );

  static const maxCacheBytes = 500 * 1024 * 1024;
  static const _remoteUrlTtl = Duration(minutes: 45);
  static const _downloadConcurrency = 3;

  final LocalArchiveDatabase _database;
  final SupabaseClient _client;

  Future<void> reconcilePrimaryPhotos(
    String userId,
    List<CollectiblePhotoModel> photos,
  ) async {
    final primaryPhotos = photos.where((photo) => photo.isPrimary).toList(growable: false);
    if (primaryPhotos.isEmpty) {
      return;
    }

    final existingEntries = {
      for (final entry in await _database.getPhotoCacheEntries(userId)) entry.photoId: entry,
    };
    final stalePhotoIds = existingEntries.keys
        .where(
          (photoId) => !primaryPhotos.any((photo) => photo.id == photoId),
        )
        .toList(growable: false);
    for (final photoId in stalePhotoIds) {
      final entry = existingEntries[photoId];
      if (entry != null) {
        await _deleteLocalFile(entry.localPath);
      }
      await _database.deletePhotoCacheEntry(photoId);
    }

    final work = <Future<void>>[];
    for (final photo in primaryPhotos) {
      work.add(_ensureCached(userId, photo, existingEntries[photo.id]));
      if (work.length == _downloadConcurrency) {
        await Future.wait(work);
        work.clear();
      }
    }
    if (work.isNotEmpty) {
      await Future.wait(work);
    }

    await _pruneIfNeeded(userId);
  }

  Future<void> seedPrimaryPhotoFromFile({
    required String userId,
    required CollectiblePhotoModel photo,
    required String sourcePath,
  }) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      return;
    }
    final targetFile = await _targetFileForPhoto(userId, photo);
    await targetFile.parent.create(recursive: true);
    await sourceFile.copy(targetFile.path);
    final length = await targetFile.length();
    await _database.upsertPhotoCacheEntry(
      LocalPhotoCacheEntry(
        photoId: photo.id!,
        userId: userId,
        collectibleId: photo.collectibleId,
        storagePath: photo.storagePath,
        localPath: targetFile.path,
        byteSize: length,
        photoUpdatedAt: photo.updatedAt ?? photo.createdAt,
        lastTouchedAt: DateTime.now(),
      ),
    );
    await _pruneIfNeeded(userId);
  }

  Future<void> seedPrimaryPhotoFromBytes({
    required String userId,
    required CollectiblePhotoModel photo,
    required Uint8List bytes,
  }) async {
    final targetFile = await _targetFileForPhoto(userId, photo);
    await targetFile.parent.create(recursive: true);
    await targetFile.writeAsBytes(bytes, flush: true);
    await _database.upsertPhotoCacheEntry(
      LocalPhotoCacheEntry(
        photoId: photo.id!,
        userId: userId,
        collectibleId: photo.collectibleId,
        storagePath: photo.storagePath,
        localPath: targetFile.path,
        byteSize: bytes.lengthInBytes,
        photoUpdatedAt: photo.updatedAt ?? photo.createdAt,
        lastTouchedAt: DateTime.now(),
      ),
    );
    await _pruneIfNeeded(userId);
  }

  Future<void> removeForCollectible(String userId, String collectibleId) async {
    final entries = (await _database.getPhotoCacheEntries(userId))
        .where((entry) => entry.collectibleId == collectibleId)
        .toList(growable: false);
    for (final entry in entries) {
      await _deleteLocalFile(entry.localPath);
      await _database.deletePhotoCacheEntry(entry.photoId);
    }
  }

  Future<void> _ensureCached(
    String userId,
    CollectiblePhotoModel photo,
    LocalPhotoCacheEntry? existingEntry,
  ) async {
    final photoId = photo.id;
    if (photoId == null || photoId.isEmpty) {
      return;
    }

    final localPath = existingEntry?.localPath;
    final hasFreshLocalFile = localPath != null &&
        localPath.isNotEmpty &&
        await File(localPath).exists() &&
        existingEntry?.storagePath == photo.storagePath &&
        existingEntry?.photoUpdatedAt == (photo.updatedAt ?? photo.createdAt);
    if (hasFreshLocalFile) {
      await _database.upsertPhotoCacheEntry(
        LocalPhotoCacheEntry(
          photoId: photoId,
          userId: userId,
          collectibleId: photo.collectibleId,
          storagePath: photo.storagePath,
          localPath: localPath,
          remoteUrl: existingEntry?.remoteUrl,
          remoteUrlExpiresAt: existingEntry?.remoteUrlExpiresAt,
          byteSize: existingEntry?.byteSize,
          photoUpdatedAt: photo.updatedAt ?? photo.createdAt,
          lastTouchedAt: DateTime.now(),
        ),
      );
      return;
    }

    final remoteUrl = await _client.storage
        .from(photo.storageBucket)
        .createSignedUrl(photo.storagePath, _remoteUrlTtl.inSeconds);
    final remoteUrlExpiresAt = DateTime.now().add(_remoteUrlTtl);

    await _database.upsertPhotoCacheEntry(
      LocalPhotoCacheEntry(
        photoId: photoId,
        userId: userId,
        collectibleId: photo.collectibleId,
        storagePath: photo.storagePath,
        localPath: existingEntry?.localPath,
        remoteUrl: remoteUrl,
        remoteUrlExpiresAt: remoteUrlExpiresAt,
        byteSize: existingEntry?.byteSize,
        photoUpdatedAt: photo.updatedAt ?? photo.createdAt,
        lastTouchedAt: DateTime.now(),
      ),
    );

    try {
      final response = await http.get(Uri.parse(remoteUrl));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return;
      }
      await seedPrimaryPhotoFromBytes(
        userId: userId,
        photo: photo,
        bytes: response.bodyBytes,
      );
      await _database.upsertPhotoCacheEntry(
        LocalPhotoCacheEntry(
          photoId: photoId,
          userId: userId,
          collectibleId: photo.collectibleId,
          storagePath: photo.storagePath,
          localPath: (await _targetFileForPhoto(userId, photo)).path,
          remoteUrl: remoteUrl,
          remoteUrlExpiresAt: remoteUrlExpiresAt,
          byteSize: response.bodyBytes.lengthInBytes,
          photoUpdatedAt: photo.updatedAt ?? photo.createdAt,
          lastTouchedAt: DateTime.now(),
        ),
      );
    } catch (_) {
      // Keep the signed URL fallback when the download cannot complete.
    }
  }

  Future<void> _pruneIfNeeded(String userId) async {
    final entries = await _database.getPhotoCacheEntries(userId);
    final candidates = <LocalPhotoCacheEntry>[];
    var totalBytes = 0;
    for (final entry in entries) {
      final localPath = entry.localPath;
      if (localPath == null || localPath.isEmpty) {
        continue;
      }
      final file = File(localPath);
      if (!await file.exists()) {
        continue;
      }
      final size = entry.byteSize ?? await file.length();
      totalBytes += size;
      candidates.add(
        LocalPhotoCacheEntry(
          photoId: entry.photoId,
          userId: entry.userId,
          collectibleId: entry.collectibleId,
          storagePath: entry.storagePath,
          localPath: localPath,
          remoteUrl: entry.remoteUrl,
          remoteUrlExpiresAt: entry.remoteUrlExpiresAt,
          byteSize: size,
          photoUpdatedAt: entry.photoUpdatedAt,
          lastTouchedAt: entry.lastTouchedAt,
        ),
      );
    }

    if (totalBytes <= maxCacheBytes) {
      return;
    }

    candidates.sort((a, b) {
      final aTouched = a.lastTouchedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTouched = b.lastTouchedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aTouched.compareTo(bTouched);
    });

    for (final entry in candidates) {
      if (totalBytes <= maxCacheBytes) {
        break;
      }
      totalBytes -= entry.byteSize ?? 0;
      await _deleteLocalFile(entry.localPath);
      await _database.upsertPhotoCacheEntry(
        LocalPhotoCacheEntry(
          photoId: entry.photoId,
          userId: entry.userId,
          collectibleId: entry.collectibleId,
          storagePath: entry.storagePath,
          remoteUrl: entry.remoteUrl,
          remoteUrlExpiresAt: entry.remoteUrlExpiresAt,
          photoUpdatedAt: entry.photoUpdatedAt,
          lastTouchedAt: DateTime.now(),
        ),
      );
    }
  }

  Future<File> _targetFileForPhoto(String userId, CollectiblePhotoModel photo) async {
    final root = await _photoCacheDirectory(userId);
    final extension = _extensionForPath(photo.storagePath);
    return File(
      p.join(root.path, '${photo.collectibleId}_${photo.id}$extension'),
    );
  }

  Future<Directory> _photoCacheDirectory(String userId) async {
    final directory = await getApplicationSupportDirectory();
    return Directory(p.join(directory.path, 'archive_photo_cache', userId));
  }

  String _extensionForPath(String storagePath) {
    final extension = p.extension(storagePath).trim();
    return extension.isEmpty ? '.jpg' : extension;
  }

  Future<void> _deleteLocalFile(String? path) async {
    final normalized = path?.trim();
    if (normalized == null || normalized.isEmpty) {
      return;
    }
    final file = File(normalized);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
