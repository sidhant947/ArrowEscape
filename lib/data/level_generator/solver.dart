import 'dart:typed_data';
import '../models/arrow.dart';
import '../models/level.dart';

class LevelSolver {
  static const int maxStates = 5000; 

  static List<String>? solve(LevelModel level, [int maxStatesLimit = maxStates]) {
    final rows = level.rows;
    final cols = level.cols;
    final arrows = level.arrows;
    final orphanDots = level.orphanDots;

    final board = Uint16List(rows * cols);
    for (int i = 0; i < arrows.length; i++) {
      final arrow = arrows[i];
      for (final pt in arrow.path) {
        board[pt[0] * cols + pt[1]] = i + 1;
      }
    }

    final orphanTypes = Uint8List(rows * cols);
    final activeOrphans = List<bool>.filled(rows * cols, false);
    for (final od in orphanDots) {
      final idx = od.row * cols + od.col;
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
      dotHash ^= (od.row * cols + od.col).hashCode;
    }

    final visited = <int>{};
    final path = <String>[];
    int statesVisited = 0;

    final exitVisited = Uint32List(rows * cols);
    int exitToken = 0;

    void undoGreedy(List<int> greedyList) {
      for (int k = greedyList.length - 1; k >= 0; k--) {
        final idx = greedyList[k];
        path.removeLast();
        for (final pt in arrows[idx].path) {
          board[pt[0] * cols + pt[1]] = idx + 1;
        }
        arrowHash ^= arrows[idx].id.hashCode;
        activeArrows[idx] = true;
      }
    }

    bool dfs(int remainingCount) {
      if (remainingCount == 0) return true;
      if (statesVisited > maxStatesLimit) return false;

      final greedyCleared = <int>[];
      bool progress = true;
      while (progress) {
        progress = false;
        for (int i = 0; i < arrows.length; i++) {
          if (!activeArrows[i]) continue;
          exitToken++;
          if (exitToken == 0) {
            exitVisited.fillRange(0, exitVisited.length, 0);
            exitToken = 1;
          }
          final consumed = _simulateExit(i, rows, cols, board, activeOrphans, orphanTypes, arrows, exitVisited, exitToken);
          if (consumed == null) continue;

          bool consumesRedirector = false;
          for (final idx in consumed) {
            if (activeOrphans[idx] && orphanTypes[idx] != OrphanDotType.neutral.index) {
              consumesRedirector = true;
              break;
            }
          }

          if (!consumesRedirector) {
            activeArrows[i] = false;
            final id = arrows[i].id;
            arrowHash ^= id.hashCode;
            for (final pt in arrows[i].path) {
              board[pt[0] * cols + pt[1]] = 0;
            }
            for (final idx in consumed) {
              if (activeOrphans[idx]) {
                activeOrphans[idx] = false;
                dotHash ^= idx.hashCode;
              }
            }
            path.add(id);
            greedyCleared.add(i);
            progress = true;
          }
        }
      }

      if (path.length == arrows.length) return true;

      final hash = ((arrowHash & 0xFFFFFFFF) << 32) | (dotHash & 0xFFFFFFFF);
      if (!visited.add(hash)) {
        undoGreedy(greedyCleared);
        return false;
      }
      statesVisited++;

      for (int i = 0; i < arrows.length; i++) {
        if (!activeArrows[i]) continue;

        exitToken++;
        if (exitToken == 0) {
          exitVisited.fillRange(0, exitVisited.length, 0);
          exitToken = 1;
        }
        final consumed = _simulateExit(i, rows, cols, board, activeOrphans, orphanTypes, arrows, exitVisited, exitToken);
        if (consumed == null) continue;

        activeArrows[i] = false;
        final id = arrows[i].id;
        arrowHash ^= id.hashCode;

        for (final pt in arrows[i].path) {
          board[pt[0] * cols + pt[1]] = 0;
        }

        final deactivated = <int>[];
        for (final idx in consumed) {
          if (activeOrphans[idx]) {
            activeOrphans[idx] = false;
            deactivated.add(idx);
            dotHash ^= idx.hashCode;
          }
        }

        path.add(id);

        if (dfs(arrows.length - path.length)) return true;

        path.removeLast();
        for (final idx in deactivated) {
          activeOrphans[idx] = true;
          dotHash ^= idx.hashCode;
        }
        for (final pt in arrows[i].path) {
          board[pt[0] * cols + pt[1]] = i + 1;
        }
        arrowHash ^= id.hashCode;
        activeArrows[i] = true;
      }

      undoGreedy(greedyCleared);
      return false;
    }

    if (dfs(arrows.length)) return path;
    return null;
  }

  static List<int>? _simulateExit(
      int arrowIdx,
      int rows,
      int cols,
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

    while (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
      final idx = nr * cols + nc;
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