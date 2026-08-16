class AccountAccess {
  const AccountAccess({
    required this.isPro,
    required this.status,
    required this.itemCount,
    required this.itemLimit,
    required this.photoIdRemaining,
    required this.photoIdLimit,
    required this.photoIdDailyRemaining,
    required this.upcRemaining,
    required this.upcLimit,
    required this.upcDailyRemaining,
    this.expiration,
    this.photoIdResetAt,
    this.upcResetAt,
  });

  const AccountAccess.freeFallback()
    : isPro = false,
      status = 'offline',
      itemCount = 0,
      itemLimit = 20,
      photoIdRemaining = 3,
      photoIdLimit = 3,
      photoIdDailyRemaining = 3,
      upcRemaining = 0,
      upcLimit = 0,
      upcDailyRemaining = 0,
      expiration = null,
      photoIdResetAt = null,
      upcResetAt = null;

  final bool isPro;
  final String status;
  final int itemCount;
  final int itemLimit;
  final int photoIdRemaining;
  final int photoIdLimit;
  final int photoIdDailyRemaining;
  final int upcRemaining;
  final int upcLimit;
  final int upcDailyRemaining;
  final DateTime? expiration;
  final DateTime? photoIdResetAt;
  final DateTime? upcResetAt;

  bool get canAddItem => itemCount < itemLimit;
  bool get canUsePhotoId => photoIdRemaining > 0 && photoIdDailyRemaining > 0;
  bool get canUseUpc => isPro && upcRemaining > 0 && upcDailyRemaining > 0;
  double get itemUsage => itemLimit == 0 ? 1 : itemCount / itemLimit;

  factory AccountAccess.fromJson(Map<String, dynamic> json) {
    int integer(String key, int fallback) {
      final value = json[key];
      return value is num ? value.toInt() : int.tryParse('$value') ?? fallback;
    }

    DateTime? date(String key) => DateTime.tryParse('${json[key] ?? ''}');
    return AccountAccess(
      isPro: json['is_pro'] == true,
      status: '${json['status'] ?? 'inactive'}',
      itemCount: integer('item_count', 0),
      itemLimit: integer('item_limit', 20),
      photoIdRemaining: integer('photo_id_remaining', 0),
      photoIdLimit: integer('photo_id_limit', 3),
      photoIdDailyRemaining: integer('photo_id_daily_remaining', 0),
      upcRemaining: integer('upc_remaining', 0),
      upcLimit: integer('upc_limit', 0),
      upcDailyRemaining: integer('upc_daily_remaining', 0),
      expiration: date('expiration'),
      photoIdResetAt: date('photo_id_reset_at'),
      upcResetAt: date('upc_reset_at'),
    );
  }

  Map<String, dynamic> toJson() => {
    'is_pro': isPro,
    'status': status,
    'item_count': itemCount,
    'item_limit': itemLimit,
    'photo_id_remaining': photoIdRemaining,
    'photo_id_limit': photoIdLimit,
    'photo_id_daily_remaining': photoIdDailyRemaining,
    'upc_remaining': upcRemaining,
    'upc_limit': upcLimit,
    'upc_daily_remaining': upcDailyRemaining,
    'expiration': expiration?.toIso8601String(),
    'photo_id_reset_at': photoIdResetAt?.toIso8601String(),
    'upc_reset_at': upcResetAt?.toIso8601String(),
  };
}
