import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../../core/data/archive_types.dart';
import '../models/home_collection_insight.dart';
import 'home_collection_insight_history_store.dart';

final class HomeCollectionInsightEngine {
  const HomeCollectionInsightEngine._();

  static List<HomeCollectionInsight> rankInsights({
    required ArchiveHomeSummary summary,
    required HomeCollectionInsightHistory history,
  }) {
    final snapshot = _InsightSnapshot.fromSummary(summary);
    if (snapshot.totalItems == 0) {
      return const [];
    }

    final candidates = <HomeCollectionInsight>[
      ..._buildDominantCategoryInsights(snapshot, history),
      ..._buildDominantFranchiseInsights(snapshot, history),
      ..._buildDominantBrandInsights(snapshot, history),
      ..._buildFavoriteInsights(snapshot, history),
      ..._buildRecentMomentumInsights(snapshot, history),
      ..._buildPhotoCoverageInsights(snapshot, history),
      ..._buildPhotoOpportunityInsights(snapshot, history),
      ..._buildValueCoverageInsights(snapshot, history),
      ..._buildMilestoneInsights(snapshot, history),
    ];

    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates;
  }

  static HomeCollectionInsight? selectInsight({
    required ArchiveHomeSummary summary,
    required HomeCollectionInsightHistory history,
  }) {
    final ranked = rankInsights(summary: summary, history: history);
    if (ranked.isEmpty) {
      return null;
    }
    return ranked.first;
  }

  static String buildSessionSignature(ArchiveHomeSummary summary) {
    final rows = summary.collectibles.map((item) {
      final id = item.id ?? item.title;
      final photo = item.id == null
          ? false
          : (summary.photoRefsByCollectibleId[item.id!]?.hasImage ?? false);
      return <String>[
        id,
        item.category,
        item.franchise ?? '',
        item.brand ?? '',
        '${item.isFavorite}',
        '${item.isGrail}',
        '${item.isDuplicate}',
        '${item.openToTrade}',
        '${item.estimatedValue ?? ''}',
        '${item.createdAt?.millisecondsSinceEpoch ?? 0}',
        '${item.updatedAt?.millisecondsSinceEpoch ?? 0}',
        '$photo',
      ].join('|');
    }).toList()..sort();

    final digest = sha1.convert(utf8.encode(rows.join('||')));
    return digest.toString();
  }

  static List<HomeCollectionInsight> _buildDominantCategoryInsights(
    _InsightSnapshot snapshot,
    HomeCollectionInsightHistory history,
  ) {
    final leader = snapshot.topCategory;
    if (snapshot.totalItems < 3 || leader == null || leader.count < 3) {
      return const [];
    }

    if (leader.share < 0.35 || snapshot.categoryLead < 1) {
      return const [];
    }

    return [
      _candidate(
        id: 'dominant-category:${leader.name}',
        family: HomeCollectionInsightFamily.identity,
        accent: HomeCollectionInsightAccent.violet,
        headline: 'Your shelf leans ${leader.name}',
        supportingText:
            'They are the strongest lane in your collection right now with ${leader.count} ${_itemLabel(leader.count)}.',
        compactEyebrow: 'Top Category',
        compactValue: _compactEntityName(leader.name),
        compactSupportingText:
            '${leader.count} ${_itemLabel(leader.count)} lead your shelf',
        action: HomeCollectionInsightAction(
          type: HomeCollectionInsightActionType.openCategory,
          label: 'View ${leader.name}',
          category: leader.name,
        ),
        primaryEntityKey: leader.name,
        baseScore: 890 + (leader.count * 18),
        history: history,
      ),
    ];
  }

  static List<HomeCollectionInsight> _buildDominantFranchiseInsights(
    _InsightSnapshot snapshot,
    HomeCollectionInsightHistory history,
  ) {
    final leader = snapshot.topFranchise;
    if (leader == null || leader.count < 3 || snapshot.franchiseLead < 1) {
      return const [];
    }

    return [
      _candidate(
        id: 'dominant-franchise:${leader.name}',
        family: HomeCollectionInsightFamily.identity,
        accent: HomeCollectionInsightAccent.violet,
        headline: '${leader.name} is shaping your archive',
        supportingText:
            '${leader.count} ${_itemLabel(leader.count)} already point back to that franchise more than any other.',
        compactEyebrow: 'Top Franchise',
        compactValue: _compactEntityName(leader.name),
        compactSupportingText:
            '${leader.count} ${_itemLabel(leader.count)} point here most often',
        action: HomeCollectionInsightAction(
          type: HomeCollectionInsightActionType.openLibrary,
          label: 'Browse ${_compactEntityName(leader.name)}',
          query: leader.name,
        ),
        primaryEntityKey: leader.name,
        baseScore: 845 + (leader.count * 16),
        history: history,
      ),
    ];
  }

  static List<HomeCollectionInsight> _buildDominantBrandInsights(
    _InsightSnapshot snapshot,
    HomeCollectionInsightHistory history,
  ) {
    final leader = snapshot.topBrand;
    if (leader == null || leader.count < 3 || snapshot.brandLead < 1) {
      return const [];
    }

    return [
      _candidate(
        id: 'dominant-brand:${leader.name}',
        family: HomeCollectionInsightFamily.identity,
        accent: HomeCollectionInsightAccent.violet,
        headline: '${leader.name} keeps showing up',
        supportingText:
            '${leader.count} ${_itemLabel(leader.count)} in your archive belong to that brand, more than any other.',
        compactEyebrow: 'Top Brand',
        compactValue: _compactEntityName(leader.name),
        compactSupportingText:
            '${leader.count} ${_itemLabel(leader.count)} belong to that brand',
        action: HomeCollectionInsightAction(
          type: HomeCollectionInsightActionType.openLibrary,
          label: 'Browse ${_compactEntityName(leader.name)}',
          query: leader.name,
        ),
        primaryEntityKey: leader.name,
        baseScore: 815 + (leader.count * 16),
        history: history,
      ),
    ];
  }

  static List<HomeCollectionInsight> _buildFavoriteInsights(
    _InsightSnapshot snapshot,
    HomeCollectionInsightHistory history,
  ) {
    if (snapshot.favoriteCount < 3) {
      return const [];
    }

    final leader = snapshot.topFavoriteCategory;
    if (leader == null || leader.count < 2) {
      return const [];
    }

    return [
      _candidate(
        id: 'favorite-category:${leader.name}',
        family: HomeCollectionInsightFamily.curation,
        accent: HomeCollectionInsightAccent.emerald,
        headline: 'Favorites keep returning to ${leader.name}',
        supportingText:
            '${leader.count} of your collector picks sit in ${leader.name}, which is starting to define your taste.',
        compactEyebrow: 'Favorite Focus',
        compactValue: _compactEntityName(leader.name),
        compactSupportingText:
            '${leader.count} favorite ${_itemLabel(leader.count)} land here',
        action: const HomeCollectionInsightAction(
          type: HomeCollectionInsightActionType.scrollToFavorites,
          label: 'See Favorites',
        ),
        primaryEntityKey: leader.name,
        baseScore: 610 + (leader.count * 12),
        history: history,
      ),
    ];
  }

  static List<HomeCollectionInsight> _buildRecentMomentumInsights(
    _InsightSnapshot snapshot,
    HomeCollectionInsightHistory history,
  ) {
    final leader = snapshot.topRecentCategory;
    if (snapshot.recentSliceCount < 4 || leader == null) {
      return const [];
    }

    if (leader.count < 3 || snapshot.recentCategoryLead < 1) {
      return const [];
    }

    return [
      _candidate(
        id: 'recent-category-momentum:${leader.name}',
        family: HomeCollectionInsightFamily.momentum,
        accent: HomeCollectionInsightAccent.azure,
        headline: 'You have been on a ${leader.name} run',
        supportingText:
            '${leader.count} of your latest ${snapshot.recentSliceCount} additions landed in ${leader.name}.',
        compactEyebrow: 'Recent Focus',
        compactValue: _compactEntityName(leader.name),
        compactSupportingText:
            '${leader.count} of your latest ${snapshot.recentSliceCount} additions landed here',
        action: HomeCollectionInsightAction(
          type: HomeCollectionInsightActionType.openCategory,
          label: 'View ${leader.name}',
          category: leader.name,
        ),
        primaryEntityKey: leader.name,
        baseScore: 820 + (leader.count * 16),
        history: history,
      ),
    ];
  }

  static List<HomeCollectionInsight> _buildPhotoCoverageInsights(
    _InsightSnapshot snapshot,
    HomeCollectionInsightHistory history,
  ) {
    if (snapshot.totalItems < 5 || snapshot.photoCount == 0) {
      return const [];
    }

    final missingCount = snapshot.totalItems - snapshot.photoCount;
    if (missingCount >= 3) {
      return const [];
    }

    final ratio = snapshot.photoCoverageRatio;
    if (ratio < 0.7) {
      return const [];
    }

    final percentage = (ratio * 100).round();
    return [
      _candidate(
        id: 'photo-coverage-strength',
        family: HomeCollectionInsightFamily.curation,
        accent: HomeCollectionInsightAccent.emerald,
        headline: 'Your collection is becoming more visual',
        supportingText:
            '$percentage% of your collection already has photos, which makes the archive easier to enjoy at a glance.',
        compactEyebrow: 'Photo Coverage',
        compactValue: '$percentage%',
        compactSupportingText:
            '${snapshot.photoCount} of ${snapshot.totalItems} items already have photos',
        action: const HomeCollectionInsightAction(
          type: HomeCollectionInsightActionType.openLibrary,
          label: 'View With Photos',
          hasPhotoOnly: true,
        ),
        baseScore: 780 + percentage,
        history: history,
      ),
    ];
  }

  static List<HomeCollectionInsight> _buildPhotoOpportunityInsights(
    _InsightSnapshot snapshot,
    HomeCollectionInsightHistory history,
  ) {
    final missingCount = snapshot.totalItems - snapshot.photoCount;
    if (snapshot.totalItems < 5 || missingCount < 3) {
      return const [];
    }

    final missingRatio = missingCount / snapshot.totalItems;
    if (missingRatio < 0.3) {
      return const [];
    }

    return [
      _candidate(
        id: 'photo-coverage-opportunity',
        family: HomeCollectionInsightFamily.care,
        accent: HomeCollectionInsightAccent.amber,
        headline: 'A few pieces could use photos',
        supportingText:
            '$missingCount ${_itemLabel(missingCount)} still do not have images, so there is room to make the archive feel even richer.',
        compactEyebrow: 'Missing Photos',
        compactValue: '$missingCount',
        compactSupportingText: '${_itemLabel(missingCount)} still need images',
        action: const HomeCollectionInsightAction(
          type: HomeCollectionInsightActionType.openLibrary,
          label: 'See Missing Photos',
          missingPhotoOnly: true,
        ),
        baseScore: 790 + (missingCount * 14),
        history: history,
      ),
    ];
  }

  static List<HomeCollectionInsight> _buildValueCoverageInsights(
    _InsightSnapshot snapshot,
    HomeCollectionInsightHistory history,
  ) {
    if (snapshot.totalItems < 6 || snapshot.valueCount == 0) {
      return const [];
    }

    final ratio = snapshot.valueCoverageRatio;
    if (ratio < 0.6) {
      return const [];
    }

    final percentage = (ratio * 100).round();
    return [
      _candidate(
        id: 'value-coverage-strength',
        family: HomeCollectionInsightFamily.value,
        accent: HomeCollectionInsightAccent.rose,
        headline: 'Your value tracking is getting stronger',
        supportingText:
            '$percentage% of your collection now has value data, which is enough to start revealing better patterns.',
        compactEyebrow: 'Value Coverage',
        compactValue: '$percentage%',
        compactSupportingText:
            '${snapshot.valueCount} of ${snapshot.totalItems} items have value data',
        action: const HomeCollectionInsightAction(
          type: HomeCollectionInsightActionType.openLibrary,
          label: 'Open Library',
        ),
        baseScore: 700 + percentage,
        history: history,
      ),
    ];
  }

  static List<HomeCollectionInsight> _buildMilestoneInsights(
    _InsightSnapshot snapshot,
    HomeCollectionInsightHistory history,
  ) {
    const milestones = <int>[3, 5, 10, 25, 50, 100];
    if (!milestones.contains(snapshot.totalItems)) {
      return const [];
    }

    return [
      _candidate(
        id: 'collection-milestone:${snapshot.totalItems}',
        family: HomeCollectionInsightFamily.milestone,
        accent: HomeCollectionInsightAccent.warm,
        headline: 'Your shelf just hit ${snapshot.totalItems}',
        supportingText:
            'The collection has reached a new milestone, and it is starting to feel more like a real archive.',
        compactEyebrow: 'Milestone',
        compactValue: '${snapshot.totalItems}',
        compactSupportingText: 'items are now in your archive',
        action: const HomeCollectionInsightAction(
          type: HomeCollectionInsightActionType.openLibrary,
          label: 'Open Library',
        ),
        primaryEntityKey: '${snapshot.totalItems}',
        baseScore: 610 + snapshot.totalItems,
        history: history,
      ),
    ];
  }

  static HomeCollectionInsight _candidate({
    required String id,
    required HomeCollectionInsightFamily family,
    required HomeCollectionInsightAccent accent,
    required String headline,
    required String supportingText,
    required int baseScore,
    required HomeCollectionInsightHistory history,
    String? compactEyebrow,
    String? compactValue,
    String? compactSupportingText,
    String? primaryEntityKey,
    HomeCollectionInsightAction? action,
  }) {
    final adjustedScore =
        baseScore -
        _historyPenalty(
          id: id,
          family: family,
          primaryEntityKey: primaryEntityKey,
          history: history,
        );

    return HomeCollectionInsight(
      id: id,
      family: family,
      accent: accent,
      headline: headline,
      supportingText: supportingText,
      compactEyebrow: compactEyebrow,
      compactValue: compactValue,
      compactSupportingText: compactSupportingText,
      action: action,
      primaryEntityKey: primaryEntityKey,
      score: adjustedScore,
    );
  }

  static int _historyPenalty({
    required String id,
    required HomeCollectionInsightFamily family,
    required HomeCollectionInsightHistory history,
    String? primaryEntityKey,
  }) {
    var penalty = 0;
    for (var index = 0; index < history.entries.length; index++) {
      final entry = history.entries[index];
      final recencyWeight = index == 0
          ? 1.0
          : index == 1
          ? 0.75
          : 0.45;
      if (entry.id == id) {
        penalty += (260 * recencyWeight).round();
      }
      if (entry.family == family) {
        penalty += (110 * recencyWeight).round();
      }
      if (primaryEntityKey != null &&
          primaryEntityKey.isNotEmpty &&
          entry.primaryEntityKey == primaryEntityKey) {
        penalty += (75 * recencyWeight).round();
      }
    }
    return penalty;
  }

  static String _itemLabel(int count) => count == 1 ? 'item' : 'items';

  static String _compactEntityName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.length <= 18) {
      return trimmed;
    }

    if (trimmed.toLowerCase() == 'teenage mutant ninja turtles') {
      return 'TMNT';
    }

    final words = trimmed
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
    if (words.length >= 3) {
      final acronym = words.map((word) => word[0].toUpperCase()).join();
      if (acronym.length >= 3 && acronym.length <= 6) {
        return acronym;
      }
    }

    return trimmed;
  }
}

class _InsightSnapshot {
  const _InsightSnapshot({
    required this.totalItems,
    required this.favoriteCount,
    required this.photoCount,
    required this.valueCount,
    required this.topCategory,
    required this.topFranchise,
    required this.topBrand,
    required this.topFavoriteCategory,
    required this.topRecentCategory,
    required this.categoryLead,
    required this.franchiseLead,
    required this.brandLead,
    required this.recentCategoryLead,
    required this.recentSliceCount,
  });

  final int totalItems;
  final int favoriteCount;
  final int photoCount;
  final int valueCount;
  final _CountLeader? topCategory;
  final _CountLeader? topFranchise;
  final _CountLeader? topBrand;
  final _CountLeader? topFavoriteCategory;
  final _CountLeader? topRecentCategory;
  final int categoryLead;
  final int franchiseLead;
  final int brandLead;
  final int recentCategoryLead;
  final int recentSliceCount;

  double get photoCoverageRatio =>
      totalItems == 0 ? 0 : photoCount / totalItems;

  double get valueCoverageRatio =>
      totalItems == 0 ? 0 : valueCount / totalItems;

  factory _InsightSnapshot.fromSummary(ArchiveHomeSummary summary) {
    final categoryCounts = <String, int>{};
    final franchiseCounts = <String, int>{};
    final brandCounts = <String, int>{};
    final favoriteCategoryCounts = <String, int>{};

    var favoriteCount = 0;
    var photoCount = 0;
    var valueCount = 0;

    for (final item in summary.collectibles) {
      categoryCounts.update(
        item.category,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      final franchise = _normalized(item.franchise);
      if (franchise != null) {
        franchiseCounts.update(
          franchise,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }

      final brand = _normalized(item.brand);
      if (brand != null) {
        brandCounts.update(brand, (value) => value + 1, ifAbsent: () => 1);
      }

      if (item.isFavorite) {
        favoriteCount += 1;
        favoriteCategoryCounts.update(
          item.category,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }

      if (item.estimatedValue != null) {
        valueCount += 1;
      }

      if (item.id != null &&
          (summary.photoRefsByCollectibleId[item.id!]?.hasImage ?? false)) {
        photoCount += 1;
      }
    }

    final recentSlice = summary.recentItems.take(6).toList(growable: false);
    final recentCounts = <String, int>{};
    for (final item in recentSlice) {
      recentCounts.update(
        item.category,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    return _InsightSnapshot(
      totalItems: summary.collectibles.length,
      favoriteCount: favoriteCount,
      photoCount: photoCount,
      valueCount: valueCount,
      topCategory: _leader(categoryCounts, summary.collectibles.length),
      topFranchise: _leader(franchiseCounts, summary.collectibles.length),
      topBrand: _leader(brandCounts, summary.collectibles.length),
      topFavoriteCategory: _leader(favoriteCategoryCounts, favoriteCount),
      topRecentCategory: _leader(recentCounts, recentSlice.length),
      categoryLead: _leaderGap(categoryCounts),
      franchiseLead: _leaderGap(franchiseCounts),
      brandLead: _leaderGap(brandCounts),
      recentCategoryLead: _leaderGap(recentCounts),
      recentSliceCount: recentSlice.length,
    );
  }

  static _CountLeader? _leader(Map<String, int> counts, int total) {
    if (counts.isEmpty || total == 0) {
      return null;
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount == 0 ? a.key.compareTo(b.key) : byCount;
      });

    final top = sorted.first;
    return _CountLeader(
      name: top.key,
      count: top.value,
      share: top.value / total,
    );
  }

  static int _leaderGap(Map<String, int> counts) {
    if (counts.length < 2) {
      return counts.values.isEmpty ? 0 : counts.values.first;
    }

    final sortedValues = counts.values.toList()..sort((a, b) => b.compareTo(a));
    return sortedValues.first - sortedValues[1];
  }

  static String? _normalized(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}

class _CountLeader {
  const _CountLeader({
    required this.name,
    required this.count,
    required this.share,
  });

  final String name;
  final int count;
  final double share;
}
