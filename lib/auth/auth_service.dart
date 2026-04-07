import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService({
    required bool isConfigured,
  }) : _isConfigured = isConfigured;

  final bool _isConfigured;

  bool get isConfigured => _isConfigured;

  Session? get currentSession {
    if (!_isConfigured) return null;
    return Supabase.instance.client.auth.currentSession;
  }

  Stream<AuthState> authStateChanges() {
    if (!_isConfigured) {
      return const Stream<AuthState>.empty();
    }

    return Supabase.instance.client.auth.onAuthStateChange;
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() {
    return Supabase.instance.client.auth.signOut();
  }
}
