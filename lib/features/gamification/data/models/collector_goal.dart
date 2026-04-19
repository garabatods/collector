import '../../../collection/data/models/collection_library_navigation_preset.dart';
import 'collector_badge.dart';

enum CollectorGoalActionType { addItem, openLibrary, openInsights }

class CollectorGoalAction {
  const CollectorGoalAction({
    required this.type,
    required this.label,
    this.libraryPreset,
  });

  final CollectorGoalActionType type;
  final String label;
  final CollectionLibraryNavigationPreset? libraryPreset;
}

class CollectorGoal {
  const CollectorGoal({
    required this.id,
    required this.title,
    required this.supportingText,
    required this.progressCurrent,
    required this.progressTarget,
    required this.progressLabel,
    this.action,
    this.rewardBadgeId,
  });

  final String id;
  final String title;
  final String supportingText;
  final int? progressCurrent;
  final int? progressTarget;
  final String? progressLabel;
  final CollectorGoalAction? action;
  final CollectorBadgeId? rewardBadgeId;

  double? get progressValue {
    final current = progressCurrent;
    final target = progressTarget;
    if (current == null || target == null || target <= 0) {
      return null;
    }
    return (current / target).clamp(0, 1);
  }
}
