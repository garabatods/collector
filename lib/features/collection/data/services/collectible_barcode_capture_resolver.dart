/// Chooses the most complete value exposed by the device barcode scanner.
///
/// UPC/EAN supplements are printed beside the primary barcode on many comics.
/// Native scanners commonly expose the base code as `rawValue` and the full
/// code (including the supplement) as `displayValue`.
class CollectibleBarcodeCaptureResolver {
  const CollectibleBarcodeCaptureResolver._();

  static String resolve({
    required String? rawValue,
    required String? displayValue,
  }) {
    final raw = rawValue?.trim() ?? '';
    final display = displayValue?.trim() ?? '';

    if (raw.isEmpty) {
      return display;
    }
    if (display.isEmpty) {
      return raw;
    }

    final rawDigits = _digitsOnly(raw);
    final displayDigits = _digitsOnly(display);
    final hasRetailBaseLength = const {
      8,
      12,
      13,
      14,
    }.contains(rawDigits.length);
    final hasSupplement =
        displayDigits.startsWith(rawDigits) &&
        (displayDigits.length == rawDigits.length + 2 ||
            displayDigits.length == rawDigits.length + 5);

    if (!hasRetailBaseLength || !hasSupplement) {
      return raw;
    }

    // Apple Vision represents UPC-A as an EAN-13 value with a leading zero.
    // Metron stores the UPC-A base plus its supplement, so drop only that
    // transport prefix when the five-digit supplement was decoded.
    if (rawDigits.length == 13 && rawDigits.startsWith('0')) {
      return displayDigits.substring(1);
    }

    return displayDigits;
  }

  static String _digitsOnly(String value) =>
      value.replaceAll(RegExp(r'[^0-9]'), '');
}
