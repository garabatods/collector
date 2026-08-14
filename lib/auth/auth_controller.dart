import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

enum AuthStage { splash, unauthenticated, authenticated }

enum AuthMode { login, join, forgotPassword, resetPassword }

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthService authService,
    Duration splashDelay = const Duration(milliseconds: 3000),
  }) : _authService = authService,
       _splashDelay = splashDelay;

  final AuthService _authService;
  final Duration _splashDelay;
  final AppLinks _appLinks = AppLinks();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  AuthStage _stage = AuthStage.splash;
  AuthMode _mode = AuthMode.login;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _errorMessage;
  String? _statusMessage;
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<Uri>? _linkSubscription;
  Uri? _lastHandledAuthLink;
  bool _isDisposed = false;

  bool get isConfigured => _authService.isConfigured;
  AuthStage get stage => _stage;
  AuthMode get mode => _mode;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;
  bool get isPasswordRecoveryMode => _mode == AuthMode.resetPassword;
  bool get isForgotPasswordMode => _mode == AuthMode.forgotPassword;

  Future<void> initialize() async {
    _authSubscription?.cancel();
    _linkSubscription?.cancel();
    if (isConfigured) {
      _authSubscription = _authService.authStateChanges().listen((event) {
        if (event.event == AuthChangeEvent.passwordRecovery) {
          _mode = AuthMode.resetPassword;
          _stage = AuthStage.unauthenticated;
          _errorMessage = null;
          _statusMessage = null;
          if (!_isDisposed) {
            notifyListeners();
          }
          return;
        }

        if (_mode == AuthMode.resetPassword &&
            event.session != null &&
            event.event != AuthChangeEvent.userUpdated) {
          _stage = AuthStage.unauthenticated;
          if (!_isDisposed) {
            notifyListeners();
          }
          return;
        }

        _setStage(
          event.session == null
              ? AuthStage.unauthenticated
              : AuthStage.authenticated,
        );
      });

      _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
        _handleIncomingAuthLink(uri);
      });
      unawaited(_handleInitialAuthLink());
    }

    if (_splashDelay > Duration.zero) {
      await Future<void>.delayed(_splashDelay);
    }

    final session = _authService.currentSession;

    _stage = _mode == AuthMode.resetPassword
        ? AuthStage.unauthenticated
        : session == null
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
    if (value != AuthMode.resetPassword) {
      confirmPasswordController.clear();
    }
    notifyListeners();
  }

  void showForgotPassword() {
    _mode = AuthMode.forgotPassword;
    _errorMessage = null;
    _statusMessage = null;
    passwordController.clear();
    confirmPasswordController.clear();
    notifyListeners();
  }

  Future<void> returnToLogin() async {
    if (_mode == AuthMode.resetPassword && isConfigured) {
      await _authService.signOut();
      _setStage(AuthStage.unauthenticated);
    }

    _mode = AuthMode.login;
    _errorMessage = null;
    _statusMessage = null;
    passwordController.clear();
    confirmPasswordController.clear();
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Future<void> _handleInitialAuthLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        _handleIncomingAuthLink(uri);
      }
    } catch (_) {
      // Deep-link handling should never block the auth screen from loading.
    }
  }

  void _handleIncomingAuthLink(Uri uri) {
    final isAuthCallback = uri.scheme == 'ownzith' && uri.host == 'auth';
    if (!isAuthCallback) {
      return;
    }

    if (_lastHandledAuthLink == uri) {
      return;
    }
    _lastHandledAuthLink = uri;

    final isEmailConfirmation =
        uri.queryParameters['flow'] == 'email-confirmation' ||
        (_mode == AuthMode.join &&
            (_statusMessage ?? '').startsWith('Account created.') &&
            uri.queryParameters.containsKey('code'));

    if (!isEmailConfirmation) {
      return;
    }

    _handleEmailConfirmationReturned();
  }

  Future<void> _handleEmailConfirmationReturned() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (_isDisposed) {
      return;
    }

    if (_authService.currentSession != null) {
      _mode = AuthMode.login;
      _errorMessage = null;
      _statusMessage = null;
      _stage = AuthStage.authenticated;
      notifyListeners();
      return;
    }

    _mode = AuthMode.login;
    _stage = AuthStage.unauthenticated;
    _errorMessage = null;
    _statusMessage =
        'Email confirmed. Sign in to continue into your Ownzith archive.';
    passwordController.clear();
    confirmPasswordController.clear();
    notifyListeners();
  }

  Future<void> submit() async {
    _errorMessage = null;
    _statusMessage = null;

    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (_mode == AuthMode.forgotPassword) {
      if (email.isEmpty) {
        _errorMessage = 'Email is required.';
        if (!_isDisposed) {
          notifyListeners();
        }
        return;
      }
    } else if (_mode == AuthMode.resetPassword) {
      if (password.isEmpty || confirmPassword.isEmpty) {
        _errorMessage = 'Enter and confirm your new password.';
        if (!_isDisposed) {
          notifyListeners();
        }
        return;
      }

      if (password.length < 8) {
        _errorMessage = 'Use at least 8 characters for your new password.';
        if (!_isDisposed) {
          notifyListeners();
        }
        return;
      }

      if (password != confirmPassword) {
        _errorMessage = 'The new passwords do not match.';
        if (!_isDisposed) {
          notifyListeners();
        }
        return;
      }
    } else if (email.isEmpty || password.isEmpty) {
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
        await _authService.signInWithPassword(email: email, password: password);
      } else if (_mode == AuthMode.join) {
        final response = await _authService.signUp(
          email: email,
          password: password,
        );

        if (response.session == null) {
          _statusMessage =
              'Account created. Check your email to confirm access to the archive.';
        }
      } else if (_mode == AuthMode.forgotPassword) {
        await _authService.sendPasswordResetEmail(email: email);
        _statusMessage =
            'Password reset email sent. Open the link on this device to choose a new password.';
      } else if (_mode == AuthMode.resetPassword) {
        await _authService.updatePassword(password: password);
        passwordController.clear();
        confirmPasswordController.clear();
        _mode = AuthMode.login;
        _statusMessage = 'Password updated. You can continue into the archive.';
        _stage = AuthStage.authenticated;
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
    _linkSubscription?.cancel();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
