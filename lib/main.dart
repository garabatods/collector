import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_shell.dart';
import 'config/supabase_config.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  runApp(
    CollectorApp(
      isSupabaseConfigured: SupabaseConfig.isConfigured,
    ),
  );
}

class CollectorApp extends StatelessWidget {
  const CollectorApp({
    super.key,
    required this.isSupabaseConfigured,
    this.splashDelay = const Duration(milliseconds: 2500),
  });

  final bool isSupabaseConfigured;
  final Duration splashDelay;

  @override
  Widget build(BuildContext context) {
    final baseTheme = AppTheme.dark();

    return MaterialApp(
      title: 'Collector',
      debugShowCheckedModeBanner: false,
      theme: baseTheme,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final adaptiveTheme = AppTheme.adaptForViewport(
          baseTheme,
          width: mediaQuery.size.width,
          height: mediaQuery.size.height,
          textScale: mediaQuery.textScaler.scale(1),
        );

        return Theme(
          data: adaptiveTheme,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: AppShell(
        isSupabaseConfigured: isSupabaseConfigured,
        splashDelay: splashDelay,
      ),
    );
  }
}
