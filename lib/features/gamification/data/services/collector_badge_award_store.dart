import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/collector_badge.dart';

class CollectorBadgeSyncResult {
  const CollectorBadgeSyncResult({
    required this.awards,
    required this.newAwards,
  });

  final List<CollectorBadgeAward> awards;
  final List<CollectorBadgeAward> newAwards;
}

/// Persists badge ownership per account and uses the on-device JSON only as a
/// one-time migration source for pre-cloud award history.
///
/// Normal reconciliation is intentionally silent. Call
/// [claimUnlockedForUserAction] only after a completed user mutation.
class CollectorBadgeAwardStore {
  CollectorBadgeAwardStore._();

  static final instance = CollectorBadgeAwardStore._();
  static const _legacyFileName = 'collector_badge_awards.json';
  Future<void> _syncQueue = Future<void>.value();
  final Set<String> _bootstrappedUserIds = <String>{};
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  Future<CollectorBadgeSyncResult> syncUnlocked(
    String userId,
    List<CollectorBadgeDefinition> unlocked,
  ) {
    return _runSyncLocked(() => _syncUnlockedSilently(userId, unlocked));
  }

  Future<CollectorBadgeSyncResult> claimUnlockedForUserAction(
    String userId,
    List<CollectorBadgeDefinition> unlocked,
  ) {
    return _runSyncLocked(() async {
      if (!_bootstrappedUserIds.contains(userId)) {
        // Without an initial baseline, there is no reliable way to distinguish
        // a historical unlock from one caused by this action. Stay silent.
        return _syncUnlockedSilently(userId, unlocked);
      }
      try {
        final createdRows = await _claimCloudAwards(userId, unlocked);
        final awards = await _readCloudAwards(userId);
        final newAwards = _toAwards(createdRows);
        if (newAwards.isNotEmpty) {
          revision.value++;
        }
        return CollectorBadgeSyncResult(awards: awards, newAwards: newAwards);
      } catch (_) {
        // Never fall back to local "new" notifications. Doing so would bring
        // back the historical/hydration alerts this migration removes.
        final legacy = await _readLegacyAwards(userId);
        return CollectorBadgeSyncResult(
          awards: await _syncLegacySilently(legacy, unlocked, userId),
          newAwards: const <CollectorBadgeAward>[],
        );
      }
    });
  }

  Future<List<CollectorBadgeAward>> readAwards(String userId) async {
    try {
      return await _readCloudAwards(userId);
    } catch (_) {
      return _toAwards((await _readLegacyAwards(userId)).awards);
    }
  }

  Future<CollectorBadgeSyncResult> _syncUnlockedSilently(
    String userId,
    List<CollectorBadgeDefinition> unlocked,
  ) async {
    if (_bootstrappedUserIds.contains(userId)) {
      try {
        return CollectorBadgeSyncResult(
          awards: await _readCloudAwards(userId),
          newAwards: const <CollectorBadgeAward>[],
        );
      } catch (_) {
        return CollectorBadgeSyncResult(
          awards: _toAwards((await _readLegacyAwards(userId)).awards),
          newAwards: const <CollectorBadgeAward>[],
        );
      }
    }

    final legacy = await _readLegacyAwards(userId);
    final candidateIds = <String>{
      ...legacy.awards.keys,
      ...unlocked.map((badge) => badge.id.name),
    };
    try {
      await _backfillCloudAwards(userId, candidateIds);
      return CollectorBadgeSyncResult(
        awards: await _readCloudAwards(userId),
        newAwards: const <CollectorBadgeAward>[],
      );
    } catch (_) {
      // A client build can safely run before its migration is deployed. It
      // keeps the existing local gallery but never presents a false unlock.
      return CollectorBadgeSyncResult(
        awards: await _syncLegacySilently(legacy, unlocked, userId),
        newAwards: const <CollectorBadgeAward>[],
      );
    } finally {
      _bootstrappedUserIds.add(userId);
    }
  }

  Future<void> _backfillCloudAwards(String userId, Set<String> badgeIds) async {
    _ensureCurrentUser(userId);
    await Supabase.instance.client.rpc(
      'backfill_collector_badges',
      params: {'p_badge_ids': badgeIds.toList(growable: false)},
    );
  }

  Future<List<Map<String, Object?>>> _claimCloudAwards(
    String userId,
    List<CollectorBadgeDefinition> unlocked,
  ) async {
    _ensureCurrentUser(userId);
    final raw = await Supabase.instance.client.rpc(
      'claim_collector_badges',
      params: {'p_badge_ids': unlocked.map((badge) => badge.id.name).toList()},
    );
    if (raw is! List) {
      return const <Map<String, Object?>>[];
    }
    return raw
        .whereType<Map>()
        .map((row) => row.map((key, value) => MapEntry(key.toString(), value)))
        .toList(growable: false);
  }

  Future<List<CollectorBadgeAward>> _readCloudAwards(String userId) async {
    _ensureCurrentUser(userId);
    final raw = await Supabase.instance.client
        .from('collector_badge_awards')
        .select('badge_id, earned_at')
        .eq('user_id', userId)
        .order('earned_at', ascending: false);
    final rows = raw
        .whereType<Map>()
        .map((row) => row.map((key, value) => MapEntry(key.toString(), value)))
        .toList(growable: false);
    return _toAwards(rows);
  }

  void _ensureCurrentUser(String userId) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null || currentUserId != userId) {
      throw StateError('Badge awards require the active collector account.');
    }
  }

  Future<List<CollectorBadgeAward>> _syncLegacySilently(
    _LegacyBadgeAwardSnapshot snapshot,
    List<CollectorBadgeDefinition> unlocked,
    String userId,
  ) async {
    final awards = Map<String, String>.of(snapshot.awards);
    for (final badge in unlocked) {
      awards.putIfAbsent(badge.id.name, () => DateTime.now().toIso8601String());
    }
    if (!snapshot.exists || awards.length != snapshot.awards.length) {
      await _writeLegacyAwards(userId, awards);
    }
    return _toAwards(awards);
  }

  Future<_LegacyBadgeAwardSnapshot> _readLegacyAwards(String userId) async {
    try {
      final file = await _awardsFile(userId);
      if (!await file.exists()) {
        return const _LegacyBadgeAwardSnapshot(
          awards: <String, String>{},
          exists: false,
        );
      }
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) {
        return const _LegacyBadgeAwardSnapshot(
          awards: <String, String>{},
          exists: true,
        );
      }
      final rawAwards = decoded['awards'];
      if (rawAwards is! Map) {
        return const _LegacyBadgeAwardSnapshot(
          awards: <String, String>{},
          exists: true,
        );
      }
      return _LegacyBadgeAwardSnapshot(
        awards: rawAwards.map(
          (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
        ),
        exists: true,
      );
    } catch (_) {
      return const _LegacyBadgeAwardSnapshot(
        awards: <String, String>{},
        exists: false,
      );
    }
  }

  Future<void> _writeLegacyAwards(
    String userId,
    Map<String, String> awards,
  ) async {
    try {
      final file = await _awardsFile(userId);
      await file.writeAsString(
        jsonEncode(<String, Object?>{
          'initialized_for_notifications': true,
          'awards': awards,
        }),
      );
    } catch (_) {
      // The cloud record remains authoritative after migration deployment.
    }
  }

  List<CollectorBadgeAward> _toAwards(Object rawAwards) {
    final definitionsById = {
      for (final badge in collectorBadgeDefinitions) badge.id.name: badge,
    };
    final raw = <String, String>{};
    if (rawAwards is Map<String, String>) {
      raw.addAll(rawAwards);
    } else if (rawAwards is List<Map<String, Object?>>) {
      for (final row in rawAwards) {
        final id = row['badge_id']?.toString();
        if (id != null && id.isNotEmpty) {
          raw[id] = row['earned_at']?.toString() ?? '';
        }
      }
    }

    final awards =
        raw.entries
            .map((entry) {
              final definition = definitionsById[entry.key];
              if (definition == null) return null;
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
    _syncQueue = _syncQueue.catchError((_) {}).then((_) async {
      try {
        result.complete(await action());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }
}

class _LegacyBadgeAwardSnapshot {
  const _LegacyBadgeAwardSnapshot({required this.awards, required this.exists});

  final Map<String, String> awards;
  final bool exists;
}
