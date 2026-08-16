import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/json_map.dart';
import '../../../../core/data/session_cache.dart';
import '../../../../core/data/supabase_repository.dart';
import '../models/collectible_identification_result.dart';

class CollectibleIdentificationRepository extends SupabaseRepository {
  CollectibleIdentificationRepository({super.client});

  static const _cachePrefix = 'identification:';
  static const _photoCacheVersion = 'luna-terra-v1';
  static const _acceptedPhotoMimeTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/heic',
    'image/heif',
  };

  Future<CollectibleIdentificationResult> identifyBarcode(
    String barcode,
  ) async {
    final normalizedBarcode = _normalizeBarcode(barcode);
    if (normalizedBarcode.isEmpty) {
      return const CollectibleIdentificationResult(
        status: CollectibleIdentificationStatus.notFound,
        providerStage: CollectibleIdentificationProviderStage.upcitemdb,
        source: CollectibleIdentificationSource.barcode,
        title: '',
        sourceBadge: 'No catalog match',
      );
    }

    final cacheKey = '${_cachePrefix}barcode:$normalizedBarcode';
    final cached = SessionCache.get<CollectibleIdentificationResult>(cacheKey);
    if (cached != null && !_shouldRefreshBarcodeResult(cached)) {
      return cached;
    }

    try {
      final response = await _invokeIdentifyCollectible(
        body: {
          'mode': 'barcode',
          'barcode': normalizedBarcode,
          'request_id': _newRequestId(),
        },
      );

      final result = CollectibleIdentificationResult.fromJson(
        asJsonMap(response.data),
        source: CollectibleIdentificationSource.barcode,
      );
      SessionCache.set(cacheKey, result);
      return result;
    } on FunctionException catch (error) {
      throw CollectibleIdentificationException(
        _messageFromFunctionException(error) ??
            'Could not identify that barcode right now.',
      );
    } catch (_) {
      throw const CollectibleIdentificationException(
        'Could not identify that barcode right now.',
      );
    }
  }

  Future<CollectibleIdentificationResult> identifyPhoto({
    required Uint8List imageBytes,
    required String mimeType,
    String? barcode,
  }) async {
    var normalizedMimeType = mimeType.trim().toLowerCase();
    if (imageBytes.isEmpty ||
        !_acceptedPhotoMimeTypes.contains(normalizedMimeType)) {
      throw const CollectibleIdentificationException(
        'Choose a JPEG, PNG, WebP, HEIC, or HEIF photo.',
      );
    }
    var uploadBytes = imageBytes;
    if (normalizedMimeType == 'image/heic' ||
        normalizedMimeType == 'image/heif' ||
        uploadBytes.lengthInBytes > 8 * 1024 * 1024) {
      uploadBytes = await FlutterImageCompress.compressWithList(
        uploadBytes,
        minWidth: 2400,
        minHeight: 2400,
        quality: 90,
        format: CompressFormat.jpeg,
      );
      normalizedMimeType = 'image/jpeg';
    }
    if (uploadBytes.lengthInBytes > 8 * 1024 * 1024) {
      throw const CollectibleIdentificationException(
        'Choose a photo that is 8 MB or smaller.',
      );
    }

    final fingerprint = sha256.convert(uploadBytes).toString();
    final cacheKey = '${_cachePrefix}photo:$_photoCacheVersion:$fingerprint';
    final cached = SessionCache.get<CollectibleIdentificationResult>(cacheKey);
    if (cached != null) {
      return cached;
    }

    try {
      final response = await _invokeIdentifyCollectible(
        body: {
          'mode': 'photo',
          'image_base64': base64Encode(uploadBytes),
          'mime_type': normalizedMimeType,
          'barcode': _normalizeBarcode(barcode ?? ''),
          'request_id': _newRequestId(),
        },
      );

      final result = CollectibleIdentificationResult.fromJson(
        asJsonMap(response.data),
        source: CollectibleIdentificationSource.aiPhoto,
      );
      SessionCache.set(cacheKey, result);
      return result;
    } on FunctionException catch (error) {
      throw CollectibleIdentificationException(
        _messageFromFunctionException(error) ??
            'AI identification is unavailable right now.',
      );
    } catch (_) {
      throw const CollectibleIdentificationException(
        'AI identification is unavailable right now.',
      );
    }
  }

  static String barcodeSessionKey(String barcode) {
    return '${_cachePrefix}barcode:${_normalizeBarcode(barcode)}';
  }

  static String photoSessionKey(Uint8List imageBytes) {
    return '${_cachePrefix}photo:$_photoCacheVersion:${sha256.convert(imageBytes)}';
  }

  static String _normalizeBarcode(String barcode) {
    final normalized = barcode.replaceAll(RegExp(r'[^0-9Xx]'), '').trim();
    return normalized;
  }

  static String _newRequestId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    final value = bytes.map(hex).join();
    return '${value.substring(0, 8)}-'
        '${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-'
        '${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }

  static bool _shouldRefreshBarcodeResult(
    CollectibleIdentificationResult result,
  ) {
    // A GO-UPC result may be an older session-cache entry from before Metron
    // became the preferred comic catalog. Refresh it once: the server either
    // upgrades a comic to Metron or returns a remote cache result, preventing
    // repeated provider calls for ordinary products. This also applies to an
    // old GO-UPC miss, because Metron may know the comic when GO-UPC did not.
    if (result.providerStage == CollectibleIdentificationProviderStage.goupc) {
      return true;
    }

    if (!result.hasCatalogMatch) {
      return false;
    }

    final imageUrl = (result.imageUrl ?? '').trim();
    if (imageUrl.isEmpty) {
      return true;
    }

    return _isLikelyBlockedImageHost(imageUrl);
  }

  static bool _isLikelyBlockedImageHost(String imageUrl) {
    final uri = Uri.tryParse(imageUrl);
    final host = (uri?.host ?? '').toLowerCase();
    if (host.isEmpty) {
      return false;
    }

    return host.contains('booksamillion.com') ||
        host.contains('entertainmentearth.com');
  }

  Future<FunctionResponse> _invokeIdentifyCollectible({
    required Object body,
  }) async {
    final session = _requireSession();
    try {
      return await _invokeFunctionWithToken(
        accessToken: session.accessToken,
        body: body,
      );
    } on FunctionException catch (error) {
      if (!_isInvalidJwtError(error)) {
        rethrow;
      }

      final refreshedSession = await _refreshSession(session);
      return _invokeFunctionWithToken(
        accessToken: refreshedSession.accessToken,
        body: body,
      );
    }
  }

  Future<FunctionResponse> _invokeFunctionWithToken({
    required String accessToken,
    required Object body,
  }) {
    client.functions.setAuth(accessToken);
    return client.functions.invoke(
      'identify_collectible',
      headers: {'Authorization': 'Bearer $accessToken'},
      body: body,
    );
  }

  Session _requireSession() {
    final session = client.auth.currentSession;
    if (session == null) {
      throw const CollectibleIdentificationException(
        'You need to be signed in to identify collectibles.',
      );
    }
    return session;
  }

  Future<Session> _refreshSession(Session session) async {
    final refreshed = await client.auth.refreshSession(session.refreshToken);
    final nextSession = refreshed.session ?? client.auth.currentSession;
    if (nextSession == null) {
      throw const CollectibleIdentificationException(
        'You need to be signed in to identify collectibles.',
      );
    }
    return nextSession;
  }

  static bool _isInvalidJwtError(FunctionException error) {
    final details = error.details;
    if (details is JsonMap) {
      final message =
          asNullableString(details['error']) ??
          asNullableString(details['message']);
      return (message ?? '').toLowerCase().contains('invalid jwt');
    }
    if (details is Map) {
      final message =
          asNullableString(details['error']) ??
          asNullableString(details['message']);
      return (message ?? '').toLowerCase().contains('invalid jwt');
    }
    return (asNullableString(error.reasonPhrase) ?? '').toLowerCase().contains(
      'invalid jwt',
    );
  }

  static String? _messageFromFunctionException(FunctionException error) {
    final details = error.details;
    if (details is JsonMap) {
      return asNullableString(details['error']) ??
          asNullableString(details['message']);
    }
    if (details is Map) {
      return asNullableString(details['error']) ??
          asNullableString(details['message']);
    }
    return asNullableString(error.reasonPhrase);
  }
}

class CollectibleIdentificationException implements Exception {
  const CollectibleIdentificationException(this.message);

  final String message;

  @override
  String toString() => 'CollectibleIdentificationException: $message';
}
