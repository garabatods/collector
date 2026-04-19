import 'dart:async';

import 'package:flutter/services.dart';

import 'collector_sound_effects.dart';

abstract final class CollectorHaptics {
  static var _didWarmUpUi = false;

  static void selection() {
    _warmUpUi();
    unawaited(HapticFeedback.selectionClick());
    CollectorSoundEffects.playSelection();
  }

  static void light() {
    _warmUpUi();
    unawaited(HapticFeedback.lightImpact());
    CollectorSoundEffects.playTap();
  }

  static void medium() {
    _warmUpUi();
    unawaited(HapticFeedback.mediumImpact());
    CollectorSoundEffects.playSuccess();
  }

  static void heavy() {
    _warmUpUi();
    unawaited(HapticFeedback.heavyImpact());
    CollectorSoundEffects.playWarning();
  }

  static void _warmUpUi() {
    if (_didWarmUpUi) {
      return;
    }

    _didWarmUpUi = true;
    CollectorSoundEffects.warmUpUi();
  }
}
