import 'dart:typed_data';
import '../models/arrow.dart';
import '../models/level.dart';

class LevelSolver {
  static const int maxStates = 5000; 

  static List<String>? solve(LevelModel level, [int maxStatesLimit = maxStates]) {
    final gridSize = level.gridSize;
    final arrows = level.arrows;
    final orphanDots = level.orphanDots;

    final board = Uint16List(gridSize * gridSize);
    for (int i = 0; i < arrows.length; i++) {
      final arrow = arrows[i];
      for (final pt in arrow.path) {
        board[pt[0] * gridSize + pt[1]] = i + 1;
      }
    }

    final orphanTypes = Uint8List(gridSize * gridSize);
    final activeOrphans = List<bool>.filled(gridSize * gridSize, false);
    for (final od in orphanDots) {
      final idx = od.row * gridSize + od.col;
      orphanTypes[idx] = od.type.index;
      activeOrphans[idx] = true;
    }

    final activeArrows = List<bool>.filled(arrows.length, true);
    
    int arrowHash = 0;
    for (int i = 0; i < arrows.length; i++) {
      arrowHash ^= arrows[i].id.hashCode;
    }
    int dotHash = orphanDots.length * 997;
    for (final od in orphanDots) {
      dotHash ^= od.key.hashCode;
    }

    final visited = <String>{};
    final path = <String>[];
    int statesVisited = 0;

    final exitVisited = Uint32List(gridSize * gridSize);
    int exitToken = 0;

    bool dfs(int remainingCount) {
      if (remainingCount == 0) return true;
      if (statesVisited > maxStatesLimit) return false;

      final hash = '$arrowHash|$dotHash';
      if (visited.contains(hash)) return false;
      visited.add(hash);
      statesVisited++;

      for (int i = arrows.length - 1; i >= 0; i--) {
        if (!activeArrows[i]) continue;

        exitToken++;
        if (exitToken == 0) {
          exitVisited.fillRange(0, exitVisited.length, 0);
          exitToken = 1;
        }
        final consumed = _simulateExit(i, gridSize, board, activeOrphans, orphanTypes, arrows, exitVisited, exitToken);
        if (consumed == null) continue;

        activeArrows[i] = false;
        final id = arrows[i].id;
        arrowHash ^= id.hashCode;

        for (final pt in arrows[i].path) {
          board[pt[0] * gridSize + pt[1]] = 0;
        }

        final deactivated = <int>[];
        for (final idx in consumed) {
          if (activeOrphans[idx]) {
            activeOrphans[idx] = false;
            deactivated.add(idx);
            final odKey = '${idx ~/ gridSize},${idx % gridSize}';
            dotHash ^= odKey.hashCode;
          }
        }

        path.add(id);

        if (dfs(remainingCount - 1)) return true;

        path.removeLast();
        for (final idx in deactivated) {
          activeOrphans[idx] = true;
          final odKey = '${idx ~/ gridSize},${idx % gridSize}';
          dotHash ^= odKey.hashCode;
        }
        for (final pt in arrows[i].path) {
          board[pt[0] * gridSize + pt[1]] = i + 1;
        }
        arrowHash ^= id.hashCode;
        activeArrows[i] = true;
      }
      return false;
    }

    if (dfs(arrows.length)) return path;
    return null;
  }

  static List<int>? _simulateExit(
      int arrowIdx,
      int gridSize,
      Uint16List board,
      List<bool> activeOrphans,
      Uint8List orphanTypes,
      List<ArrowModel> arrows,
      Uint32List exitVisited,
      int token) {
    final arrow = arrows[arrowIdx];
    ArrowDirection currentDir = arrow.direction;
    final head = arrow.path[0];
    var d = currentDir.delta;
    int nr = head[0] + d[0];
    int nc = head[1] + d[1];
    final consumed = <int>[];

    while (nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize) {
      final idx = nr * gridSize + nc;
      if (exitVisited[idx] == token) return null;
      exitVisited[idx] = token;

      if (activeOrphans[idx]) {
        consumed.add(idx);
        final typeVal = orphanTypes[idx];
        if (typeVal == 0) {
          currentDir = ArrowDirection.up;
        } else if (typeVal == 1) {
          currentDir = ArrowDirection.down;
        } else if (typeVal == 2) {
          currentDir = ArrowDirection.left;
        } else if (typeVal == 3) {
          currentDir = ArrowDirection.right;
        }
      } else {
        final val = board[idx];
        if (val != 0 && val != arrowIdx + 1) {
          return null;
        }
      }

      d = currentDir.delta;
      nr += d[0];
      nc += d[1];
    }
    return consumed;
  }
}