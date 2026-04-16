import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

abstract final class CollectorSoundEffects {
  static const _scanSoundAssetPath = 'sounds/ring.m4a';

  static AudioPool? _scanPool;
  static Future<AudioPool>? _scanPoolFuture;

  static void warmUpScan() {
    unawaited(_resolveScanPool());
  }

  static void playScan() {
    unawaited(_playScan());
  }

  static Future<void> disposeScan() async {
    final pool = _scanPool;
    _scanPool = null;
    _scanPoolFuture = null;

    if (pool != null) {
      await pool.dispose();
    }
  }

  static Future<void> _playScan() async {
    try {
      final pool = await _resolveScanPool();
      await pool.start(volume: 1);
    } catch (_) {
      // Sound effects are non-critical; ignore playback failures.
    }
  }

  static Future<AudioPool> _resolveScanPool() {
    if (_scanPool != null) {
      return Future<AudioPool>.value(_scanPool);
    }

    final existingFuture = _scanPoolFuture;
    if (existingFuture != null) {
      return existingFuture;
    }

    final future =
        AudioPool.createFromAsset(
          path: _scanSoundAssetPath,
          maxPlayers: 2,
          minPlayers: 1,
          playerMode: PlayerMode.lowLatency,
        ).then((pool) {
          _scanPool = pool;
          return pool;
        });

    _scanPoolFuture = future;
    return future;
  }
}
