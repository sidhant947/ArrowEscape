import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/level.dart';
import '../level_generator/level_generator.dart';

@pragma('vm:entry-point')
LevelModel generateLevelIsolate(int levelNumber) {
  return LevelGenerator.generateLevel(levelNumber);
}

LevelModel generateRandomLevelIsolate(String difficulty) {
  return LevelGenerator.generateRandomLevel(difficulty: difficulty);
}

class LevelRepository {
  static const int cacheVersion = LevelModel.currentVersion;

  late Box _cacheBox;
  final Map<int, LevelModel> _cache = {};
  final Set<int> _generating = {};

  LevelRepository._();

  static Future<LevelRepository> create() async {
    final repo = LevelRepository._();
    await repo._init();
    return repo;
  }

  Future<void> _init() async {
    _cacheBox = await Hive.openBox('levelCache');
    final storedVersion = _cacheBox.get('generator_version');
    if (storedVersion != cacheVersion) {
      await _cacheBox.clear();
      await _cacheBox.put('generator_version', cacheVersion);
    }
  }

  LevelModel? _tryLoadCached(int levelNumber) {
    if (_cache.containsKey(levelNumber)) {
      final cached = _cache[levelNumber]!;
      if (cached.version == cacheVersion) return cached;
      _cache.remove(levelNumber);
    }

    final jsonStr = _cacheBox.get('cached_level_$levelNumber');
    if (jsonStr != null) {
      try {
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map<String, dynamic>) {
          final level = LevelModel.fromJson(decoded);
          if (level.version == cacheVersion) {
            _cache[levelNumber] = level;
            return level;
          }
        }
      } catch (e) {
        debugPrint('Error decoding cached level: $e');
      }
      _cacheBox.delete('cached_level_$levelNumber');
    }
    return null;
  }

  LevelModel getLevel(int levelNumber) {
    final cached = _tryLoadCached(levelNumber);
    if (cached != null) return cached;

    final level = LevelGenerator.generateLevel(levelNumber);
    _cache[levelNumber] = level;
    _saveToDisk(levelNumber, level);
    return level;
  }

  Future<void> preGenerateAsync(int levelNumber) async {
    if (isCached(levelNumber)) return;
    if (_generating.isNotEmpty) return;
    _generating.add(levelNumber);

    try {
      final cached = _tryLoadCached(levelNumber);
      if (cached != null) return;

      final level = await compute(generateLevelIsolate, levelNumber)
          .timeout(const Duration(seconds: 15));
      _cache[levelNumber] = level;
      _saveToDisk(levelNumber, level);
    } catch (e) {
      debugPrint('Async pre-generation error for level $levelNumber: $e');
    } finally {
      _generating.remove(levelNumber);
    }
  }

  Future<void> preGenerateRangeAsync(int from, int count) async {
    if (count <= 0) return;
    unawaited(preGenerateAsync(from));
  }

  Future<LevelModel> getLevelAsync(int levelNumber,
      {bool preGenerateNext = true}) async {
    final cached = _tryLoadCached(levelNumber);
    if (cached != null) {
      if (preGenerateNext) {
        preGenerateRangeAsync(levelNumber + 1, 1);
      }
      return cached;
    }

    try {
      final level = await compute(generateLevelIsolate, levelNumber)
          .timeout(const Duration(seconds: 25));
      _cache[levelNumber] = level;
      _saveToDisk(levelNumber, level);

      if (preGenerateNext) {
        preGenerateRangeAsync(levelNumber + 1, 1);
      }
      return level;
    } catch (e) {
      debugPrint('Isolate generation failed: $e');
      final level = await compute(generateLevelIsolate, levelNumber);
      _cache[levelNumber] = level;
      _saveToDisk(levelNumber, level);
      if (preGenerateNext) {
        preGenerateRangeAsync(levelNumber + 1, 1);
      }
      return level;
    }
  }

  Future<LevelModel> getRandomLevelAsync(int levelNumber,
      {String? difficulty}) async {
    if (difficulty != null) {
      try {
        return await compute(generateRandomLevelIsolate, difficulty)
            .timeout(const Duration(seconds: 15));
      } catch (e) {
        debugPrint('Random level generation isolate error: $e');
        return LevelGenerator.generateRandomLevel(difficulty: difficulty);
      }
    }
    return getLevelAsync(levelNumber, preGenerateNext: false);
  }

  bool isCached(int levelNumber) {
    return _tryLoadCached(levelNumber) != null;
  }

  void _saveToDisk(int levelNumber, LevelModel level) {
    try {
      _cacheBox.put('cached_level_$levelNumber', jsonEncode(level.toJson()));
    } catch (e) {
      debugPrint('Error saving level to disk: $e');
    }
  }
}