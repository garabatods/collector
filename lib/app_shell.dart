import 'package:flutter/material.dart';

import 'auth/auth_controller.dart';
import 'auth/auth_service.dart';
import 'screens/authentication_screen.dart';
import 'screens/home_dashboard_screen.dart';
import 'screens/splash_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.isSupabaseConfigured,
    this.splashDelay = const Duration(milliseconds: 3000),
  });

  final bool isSupabaseConfigured;
  final Duration splashDelay;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final AuthController _controller;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(isConfigured: widget.isSupabaseConfigured);
    _controller = AuthController(
      authService: _authService,
      splashDelay: widget.splashDelay,
    );
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        switch (_controller.stage) {
          case AuthStage.splash:
            return const SplashScreen();
          case AuthStage.unauthenticated:
            return AuthenticationScreen(controller: _controller);
          case AuthStage.authenticated:
            return HomeDashboardScreen(
              isSupabaseConfigured: widget.isSupabaseConfigured,
              onSignOut: _controller.signOut,
            );
        }
      },
    );
  }
}
