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
      final raw = 22 + ((level / 50.0) * 1.2).round();
      return raw.clamp(22, 32);
    }

    if (type == LevelType.boss) {
      final raw = 20 + ((level / 50.0) * 1.2).round();
      return raw.clamp(20, 30);
    }

    if (level <= 10) {
      return 10 + ((level - 1) * 0.44).round();
    } else if (level <= 50) {
      return 14 + ((level - 10) * 0.15).round();
    } else if (level <= 150) {
      return 20 + ((level - 50) * 0.05).round();
    } else if (level <= 300) {
      return 25 + ((level - 150) * 0.03).round();
    } else if (level <= 500) {
      return 29 + ((level - 300) * 0.01).round();
    } else {
      return 32;
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

  static const int randomEasyMin = 11;
  static const int randomEasyMax = 50;
  static const int randomMediumMin = 51;
  static const int randomMediumMax = 150;
  static const int randomHardMin = 151;
  static const int randomHardMax = 300;
  static const int randomMasterMin = 301;
  static const int randomMasterMax = 500;
  static const int randomExpertMin = 501;
  static const int randomExpertMax = 700;
}

enum LevelType {
  normal,
  boss,
  god;
}