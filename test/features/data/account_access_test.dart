import 'package:collectorapp/features/access/data/models/account_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps server access and computes limits', () {
    final access = AccountAccess.fromJson({
      'is_pro': true,
      'status': 'active',
      'item_count': 9999,
      'item_limit': 10000,
      'photo_id_remaining': 1,
      'photo_id_limit': 50,
      'photo_id_daily_remaining': 1,
      'upc_remaining': 0,
      'upc_limit': 100,
      'upc_daily_remaining': 25,
    });

    expect(access.canAddItem, isTrue);
    expect(access.canUsePhotoId, isTrue);
    expect(access.canUseUpc, isFalse);
    expect(access.itemUsage, closeTo(0.9999, 0.00001));
  });

  test('downgraded account preserves visibility but cannot add', () {
    final access = AccountAccess.fromJson({
      'is_pro': false,
      'item_count': 21,
      'item_limit': 20,
      'photo_id_remaining': 0,
      'photo_id_limit': 3,
      'photo_id_daily_remaining': 0,
      'upc_remaining': 0,
      'upc_limit': 0,
      'upc_daily_remaining': 0,
    });

    expect(access.itemCount, 21);
    expect(access.canAddItem, isFalse);
    expect(access.canUsePhotoId, isFalse);
    expect(access.canUseUpc, isFalse);
  });
}
