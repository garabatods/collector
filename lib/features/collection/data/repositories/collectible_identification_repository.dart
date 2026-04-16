import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/json_map.dart';
import '../../../../core/data/session_cache.dart';
import '../../../../core/data/supabase_repository.dart';
import '../models/collectible_identification_result.dart';

class CollectibleIdentificationRepository extends SupabaseRepository {
  CollectibleIdentificationRepository({super.client});

  static const _cachePrefix = 'identification:';

  Future<CollectibleIdentificationResult> identifyBarcode(String barcode) async {
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
    if (cached != null) {
      return cached;
    }

    try {
      final response = await _invokeIdentifyCollectible(
        body: {
          'mode': 'barcode',
          'barcode': normalizedBarcode,
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
    final normalizedMimeType = mimeType.trim().toLowerCase();
    if (imageBytes.isEmpty || !normalizedMimeType.startsWith('image/')) {
      throw const CollectibleIdentificationException(
        'Choose a valid image before running AI identification.',
      );
    }

    final fingerprint = sha256.convert(imageBytes).toString();
    final cacheKey = '${_cachePrefix}photo:$fingerprint';
    final cached = SessionCache.get<CollectibleIdentificationResult>(cacheKey);
    if (cached != null) {
      return cached;
    }

    try {
      final response = await _invokeIdentifyCollectible(
        body: {
          'mode': 'photo',
          'image_base64': base64Encode(imageBytes),
          'mime_type': normalizedMimeType,
          'barcode': _normalizeBarcode(barcode ?? ''),
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
    return '${_cachePrefix}photo:${sha256.convert(imageBytes)}';
  }

  static String _normalizeBarcode(String barcode) {
    final normalized = barcode.replaceAll(RegExp(r'[^0-9Xx]'), '').trim();
    return normalized;
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
