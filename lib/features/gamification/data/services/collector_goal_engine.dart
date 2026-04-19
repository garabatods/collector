import '../../../../core/data/archive_types.dart';
import '../../../collection/data/models/collection_library_navigation_preset.dart';
import '../models/collector_badge.dart';
import '../models/collector_goal.dart';

final class CollectorGoalEngine {
  const CollectorGoalEngine._();

  static List<CollectorGoal> buildGoals({
    required ArchiveHomeSummary summary,
    required Set<CollectorBadgeId> earnedBadgeIds,
  }) {
    final progress = CollectorProgressSnapshot.fromHomeSummary(summary);
    final missingPhotoCount = progress.totalItems - progress.photoCount;
    final goals = <CollectorGoal>[];

    if (progress.totalItems == 0) {
      return [
        const CollectorGoal(
          id: 'add-first-item',
          title: 'Add your first item',
          supportingText: 'Start the shelf and unlock your first milestone.',
          progressCurrent: 0,
          progressTarget: 1,
          progressLabel: '0 / 1',
          rewardBadgeId: CollectorBadgeId.firstShelf,
          action: CollectorGoalAction(
            type: CollectorGoalActionType.addItem,
            label: 'Add Item',
          ),
        ),
      ];
    }

    if (!earnedBadgeIds.contains(CollectorBadgeId.photoReady) &&
        missingPhotoCount > 0) {
      goals.add(
        CollectorGoal(
          id: 'add-photo',
          title: 'Add a photo to 1 item',
          supportingText:
              'Bring more of your archive to life with photography.',
          progressCurrent: progress.photoCount,
          progressTarget: progress.totalItems == 0 ? 1 : progress.totalItems,
          progressLabel: '${progress.photoCount} / ${progress.totalItems}',
          rewardBadgeId: CollectorBadgeId.photoReady,
          action: const CollectorGoalAction(
            type: CollectorGoalActionType.openLibrary,
            label: 'Open Library',
            libraryPreset: CollectionLibraryNavigationPreset(
              missingPhotoOnly: true,
            ),
          ),
        ),
      );
    }

    if (!earnedBadgeIds.contains(CollectorBadgeId.favoriteFinder) &&
        progress.favoriteCount == 0) {
      goals.add(
        const CollectorGoal(
          id: 'pick-first-favorite',
          title: 'Pick your first favorite',
          supportingText:
              'Mark the first piece you never want to lose track of.',
          progressCurrent: 0,
          progressTarget: 1,
          progressLabel: '0 / 1',
          rewardBadgeId: CollectorBadgeId.favoriteFinder,
          action: CollectorGoalAction(
            type: CollectorGoalActionType.openLibrary,
            label: 'Open Library',
          ),
        ),
      );
    }

    if (!earnedBadgeIds.contains(CollectorBadgeId.archiveStarter) &&
        progress.totalItems < 10) {
      goals.add(
        CollectorGoal(
          id: 'reach-archive-starter',
          title: 'Catalog your next pickup',
          supportingText:
              'Keep building the shelf and lock in your starter milestone.',
          progressCurrent: progress.totalItems,
          progressTarget: 10,
          progressLabel: '${progress.totalItems} / 10',
          rewardBadgeId: CollectorBadgeId.archiveStarter,
          action: const CollectorGoalAction(
            type: CollectorGoalActionType.addItem,
            label: 'Add Item',
          ),
        ),
      );
    }

    if (earnedBadgeIds.contains(CollectorBadgeId.archiveStarter) &&
        !earnedBadgeIds.contains(CollectorBadgeId.shelfExpander) &&
        progress.totalItems < 25) {
      goals.add(
        CollectorGoal(
          id: 'reach-shelf-expander',
          title: 'Grow toward 25 items',
          supportingText:
              'Expand the archive until it starts feeling like a true shelf.',
          progressCurrent: progress.totalItems,
          progressTarget: 25,
          progressLabel: '${progress.totalItems} / 25',
          rewardBadgeId: CollectorBadgeId.shelfExpander,
          action: const CollectorGoalAction(
            type: CollectorGoalActionType.addItem,
            label: 'Add Item',
          ),
        ),
      );
    }

    if (earnedBadgeIds.contains(CollectorBadgeId.shelfExpander) &&
        !earnedBadgeIds.contains(CollectorBadgeId.deepArchive) &&
        progress.totalItems < 50) {
      goals.add(
        CollectorGoal(
          id: 'reach-deep-archive',
          title: 'Push toward 50 items',
          supportingText:
              'You are close to turning the archive into a deeper collection.',
          progressCurrent: progress.totalItems,
          progressTarget: 50,
          progressLabel: '${progress.totalItems} / 50',
          rewardBadgeId: CollectorBadgeId.deepArchive,
          action: const CollectorGoalAction(
            type: CollectorGoalActionType.addItem,
            label: 'Add Item',
          ),
        ),
      );
    }

    if (earnedBadgeIds.contains(CollectorBadgeId.deepArchive) &&
        !earnedBadgeIds.contains(CollectorBadgeId.centuryShelf) &&
        progress.totalItems < 100) {
      goals.add(
        CollectorGoal(
          id: 'reach-century-shelf',
          title: 'Build toward 100 items',
          supportingText:
              'Keep going and turn the shelf into a true long-term archive.',
          progressCurrent: progress.totalItems,
          progressTarget: 100,
          progressLabel: '${progress.totalItems} / 100',
          rewardBadgeId: CollectorBadgeId.centuryShelf,
          action: const CollectorGoalAction(
            type: CollectorGoalActionType.addItem,
            label: 'Add Item',
          ),
        ),
      );
    }

    if (!earnedBadgeIds.contains(CollectorBadgeId.categoryBuilder) &&
        progress.totalItems >= 2 &&
        progress.categoryCount < 4) {
      goals.add(
        CollectorGoal(
          id: 'broaden-categories',
          title: 'Broaden the shelf',
          supportingText:
              'A little more variety will make the archive feel fuller.',
          progressCurrent: progress.categoryCount,
          progressTarget: 4,
          progressLabel: '${progress.categoryCount} / 4',
          rewardBadgeId: CollectorBadgeId.categoryBuilder,
          action: const CollectorGoalAction(
            type: CollectorGoalActionType.addItem,
            label: 'Add Item',
          ),
        ),
      );
    }

    if (earnedBadgeIds.contains(CollectorBadgeId.photoReady) &&
        !earnedBadgeIds.contains(CollectorBadgeId.photoKeeper) &&
        progress.totalItems >= 10 &&
        progress.photoCoverageRatio < 0.9) {
      goals.add(
        CollectorGoal(
          id: 'reach-photo-keeper',
          title: 'Lift photo coverage to 90%',
          supportingText:
              'Better photo coverage makes the archive easier to browse.',
          progressCurrent: (progress.photoCoverageRatio * 100).round(),
          progressTarget: 90,
          progressLabel:
              '${(progress.photoCoverageRatio * 100).round().clamp(0, 100)}% / 90%',
          rewardBadgeId: CollectorBadgeId.photoKeeper,
          action: const CollectorGoalAction(
            type: CollectorGoalActionType.openLibrary,
            label: 'Open Library',
            libraryPreset: CollectionLibraryNavigationPreset(
              missingPhotoOnly: true,
            ),
          ),
        ),
      );
    }

    if (earnedBadgeIds.contains(CollectorBadgeId.photoKeeper) &&
        !earnedBadgeIds.contains(CollectorBadgeId.fullyFramed) &&
        progress.totalItems >= 10 &&
        progress.photoCoverageRatio < 1) {
      goals.add(
        CollectorGoal(
          id: 'reach-fully-framed',
          title: 'Finish the last photos',
          supportingText:
              'Close the last photo gaps and complete the visual archive.',
          progressCurrent: progress.photoCount,
          progressTarget: progress.totalItems,
          progressLabel: '${progress.photoCount} / ${progress.totalItems}',
          rewardBadgeId: CollectorBadgeId.fullyFramed,
          action: const CollectorGoalAction(
            type: CollectorGoalActionType.openLibrary,
            label: 'Open Library',
            libraryPreset: CollectionLibraryNavigationPreset(
              missingPhotoOnly: true,
            ),
          ),
        ),
      );
    }

    if (earnedBadgeIds.contains(CollectorBadgeId.favoriteFinder) &&
        !earnedBadgeIds.contains(CollectorBadgeId.curatedEye) &&
        progress.favoriteCount < 10) {
      goals.add(
        CollectorGoal(
          id: 'reach-curated-eye',
          title: 'Curate 10 favorites',
          supportingText: 'Save the pieces that best define your taste.',
          progressCurrent: progress.favoriteCount,
          progressTarget: 10,
          progressLabel: '${progress.favoriteCount} / 10',
          rewardBadgeId: CollectorBadgeId.curatedEye,
          action: const CollectorGoalAction(
            type: CollectorGoalActionType.openLibrary,
            label: 'Open Library',
          ),
        ),
      );
    }

    if (earnedBadgeIds.contains(CollectorBadgeId.categoryBuilder) &&
        !earnedBadgeIds.contains(CollectorBadgeId.focusedCollector) &&
        progress.topCategoryItemCount > 0 &&
        progress.topCategoryItemCount < 10) {
      goals.add(
        CollectorGoal(
          id: 'reach-focused-collector',
          title: 'Build one category to 10 items',
          supportingText:
              'Depth in one category will earn your focused collector mark.',
          progressCurrent: progress.topCategoryItemCount,
          progressTarget: 10,
          progressLabel: '${progress.topCategoryItemCount} / 10',
          rewardBadgeId: CollectorBadgeId.focusedCollector,
          action: const CollectorGoalAction(
            type: CollectorGoalActionType.addItem,
            label: 'Add Item',
          ),
        ),
      );
    }

    if (!earnedBadgeIds.contains(CollectorBadgeId.universeBuilder) &&
        progress.topFranchiseItemCount > 0 &&
        progress.topFranchiseItemCount < 10) {
      goals.add(
        CollectorGoal(
          id: 'reach-universe-builder',
          title: 'Build one franchise to 10 items',
          supportingText:
              'Build more depth in one universe and make it unmistakably yours.',
          progressCurrent: progress.topFranchiseItemCount,
          progressTarget: 10,
          progressLabel: '${progress.topFranchiseItemCount} / 10',
          rewardBadgeId: CollectorBadgeId.universeBuilder,
          action: const CollectorGoalAction(
            type: CollectorGoalActionType.addItem,
            label: 'Add Item',
          ),
        ),
      );
    }

    if (goals.isEmpty && progress.totalItems >= 3) {
      goals.add(
        const CollectorGoal(
          id: 'explore-insights',
          title: 'Check your collection signals',
          supportingText: 'See what your archive is starting to say about you.',
          progressCurrent: null,
          progressTarget: null,
          progressLabel: null,
          action: CollectorGoalAction(
            type: CollectorGoalActionType.openInsights,
            label: 'Open Insights',
          ),
        ),
      );
    }

    return goals.take(3).toList(growable: false);
  }
}
