import 'dart:typed_data';
import 'package:material_ui/material_ui.dart';
import '../data/models/arrow.dart';
import '../data/models/level.dart';
import '../core/constants.dart';
import '../core/app_themes.dart';
import '../core/game_mode.dart';

class GameState extends ChangeNotifier {
  
  late LevelModel _currentLevel;
  late List<ArrowModel> _arrows;
  int _lives = AppConstants.maxLives;
  int _livesLost = 0;
  bool _isComplete = false;
  bool _isGameOver = false;
  bool _isDeadlocked = false;
  final GameTheme theme;
  final GameMode gameMode;
  final bool heartRemover;
  final bool assistMode;

  late Map<String, OrphanDotType> _orphanDots;
  late Uint16List _board;
  final Map<String, int> _arrowIndices = {};

  final Map<String, List<OrphanDot>> _consumedDotsByArrow = {};

  final void Function() onLevelComplete;
  final void Function() onGameOver;
  final void Function() onLifeLost;
  final void Function()? onDeadlock;
  final void Function()? onCombo;
  final void Function(Offset globalPos, Color color)? onParticleBurst;
  final void Function()? onCameraShake;
  
  DateTime? _lastExitTime;
  int _comboCount = 0;
  
  int get comboCount => _comboCount;

  GameState({
    required LevelModel level,
    required this.theme,
    required this.onLevelComplete,
    required this.onGameOver,
    required this.onLifeLost,
    this.onDeadlock,
    this.gameMode = GameMode.classic,
    this.heartRemover = false,
    this.assistMode = false,
    this.onCombo,
    this.onParticleBurst,
    this.onCameraShake,
  }) {
    _currentLevel = level;
    _arrows = level.arrows.map((a) => a.copyWith()).toList();
    _orphanDots = {for (final od in level.orphanDots) od.key: od.type};
    _lives = (gameMode == GameMode.zen || gameMode == GameMode.timeAttack || heartRemover) ? 999 : AppConstants.maxLives;
    _initBoard();
  }

  void _initBoard() {
    final rows = _currentLevel.rows;
    final cols = _currentLevel.cols;
    _board = Uint16List(rows * cols);
    _arrowIndices.clear();
    for (int i = 0; i < _arrows.length; i++) {
      _arrowIndices[_arrows[i].id] = i + 1;
      for (final pt in _arrows[i].path) {
        _board[pt[0] * cols + pt[1]] = i + 1;
      }
    }
  }

  bool isCellOccupied(int r, int c, [String? ignoreArrowId]) {
    final cols = _currentLevel.cols;
    final val = _board[r * cols + c];
    if (val == 0) return false;
    if (ignoreArrowId != null && val == (_arrowIndices[ignoreArrowId] ?? 0)) {
      return false;
    }
    return true;
  }

  List<ArrowModel> get arrows => _arrows;
  int get lives => _lives;
  int get livesLost => _livesLost;
  bool get isComplete => _isComplete;
  bool get isGameOver => _isGameOver;
  bool get isDeadlocked => _isDeadlocked;
  LevelModel get level => _currentLevel;
  
  Map<String, OrphanDotType> get orphanDots => _orphanDots;

  void handleArrowExitCompleted(String arrowId) {
    _arrows.removeWhere((a) => a.id == arrowId);
    _consumedDotsByArrow.remove(arrowId);

    if (_arrows.isEmpty) {
      _isComplete = true;
      onLevelComplete();
    } else {
      if (checkDeadlock()) {
        _isDeadlocked = true;
        onDeadlock?.call();
      }
    }
    notifyListeners();
  }

  bool checkDeadlock() {
    if (_arrows.isEmpty) return false;

    for (final arrow in _arrows) {
      final exit = _computeExitInfo(arrow);
      if (!exit.blocked) {
        return false;
      }
    }
    return true;
  }

  bool isArrowBlocked(String arrowId) {
    final index = _arrows.indexWhere((a) => a.id == arrowId);
    if (index == -1) return true;
    final arrow = _arrows[index];
    return _computeExitInfo(arrow).blocked;
  }

  List<OrphanDot> getConsumedDotsForArrow(String arrowId) {
    return _consumedDotsByArrow[arrowId] ?? [];
  }

  void _recordConsumedDots(String arrowId, List<String> consumedKeys) {
    final dots = <OrphanDot>[];
    for (final key in consumedKeys) {
      final match = _currentLevel.orphanDots.firstWhere(
        (od) => od.key == key,
        orElse: () {
          final parts = key.split(',');
          return OrphanDot(
            row: int.parse(parts[0]),
            col: int.parse(parts[1]),
            type: OrphanDotType.neutral,
          );
        },
      );
      dots.add(match);
    }
    _consumedDotsByArrow[arrowId] = dots;
  }

  TapResult tapArrow(String arrowId) {
    if (_isComplete || _isGameOver) return TapResult.ignored;

    final index = _arrows.indexWhere((a) => a.id == arrowId);
    if (index == -1) return TapResult.ignored;

    final arrow = _arrows[index];
    if (arrow.state != ArrowState.idle) {
      return TapResult.ignored;
    }

    final exitInfo = _computeExitInfo(arrow);
    if (exitInfo.blocked) {
      _comboCount = 0;
      onCameraShake?.call();
      return _handleBlocked(index, arrow, arrowId);
    }

    final now = DateTime.now();
    if (_lastExitTime != null && now.difference(_lastExitTime!).inMilliseconds < 1500) {
      _comboCount++;
      if (_comboCount >= 2) {
        onCombo?.call();
      }
    } else {
      _comboCount = 1;
    }
    _lastExitTime = now;

    _arrows[index] = arrow.copyWith(state: ArrowState.sliding);
    final cols = _currentLevel.cols;
    for (final pt in arrow.path) {
      _board[pt[0] * cols + pt[1]] = 0;
    }
    _recordConsumedDots(arrowId, exitInfo.consumed);
    
    for (final k in exitInfo.consumed) {
      _orphanDots.remove(k);
    }
    notifyListeners();

    return TapResult.exited;
  }

  TapResult _handleBlocked(int index, ArrowModel arrow, String arrowId) {
    _arrows[index] = arrow.copyWith(state: ArrowState.blocked);
    if (gameMode != GameMode.zen && gameMode != GameMode.timeAttack && !heartRemover) {
      _lives--;
      _livesLost++;
      onLifeLost();
    }
 
    Future.delayed(AppConstants.arrowShakeDuration, () {
      final idx = _arrows.indexWhere((a) => a.id == arrowId);
      if (idx != -1) {
        _arrows[idx] = _arrows[idx].copyWith(state: ArrowState.idle);
        notifyListeners();
      }
    });
 
    if (gameMode != GameMode.zen && gameMode != GameMode.timeAttack && !heartRemover && _lives <= 0) {
      _isGameOver = true;
      onGameOver();
      notifyListeners();
      return TapResult.blocked;
    }
 
    notifyListeners();
    return TapResult.blocked;
  }

  _ExitInfo _computeExitInfo(ArrowModel arrow) {
    ArrowDirection currentDir = arrow.direction;
    final head = arrow.path[0];
    final rows = _currentLevel.rows;
    final cols = _currentLevel.cols;
    var d = currentDir.delta;
    int nr = head[0] + d[0];
    int nc = head[1] + d[1];
    final consumed = <String>[];
    final visited = <String>{};
    final arrowVal = _arrowIndices[arrow.id] ?? 0;

    while (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
      final key = '$nr,$nc';
      if (visited.contains(key)) return const _ExitInfo(true);
      visited.add(key);

      if (_orphanDots.containsKey(key)) {
        consumed.add(key);
        final dotType = _orphanDots[key]!;
        if (dotType == OrphanDotType.up) {
          currentDir = ArrowDirection.up;
        } else if (dotType == OrphanDotType.down) {
          currentDir = ArrowDirection.down;
        } else if (dotType == OrphanDotType.left) {
          currentDir = ArrowDirection.left;
        } else if (dotType == OrphanDotType.right) {
          currentDir = ArrowDirection.right;
        }
      } else {
        final val = _board[nr * cols + nc];
        if (val != 0 && val != arrowVal) {
          return const _ExitInfo(true);
        }
      }

      d = currentDir.delta;
      nr += d[0];
      nc += d[1];
    }
    return _ExitInfo(false, consumed);
  }

  void resetLevel() {
    _arrows = _currentLevel.arrows.map((a) => a.copyWith(state: ArrowState.idle)).toList();
    _orphanDots = {for (final od in _currentLevel.orphanDots) od.key: od.type};
    _initBoard();
    _consumedDotsByArrow.clear();
    _lives = (gameMode == GameMode.zen || gameMode == GameMode.timeAttack || heartRemover) ? 999 : AppConstants.maxLives;
    _livesLost = 0;
    _isComplete = false;
    _isGameOver = false;
    _isDeadlocked = false;
    notifyListeners();
  }

  void restoreLife() {
    if (_lives < AppConstants.maxLives) {
      _lives++;
      if (_isGameOver && _lives > 0) {
        _isGameOver = false;
      }
      notifyListeners();
    }
  }

  void forceGameOver() {
    _isGameOver = true;
    onGameOver();
    notifyListeners();
  }

  void resumeFromTimeout() {
    _isGameOver = false;
    notifyListeners();
  }
}

enum TapResult { exited, blocked, ignored }

class _ExitInfo {
  final bool blocked;
  final List<String> consumed; 
  const _ExitInfo(this.blocked, [this.consumed = const []]);
}