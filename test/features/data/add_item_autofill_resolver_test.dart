import 'package:collectorapp/features/collection/data/models/add_item_autofill_result.dart';
import 'package:collectorapp/features/collection/data/models/collectible_identification_result.dart';
import 'package:collectorapp/features/collection/data/models/tag_model.dart';
import 'package:collectorapp/features/collection/data/models/user_collection_vocabulary.dart';
import 'package:collectorapp/features/collection/data/services/add_item_autofill_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddItemAutofillResolver', () {
    test('does not create number-only tag suggestions', () {
      final resolver = AddItemAutofillResolver();
      final result = resolver.resolveWithVocabulary(
        identificationResult: const CollectibleIdentificationResult(
          status: CollectibleIdentificationStatus.matched,
          providerStage: CollectibleIdentificationProviderStage.openai,
          source: CollectibleIdentificationSource.aiPhoto,
          title: 'Betty & Veronica, vol. 2',
          sourceBadge: 'AI identification',
          suggestedCategory: 'Comics',
          franchise: 'Archie Comics',
          series: '2',
          characterOrSubject: '14',
          barcode: '76281646748300241',
        ),
        vocabulary: const UserCollectionVocabulary(
          tags: [
            TagModel(id: 'tag-1', name: '2'),
            TagModel(id: 'tag-2', name: 'Archie Comics'),
          ],
        ),
      );

      expect(result.newTagNames, isEmpty);
      expect(result.matchedTagIds, ['tag-2']);
      expect(result.seriesOrVolume, isNull);
    });

    test('keeps mixed text and number tag suggestions', () {
      final resolver = AddItemAutofillResolver();
      final result = resolver.resolveWithVocabulary(
        identificationResult: const CollectibleIdentificationResult(
          status: CollectibleIdentificationStatus.matched,
          providerStage: CollectibleIdentificationProviderStage.openai,
          source: CollectibleIdentificationSource.aiPhoto,
          title: 'Spider-Man 2099',
          sourceBadge: 'AI identification',
          franchise: 'Marvel',
          series: 'Spider-Man 2099',
        ),
        vocabulary: const UserCollectionVocabulary(),
      );

      expect(result.newTagNames, contains('Spider-Man 2099'));
      expect(result.seriesOrVolume, 'Spider-Man 2099');
    });

    test('ignores code-like line and series metadata', () {
      final resolver = AddItemAutofillResolver();
      final result = resolver.resolveWithVocabulary(
        identificationResult: const CollectibleIdentificationResult(
          status: CollectibleIdentificationStatus.matched,
          providerStage: CollectibleIdentificationProviderStage.openai,
          source: CollectibleIdentificationSource.aiPhoto,
          title: 'Random Figure',
          sourceBadge: 'AI identification',
          franchise: 'HACPBDGEA',
          series: 'HACPBDGEA',
        ),
        vocabulary: const UserCollectionVocabulary(),
      );

      expect(result.seriesOrVolume, isNull);
      expect(result.newTagNames, isEmpty);
    });

    test('keeps selected non-comic category in general mode', () {
      final resolver = AddItemAutofillResolver();
      final result = resolver.resolveWithVocabulary(
        identificationResult: const CollectibleIdentificationResult(
          status: CollectibleIdentificationStatus.matched,
          providerStage: CollectibleIdentificationProviderStage.openai,
          source: CollectibleIdentificationSource.aiPhoto,
          title: 'Comic Style Vinyl Figure',
          sourceBadge: 'Catalog match',
          suggestedCategory: 'Comics',
          series: 'Designer Vinyl',
        ),
        vocabulary: const UserCollectionVocabulary(),
        preferredCategory: 'Vinyl Figures',
      );

      expect(result.formMode, AddItemFormMode.general);
      expect(result.seriesOrVolume, 'Designer Vinyl');
    });

    test('keeps selected comics category in comic mode', () {
      final resolver = AddItemAutofillResolver();
      final result = resolver.resolveWithVocabulary(
        identificationResult: const CollectibleIdentificationResult(
          status: CollectibleIdentificationStatus.matched,
          providerStage: CollectibleIdentificationProviderStage.openai,
          source: CollectibleIdentificationSource.aiPhoto,
          title: 'Issue One',
          sourceBadge: 'Catalog match',
          suggestedCategory: 'Vinyl Figures',
          series: 'Issue One',
        ),
        vocabulary: const UserCollectionVocabulary(),
        preferredCategory: 'Comics',
      );

      expect(result.formMode, AddItemFormMode.comic);
    });
  });
}
