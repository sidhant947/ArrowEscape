import 'dart:async';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants.dart';
import '../../data/models/level.dart';
import 'components/grid_component.dart';
import 'game_state.dart';

class ArrowPuzzleGame extends FlameGame {
  
  final LevelModel level;
  final GameState gameState;
  GridComponent? gridComponent;

  final void Function() onLevelComplete;
  final void Function() onGameOver;
  final void Function() onLifeLost;

  ArrowPuzzleGame({
    required this.level,
    required this.gameState,
    required this.onLevelComplete,
    required this.onGameOver,
    required this.onLifeLost,
  });

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    final levelType = AppConstants.levelTypeFor(level.levelNumber);
    final scale = AppConstants.canvasScaleForType(levelType);

    final availWidth = size.x * scale;
    final availHeight = size.y * scale;
    final cellSize = (availWidth / level.cols < availHeight / level.rows)
        ? (availWidth / level.cols)
        : (availHeight / level.rows);
    final gridWidth = level.cols * cellSize;
    final gridHeight = level.rows * cellSize;
    final gridX = (size.x - gridWidth) / 2;
    final gridY = (size.y - gridHeight) / 2;

    gridComponent = GridComponent(
      gameState: gameState,
      cellSize: cellSize,
      position: Vector2(gridX + gridWidth / 2, gridY + gridHeight / 2),
    )..anchor = Anchor.center;

    add(gridComponent!);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    final levelType = AppConstants.levelTypeFor(level.levelNumber);
    final scale = AppConstants.canvasScaleForType(levelType);
    final availWidth = size.x * scale;
    final availHeight = size.y * scale;
    final cellSize = (availWidth / level.cols < availHeight / level.rows)
        ? (availWidth / level.cols)
        : (availHeight / level.rows);
    final gridWidth = level.cols * cellSize;
    final gridHeight = level.rows * cellSize;
    final gridX = (size.x - gridWidth) / 2;
    final gridY = (size.y - gridHeight) / 2;

    if (gridComponent != null) {
      gridComponent!.position = Vector2(gridX + gridWidth / 2, gridY + gridHeight / 2);
      gridComponent!.resize(cellSize);
    }
  }

  void resetLevel() {
    gameState.resetLevel();
    gridComponent?.rebuild();
  }
}