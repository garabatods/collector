import 'tag_model.dart';

enum AddItemFormMode { general, comic }

enum ResolvedMatchKind { exact, alias, fuzzy, prefilled }

class ResolvedMatch<T> {
  const ResolvedMatch({
    required this.kind,
    this.matchedValue,
    this.prefilledValue,
    this.displayLabel,
  });

  final ResolvedMatchKind kind;
  final T? matchedValue;
  final T? prefilledValue;
  final String? displayLabel;

  bool get hasExistingMatch => matchedValue != null;

  T? get resolvedValue => matchedValue ?? prefilledValue;
}

class AddItemAutofillTagSuggestion {
  const AddItemAutofillTagSuggestion({
    required this.label,
    required this.kind,
    this.matchedTag,
  });

  final String label;
  final ResolvedMatchKind kind;
  final TagModel? matchedTag;

  String? get matchedTagId => matchedTag?.id;

  bool get isExistingTag => matchedTagId != null && matchedTagId!.isNotEmpty;
}

class AddItemAutofillResult {
  const AddItemAutofillResult({
    required this.formMode,
    this.title,
    this.category,
    this.brandOrPublisher,
    this.description,
    this.franchise,
    this.seriesOrVolume,
    this.characterOrSubject,
    this.releaseYear,
    this.issueNumber,
    this.barcode,
    this.tagSuggestions = const [],
  });

  final AddItemFormMode formMode;
  final String? title;
  final ResolvedMatch<String>? category;
  final ResolvedMatch<String>? brandOrPublisher;
  final String? description;
  final String? franchise;
  final String? seriesOrVolume;
  final String? characterOrSubject;
  final int? releaseYear;
  final String? issueNumber;
  final String? barcode;
  final List<AddItemAutofillTagSuggestion> tagSuggestions;

  List<String> get matchedTagIds => tagSuggestions
      .map((tag) => tag.matchedTagId)
      .whereType<String>()
      .where((id) => id.isNotEmpty)
      .toList(growable: false);

  List<String> get newTagNames => tagSuggestions
      .where((tag) => !tag.isExistingTag)
      .map((tag) => tag.label)
      .where((label) => label.trim().isNotEmpty)
      .toList(growable: false);
}
