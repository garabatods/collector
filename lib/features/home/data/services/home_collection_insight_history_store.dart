import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/home_collection_insight.dart';

class HomeCollectionInsightHistoryEntry {
  const HomeCollectionInsightHistoryEntry({
    required this.id,
    required this.family,
    required this.shownAt,
    this.primaryEntityKey,
  });

  final String id;
  final HomeCollectionInsightFamily family;
  final DateTime shownAt;
  final String? primaryEntityKey;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'family': family.name,
      'shown_at': shownAt.toIso8601String(),
      'primary_entity_key': primaryEntityKey,
    };
  }

  factory HomeCollectionInsightHistoryEntry.fromJson(
    Map<String, Object?> json,
  ) {
    final familyName = json['family'];
    final shownAtValue = json['shown_at'];
    return HomeCollectionInsightHistoryEntry(
      id: json['id'] as String? ?? '',
      family: HomeCollectionInsightFamily.values.firstWhere(
        (value) => value.name == familyName,
        orElse: () => HomeCollectionInsightFamily.identity,
      ),
      shownAt:
          DateTime.tryParse(shownAtValue as String? ?? '') ?? DateTime.now(),
      primaryEntityKey: json['primary_entity_key'] as String?,
    );
  }
}

class HomeCollectionInsightHistory {
  const HomeCollectionInsightHistory({required this.entries});

  static const empty = HomeCollectionInsightHistory(
    entries: <HomeCollectionInsightHistoryEntry>[],
  );

  final List<HomeCollectionInsightHistoryEntry> entries;

  HomeCollectionInsightHistoryEntry? get latest =>
      entries.isEmpty ? null : entries.first;
}

class HomeCollectionInsightHistoryStore {
  HomeCollectionInsightHistoryStore._();

  static final instance = HomeCollectionInsightHistoryStore._();
  static const _fileName = 'home_collection_insight_history.json';
  static const _maxEntries = 12;

  Future<HomeCollectionInsightHistory> read() async {
    try {
      final file = await _historyFile();
      if (!await file.exists()) {
        return HomeCollectionInsightHistory.empty;
      }

      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) {
        return HomeCollectionInsightHistory.empty;
      }

      final rawEntries = decoded['entries'];
      if (rawEntries is! List) {
        return HomeCollectionInsightHistory.empty;
      }

      final entries = rawEntries
          .whereType<Map>()
          .map(
            (entry) => HomeCollectionInsightHistoryEntry.fromJson(
              entry.map(
                (key, value) => MapEntry(key.toString(), value as Object?),
              ),
            ),
          )
          .toList(growable: false);

      return HomeCollectionInsightHistory(entries: entries);
    } catch (_) {
      return HomeCollectionInsightHistory.empty;
    }
  }

  Future<HomeCollectionInsightHistory> recordShown(
    HomeCollectionInsight insight,
    HomeCollectionInsightHistory history,
  ) async {
    final entry = HomeCollectionInsightHistoryEntry(
      id: insight.id,
      family: insight.family,
      shownAt: DateTime.now(),
      primaryEntityKey: insight.primaryEntityKey,
    );

    final nextEntries = <HomeCollectionInsightHistoryEntry>[
      entry,
      ...history.entries.where((existing) => existing.id != insight.id),
    ].take(_maxEntries).toList(growable: false);

    final nextHistory = HomeCollectionInsightHistory(entries: nextEntries);

    try {
      final file = await _historyFile();
      await file.writeAsString(
        jsonEncode(<String, Object?>{
          'entries': nextEntries.map((value) => value.toJson()).toList(),
        }),
      );
    } catch (_) {
      // Ignore persistence failures. The feature should stay usable.
    }

    return nextHistory;
  }

  Future<File> _historyFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File(p.join(directory.path, _fileName));
  }
}
