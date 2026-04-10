import 'package:flutter/material.dart';

import '../core/data/archive_repository.dart';
import '../core/data/archive_types.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'collector_loading_overlay.dart';
import 'collector_panel.dart';

class ArchiveBootstrapGate extends StatefulWidget {
  const ArchiveBootstrapGate({
    super.key,
    required this.child,
    this.loadingLabel = 'Loading your archive...',
    this.offlineTitle = 'Connect once to download your archive.',
    this.offlineDescription =
        'You are signed in, but this device has not downloaded your collection yet.',
  });

  final Widget child;
  final String loadingLabel;
  final String offlineTitle;
  final String offlineDescription;

  @override
  State<ArchiveBootstrapGate> createState() => _ArchiveBootstrapGateState();
}

class _ArchiveBootstrapGateState extends State<ArchiveBootstrapGate> {
  var _isRetrying = false;

  Future<void> _retry() async {
    if (_isRetrying) {
      return;
    }

    setState(() {
      _isRetrying = true;
    });

    try {
      await ArchiveRepository.instance.syncIfNeeded(force: true);
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SyncStatus>(
      valueListenable: ArchiveRepository.instance.syncStatus,
      builder: (context, status, _) {
        if (status.hasCompletedInitialSync) {
          return widget.child;
        }

        if (status.isSyncing) {
          return CollectorLoadingOverlay(label: widget.loadingLabel);
        }

        if (status.isOffline) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: CollectorPanel(
                padding: const EdgeInsets.all(AppSpacing.xl),
                backgroundColor:
                    AppColors.surfaceContainer.withValues(alpha: 0.94),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 42,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      widget.offlineTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      status.message ?? widget.offlineDescription,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: _isRetrying ? null : _retry,
                      child: Text(_isRetrying ? 'Retrying...' : 'Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: CollectorPanel(
              padding: const EdgeInsets.all(AppSpacing.xl),
              backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.94),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 42,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Could not load your archive.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    status.message ??
                        'The first archive download did not complete.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: _isRetrying ? null : _retry,
                    child: Text(_isRetrying ? 'Retrying...' : 'Retry Sync'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
