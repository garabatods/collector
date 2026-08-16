import 'package:collectorapp/features/collection/data/services/collectible_barcode_capture_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CollectibleBarcodeCaptureResolver', () {
    test('keeps a comic UPC supplement reported in displayValue', () {
      expect(
        CollectibleBarcodeCaptureResolver.resolve(
          rawValue: '827714034714',
          displayValue: '827714034714 00411',
        ),
        '82771403471400411',
      );
    });

    test('combines an EAN-13 comic barcode with its five-digit supplement', () {
      expect(
        CollectibleBarcodeCaptureResolver.resolve(
          rawValue: '0827714034578',
          displayValue: '082771403457800111',
        ),
        '82771403457800111',
      );
    });

    test('does not replace a normal barcode with unrelated display text', () {
      expect(
        CollectibleBarcodeCaptureResolver.resolve(
          rawValue: '012345678905',
          displayValue: 'Product 012345678905',
        ),
        '012345678905',
      );
    });

    test('uses displayValue when rawValue is absent', () {
      expect(
        CollectibleBarcodeCaptureResolver.resolve(
          rawValue: null,
          displayValue: '9781234567890',
        ),
        '9781234567890',
      );
    });
  });
}
