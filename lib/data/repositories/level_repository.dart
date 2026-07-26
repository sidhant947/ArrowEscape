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

class LevelRepository {
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
  }

  LevelModel getLevel(int levelNumber) {
    if (_cache.containsKey(levelNumber)) return _cache[levelNumber]!;

    final jsonStr = _cacheBox.get('cached_level_$levelNumber');
    if (jsonStr != null) {
      try {
        final level = LevelModel.fromJson(jsonDecode(jsonStr));
        _cache[levelNumber] = level;
        return level;
      } catch (e) {
        debugPrint('Error decoding cached level: $e');
      }
    }

    final level = LevelGenerator.generateLevel(levelNumber);
    _cache[levelNumber] = level;
    _saveToDisk(levelNumber, level);
    return level;
  }

  Future<void> preGenerateAsync(int levelNumber) async {
    if (isCached(levelNumber)) return;
    if (_generating.contains(levelNumber)) return;
    _generating.add(levelNumber);

    try {
      final jsonStr = _cacheBox.get('cached_level_$levelNumber');
      if (jsonStr != null) {
        final level = LevelModel.fromJson(jsonDecode(jsonStr));
        _cache[levelNumber] = level;
        return;
      }

      final level = await compute(generateLevelIsolate, levelNumber)
          .timeout(const Duration(seconds: 4));
      _cache[levelNumber] = level;
      _saveToDisk(levelNumber, level);
    } catch (e) {
      debugPrint('Async pre-generation error for level $levelNumber: $e');
    } finally {
      _generating.remove(levelNumber);
    }
  }

  Future<void> preGenerateRangeAsync(int from, int count) async {
    for (int i = from; i < from + count; i++) {
      unawaited(preGenerateAsync(i));
    }
  }

  Future<LevelModel> getLevelAsync(int levelNumber, {bool preGenerateNext = true}) async {
    if (preGenerateNext) {
      preGenerateRangeAsync(levelNumber + 1, 3);
    }

    if (_cache.containsKey(levelNumber)) return _cache[levelNumber]!;

    final jsonStr = _cacheBox.get('cached_level_$levelNumber');
    if (jsonStr != null) {
      try {
        final level = LevelModel.fromJson(jsonDecode(jsonStr));
        _cache[levelNumber] = level;
        return level;
      } catch (_) {}
    }

    try {
      final level = await compute(generateLevelIsolate, levelNumber)
          .timeout(const Duration(seconds: 3));
      _cache[levelNumber] = level;
      _saveToDisk(levelNumber, level);
      return level;
    } catch (e) {
      debugPrint('Isolate generation failed/timed out, generating synchronously: $e');
      return getLevel(levelNumber);
    }
  }

  bool isCached(int levelNumber) {
    if (_cache.containsKey(levelNumber)) return true;
    if (_cacheBox.containsKey('cached_level_$levelNumber')) {
      return true;
    }
    return false;
  }

  void _saveToDisk(int levelNumber, LevelModel level) {
    try {
      _cacheBox.put('cached_level_$levelNumber', jsonEncode(level.toJson()));
    } catch (e) {
      debugPrint('Error saving level to disk: $e');
    }
  }
}