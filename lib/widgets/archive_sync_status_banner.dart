import 'package:flutter/material.dart';

import '../core/data/archive_repository.dart';
import '../core/data/archive_types.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class ArchiveSyncStatusBanner extends StatelessWidget {
  const ArchiveSyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SyncStatus>(
      valueListenable: ArchiveRepository.instance.syncStatus,
      builder: (context, status, _) {
        final showBanner = status.isSyncing || status.isOffline;
        if (!showBanner) {
          return const SizedBox.shrink();
        }

        final tone = status.isOffline ? AppColors.secondary : AppColors.primary;
        final icon = status.isOffline
            ? Icons.cloud_off_rounded
            : Icons.sync_rounded;
        final message = status.message ??
            (status.isOffline
                ? 'Showing saved archive while offline.'
                : 'Refreshing your archive…');

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tone.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Icon(icon, color: tone, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tone,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
