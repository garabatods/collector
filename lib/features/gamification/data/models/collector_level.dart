class CollectorLevel {
  const CollectorLevel({
    required this.level,
    required this.title,
    required this.description,
    required this.minBadges,
    required this.maxBadges,
    required this.unlockedBadgesCount,
    required this.totalBadgesCount,
  });

  final int level;
  final String title;
  final String description;
  final int minBadges;
  final int maxBadges;
  final int unlockedBadgesCount;
  final int totalBadgesCount;

  String get label => 'Level $level · $title';

  String get assetPath {
    switch (level) {
      case 1:
        return 'assets/collector_levels/collector_level_1.png';
      case 2:
        return 'assets/collector_levels/collector_level_2.png';
      case 3:
        return 'assets/collector_levels/collector_level_3.png';
      case 4:
        return 'assets/collector_levels/collector_level_4.png';
      case 5:
      default:
        return 'assets/collector_levels/level_collector.png';
    }
  }
}

class CollectorLevelDefinition {
  const CollectorLevelDefinition({
    required this.level,
    required this.title,
    required this.description,
    required this.minBadges,
    required this.maxBadges,
  });

  final int level;
  final String title;
  final String description;
  final int minBadges;
  final int maxBadges;
}

const collectorLevelDefinitions = <CollectorLevelDefinition>[
  CollectorLevelDefinition(
    level: 1,
    title: 'New Collector',
    description: 'The shelf is just getting started.',
    minBadges: 0,
    maxBadges: 1,
  ),
  CollectorLevelDefinition(
    level: 2,
    title: 'Starting Shelf',
    description: 'The archive is beginning to take shape.',
    minBadges: 2,
    maxBadges: 4,
  ),
  CollectorLevelDefinition(
    level: 3,
    title: 'Curated Collector',
    description: 'Your collection is showing real taste and intention.',
    minBadges: 5,
    maxBadges: 7,
  ),
  CollectorLevelDefinition(
    level: 4,
    title: 'Archive Builder',
    description: 'The shelf has depth and a strong collector rhythm.',
    minBadges: 8,
    maxBadges: 10,
  ),
  CollectorLevelDefinition(
    level: 5,
    title: 'Collection Master',
    description: 'You have unlocked the highest current collector standing.',
    minBadges: 11,
    maxBadges: 13,
  ),
];

CollectorLevel resolveCollectorLevel({
  required int unlockedBadgesCount,
  required int totalBadgesCount,
}) {
  final definition = collectorLevelDefinitions.firstWhere(
    (definition) =>
        unlockedBadgesCount >= definition.minBadges &&
        unlockedBadgesCount <= definition.maxBadges,
    orElse: () => collectorLevelDefinitions.last,
  );

  return CollectorLevel(
    level: definition.level,
    title: definition.title,
    description: definition.description,
    minBadges: definition.minBadges,
    maxBadges: definition.maxBadges,
    unlockedBadgesCount: unlockedBadgesCount,
    totalBadgesCount: totalBadgesCount,
  );
}

CollectorLevelDefinition? nextCollectorLevelDefinition(CollectorLevel level) {
  for (final definition in collectorLevelDefinitions) {
    if (definition.level > level.level) {
      return definition;
    }
  }
  return null;
}
