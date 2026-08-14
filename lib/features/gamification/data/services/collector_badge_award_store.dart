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
  static const _legacyFileName = 'collector_badge_awards.json';
  Future<void> _syncQueue = Future<void>.value();

  Future<CollectorBadgeSyncResult> syncUnlocked(
    String userId,
    List<CollectorBadgeDefinition> unlocked,
  ) async {
    return _runSyncLocked(() async {
      final existingSnapshot = await _readRawAwards(userId);
      final existing = Map<String, String>.of(existingSnapshot.awards);
      var didChange = false;
      final shouldReportNewAwards = existingSnapshot.canReportNewAwards;
      final newKeys = <String>{};

      for (final badge in unlocked) {
        final key = badge.id.name;
        if (!existing.containsKey(key)) {
          existing[key] = DateTime.now().toIso8601String();
          didChange = true;
          newKeys.add(key);
        }
      }

      if (didChange || !existingSnapshot.exists) {
        try {
          final file = await _awardsFile(userId);
          await file.writeAsString(
            jsonEncode(<String, Object?>{
              'initialized_for_notifications': true,
              'awards': existing,
            }),
          );
        } catch (_) {
          // Ignore persistence issues. Badges should still render from current data.
        }
      }

      final awards = _toAwards(existing);
      final newAwards = shouldReportNewAwards
          ? awards
                .where((award) => newKeys.contains(award.badge.id.name))
                .toList(growable: false)
          : const <CollectorBadgeAward>[];

      return CollectorBadgeSyncResult(awards: awards, newAwards: newAwards);
    });
  }

  Future<List<CollectorBadgeAward>> readAwards(String userId) async {
    final snapshot = await _readRawAwards(userId);
    return _toAwards(snapshot.awards);
  }

  Future<_RawBadgeAwardSnapshot> _readRawAwards(String userId) async {
    try {
      final file = await _awardsFile(userId);
      if (!await file.exists()) {
        return const _RawBadgeAwardSnapshot(
          awards: <String, String>{},
          exists: false,
          canReportNewAwards: false,
        );
      }

      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) {
        return const _RawBadgeAwardSnapshot(
          awards: <String, String>{},
          exists: true,
          canReportNewAwards: false,
        );
      }

      final awards = decoded['awards'];
      if (awards is! Map) {
        return const _RawBadgeAwardSnapshot(
          awards: <String, String>{},
          exists: true,
          canReportNewAwards: false,
        );
      }

      final parsedAwards = awards.map(
        (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
      );
      final hasInitializedNotifications =
          decoded['initialized_for_notifications'] == true;
      return _RawBadgeAwardSnapshot(
        awards: parsedAwards,
        exists: true,
        canReportNewAwards:
            hasInitializedNotifications || parsedAwards.isNotEmpty,
      );
    } catch (_) {
      return const _RawBadgeAwardSnapshot(
        awards: <String, String>{},
        exists: false,
        canReportNewAwards: false,
      );
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

  Future<File> _awardsFile(String userId) async {
    final directory = await getApplicationDocumentsDirectory();
    final safeUserId = userId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final fileName = safeUserId.isEmpty
        ? _legacyFileName
        : 'collector_badge_awards_$safeUserId.json';
    return File(p.join(directory.path, fileName));
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

class _RawBadgeAwardSnapshot {
  const _RawBadgeAwardSnapshot({
    required this.awards,
    required this.exists,
    required this.canReportNewAwards,
  });

  final Map<String, String> awards;
  final bool exists;
  final bool canReportNewAwards;
}
