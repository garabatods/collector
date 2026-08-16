import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/account_access.dart';

class AccountAccessService extends ValueNotifier<AccountAccess> {
  AccountAccessService._() : super(const AccountAccess.freeFallback());

  static final instance = AccountAccessService._();
  static const _cachePrefix = 'ownzith-account-access:';

  bool isRefreshing = false;

  Future<void> loadCachedAndRefresh() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final preferences = await SharedPreferences.getInstance();
    final cached = preferences.getString('$_cachePrefix$userId');
    if (cached != null) {
      try {
        value = AccountAccess.fromJson(
          Map<String, dynamic>.from(jsonDecode(cached) as Map),
        );
      } catch (_) {
        // A malformed local cache should never prevent a server refresh.
      }
    }
    await refresh();
  }

  Future<AccountAccess> refresh() async {
    if (isRefreshing) return value;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return value;
    isRefreshing = true;
    try {
      final response = await Supabase.instance.client.rpc('get_account_access');
      final access = AccountAccess.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
      value = access;
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        '$_cachePrefix$userId',
        jsonEncode(access.toJson()),
      );
      return access;
    } catch (_) {
      return value;
    } finally {
      isRefreshing = false;
    }
  }
}
