import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum CollectorSnackBarTone { success, error, info, warning }

abstract final class CollectorSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    CollectorSnackBarTone tone = CollectorSnackBarTone.info,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    showOn(
      ScaffoldMessenger.of(context),
      message: message,
      tone: tone,
      icon: icon,
      duration: duration,
    );
  }

  static void showOn(
    ScaffoldMessengerState messenger, {
    required String message,
    CollectorSnackBarTone tone = CollectorSnackBarTone.info,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          duration: duration,
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            112,
          ),
          content: _CollectorSnackBarContent(
            message: message,
            tone: tone,
            icon: icon ?? _defaultIconForTone(tone),
          ),
        ),
      );
  }

  static IconData _defaultIconForTone(CollectorSnackBarTone tone) {
    return switch (tone) {
      CollectorSnackBarTone.success => Icons.check_rounded,
      CollectorSnackBarTone.error => Icons.warning_amber_rounded,
      CollectorSnackBarTone.info => Icons.info_outline_rounded,
      CollectorSnackBarTone.warning => Icons.priority_high_rounded,
    };
  }
}

class _CollectorSnackBarContent extends StatelessWidget {
  const _CollectorSnackBarContent({
    required this.message,
    required this.tone,
    required this.icon,
  });

  final String message;
  final CollectorSnackBarTone tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final toneColor = _colorForTone(tone);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: toneColor.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: toneColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: toneColor, size: 18),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurface,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForTone(CollectorSnackBarTone tone) {
    return switch (tone) {
      CollectorSnackBarTone.success => AppColors.success,
      CollectorSnackBarTone.error => AppColors.error,
      CollectorSnackBarTone.info => AppColors.primary,
      CollectorSnackBarTone.warning => AppColors.warning,
    };
  }
}
