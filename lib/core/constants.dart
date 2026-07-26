class AppConstants {
  AppConstants._();

  static const String appName = 'Arrow Escape';

  static const int maxLives = 3;

  static const int bossLevelEvery = 5;   
  static const int godLevelEvery  = 10;  

  static const Duration arrowShakeDuration = Duration(milliseconds: 400);

  static int bossCycleCount(int level) {
    int count = 0;
    for (int l = 1; l <= level; l++) {
      if (levelTypeFor(l) == LevelType.boss) count++;
    }
    return count;
  }

  static int godCycleCount(int level) {
    int count = 0;
    for (int l = 1; l <= level; l++) {
      if (levelTypeFor(l) == LevelType.god) count++;
    }
    return count;
  }

  static int gridSizeForLevel(int level) {
    final type = levelTypeFor(level);

    if (type == LevelType.god) {
      final cycle = godCycleCount(level);
      final raw = 25 + ((cycle - 1) * (15.0 / 15.0)).round();
      return raw.clamp(25, 40);
    }

    if (type == LevelType.boss) {
      final cycle = bossCycleCount(level);
      final raw = 20 + ((cycle - 1) * (15.0 / 15.0)).round();
      return raw.clamp(20, 35);
    }

    if (level <= 10) {
      return 10 + ((level - 1) * 0.44).round();
    } else if (level <= 50) {
      return 14 + ((level - 10) * 0.15).round();
    } else if (level <= 100) {
      return 20 + ((level - 50) * 0.1).round();
    } else {
      return 25 + ((level - 100) * 0.01).round().clamp(0, 5);
    }
  }

  static LevelType levelTypeFor(int level) {
    if (level % godLevelEvery == 0) return LevelType.god;
    if (level % bossLevelEvery == 0) return LevelType.boss;
    return LevelType.normal;
  }

  static double canvasScaleForType(LevelType type) {
    switch (type) {
      case LevelType.god:  return 0.93;
      case LevelType.boss: return 0.93;
      default:             return 0.90;
    }
  }

  static const int randomEasyMin = 1;
  static const int randomEasyMax = 10;
  static const int randomMediumMin = 30;
  static const int randomMediumMax = 50;
  static const int randomHardMin = 80;
  static const int randomHardMax = 100;
}

enum LevelType {
  normal,
  boss,
  god;
}