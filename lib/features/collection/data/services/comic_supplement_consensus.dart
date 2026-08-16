class ComicSupplementObservation {
  const ComicSupplementObservation({
    required this.baseBarcode,
    required this.candidate,
    required this.confidence,
    required this.source,
  });

  final String baseBarcode;
  final String? candidate;
  final double? confidence;
  final String? source;
}

class ComicSupplementConsensusUpdate {
  const ComicSupplementConsensusUpdate({
    required this.baseBarcode,
    required this.leadingCandidate,
    required this.leadingCount,
    required this.totalObservations,
    required this.confirmedSupplement,
  });

  final String baseBarcode;
  final String? leadingCandidate;
  final int leadingCount;
  final int totalObservations;
  final String? confirmedSupplement;

  bool get isConfirmed => confirmedSupplement != null;
}

class ComicSupplementConsensus {
  ComicSupplementConsensus({
    this.requiredObservations = 3,
    this.minimumConfidence = 0.55,
  });

  final int requiredObservations;
  final double minimumConfidence;

  String? _baseBarcode;
  final Map<String, int> _candidateCounts = <String, int>{};
  int _totalObservations = 0;

  ComicSupplementConsensusUpdate observe(ComicSupplementObservation value) {
    final baseBarcode = _digitsOnly(value.baseBarcode);
    if (_baseBarcode != baseBarcode) {
      reset();
      _baseBarcode = baseBarcode;
    }

    _totalObservations += 1;
    final candidate = _normalizedCandidate(value.candidate);
    final confidence = value.confidence ?? 0;
    final isNativeBarcode = value.source == 'vision_barcode';
    if (candidate != null &&
        (isNativeBarcode || confidence >= minimumConfidence)) {
      _candidateCounts.update(
        candidate,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    String? leadingCandidate;
    var leadingCount = 0;
    for (final entry in _candidateCounts.entries) {
      if (entry.value > leadingCount) {
        leadingCandidate = entry.key;
        leadingCount = entry.value;
      }
    }

    final confirmed = isNativeBarcode && candidate != null
        ? candidate
        : leadingCount >= requiredObservations
        ? leadingCandidate
        : null;

    return ComicSupplementConsensusUpdate(
      baseBarcode: baseBarcode,
      leadingCandidate: leadingCandidate,
      leadingCount: leadingCount,
      totalObservations: _totalObservations,
      confirmedSupplement: confirmed,
    );
  }

  void reset() {
    _baseBarcode = null;
    _candidateCounts.clear();
    _totalObservations = 0;
  }

  static String _digitsOnly(String value) =>
      value.replaceAll(RegExp(r'\D'), '');

  static String? _normalizedCandidate(String? value) {
    if (value == null) return null;
    final digits = _digitsOnly(value);
    return digits.length == 5 ? digits : null;
  }
}
