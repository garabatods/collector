import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

enum AuthStage {
  splash,
  unauthenticated,
  authenticated,
}

enum AuthMode {
  login,
  join,
}

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthService authService,
    Duration splashDelay = const Duration(milliseconds: 2500),
  })  : _authService = authService,
        _splashDelay = splashDelay;

  final AuthService _authService;
  final Duration _splashDelay;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  AuthStage _stage = AuthStage.splash;
  AuthMode _mode = AuthMode.login;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _errorMessage;
  String? _statusMessage;
  StreamSubscription<AuthState>? _authSubscription;
  bool _isDisposed = false;

  bool get isConfigured => _authService.isConfigured;
  AuthStage get stage => _stage;
  AuthMode get mode => _mode;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;

  Future<void> initialize() async {
    _authSubscription?.cancel();
    if (isConfigured) {
      _authSubscription = _authService.authStateChanges().listen((event) {
        _setStage(
          event.session == null
              ? AuthStage.unauthenticated
              : AuthStage.authenticated,
        );
      });
    }

    if (_splashDelay > Duration.zero) {
      await Future<void>.delayed(_splashDelay);
    }

    final session = _authService.currentSession;

    _stage = session == null
        ? AuthStage.unauthenticated
        : AuthStage.authenticated;
    _isInitializing = false;
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void setMode(AuthMode value) {
    if (_mode == value) return;
    _mode = value;
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();
  }

  Future<void> submit() async {
    _errorMessage = null;
    _statusMessage = null;

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _errorMessage = 'Email and password are required.';
      if (!_isDisposed) {
        notifyListeners();
      }
      return;
    }

    if (!isConfigured) {
      _errorMessage =
          'Supabase is not configured for this build yet. Add dart-defines first.';
      if (!_isDisposed) {
        notifyListeners();
      }
      return;
    }

    _isLoading = true;
    if (!_isDisposed) {
      notifyListeners();
    }

    try {
      if (_mode == AuthMode.login) {
        await _authService.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        final response = await _authService.signUp(
          email: email,
          password: password,
        );

        if (response.session == null) {
          _statusMessage =
              'Account created. Check your email to confirm access to the archive.';
        }
      }
    } on AuthException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Something went wrong while contacting Supabase.';
    } finally {
      _isLoading = false;
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  Future<void> signOut() async {
    if (!isConfigured) return;
    await _authService.signOut();
    _setStage(AuthStage.unauthenticated);
  }

  void _setStage(AuthStage value) {
    if (_isInitializing || _isDisposed || _stage == value) {
      return;
    }

    _stage = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authSubscription?.cancel();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
