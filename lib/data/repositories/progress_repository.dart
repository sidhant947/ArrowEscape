import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/level_result.dart';
import '../../core/constants.dart';

class ProgressRepository extends ChangeNotifier {
  late Box _box;
  late Box _resultsBox;

  int _lives = AppConstants.maxLives;
  int _currentLevel = 1;
  int _highestUnlockedLevel = 1;

  final Map<int, LevelResult> _levelResults = {};

  int get lives => _lives;
  int get maxLives => AppConstants.maxLives;
  int get currentLevel => _currentLevel;
  int get highestUnlockedLevel => _highestUnlockedLevel;
  bool get hasLives => _lives > 0;
  bool get livesAreFull => _lives >= AppConstants.maxLives;

  int getStarsForLevel(int level) => _levelResults[level]?.stars ?? 0;

  bool isLevelUnlocked(int level) {
    return level <= _highestUnlockedLevel;
  }

  bool isLevelCompleted(int level) => _levelResults.containsKey(level);

  ProgressRepository._();

  static Future<ProgressRepository> create() async {
    final repo = ProgressRepository._();
    await repo._init();
    return repo;
  }

  Future<void> _init() async {
    _box = await Hive.openBox('progress');
    _resultsBox = await Hive.openBox('levelResults');
    _load();
  }

  void _load() {
    _lives = _box.get('lives', defaultValue: AppConstants.maxLives);
    _currentLevel = _box.get('currentLevel', defaultValue: 1);
    _highestUnlockedLevel = _box.get('highestUnlockedLevel', defaultValue: 1);

    for (final key in _resultsBox.keys) {
      final level = int.tryParse(key.toString());
      if (level != null) {
        final jsonStr = _resultsBox.get(key);
        if (jsonStr != null) {
          try {
            _levelResults[level] = LevelResult.fromJson(jsonDecode(jsonStr));
          } catch (e) {
            debugPrint('Error loading level result: $e');
          }
        }
      }
    }
  }

  Future<void> _save() async {
    await _box.putAll({
      'lives': _lives,
      'currentLevel': _currentLevel,
      'highestUnlockedLevel': _highestUnlockedLevel,
    });

    for (final entry in _levelResults.entries) {
      await _resultsBox.put(entry.key.toString(), jsonEncode(entry.value.toJson()));
    }
  }

  Future<void> recordLevelComplete(LevelResult result) async {
    final existing = _levelResults[result.levelNumber];
    if (existing == null || result.stars > existing.stars) {
      _levelResults[result.levelNumber] = result;
    }
    if (result.levelNumber >= _currentLevel) {
      _currentLevel = result.levelNumber + 1;
    }
    if (result.levelNumber >= _highestUnlockedLevel) {
      _highestUnlockedLevel = result.levelNumber + 1;
    }
    await _save();
    notifyListeners();
  }

  Future<void> setCurrentLevel(int level) async {
    _currentLevel = level;
    await _save();
    notifyListeners();
  }

  static int calculateStars(int livesLost) {
    if (livesLost == 0) return 3;
    if (livesLost == 1) return 2;
    return 1;
  }
}