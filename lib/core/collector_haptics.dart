import 'dart:async';

import 'package:flutter/services.dart';

abstract final class CollectorHaptics {
  static void selection() {
    unawaited(HapticFeedback.selectionClick());
  }

  static void light() {
    unawaited(HapticFeedback.lightImpact());
  }

  static void medium() {
    unawaited(HapticFeedback.mediumImpact());
  }

  static void heavy() {
    unawaited(HapticFeedback.heavyImpact());
  }
}
