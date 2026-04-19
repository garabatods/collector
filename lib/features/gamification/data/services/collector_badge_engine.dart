import '../models/collector_badge.dart';

final class CollectorBadgeEngine {
  const CollectorBadgeEngine._();

  static List<CollectorBadgeDefinition> unlockedBadges(
    CollectorProgressSnapshot snapshot,
  ) {
    final unlocked = <CollectorBadgeDefinition>[];

    if (snapshot.totalItems >= 1) {
      unlocked.add(_definition(CollectorBadgeId.firstShelf));
    }
    if (snapshot.totalItems >= 10) {
      unlocked.add(_definition(CollectorBadgeId.archiveStarter));
    }
    if (snapshot.totalItems >= 25) {
      unlocked.add(_definition(CollectorBadgeId.shelfExpander));
    }
    if (snapshot.totalItems >= 50) {
      unlocked.add(_definition(CollectorBadgeId.deepArchive));
    }
    if (snapshot.totalItems >= 100) {
      unlocked.add(_definition(CollectorBadgeId.centuryShelf));
    }
    if (snapshot.favoriteCount >= 1) {
      unlocked.add(_definition(CollectorBadgeId.favoriteFinder));
    }
    if (snapshot.favoriteCount >= 10) {
      unlocked.add(_definition(CollectorBadgeId.curatedEye));
    }
    if (snapshot.categoryCount >= 4) {
      unlocked.add(_definition(CollectorBadgeId.categoryBuilder));
    }
    if (snapshot.topCategoryItemCount >= 10) {
      unlocked.add(_definition(CollectorBadgeId.focusedCollector));
    }
    if (snapshot.topFranchiseItemCount >= 10) {
      unlocked.add(_definition(CollectorBadgeId.universeBuilder));
    }
    if (snapshot.totalItems >= 5 && snapshot.photoCoverageRatio >= 0.7) {
      unlocked.add(_definition(CollectorBadgeId.photoReady));
    }
    if (snapshot.totalItems >= 10 && snapshot.photoCoverageRatio >= 0.9) {
      unlocked.add(_definition(CollectorBadgeId.photoKeeper));
    }
    if (snapshot.totalItems >= 10 && snapshot.photoCoverageRatio >= 1) {
      unlocked.add(_definition(CollectorBadgeId.fullyFramed));
    }

    return unlocked;
  }

  static String buildSignature(CollectorProgressSnapshot snapshot) {
    return [
      snapshot.totalItems,
      snapshot.categoryCount,
      snapshot.favoriteCount,
      snapshot.photoCount,
      snapshot.topCategoryItemCount,
      snapshot.topFranchiseItemCount,
    ].join('|');
  }

  static CollectorBadgeDefinition _definition(CollectorBadgeId id) {
    return collectorBadgeDefinitions.firstWhere((badge) => badge.id == id);
  }
}
