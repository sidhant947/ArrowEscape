import 'package:flutter/services.dart';

class AudioHapticHelper {
  static bool soundEnabled = false;
  static bool hapticsEnabled = true;

  static Future<void> playClick() async {
    if (soundEnabled) {
      await SystemSound.play(SystemSoundType.click);
    }
    if (hapticsEnabled) {
      await HapticFeedback.selectionClick();
    }
  }

  static Future<void> playSuccess() async {
    if (soundEnabled) {
      await SystemSound.play(SystemSoundType.click);
    }
    if (hapticsEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }

  static Future<void> playFailure() async {
    if (soundEnabled) {
      await SystemSound.play(SystemSoundType.alert);
    }
    if (hapticsEnabled) {
      await HapticFeedback.heavyImpact();
    }
  }
}
