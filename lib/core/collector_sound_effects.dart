import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

enum _CollectorSoundEffect { scan, tap, selection, open, success, warning }

abstract final class CollectorSoundEffects {
  static final Map<_CollectorSoundEffect, AudioPool> _pools =
      <_CollectorSoundEffect, AudioPool>{};
  static final Map<_CollectorSoundEffect, Future<AudioPool>> _poolFutures =
      <_CollectorSoundEffect, Future<AudioPool>>{};

  static void warmUpScan() {
    unawaited(_resolvePool(_CollectorSoundEffect.scan));
  }

  static void warmUpUi() {
    for (final effect in const <_CollectorSoundEffect>[
      _CollectorSoundEffect.tap,
      _CollectorSoundEffect.selection,
      _CollectorSoundEffect.open,
      _CollectorSoundEffect.success,
      _CollectorSoundEffect.warning,
    ]) {
      unawaited(_resolvePool(effect));
    }
  }

  static void playScan() {
    _playEffect(_CollectorSoundEffect.scan);
  }

  static void playTap() {
    _playEffect(_CollectorSoundEffect.tap);
  }

  static void playSelection() {
    _playEffect(_CollectorSoundEffect.selection);
  }

  static void playOpen() {
    _playEffect(_CollectorSoundEffect.open);
  }

  static void playSuccess() {
    _playEffect(_CollectorSoundEffect.success);
  }

  static void playWarning() {
    _playEffect(_CollectorSoundEffect.warning);
  }

  static Future<void> disposeScan() async {
    await _dispose(_CollectorSoundEffect.scan);
  }

  static void _playEffect(_CollectorSoundEffect effect) {
    unawaited(_play(effect));
  }

  static Future<void> _play(_CollectorSoundEffect effect) async {
    try {
      final pool = await _resolvePool(effect);
      await pool.start(volume: effect.volume);
    } catch (_) {
      // Sound effects are non-critical; ignore playback failures.
    }
  }

  static Future<AudioPool> _resolvePool(_CollectorSoundEffect effect) {
    final pool = _pools[effect];
    if (pool != null) {
      return Future<AudioPool>.value(pool);
    }

    final existingFuture = _poolFutures[effect];
    if (existingFuture != null) {
      return existingFuture;
    }

    final future =
        AudioPool.createFromAsset(
          path: effect.assetPath,
          maxPlayers: effect.maxPlayers,
          minPlayers: 1,
          playerMode: PlayerMode.lowLatency,
        ).then((pool) {
          _pools[effect] = pool;
          return pool;
        });

    _poolFutures[effect] = future;
    return future;
  }

  static Future<void> _dispose(_CollectorSoundEffect effect) async {
    final pool = _pools.remove(effect);
    _poolFutures.remove(effect);

    if (pool != null) {
      await pool.dispose();
    }
  }
}

extension on _CollectorSoundEffect {
  String get assetPath => switch (this) {
    _CollectorSoundEffect.scan => 'sounds/scanner.wav',
    _CollectorSoundEffect.tap => 'sounds/ui_tap.wav',
    _CollectorSoundEffect.selection => 'sounds/ui_select.wav',
    _CollectorSoundEffect.open => 'sounds/ui_open.wav',
    _CollectorSoundEffect.success => 'sounds/ui_success.wav',
    _CollectorSoundEffect.warning => 'sounds/ui_warning.wav',
  };

  int get maxPlayers => switch (this) {
    _CollectorSoundEffect.scan => 2,
    _CollectorSoundEffect.tap => 3,
    _CollectorSoundEffect.selection => 2,
    _CollectorSoundEffect.open => 2,
    _CollectorSoundEffect.success => 2,
    _CollectorSoundEffect.warning => 1,
  };

  double get volume => switch (this) {
    _CollectorSoundEffect.scan => 1,
    _CollectorSoundEffect.tap => 0.34,
    _CollectorSoundEffect.selection => 0.42,
    _CollectorSoundEffect.open => 0.38,
    _CollectorSoundEffect.success => 0.5,
    _CollectorSoundEffect.warning => 0.4,
  };
}
