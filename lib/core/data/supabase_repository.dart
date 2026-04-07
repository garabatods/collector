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
}
