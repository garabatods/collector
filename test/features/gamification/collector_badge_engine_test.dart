import 'package:flutter_test/flutter_test.dart';
import 'package:collectorapp/features/gamification/data/models/collector_badge.dart';
import 'package:collectorapp/features/gamification/data/services/collector_badge_engine.dart';

void main() {
  test('does not award badges for an empty archive', () {
    final unlocked = CollectorBadgeEngine.unlockedBadges(
      const CollectorProgressSnapshot(
        totalItems: 0,
        categoryCount: 0,
        favoriteCount: 0,
        photoCount: 0,
        topCategoryItemCount: 0,
        topFranchiseItemCount: 0,
      ),
    );

    expect(unlocked, isEmpty);
  });

  test('includes every threshold reached by a completed action', () {
    final unlocked = CollectorBadgeEngine.unlockedBadges(
      const CollectorProgressSnapshot(
        totalItems: 10,
        categoryCount: 4,
        favoriteCount: 10,
        photoCount: 10,
        topCategoryItemCount: 10,
        topFranchiseItemCount: 10,
      ),
    );

    expect(
      unlocked.map((badge) => badge.id),
      containsAll(<CollectorBadgeId>[
        CollectorBadgeId.firstShelf,
        CollectorBadgeId.archiveStarter,
        CollectorBadgeId.favoriteFinder,
        CollectorBadgeId.curatedEye,
        CollectorBadgeId.categoryBuilder,
        CollectorBadgeId.focusedCollector,
        CollectorBadgeId.universeBuilder,
        CollectorBadgeId.photoReady,
        CollectorBadgeId.photoKeeper,
        CollectorBadgeId.fullyFramed,
      ]),
    );
  });
}
