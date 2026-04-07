import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/data/json_map.dart';
import '../models/barcode_lookup_result.dart';

class UpcItemDbBarcodeLookupService {
  UpcItemDbBarcodeLookupService({
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  static const String trialLookupEndpoint =
      'https://api.upcitemdb.com/prod/trial/lookup';

  final http.Client _httpClient;

  Future<BarcodeLookupResult?> lookup(String barcode) async {
    final normalizedBarcode = barcode.trim();
    if (normalizedBarcode.isEmpty) {
      return null;
    }

    final response = await _httpClient.get(
      Uri.parse('$trialLookupEndpoint?upc=$normalizedBarcode'),
      headers: const {
        'Accept': 'application/json',
      },
    );

    final payload = _decodeBody(response.body);

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode == 429) {
      throw const BarcodeLookupException(
        'Barcode lookup is temporarily rate-limited. You can still add the item manually.',
      );
    }

    if (response.statusCode >= 400) {
      throw BarcodeLookupException(
        _messageFromPayload(payload) ??
            'Could not look up that barcode right now. You can still add the item manually.',
      );
    }

    final items = asJsonList(payload['items']);
    if (items.isEmpty) {
      return null;
    }

    final item = asJsonMap(items.first);
    final title = asNullableString(item['title'])?.trim() ?? '';
    if (title.isEmpty) {
      return null;
    }

    final rawCategory = asNullableString(item['category']);
    final brand = asNullableString(item['brand']);
    final imageUrl = _preferredImageUrl(item['images']);

    return BarcodeLookupResult(
      barcode: normalizedBarcode,
      title: title,
      suggestedCategory: suggestCollectorCategory(
        rawCategory: rawCategory,
        title: title,
      ),
      imageUrl: imageUrl,
      description: asNullableString(item['description']),
      brand: brand,
      rawCategory: rawCategory,
    );
  }

  static String suggestCollectorCategory({
    String? rawCategory,
    String? title,
  }) {
    final haystack = '${rawCategory ?? ''} ${title ?? ''}'.toLowerCase();

    if (_matchesAny(haystack, const [
      'trading card',
      'collectible card',
      'tcg',
      'pokemon card',
      'sports card',
      'cards',
    ])) {
      return 'Trading Cards';
    }

    if (_matchesAny(haystack, const [
      'comic',
      'graphic novel',
      'manga',
    ])) {
      return 'Comics';
    }

    if (_matchesAny(haystack, const [
      'die-cast',
      'die cast',
      'hot wheels',
      'matchbox',
      'model car',
    ])) {
      return 'Die-cast';
    }

    if (_matchesAny(haystack, const [
      'vinyl figure',
      'vinyl collectible',
      'funko',
      'pop!',
    ])) {
      return 'Vinyl Figures';
    }

    if (_matchesAny(haystack, const [
      'statue',
      'bust',
      'figurine',
      'sculpture',
    ])) {
      return 'Statues';
    }

    if (_matchesAny(haystack, const [
      'memorabilia',
      'autograph',
      'signed',
      'prop replica',
      'collector pin',
      'poster',
    ])) {
      return 'Memorabilia';
    }

    if (_matchesAny(haystack, const [
      'action figure',
      'figure',
      'toy',
      'toys & games',
      'doll',
      'playset',
    ])) {
      return 'Action Figures';
    }

    return 'Other';
  }

  static String? _preferredImageUrl(Object? rawImages) {
    if (rawImages is! List) {
      return null;
    }

    final images = rawImages
        .map((image) => asNullableString(image))
        .whereType<String>()
        .map((image) => image.trim())
        .where((image) => image.isNotEmpty)
        .toList(growable: false);

    for (final image in images) {
      if (image.toLowerCase().startsWith('https://')) {
        return image;
      }
    }

    return images.isEmpty ? null : images.first;
  }

  static bool _matchesAny(String haystack, List<String> needles) {
    for (final needle in needles) {
      if (haystack.contains(needle)) {
        return true;
      }
    }

    return false;
  }

  static JsonMap _decodeBody(String body) {
    if (body.trim().isEmpty) {
      return const {};
    }

    final decoded = jsonDecode(body);
    return decoded is Map<String, Object?> ? decoded : const {};
  }

  static String? _messageFromPayload(JsonMap payload) {
    final message = asNullableString(payload['message'])?.trim();
    return message == null || message.isEmpty ? null : message;
  }
}

class BarcodeLookupException implements Exception {
  const BarcodeLookupException(this.message);

  final String message;

  @override
  String toString() => 'BarcodeLookupException: $message';
}
