import 'package:flutter/services.dart';

class AudioHapticHelper {
  static bool hapticsEnabled = true;

  static void init() {}

  static Future<void> playClick() async {
    if (hapticsEnabled) {
      await HapticFeedback.selectionClick();
    }
  }

  static Future<void> playSuccess({int combo = 1}) async {
    if (hapticsEnabled) {
      if (combo > 2) {
        await HapticFeedback.heavyImpact();
      } else {
        await HapticFeedback.mediumImpact();
      }
    }
  }

  static Future<void> playFailure() async {
    if (hapticsEnabled) {
      await HapticFeedback.heavyImpact();
    }
  }
}
