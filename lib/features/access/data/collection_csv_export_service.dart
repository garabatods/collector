import 'dart:convert';
import 'dart:ui';

import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/local_archive_database.dart';

class CollectionCsvExportService {
  static Future<void> shareExport({Rect? sharePositionOrigin}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw StateError('Sign in before exporting.');
    final items = await LocalArchiveDatabase.instance.getCollectibles(userId);
    final rows = <List<Object?>>[
      const [
        'title',
        'category',
        'brand',
        'franchise',
        'series',
        'item_number',
        'barcode',
        'condition',
        'quantity',
        'purchase_price',
        'estimated_value',
        'acquired_on',
        'favorite',
        'grail',
        'notes',
        'created_at',
      ],
      for (final item in items)
        [
          item.title,
          item.category,
          item.brand,
          item.franchise,
          item.lineOrSeries ?? item.series,
          item.itemNumber,
          item.barcode,
          item.itemCondition,
          item.quantity,
          item.purchasePrice,
          item.estimatedValue,
          item.acquiredOn?.toIso8601String().split('T').first,
          item.isFavorite,
          item.isGrail,
          item.notes,
          item.createdAt?.toUtc().toIso8601String(),
        ],
    ];
    final csv = rows.map((row) => row.map(_escape).join(',')).join('\r\n');
    final date = DateTime.now().toIso8601String().split('T').first;
    await SharePlus.instance.share(
      ShareParams(
        subject: 'Ownzith collection export',
        text: 'Ownzith collection export ($date)',
        files: [
          XFile.fromData(
            utf8.encode(csv),
            name: 'ownzith-collection-$date.csv',
            mimeType: 'text/csv',
          ),
        ],
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  static String _escape(Object? value) {
    final text = value?.toString() ?? '';
    return '"${text.replaceAll('"', '""')}"';
  }
}
