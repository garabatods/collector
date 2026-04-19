import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/collector_badge.dart';

class CollectorBadgeSyncResult {
  const CollectorBadgeSyncResult({
    required this.awards,
    required this.newAwards,
  });

  final List<CollectorBadgeAward> awards;
  final List<CollectorBadgeAward> newAwards;
}

class CollectorBadgeAwardStore {
  CollectorBadgeAwardStore._();

  static final instance = CollectorBadgeAwardStore._();
  static const _fileName = 'collector_badge_awards.json';
  Future<void> _syncQueue = Future<void>.value();

  Future<CollectorBadgeSyncResult> syncUnlocked(
    List<CollectorBadgeDefinition> unlocked,
  ) async {
    return _runSyncLocked(() async {
      final existing = await _readRawAwards();
      var didChange = false;
      final newKeys = <String>{};

      for (final badge in unlocked) {
        final key = badge.id.name;
        if (!existing.containsKey(key)) {
          existing[key] = DateTime.now().toIso8601String();
          didChange = true;
          newKeys.add(key);
        }
      }

      if (didChange) {
        try {
          final file = await _awardsFile();
          await file.writeAsString(
            jsonEncode(<String, Object?>{'awards': existing}),
          );
        } catch (_) {
          // Ignore persistence issues. Badges should still render from current data.
        }
      }

      final awards = _toAwards(existing);
      final newAwards = awards
          .where((award) => newKeys.contains(award.badge.id.name))
          .toList(growable: false);

      return CollectorBadgeSyncResult(awards: awards, newAwards: newAwards);
    });
  }

  Future<List<CollectorBadgeAward>> readAwards() async {
    final raw = await _readRawAwards();
    return _toAwards(raw);
  }

  Future<Map<String, String>> _readRawAwards() async {
    try {
      final file = await _awardsFile();
      if (!await file.exists()) {
        return <String, String>{};
      }

      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) {
        return <String, String>{};
      }

      final awards = decoded['awards'];
      if (awards is! Map) {
        return <String, String>{};
      }

      return awards.map(
        (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
      );
    } catch (_) {
      return <String, String>{};
    }
  }

  List<CollectorBadgeAward> _toAwards(Map<String, String> rawAwards) {
    final definitionsById = {
      for (final badge in collectorBadgeDefinitions) badge.id.name: badge,
    };

    final awards =
        rawAwards.entries
            .map((entry) {
              final definition = definitionsById[entry.key];
              if (definition == null) {
                return null;
              }
              return CollectorBadgeAward(
                badge: definition,
                awardedAt: DateTime.tryParse(entry.value) ?? DateTime.now(),
              );
            })
            .whereType<CollectorBadgeAward>()
            .toList(growable: false)
          ..sort((a, b) => b.awardedAt.compareTo(a.awardedAt));

    return awards;
  }

  Future<File> _awardsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File(p.join(directory.path, _fileName));
  }

  Future<T> _runSyncLocked<T>(Future<T> Function() action) {
    final result = Completer<T>();
    _syncQueue = _syncQueue
        .catchError((_) {
          // Keep the queue alive if a prior sync failed.
        })
        .then((_) async {
          try {
            result.complete(await action());
          } catch (error, stackTrace) {
            result.completeError(error, stackTrace);
          }
        });
    return result.future;
  }
}
