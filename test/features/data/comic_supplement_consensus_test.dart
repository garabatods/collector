import 'package:collectorapp/features/collection/data/services/comic_supplement_consensus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ComicSupplementConsensus', () {
    test('confirms the same OCR value after three confident frames', () {
      final consensus = ComicSupplementConsensus();

      for (var index = 0; index < 2; index += 1) {
        final update = consensus.observe(
          const ComicSupplementObservation(
            baseBarcode: '0827714034578',
            candidate: '00111',
            confidence: 0.8,
            source: 'vision_ocr',
          ),
        );
        expect(update.isConfirmed, isFalse);
      }

      final confirmed = consensus.observe(
        const ComicSupplementObservation(
          baseBarcode: '0827714034578',
          candidate: '00111',
          confidence: 0.82,
          source: 'vision_ocr',
        ),
      );

      expect(confirmed.confirmedSupplement, '00111');
      expect(confirmed.leadingCount, 3);
    });

    test('ignores low confidence and malformed OCR values', () {
      final consensus = ComicSupplementConsensus();

      final update = consensus.observe(
        const ComicSupplementObservation(
          baseBarcode: '827714034578',
          candidate: '0011',
          confidence: 0.9,
          source: 'vision_ocr',
        ),
      );
      final lowConfidence = consensus.observe(
        const ComicSupplementObservation(
          baseBarcode: '827714034578',
          candidate: '00111',
          confidence: 0.2,
          source: 'vision_ocr',
        ),
      );

      expect(update.leadingCandidate, isNull);
      expect(lowConfidence.leadingCandidate, isNull);
    });

    test('accepts the native Vision supplement immediately', () {
      final update = ComicSupplementConsensus().observe(
        const ComicSupplementObservation(
          baseBarcode: '0827714034578',
          candidate: '00421',
          confidence: 1,
          source: 'vision_barcode',
        ),
      );

      expect(update.confirmedSupplement, '00421');
    });

    test('resets candidate votes when the base barcode changes', () {
      final consensus = ComicSupplementConsensus(requiredObservations: 2);
      consensus.observe(
        const ComicSupplementObservation(
          baseBarcode: '827714034578',
          candidate: '00111',
          confidence: 0.8,
          source: 'vision_ocr',
        ),
      );

      final changed = consensus.observe(
        const ComicSupplementObservation(
          baseBarcode: '827714034714',
          candidate: '00111',
          confidence: 0.8,
          source: 'vision_ocr',
        ),
      );

      expect(changed.leadingCount, 1);
      expect(changed.isConfirmed, isFalse);
    });
  });
}
