import 'dart:math';
import 'dart:typed_data';
import '../models/arrow.dart';
import '../models/level.dart';
import '../../core/constants.dart';
import 'solver.dart';
import 'mask_generator.dart';

class LevelGenerator {
  static LevelModel generateLevel(int levelNumber) {
    final type = AppConstants.levelTypeFor(levelNumber);
    final (cols, rows) = AppConstants.dimensionsForLevel(levelNumber);
    final rng = Random(levelNumber);

    final maskShape = _shapeFor(type, rng);
    final mask = (type == LevelType.normal && (cols != rows))
        ? MaskGenerator.rectMask(cols, rows)
        : MaskGenerator.shapeByName(maskShape.name, cols, rng);
    final params = _paramsFor(levelNumber, type, cols, rows, mask);

    return _generateReverse(
      levelNumber: levelNumber,
      rows: rows,
      cols: cols,
      mask: mask,
      params: params,
      type: type,
      rng: rng,
      maskShape: maskShape,
    );
  }

  static LevelModel generateRandomLevel({required String difficulty, int? seed}) {
    final rng = Random(seed ?? DateTime.now().microsecondsSinceEpoch);
    final effectiveLevel = switch (difficulty) {
      'easy' => 24,
      'medium' => 79,
      'hard' => 199,
      'master' => 399,
      'expert' => 599,
      _ => 24,
    };
    final (cols, rows) = AppConstants.dimensionsForDifficulty(difficulty);
    final mask = MaskGenerator.rectMask(cols, rows);
    final params = _paramsFor(effectiveLevel, LevelType.normal, cols, rows, mask);

    return _generateReverse(
      levelNumber: effectiveLevel,
      rows: rows,
      cols: cols,
      mask: mask,
      params: params,
      type: LevelType.normal,
      rng: rng,
      maskShape: MaskShape.square,
    );
  }

  static LevelModel _generateReverse({
    required int levelNumber,
    required int rows,
    required int cols,
    required Set<String> mask,
    required _Params params,
    required LevelType type,
    required Random rng,
    required MaskShape maskShape,
  }) {
    final maskCells = mask.map((k) {
      final parts = k.split(',');
      return [int.parse(parts[0]), int.parse(parts[1])];
    }).toList();

    final maskPacked = <int>{};
    for (final cell in maskCells) {
      maskPacked.add(cell[0] * 1000 + cell[1]);
    }

    final occupied = <String>{};
    final occupiedPacked = <int>{};
    final allExitPathsPacked = <int>{};
    final reverseArrows = <ArrowModel>[];

    final double tangleFactor;
    double baseTangle;
    if (levelNumber <= 14) {
      baseTangle = 0.0;
    } else if (levelNumber <= 30) {
      baseTangle = 0.10;
    } else if (levelNumber <= 60) {
      baseTangle = 0.30;
    } else if (levelNumber <= 150) {
      baseTangle = 0.60;
    } else if (levelNumber <= 300) {
      baseTangle = 0.85;
    } else {
      baseTangle = 1.0;
    }
    if (type == LevelType.boss) {
      baseTangle = (baseTangle + 0.15).clamp(0.15, 1.0);
    } else if (type == LevelType.god) {
      baseTangle = (baseTangle + 0.25).clamp(0.40, 1.0);
    }
    tangleFactor = baseTangle;

    int veryLongMin;
    int longMin;
    int veryLongMax;

    if (levelNumber >= 500) {
      veryLongMin = 14;
      longMin = 8;
      veryLongMax = 22;
    } else if (levelNumber >= 300) {
      veryLongMin = 12;
      longMin = 7;
      veryLongMax = 18;
    } else if (levelNumber >= 150) {
      veryLongMin = 10;
      longMin = 6;
      veryLongMax = 16;
    } else {
      final maxDim = max(rows, cols);
      veryLongMin = 5 + (maxDim ~/ 6);
      longMin = 3 + (maxDim ~/ 10);
      veryLongMax = max(
        veryLongMin + 1,
        (veryLongMin + 4).clamp(veryLongMin + 1, mask.length),
      );
    }

    if (maskShape != MaskShape.square) {
      veryLongMin = max(5, (veryLongMin * 0.8).round());
      longMin = max(3, (longMin * 0.8).round());
      veryLongMax = max(veryLongMin + 1, (veryLongMax * 0.8).round());
    }

    int targetLenForTier(_LenTier tier) {
      switch (tier) {
        case _LenTier.veryLong:
          return veryLongMin + rng.nextInt(max(1, veryLongMax - veryLongMin + 1));
        case _LenTier.long:
          return longMin + rng.nextInt(max(1, veryLongMin - longMin));
        case _LenTier.medium:
          return 2 + rng.nextInt(max(1, longMin - 1));
      }
    }

    int veryLongCount = 0;
    int longCount = 0;
    int medCount = 0;
    int failures = 0;
    final int maxFailures = max(180, max(rows, cols) * 10);

    final activeUnblockedMap = <int, Set<int>>{};

    while (failures < maxFailures && occupiedPacked.length < mask.length) {
      final candidates = _exitCandidates(
        maskCells,
        occupiedPacked,
        rows,
        cols,
      );

      if (candidates.isEmpty) {
        break;
      }

      _shuffleCandidates(candidates, rows, cols, rng, levelNumber);

      final total = veryLongCount + longCount + medCount;
      final _LenTier wantTier;
      if (failures > 8 || occupiedPacked.length >= mask.length * 0.80) {
        wantTier = _LenTier.medium;
      } else if (failures > 4 || occupiedPacked.length >= mask.length * 0.65) {
        wantTier = _LenTier.long;
      } else if (total == 0) {
        wantTier = _LenTier.veryLong;
      } else {
        final vlRatio = veryLongCount / total;
        final lRatio = longCount / total;
        if (vlRatio < 0.33) {
          wantTier = _LenTier.veryLong;
        } else if (lRatio < 0.33) {
          wantTier = _LenTier.long;
        } else {
          wantTier = _LenTier.medium;
        }
      }

      int targetLen = targetLenForTier(wantTier);
      if (failures > 5) {
        targetLen = max(2, targetLen - (failures - 5));
      }

      _Cand? bestCand;
      List<List<int>>? bestPath;
      _Cand? fallbackCand;
      List<List<int>>? fallbackPath;

      final minAcceptable = failures > 15
          ? 2
          : failures > 8
              ? 3
              : (occupiedPacked.length >= mask.length * 0.75
                  ? max(2, (targetLen * 0.40).floor())
                  : max(2, (targetLen * 0.60).floor()));

      final takeCount = failures > 15 ? 180 : (levelNumber >= 150 ? 80 : 30);
      final filteredCandidates = candidates;

      if (filteredCandidates.isEmpty) {
        failures++;
        continue;
      }

      final activeUnblockedCells =
          activeUnblockedMap.values.expand((s) => s).toSet();

      for (final cand in filteredCandidates.take(takeCount)) {
        final path = _growPath(
          startRow: cand.row,
          startCol: cand.col,
          exitDir: cand.dir,
          maskPacked: maskPacked,
          occupiedPacked: occupiedPacked,
          targetLen: targetLen,
          rng: rng,
          rows: rows,
          cols: cols,
          tangleFactor: tangleFactor,
          levelNumber: levelNumber,
          allExitPathsPacked: allExitPathsPacked,
          activeUnblockedCells: activeUnblockedCells,
        );

        if (path != null && path.length >= minAcceptable) {
          bestCand = cand;
          bestPath = path;
          break;
        } else if (path != null && path.length >= 2) {
          if (fallbackPath == null || path.length > fallbackPath.length) {
            fallbackCand = cand;
            fallbackPath = path;
          }
        }
      }

      final chosenCand = bestCand ?? (failures > 5 ? fallbackCand : null);
      final chosenPath = bestPath ?? (failures > 5 ? fallbackPath : null);

      if (chosenCand != null && chosenPath != null) {
        final arrowId = 'a_${levelNumber}_${reverseArrows.length}';
        reverseArrows.add(ArrowModel(
          id: arrowId,
          row: chosenPath[0][0],
          col: chosenPath[0][1],
          direction: chosenCand.dir,
          path: chosenPath,
        ));

        final candExit = _getExitPathPacked(
          chosenPath[0][0],
          chosenPath[0][1],
          chosenCand.dir,
          rows,
          cols,
        );
        if (candExit.isNotEmpty) {
          activeUnblockedMap[reverseArrows.length - 1] = candExit;
        }

        for (final pt in chosenPath) {
          final pk = pt[0] * 1000 + pt[1];
          occupied.add('${pt[0]},${pt[1]}');
          occupiedPacked.add(pk);

          final toRemove = <int>[];
          for (final entry in activeUnblockedMap.entries) {
            if (entry.value.contains(pk)) {
              toRemove.add(entry.key);
            }
          }
          for (final k in toRemove) {
            activeUnblockedMap.remove(k);
          }
        }
        allExitPathsPacked.addAll(candExit);

        if (chosenPath.length >= veryLongMin) {
          veryLongCount++;
        } else if (chosenPath.length >= longMin) {
          longCount++;
        } else {
          medCount++;
        }
        failures = 0;
      } else {
        failures++;
      }
    }

    bool madeFillProgress = true;
    while (madeFillProgress && occupiedPacked.length < mask.length) {
      madeFillProgress = false;
      final candidates = _exitCandidates(
        maskCells,
        occupiedPacked,
        rows,
        cols,
      );
      if (candidates.isEmpty) break;
      _shuffleCandidates(candidates, rows, cols, rng, levelNumber);

      final nonZeroCandidates = candidates
          .where((c) => !_isZeroLengthExit(c.row, c.col, c.dir, rows, cols))
          .toList();
      final loopCandidates =
          nonZeroCandidates.isNotEmpty ? nonZeroCandidates : candidates;

      if (loopCandidates.isEmpty) break;

      final activeUnblockedCells =
          activeUnblockedMap.values.expand((s) => s).toSet();

      for (final cand in loopCandidates) {
        final path = _growPath(
          startRow: cand.row,
          startCol: cand.col,
          exitDir: cand.dir,
          maskPacked: maskPacked,
          occupiedPacked: occupiedPacked,
          targetLen: max(2, min(12, mask.length - occupiedPacked.length)),
          rng: rng,
          rows: rows,
          cols: cols,
          tangleFactor: 0.0,
          levelNumber: levelNumber,
          allExitPathsPacked: allExitPathsPacked,
          activeUnblockedCells: activeUnblockedCells,
        );

        if (path != null && path.length >= 2) {
          final arrowId = 'a_${levelNumber}_${reverseArrows.length}';
          reverseArrows.add(ArrowModel(
            id: arrowId,
            row: path[0][0],
            col: path[0][1],
            direction: cand.dir,
            path: path,
          ));

          final candExit = _getExitPathPacked(
            path[0][0],
            path[0][1],
            cand.dir,
            rows,
            cols,
          );
          if (candExit.isNotEmpty) {
            activeUnblockedMap[reverseArrows.length - 1] = candExit;
          }

          for (final pt in path) {
            final pk = pt[0] * 1000 + pt[1];
            occupied.add('${pt[0]},${pt[1]}');
            occupiedPacked.add(pk);

            final toRemove = <int>[];
            for (final entry in activeUnblockedMap.entries) {
              if (entry.value.contains(pk)) {
                toRemove.add(entry.key);
              }
            }
            for (final k in toRemove) {
              activeUnblockedMap.remove(k);
            }
          }
          allExitPathsPacked.addAll(candExit);
          madeFillProgress = true;
          break;
        }
      }
    }

    if (occupied.length < mask.length) {
      _absorbOrphans(reverseArrows, occupied, occupiedPacked, mask, rows, cols);
    }

    final arrows = <ArrowModel>[];
    for (int i = reverseArrows.length - 1; i >= 0; i--) {
      final a = reverseArrows[i];
      arrows.add(a.copyWith(id: 'a_${levelNumber}_${arrows.length}'));
    }

    if (arrows.isEmpty) {
      final midR = rows ~/ 2;
      final midC = cols ~/ 2;
      arrows.add(ArrowModel(
        id: 'a_${levelNumber}_0',
        row: midR,
        col: midC,
        direction: ArrowDirection.right,
        path: [
          [midR, midC],
          [midR, max(0, midC - 1)]
        ],
      ));
      occupied.add('$midR,$midC');
      occupied.add('$midR,${max(0, midC - 1)}');
    }

    final emptyCount = mask.length - occupied.length;
    final orphanDots = <OrphanDot>[];

    if (emptyCount > 0) {
      final emptyKeysPacked = maskCells
          .where((cell) => !occupiedPacked.contains(cell[0] * 1000 + cell[1]))
          .map((cell) => cell[0] * 1000 + cell[1])
          .toSet();
      final orphanMap = <int, OrphanDotType>{};

      double colorProb;
      if (levelNumber == 395 || levelNumber == 437) {
        colorProb = 0.0;
      } else if (type == LevelType.god) {
        if (levelNumber <= 7) {
          colorProb = 0.50;
        } else if (levelNumber <= 20) {
          colorProb = 0.65;
        } else if (levelNumber <= 50) {
          colorProb = 0.78;
        } else {
          colorProb = 0.88;
        }
      } else if (type == LevelType.boss) {
        if (levelNumber <= 7) {
          colorProb = 0.35;
        } else if (levelNumber <= 20) {
          colorProb = 0.50;
        } else if (levelNumber <= 50) {
          colorProb = 0.65;
        } else {
          colorProb = 0.80;
        }
      } else if (levelNumber == 3) {
        colorProb = 0.60;
      } else if (levelNumber <= 14) {
        colorProb = 0.0;
      } else {
        if (levelNumber <= 30) {
          colorProb = 0.10;
        } else if (levelNumber <= 60) {
          colorProb = 0.20;
        } else if (levelNumber <= 150) {
          colorProb = 0.40;
        } else if (levelNumber <= 300) {
          colorProb = 0.65;
        } else {
          colorProb = 0.80;
        }
      }

      for (int i = 0; i < arrows.length; i++) {
        final arrow = arrows[i];
        ArrowDirection currentDir = arrow.direction;
        final head = arrow.path[0];
        var d = currentDir.delta;
        int nr = head[0] + d[0];
        int nc = head[1] + d[1];
        final visited = <int>{};

        while (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
          final keyPacked = nr * 1000 + nc;
          if (visited.contains(keyPacked)) break;
          visited.add(keyPacked);

          if (emptyKeysPacked.contains(keyPacked)) {
            if (!orphanMap.containsKey(keyPacked)) {
              final bool shouldColor = rng.nextDouble() < colorProb;
              if (shouldColor) {
                final int maxRedirectorsForLevel;
                final int minDistance;
                if (levelNumber >= 500) {
                  maxRedirectorsForLevel = 28;
                  minDistance = 1;
                } else if (levelNumber >= 300) {
                  maxRedirectorsForLevel = 18;
                  minDistance = 2;
                } else if (levelNumber >= 150) {
                  maxRedirectorsForLevel = 12;
                  minDistance = 2;
                } else if (levelNumber <= 30) {
                  maxRedirectorsForLevel = 2;
                  minDistance = 3;
                } else if (levelNumber <= 100) {
                  maxRedirectorsForLevel = 4;
                  minDistance = 3;
                } else {
                  maxRedirectorsForLevel = 8;
                  minDistance = 3;
                }

                bool tooClose = false;
                for (final entry in orphanMap.entries) {
                  if (entry.value == OrphanDotType.neutral) continue;
                  final pk = entry.key;
                  final er = pk ~/ 1000, ec = pk % 1000;
                  if ((er - nr).abs() + (ec - nc).abs() < minDistance) {
                    tooClose = true;
                    break;
                  }
                }

                int redirectorChainCount = 0;
                for (final val in orphanMap.values) {
                  if (val != OrphanDotType.neutral) redirectorChainCount++;
                }

                if (!tooClose && redirectorChainCount < maxRedirectorsForLevel) {
                  final turns = rng.nextBool()
                      ? [currentDir.turnRight, currentDir.turnLeft]
                      : [currentDir.turnLeft, currentDir.turnRight];

                  bool assigned = false;
                  for (final candDir in turns) {
                    orphanMap[keyPacked] = _dotTypeForDir(candDir);

                    final isSolvable = _isValidRedirectorMap(orphanMap, rows, cols, arrows) &&
                        _greedySolveWithMap(rows, cols, arrows, orphanMap) !=
                            null;

                    if (isSolvable) {
                      currentDir = candDir;
                      assigned = true;
                      break;
                    } else {
                      orphanMap.remove(keyPacked); 
                    }
                  }

                  if (!assigned) {
                    orphanMap[keyPacked] = _dotTypeForDir(currentDir);
                    final isSolvable = _isValidRedirectorMap(orphanMap, rows, cols, arrows) &&
                        _greedySolveWithMap(rows, cols, arrows, orphanMap) !=
                            null;
                    if (!isSolvable) {
                      orphanMap[keyPacked] = OrphanDotType.neutral;
                    }
                  }
                } else {
                  orphanMap[keyPacked] = OrphanDotType.neutral;
                }
              } else {
                orphanMap[keyPacked] = OrphanDotType.neutral;
              }
            } else {
              final dotType = orphanMap[keyPacked]!;
              if (dotType == OrphanDotType.up) {
                currentDir = ArrowDirection.up;
              } else if (dotType == OrphanDotType.down) {
                currentDir = ArrowDirection.down;
              } else if (dotType == OrphanDotType.left) {
                currentDir = ArrowDirection.left;
              } else if (dotType == OrphanDotType.right) {
                currentDir = ArrowDirection.right;
              }
            }
          }

          d = currentDir.delta;
          nr += d[0];
          nc += d[1];
        }
      }

      for (final keyPacked in emptyKeysPacked) {
        if (!orphanMap.containsKey(keyPacked)) {
          orphanMap[keyPacked] = OrphanDotType.neutral;
        }
      }

      if (!_isValidRedirectorMap(orphanMap, rows, cols, arrows) ||
          _greedySolveWithMap(rows, cols, arrows, orphanMap) == null) {
        for (final k in emptyKeysPacked) {
          orphanMap[k] = OrphanDotType.neutral;
        }
      }

      orphanDots.addAll(orphanMap.entries.map((entry) => OrphanDot(
            row: entry.key ~/ 1000,
            col: entry.key % 1000,
            type: entry.value,
          )));

      final tempLevel = LevelModel(
        levelNumber: levelNumber,
        gridSize: cols,
        rowCount: rows,
        colCount: cols,
        arrows: arrows,
        maskShape: maskShape,
        mask: mask,
        orphanDots: orphanDots,
      );

      if (LevelSolver.solve(tempLevel, 2000) == null) {
        orphanDots.clear();
        orphanDots.addAll(orphanMap.entries.map((entry) => OrphanDot(
              row: entry.key ~/ 1000,
              col: entry.key % 1000,
              type: OrphanDotType.neutral,
            )));
      }
    }

    return LevelModel(
      levelNumber: levelNumber,
      gridSize: cols,
      rowCount: rows,
      colCount: cols,
      arrows: arrows,
      maskShape: maskShape,
      mask: mask,
      orphanDots: orphanDots,
    );
  }

  static void _shuffleCandidates(
      List<_Cand> candidates, int rows, int cols, Random rng, [int levelNumber = 1]) {
    final centerRow = rows / 2;
    final centerCol = cols / 2;
    candidates.sort((a, b) {
      if (levelNumber >= 150) {
        final isZeroA = _isZeroLengthExit(a.row, a.col, a.dir, rows, cols);
        final isZeroB = _isZeroLengthExit(b.row, b.col, b.dir, rows, cols);
        if (isZeroA != isZeroB) {
          return isZeroA ? 1 : -1;
        }
      }
      final distA = (a.row - centerRow).abs() + (a.col - centerCol).abs();
      final distB = (b.row - centerRow).abs() + (b.col - centerCol).abs();
      final scoreA = distA + (rng.nextDouble() * 2.0 - 1.0);
      final scoreB = distB + (rng.nextDouble() * 2.0 - 1.0);
      return scoreA.compareTo(scoreB);
    });
  }

  static bool _isZeroLengthExit(
      int r, int c, ArrowDirection dir, int rows, int cols) {
    final nr = r + dir.delta[0];
    final nc = c + dir.delta[1];
    return nr < 0 || nr >= rows || nc < 0 || nc >= cols;
  }

  static List<_Cand> _exitCandidates(
    List<List<int>> maskCells,
    Set<int> occupiedPacked,
    int rows,
    int cols,
  ) {
    final out = <_Cand>[];
    for (final cell in maskCells) {
      final r = cell[0], c = cell[1];
      if (occupiedPacked.contains(r * 1000 + c)) continue;
      for (final dir in ArrowDirection.values) {
        if (_canExitClean(r, c, dir, occupiedPacked, rows, cols)) {
          out.add(_Cand(r, c, dir));
        }
      }
    }
    return out;
  }

  static List<List<int>>? _growPath({
    required int startRow,
    required int startCol,
    required ArrowDirection exitDir,
    required Set<int> maskPacked,
    required Set<int> occupiedPacked,
    required int targetLen,
    required Random rng,
    required int rows,
    required int cols,
    double tangleFactor = 0.0,
    int levelNumber = 1,
    Set<int>? allExitPathsPacked,
    Set<int>? activeUnblockedCells,
  }) {
    final exitPath = _getExitPathPacked(startRow, startCol, exitDir, rows, cols);
    final path = <List<int>>[
      [startRow, startCol]
    ];
    final pathPacked = <int>{startRow * 1000 + startCol};
    int cr = startRow, cc = startCol;
    var growDir = exitDir.opposite; 
    int straight = 0;
    int crenStep = 0;
    final isHighDiff = levelNumber >= 150;

    for (int step = 1; step < targetLen; step++) {
      final valid = <ArrowDirection>[];
      for (final d in ArrowDirection.values) {
        if (d == growDir.opposite) continue; 
        final nd = d.delta;
        final nr = cr + nd[0], nc = cc + nd[1];
        if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;
        final np = nr * 1000 + nc;
        if (!maskPacked.contains(np)) continue;
        if (occupiedPacked.contains(np)) continue;
        if (exitPath.contains(np)) continue;
        if (pathPacked.contains(np)) continue;

        bool wouldFormLoop = false;
        for (final nb in [
          [-1, 0],
          [1, 0],
          [0, -1],
          [0, 1]
        ]) {
          final adjR = nr + nb[0], adjC = nc + nb[1];
          final adjP = adjR * 1000 + adjC;
          if (adjP != cr * 1000 + cc && pathPacked.contains(adjP)) {
            wouldFormLoop = true;
            break;
          }
        }
        if (wouldFormLoop) continue;

        valid.add(d);
      }
      if (valid.isEmpty) break;

      ArrowDirection chosen;
      if (step == 1) {
        if (!valid.contains(growDir)) break;
        chosen = growDir;
      } else if (isHighDiff && rng.nextDouble() < 0.65) {
        final turns = valid.where((d) => d != growDir).toList();
        final straights = valid.where((d) => d == growDir).toList();
        if (crenStep % 2 == 1 && turns.isNotEmpty) {
          chosen = _packedPick(turns, cr, cc, occupiedPacked, rng, allExitPathsPacked, activeUnblockedCells);
        } else if (straights.isNotEmpty) {
          chosen = straights[0];
        } else if (turns.isNotEmpty) {
          chosen = _packedPick(turns, cr, cc, occupiedPacked, rng, allExitPathsPacked, activeUnblockedCells);
        } else {
          chosen = valid[0];
        }
        crenStep++;
      } else {
        final turns = valid.where((d) => d != growDir).toList();
        final straights = valid.where((d) => d == growDir).toList();
        final mustTurn = straight >= 3;
        if (mustTurn && turns.isNotEmpty) {
          chosen = _packedPick(turns, cr, cc, occupiedPacked, rng, allExitPathsPacked, activeUnblockedCells);
        } else if (valid.length == 1) {
          chosen = valid[0];
        } else if (rng.nextDouble() < 0.70 && turns.isNotEmpty) {
          chosen = _packedPick(turns, cr, cc, occupiedPacked, rng, allExitPathsPacked, activeUnblockedCells);
        } else if (straights.isNotEmpty) {
          chosen = straights[0];
        } else {
          chosen = _packedPick(turns, cr, cc, occupiedPacked, rng, allExitPathsPacked, activeUnblockedCells);
        }
      }

      straight = chosen == growDir ? straight + 1 : 0;
      final nd = chosen.delta;
      cr += nd[0];
      cc += nd[1];
      path.add([cr, cc]);
      pathPacked.add(cr * 1000 + cc);
      growDir = chosen;
    }

    return path.length >= 2 ? path : null;
  }

  static ArrowDirection _packedPick(
    List<ArrowDirection> dirs,
    int cr,
    int cc,
    Set<int> occupiedPacked,
    Random rng, [
    Set<int>? exitPathsPacked,
    Set<int>? activeUnblockedCells,
  ]) {
    if (dirs.length == 1) return dirs[0];
    int best = -1;
    final bestDirs = <ArrowDirection>[];
    for (final d in dirs) {
      final nd = d.delta;
      final nr = cr + nd[0], nc = cc + nd[1];
      int score = 0;
      final np = nr * 1000 + nc;
      if (activeUnblockedCells != null && activeUnblockedCells.contains(np)) {
        score += 15;
      }
      if (exitPathsPacked != null && exitPathsPacked.contains(np)) {
        score += 3;
      }
      for (final nb in [
        [-1, 0],
        [1, 0],
        [0, -1],
        [0, 1]
      ]) {
        if (occupiedPacked.contains((nr + nb[0]) * 1000 + (nc + nb[1]))) {
          score++;
        }
      }
      if (score > best) {
        best = score;
        bestDirs.clear();
        bestDirs.add(d);
      } else if (score == best) {
        bestDirs.add(d);
      }
    }
    return bestDirs[rng.nextInt(bestDirs.length)];
  }

  static OrphanDotType _dotTypeForDir(ArrowDirection dir) {
    switch (dir) {
      case ArrowDirection.up:
        return OrphanDotType.up;
      case ArrowDirection.down:
        return OrphanDotType.down;
      case ArrowDirection.left:
        return OrphanDotType.left;
      case ArrowDirection.right:
        return OrphanDotType.right;
    }
  }

  static ArrowDirection _dirForDotType(OrphanDotType type) {
    switch (type) {
      case OrphanDotType.up:
        return ArrowDirection.up;
      case OrphanDotType.down:
        return ArrowDirection.down;
      case OrphanDotType.left:
        return ArrowDirection.left;
      case OrphanDotType.right:
        return ArrowDirection.right;
      default:
        return ArrowDirection.up;
    }
  }

  static bool _hasRedirectorCycle(
      Map<int, OrphanDotType> orphanMap, int rows, int cols) {
    for (final entry in orphanMap.entries) {
      if (entry.value == OrphanDotType.neutral) continue;
      final startPacked = entry.key;
      int r = startPacked ~/ 1000;
      int c = startPacked % 1000;
      ArrowDirection dir = _dirForDotType(entry.value);

      final visited = <int>{startPacked};
      int steps = 0;
      final maxSteps = rows * cols;

      while (true) {
        final d = dir.delta;
        r += d[0];
        c += d[1];
        if (r < 0 || r >= rows || c < 0 || c >= cols) {
          break;
        }
        steps++;
        if (steps > maxSteps) return true;

        final packed = r * 1000 + c;
        final nextType = orphanMap[packed];
        if (nextType != null && nextType != OrphanDotType.neutral) {
          if (visited.contains(packed)) {
            return true;
          }
          visited.add(packed);
          dir = _dirForDotType(nextType);
        }
      }
    }
    return false;
  }

  static bool _arrowHitsOwnBody(
      ArrowModel arrow, Map<int, OrphanDotType> orphanMap, int rows, int cols) {
    ArrowDirection currentDir = arrow.direction;
    final head = arrow.path[0];
    var d = currentDir.delta;
    int nr = head[0] + d[0];
    int nc = head[1] + d[1];
    final visited = <int>{};

    while (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
      final keyPacked = nr * 1000 + nc;
      if (visited.contains(keyPacked)) return true;
      visited.add(keyPacked);

      for (int i = 1; i < arrow.path.length; i++) {
        if (nr == arrow.path[i][0] && nc == arrow.path[i][1]) {
          return true;
        }
      }

      final dotType = orphanMap[keyPacked];
      if (dotType != null && dotType != OrphanDotType.neutral) {
        currentDir = _dirForDotType(dotType);
      }

      d = currentDir.delta;
      nr += d[0];
      nc += d[1];
    }
    return false;
  }

  static bool _isValidRedirectorMap(
      Map<int, OrphanDotType> orphanMap, int rows, int cols, List<ArrowModel> arrows) {
    if (_hasRedirectorCycle(orphanMap, rows, cols)) return false;
    for (final a in arrows) {
      if (_arrowHitsOwnBody(a, orphanMap, rows, cols)) return false;
    }
    return true;
  }

  static _Params _paramsFor(
      int level, LevelType type, int cols, int rows, Set<String> mask) {
    int avgLen;
    int arrowCount;

    if (level <= 3) {
      avgLen = 2;
      arrowCount = 4;
      return _Params(arrowCount, avgLen, mask.length);
    }

    final int cyclePhase = (level - 1) % 5;
    final bool isFlowLevel = cyclePhase == 4;

    if (level == 395 || level == 437) {
      avgLen = 6;
    } else if (isFlowLevel) {
      avgLen = (cols > 20 || rows > 20) ? 4 : 3;
    } else if (level <= 15) {
      avgLen = 3;
    } else if (level <= 50) {
      avgLen = 4;
    } else if (level < 150) {
      avgLen = 5;
    } else if (level < 300) {
      avgLen = 7;
    } else if (level < 500) {
      avgLen = 8;
    } else {
      avgLen = 9;
    }

    final totalCells = mask.length;
    final double fillRate = (level >= 150) ? 1.0 : (isFlowLevel ? 0.88 : 1.0);
    final targetOccupiedCells = (totalCells * fillRate).round();
    arrowCount = (targetOccupiedCells / avgLen).round().clamp(4, 1200);

    return _Params(arrowCount, avgLen, targetOccupiedCells);
  }

  static Set<int> _getExitPathPacked(
      int startRow, int startCol, ArrowDirection exitDir, int rows, int cols) {
    final path = <int>{};
    final d = exitDir.delta;
    int nr = startRow + d[0];
    int nc = startCol + d[1];
    while (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
      path.add(nr * 1000 + nc);
      nr += d[0];
      nc += d[1];
    }
    return path;
  }

  static MaskShape _shapeFor(LevelType type, Random rng) {
    switch (type) {
      case LevelType.normal:
        return MaskShape.square;
      case LevelType.boss:
        const bossShapes = [
          MaskShape.cat,
          MaskShape.dog,
          MaskShape.frog,
          MaskShape.fox,
          MaskShape.tiger,
          MaskShape.panda,
          MaskShape.fish,
          MaskShape.bird,
          MaskShape.butterfly,
          MaskShape.guitar,
          MaskShape.tree,
          MaskShape.house,
          MaskShape.crown,
        ];
        return bossShapes[rng.nextInt(bossShapes.length)];
      case LevelType.god:
        const godShapes = [
          MaskShape.heart,
          MaskShape.star,
          MaskShape.diamond,
          MaskShape.hexagon,
          MaskShape.blob,
          MaskShape.circle,
        ];
        return godShapes[rng.nextInt(godShapes.length)];
    }
  }

  static void _absorbOrphans(List<ArrowModel> arrows, Set<String> occupied,
      Set<int> occupiedPacked, Set<String> mask, int rows, int cols) {
    bool madeProgress = true;
    while (madeProgress) {
      madeProgress = false;
      final orphans = mask.where((k) => !occupied.contains(k)).toList();
      for (final cellKey in orphans) {
        final parts = cellKey.split(',');
        final r = int.parse(parts[0]), c = int.parse(parts[1]);
        final ptPacked = r * 1000 + c;

        for (int i = 0; i < arrows.length; i++) {
          final arrow = arrows[i];
          final tail = arrow.path.last;
          final head = arrow.path.first;
          final distTail = (tail[0] - r).abs() + (tail[1] - c).abs();
          final isHeadFront = (head[0] + arrow.direction.delta[0] == r) &&
              (head[1] + arrow.direction.delta[1] == c);

          if (distTail == 1) {
            final exitPath = _getExitPathPacked(arrow.path[0][0],
                arrow.path[0][1], arrow.direction, rows, cols);
            if (exitPath.contains(ptPacked)) continue;

            bool blocksOther = false;
            for (int j = i + 1; j < arrows.length; j++) {
              final otherExit = _getExitPathPacked(
                arrows[j].path[0][0],
                arrows[j].path[0][1],
                arrows[j].direction,
                rows,
                cols,
              );
              if (otherExit.contains(ptPacked)) {
                blocksOther = true;
                break;
              }
            }
            if (blocksOther) continue;

            bool wouldFormLoop = false;
            if (arrow.path.length >= 3) {
              for (final nb in [
                [-1, 0],
                [1, 0],
                [0, -1],
                [0, 1]
              ]) {
                final adjR = r + nb[0], adjC = c + nb[1];
                if (adjR == tail[0] && adjC == tail[1]) continue;
                for (final pt in arrow.path) {
                  if (pt[0] == adjR && pt[1] == adjC) {
                    wouldFormLoop = true;
                    break;
                  }
                }
                if (wouldFormLoop) break;
              }
            }
            if (wouldFormLoop) continue;

            final newPath = List<List<int>>.from(arrow.path)..add([r, c]);
            arrows[i] = arrow.copyWith(path: newPath);
            occupied.add(cellKey);
            occupiedPacked.add(ptPacked);
            madeProgress = true;
            break;
          } else if (isHeadFront) {
            bool blocksOther = false;
            for (int j = i + 1; j < arrows.length; j++) {
              final otherExit = _getExitPathPacked(
                arrows[j].path[0][0],
                arrows[j].path[0][1],
                arrows[j].direction,
                rows,
                cols,
              );
              if (otherExit.contains(ptPacked)) {
                blocksOther = true;
                break;
              }
            }
            if (blocksOther) continue;

            final newPath = <List<int>>[[r, c], ...arrow.path];
            arrows[i] = arrow.copyWith(path: newPath, row: r, col: c);
            occupied.add(cellKey);
            occupiedPacked.add(ptPacked);
            madeProgress = true;
            break;
          }
        }
      }
    }
  }

  static bool _canExitClean(int headRow, int headCol, ArrowDirection dir,
      Set<int> occupiedPacked, int rows, int cols) {
    final d = dir.delta;
    int nr = headRow + d[0];
    int nc = headCol + d[1];
    while (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
      if (occupiedPacked.contains(nr * 1000 + nc)) return false;
      nr += d[0];
      nc += d[1];
    }
    return true;
  }

  static List<String>? _greedySolveWithMap(int rows, int cols,
      List<ArrowModel> arrows, Map<int, OrphanDotType> orphanMap) {
    final board = Uint16List(rows * cols);
    for (int i = 0; i < arrows.length; i++) {
      for (final pt in arrows[i].path) {
        board[pt[0] * cols + pt[1]] = i + 1;
      }
    }

    final orphanTypes = Uint8List(rows * cols);
    final orphanActive = List<bool>.filled(rows * cols, false);
    orphanMap.forEach((packed, type) {
      final r = packed ~/ 1000;
      final c = packed % 1000;
      final idx = r * cols + c;
      orphanTypes[idx] = type.index;
      orphanActive[idx] = true;
    });

    final active = List<bool>.filled(arrows.length, true);
    final order = <String>[];
    int remaining = arrows.length;

    final exitVisited = Uint16List(rows * cols);
    int exitToken = 0;

    List<int>? tryExit(int ai) {
      exitToken++;
      ArrowDirection dir = arrows[ai].direction;
      final h = arrows[ai].path[0];
      var d = dir.delta;
      int nr = h[0] + d[0], nc = h[1] + d[1];
      final consumed = <int>[];
      while (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
        final idx = nr * cols + nc;
        if (exitVisited[idx] == exitToken) return null;
        exitVisited[idx] = exitToken;
        if (orphanActive[idx]) {
          consumed.add(idx);
          final t = orphanTypes[idx];
          if (t == 0) {
            dir = ArrowDirection.up;
          } else if (t == 1) {
            dir = ArrowDirection.down;
          } else if (t == 2) {
            dir = ArrowDirection.left;
          } else if (t == 3) {
            dir = ArrowDirection.right;
          }
        } else {
          final val = board[idx];
          if (val != 0 && val != ai + 1) {
            return null;
          }
        }
        d = dir.delta;
        nr += d[0];
        nc += d[1];
      }
      return consumed;
    }

    void clearArrow(int idx) {
      active[idx] = false;
      remaining--;
      for (final pt in arrows[idx].path) {
        board[pt[0] * cols + pt[1]] = 0;
      }
      order.add(arrows[idx].id);
    }

    bool madeProgress = true;
    while (madeProgress && remaining > 0) {
      madeProgress = false;

      for (int i = 0; i < arrows.length; i++) {
        if (!active[i]) continue;
        final c = tryExit(i);
        if (c != null) {
          for (final f in c) {
            orphanActive[f] = false;
          }
          clearArrow(i);
          madeProgress = true;
        }
      }
    }

    return remaining == 0 ? order : null;
  }

  static List<String>? greedySolve(LevelModel level) {
    final orphanMap = <int, OrphanDotType>{};
    for (final od in level.orphanDots) {
      orphanMap[od.row * 1000 + od.col] = od.type;
    }
    return _greedySolveWithMap(level.rows, level.cols, level.arrows, orphanMap);
  }
}

enum _LenTier { veryLong, long, medium }

class _Cand {
  final int row, col;
  final ArrowDirection dir;
  _Cand(this.row, this.col, this.dir);
}

class _Params {
  final int arrowCount, avgLen, targetCells;
  _Params(this.arrowCount, this.avgLen, this.targetCells);
}
