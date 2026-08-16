import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/collector_haptics.dart';
import '../../../core/data/archive_repository.dart';
import '../data/models/collector_badge.dart';
import '../data/services/collector_badge_award_store.dart';
import '../data/services/collector_badge_engine.dart';
import '../../../widgets/collector_badge_unlock_sheet.dart';

/// Presents one consolidated achievement sheet only after a completed action
/// initiated in the app. Startup, sign-in, sync, and device migration never
/// call this coordinator.
class CollectorAchievementNotifier {
  CollectorAchievementNotifier._();

  static final instance = CollectorAchievementNotifier._();

  final _archiveRepository = ArchiveRepository.instance;
  final _awardStore = CollectorBadgeAwardStore.instance;
  Future<void> _presentationQueue = Future<void>.value();

  Future<void> celebrateAfterUserAction(BuildContext context) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _archiveRepository.syncIfNeeded(force: true);
      final summary = await _archiveRepository.watchHomeSummary().first;
      if (summary.userId != userId) return;

      final progress = CollectorProgressSnapshot.fromHomeSummary(summary);
      final result = await _awardStore.claimUnlockedForUserAction(
        userId,
        CollectorBadgeEngine.unlockedBadges(progress),
      );
      if (result.newAwards.isEmpty || !context.mounted) return;
      await _enqueuePresentation(context, result.newAwards);
    } catch (_) {
      // Achievement delivery must never make a completed collection action fail.
    }
  }

  Future<void> _enqueuePresentation(
    BuildContext context,
    List<CollectorBadgeAward> awards,
  ) {
    final result = Completer<void>();
    _presentationQueue = _presentationQueue.catchError((_) {}).then((_) async {
      if (!context.mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) {
        result.complete();
        return;
      }
      try {
        CollectorHaptics.medium();
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => CollectorBadgeUnlockSheet(awards: awards),
        );
        result.complete();
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }
}
