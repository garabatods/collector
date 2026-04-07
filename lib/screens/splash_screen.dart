import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.9,
                  colors: [
                    AppColors.splashGlow,
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(),
                  SizedBox(
                    width: 312,
                    child: SvgPicture.asset(
                      'asse/logo_collector.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'MUSEUM-GRADE\nARCHIVE',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.outline,
                              fontSize: 9,
                            ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.outlineVariant,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'DIGITAL CURATOR\nV2.0',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.outline,
                              fontSize: 9,
                            ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 192,
                    height: 1,
                    color: AppColors.surfaceContainerHighest,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 64,
                      height: 1,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.primary,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'SYNCHRONIZING VAULT',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 9,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'INITIALIZING SECURE EXHIBITION ENVIRONMENT...',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.outline,
                          fontSize: 8,
                          letterSpacing: 0.8,
                        ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
