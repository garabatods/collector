import '../../../../core/data/supabase_repository.dart';

class BarcodeScanDiagnosticsRepository extends SupabaseRepository {
  BarcodeScanDiagnosticsRepository({super.client});

  Future<void> record({
    required int buildNumber,
    required String scannerVersion,
    required String? category,
    required String baseBarcode,
    required String? supplement,
    required String source,
    required String outcome,
    required int observationCount,
    required int durationMs,
  }) async {
    await client.from('barcode_scan_diagnostics').insert({
      'user_id': currentUserId,
      'build_number': buildNumber,
      'scanner_version': scannerVersion,
      'category': category?.trim(),
      'base_barcode': baseBarcode,
      'supplement': supplement,
      'source': source,
      'outcome': outcome,
      'observation_count': observationCount,
      'duration_ms': durationMs,
    });
  }
}
