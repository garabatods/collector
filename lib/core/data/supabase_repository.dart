import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SupabaseRepository {
  SupabaseRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get client => _client ?? Supabase.instance.client;

  String get currentUserId {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No authenticated Supabase user is available.');
    }

    return userId;
  }

  Future<void> ensureOnlineForWrite() async {
    final connectivity = await Connectivity().checkConnectivity();
    final isOffline = connectivity.every(
      (result) => result == ConnectivityResult.none,
    );
    if (isOffline) {
      throw const OfflineWriteException(
        'Browsing works offline, but changes require an internet connection.',
      );
    }
  }
}

class OfflineWriteException implements Exception {
  const OfflineWriteException(this.message);

  final String message;

  @override
  String toString() => 'OfflineWriteException: $message';
}
