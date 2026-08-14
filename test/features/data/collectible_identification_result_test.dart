import 'package:collectorapp/features/collection/data/models/collectible_identification_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('partial AI results are not presented as confirmed matches', () {
    const result = CollectibleIdentificationResult(
      status: CollectibleIdentificationStatus.partial,
      providerStage: CollectibleIdentificationProviderStage.openai,
      source: CollectibleIdentificationSource.aiPhoto,
      title: 'Possible Spider-Man figure',
      sourceBadge: 'Possible AI match',
    );

    expect(result.hasCatalogMatch, isFalse);
    expect(result.hasSuggestedMatch, isTrue);
    expect(result.isNotFound, isFalse);
    expect(result.hasPrefillData, isTrue);
  });

  test('empty partial AI results remain not found', () {
    const result = CollectibleIdentificationResult(
      status: CollectibleIdentificationStatus.partial,
      providerStage: CollectibleIdentificationProviderStage.openai,
      source: CollectibleIdentificationSource.aiPhoto,
      title: '',
      sourceBadge: 'AI identification',
    );

    expect(result.hasSuggestedMatch, isFalse);
    expect(result.isNotFound, isTrue);
  });

  test('matched and enriched results remain confirmed matches', () {
    for (final status in [
      CollectibleIdentificationStatus.matched,
      CollectibleIdentificationStatus.enriched,
    ]) {
      final result = CollectibleIdentificationResult(
        status: status,
        providerStage: CollectibleIdentificationProviderStage.openai,
        source: CollectibleIdentificationSource.aiPhoto,
        title: 'Confirmed collectible',
        sourceBadge: 'AI identification',
      );

      expect(result.hasCatalogMatch, isTrue);
      expect(result.hasSuggestedMatch, isTrue);
      expect(result.isNotFound, isFalse);
    }
  });
}
