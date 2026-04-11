import '../models/add_item_autofill_result.dart';
import '../models/collectible_identification_result.dart';
import '../models/tag_model.dart';
import '../models/user_collection_vocabulary.dart';
import '../repositories/collection_vocabulary_repository.dart';

class AddItemAutofillResolver {
  AddItemAutofillResolver({
    CollectionVocabularyRepository? vocabularyRepository,
  }) : _vocabularyRepository =
           vocabularyRepository ?? CollectionVocabularyRepository();

  final CollectionVocabularyRepository _vocabularyRepository;

  Future<AddItemAutofillResult> resolve(
    CollectibleIdentificationResult identificationResult,
  ) async {
    final vocabulary = await _vocabularyRepository.fetch();
    return resolveWithVocabulary(
      identificationResult: identificationResult,
      vocabulary: vocabulary,
    );
  }

  AddItemAutofillResult resolveWithVocabulary({
    required CollectibleIdentificationResult identificationResult,
    required UserCollectionVocabulary vocabulary,
  }) {
    final formMode = identificationResult.isComicLike
        ? AddItemFormMode.comic
        : AddItemFormMode.general;

    final brandCandidate = formMode == AddItemFormMode.comic
        ? identificationResult.publisherCandidate
        : identificationResult.brand;
    final seriesCandidate = formMode == AddItemFormMode.comic
        ? identificationResult.volumeCandidate
        : identificationResult.series;

    return AddItemAutofillResult(
      formMode: formMode,
      title: _clean(identificationResult.title),
      brandOrPublisher: _resolveStringMatch(
        candidate: brandCandidate,
        options: vocabulary.brands,
      ),
      description: _clean(identificationResult.description),
      franchise: _resolveOptionalMetadata(
        candidate: identificationResult.franchise,
        options: vocabulary.franchises,
      )?.resolvedValue,
      seriesOrVolume: _resolveOptionalMetadata(
        candidate: seriesCandidate,
        options: vocabulary.series,
      )?.resolvedValue,
      characterOrSubject: _clean(identificationResult.characterOrSubject),
      releaseYear: identificationResult.releaseYear,
      issueNumber: _clean(identificationResult.issueNumber),
      barcode: _clean(identificationResult.barcode),
      tagSuggestions: _resolveTagSuggestions(
        identificationResult: identificationResult,
        vocabulary: vocabulary,
        formMode: formMode,
      ),
    );
  }

  List<AddItemAutofillTagSuggestion> _resolveTagSuggestions({
    required CollectibleIdentificationResult identificationResult,
    required UserCollectionVocabulary vocabulary,
    required AddItemFormMode formMode,
  }) {
    final candidates = <String>[
      if ((_clean(identificationResult.franchise) ?? '').isNotEmpty)
        _clean(identificationResult.franchise)!,
      if ((_clean(identificationResult.series) ?? '').isNotEmpty)
        _clean(identificationResult.series)!,
      if ((_clean(identificationResult.characterOrSubject) ?? '').isNotEmpty)
        _clean(identificationResult.characterOrSubject)!,
      if (formMode == AddItemFormMode.comic &&
          (_clean(identificationResult.volumeCandidate) ?? '').isNotEmpty)
        _clean(identificationResult.volumeCandidate)!,
      if (formMode == AddItemFormMode.comic &&
          (_clean(identificationResult.publisherCandidate) ?? '').isNotEmpty)
        _clean(identificationResult.publisherCandidate)!,
    ];

    final uniqueCandidates = <String>[];
    final seen = <String>{};
    for (final candidate in candidates) {
      final normalized = _normalize(candidate);
      if (normalized.isEmpty) {
        continue;
      }
      if (seen.add(normalized)) {
        uniqueCandidates.add(candidate);
      }
    }

    final suggestions = <AddItemAutofillTagSuggestion>[];
    for (final candidate in uniqueCandidates.take(
      formMode == AddItemFormMode.comic ? 4 : 3,
    )) {
      final matchedTag = _resolveTag(candidate, vocabulary.tags);
      suggestions.add(
        AddItemAutofillTagSuggestion(
          label: matchedTag?.$1.name ?? candidate,
          kind: matchedTag == null
              ? ResolvedMatchKind.prefilled
              : matchedTag.$2,
          matchedTag: matchedTag?.$1,
        ),
      );
    }

    return suggestions;
  }

  ResolvedMatch<String>? _resolveOptionalMetadata({
    required String? candidate,
    required List<String> options,
  }) {
    final resolved = _resolveStringMatch(
      candidate: candidate,
      options: options,
    );
    if (resolved == null) {
      return null;
    }
    return resolved;
  }

  ResolvedMatch<String>? _resolveStringMatch({
    required String? candidate,
    required List<String> options,
  }) {
    final cleanedCandidate = _clean(candidate);
    if (cleanedCandidate == null) {
      return null;
    }

    final direct = _exactMatch(cleanedCandidate, options);
    if (direct != null) {
      return ResolvedMatch<String>(
        kind: direct.$2,
        matchedValue: direct.$1,
        displayLabel: direct.$1,
      );
    }

    final fuzzy = _fuzzyMatch(cleanedCandidate, options);
    if (fuzzy != null) {
      return ResolvedMatch<String>(
        kind: ResolvedMatchKind.fuzzy,
        matchedValue: fuzzy,
        displayLabel: fuzzy,
      );
    }

    return ResolvedMatch<String>(
      kind: ResolvedMatchKind.prefilled,
      prefilledValue: cleanedCandidate,
      displayLabel: cleanedCandidate,
    );
  }

  (String, ResolvedMatchKind)? _exactMatch(
    String candidate,
    List<String> options,
  ) {
    final normalizedCandidate = _normalize(candidate);
    final candidateAliases = _aliasesFor(candidate);

    for (final option in options) {
      final normalizedOption = _normalize(option);
      if (normalizedOption == normalizedCandidate) {
        return (option, ResolvedMatchKind.exact);
      }

      if (candidateAliases.contains(normalizedOption)) {
        return (option, ResolvedMatchKind.alias);
      }
    }

    return null;
  }

  String? _fuzzyMatch(String candidate, List<String> options) {
    final normalizedCandidate = _normalize(candidate);
    var bestOption = '';
    var bestScore = 0.0;
    var secondBestScore = 0.0;

    for (final option in options) {
      final score = _similarity(normalizedCandidate, _normalize(option));
      if (score > bestScore) {
        secondBestScore = bestScore;
        bestScore = score;
        bestOption = option;
      } else if (score > secondBestScore) {
        secondBestScore = score;
      }
    }

    if (bestOption.isEmpty) {
      return null;
    }

    if (bestScore >= 0.92 && (bestScore - secondBestScore) >= 0.12) {
      return bestOption;
    }

    return null;
  }

  (TagModel, ResolvedMatchKind)? _resolveTag(
    String candidate,
    List<TagModel> tags,
  ) {
    final exact = _exactMatch(
      candidate,
      tags.map((tag) => tag.name).toList(growable: false),
    );
    if (exact != null) {
      final tag = tags.firstWhere((item) => item.name == exact.$1);
      return (tag, exact.$2);
    }

    final fuzzy = _fuzzyMatch(
      candidate,
      tags.map((tag) => tag.name).toList(growable: false),
    );
    if (fuzzy != null) {
      final tag = tags.firstWhere((item) => item.name == fuzzy);
      return (tag, ResolvedMatchKind.fuzzy);
    }

    return null;
  }

  Set<String> _aliasesFor(String value) {
    final normalized = _normalize(value);
    final aliases = <String>{normalized};
    final aliasMap = <String, List<String>>{
      'tmnt': ['teenage mutant ninja turtles', 'teenage mutant ninja turtle'],
      'teenage mutant ninja turtles': ['tmnt', 'teenage mutant ninja turtle'],
      'star wars': ['starwars'],
      'board games': ['board game'],
      'comics': ['comic'],
    };

    aliases.addAll(aliasMap[normalized] ?? const []);
    return aliases.map(_normalize).toSet();
  }

  double _similarity(String left, String right) {
    if (left.isEmpty || right.isEmpty) {
      return 0;
    }
    if (left == right) {
      return 1;
    }

    final leftTokens = left
        .split(' ')
        .where((token) => token.isNotEmpty)
        .toSet();
    final rightTokens = right
        .split(' ')
        .where((token) => token.isNotEmpty)
        .toSet();

    final intersection = leftTokens.intersection(rightTokens).length.toDouble();
    final union = leftTokens.union(rightTokens).length.toDouble();
    final jaccard = union == 0 ? 0.0 : intersection / union;

    if (left.contains(right) || right.contains(left)) {
      return jaccard + 0.2;
    }

    return jaccard;
  }

  String _normalize(String value) {
    var normalized = value.toLowerCase().trim();
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.endsWith('s') && normalized.length > 4) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  String? _clean(String? value) {
    final cleaned = value?.trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }
}
