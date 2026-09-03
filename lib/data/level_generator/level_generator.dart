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
    int gridSize = AppConstants.gridSizeForLevel(levelNumber);
    if (levelNumber == 213) gridSize = 32;
    if (levelNumber == 395) gridSize = 35;
    if (levelNumber == 437) gridSize = 36;

    final seed = levelNumber * 103 + 51;
    final rng = Random(seed);

    final maskShape = _shapeFor(type, rng);
    final mask = MaskGenerator.shapeByName(maskShape.name, gridSize, rng);
    final params = _paramsFor(levelNumber, type, gridSize, mask);

    return _generateReverse(
      levelNumber: levelNumber,
      gridSize: gridSize,
      mask: mask,
      params: params,
      type: type,
      rng: rng,
      maskShape: maskShape,
    );
  }

  static LevelModel _generateReverse({
    required int levelNumber,
    required int gridSize,
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
      baseTangle = 0.80;
    } else {
      baseTangle = 1.0;
    }
    if (type == LevelType.boss) {
      baseTangle = (baseTangle + 0.15).clamp(0.15, 1.0);
    } else if (type == LevelType.god) {
      baseTangle = (baseTangle + 0.25).clamp(0.40, 1.0);
    }
    tangleFactor = baseTangle;

    int veryLongMin = 5 + (gridSize ~/ 6);
    int longMin = 3 + (gridSize ~/ 10);
    int veryLongMax = max(
      veryLongMin + 1,
      (veryLongMin + 4).clamp(veryLongMin + 1, mask.length),
    );

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
    const int maxFailures = 40;

    while (failures < maxFailures && occupiedPacked.length < mask.length) {
      final candidates = _exitCandidates(
        maskCells,
        occupiedPacked,
        gridSize,
      );

      if (candidates.isEmpty) break;

      _shuffleCandidatesFromCenter(candidates, gridSize, rng);

      final total = veryLongCount + longCount + medCount;
      final _LenTier wantTier;
      if (failures > 10) {
        wantTier = _LenTier.medium;
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

      for (final cand in candidates.take(25)) {
        final path = _growPath(
          startRow: cand.row,
          startCol: cand.col,
          exitDir: cand.dir,
          maskPacked: maskPacked,
          occupiedPacked: occupiedPacked,
          targetLen: targetLen,
          rng: rng,
          gridSize: gridSize,
          tangleFactor: tangleFactor,
        );

        if (path != null && path.length >= 2) {
          bestCand = cand;
          bestPath = path;
          break;
        }
      }

      if (bestCand != null && bestPath != null) {
        final arrowId = 'a_${levelNumber}_${reverseArrows.length}';
        reverseArrows.add(ArrowModel(
          id: arrowId,
          row: bestPath[0][0],
          col: bestPath[0][1],
          direction: bestCand.dir,
          path: bestPath,
        ));

        for (final pt in bestPath) {
          occupied.add('${pt[0]},${pt[1]}');
          occupiedPacked.add(pt[0] * 1000 + pt[1]);
        }

        if (bestPath.length >= veryLongMin) {
          veryLongCount++;
        } else if (bestPath.length >= longMin) {
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
        gridSize,
      );
      if (candidates.isEmpty) break;
      _shuffleCandidatesFromCenter(candidates, gridSize, rng);

      for (final cand in candidates) {
        final path = _growPath(
          startRow: cand.row,
          startCol: cand.col,
          exitDir: cand.dir,
          maskPacked: maskPacked,
          occupiedPacked: occupiedPacked,
          targetLen: 2,
          rng: rng,
          gridSize: gridSize,
          tangleFactor: 0.0,
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

          for (final pt in path) {
            occupied.add('${pt[0]},${pt[1]}');
            occupiedPacked.add(pt[0] * 1000 + pt[1]);
          }
          madeFillProgress = true;
          break;
        }
      }
    }

    if (occupied.length < mask.length) {
      _absorbOrphans(reverseArrows, occupied, occupiedPacked, mask, gridSize);
    }

    final arrows = <ArrowModel>[];
    for (int i = reverseArrows.length - 1; i >= 0; i--) {
      final a = reverseArrows[i];
      arrows.add(a.copyWith(id: 'a_${levelNumber}_${arrows.length}'));
    }

    if (arrows.isEmpty) {
      final mid = gridSize ~/ 2;
      arrows.add(ArrowModel(
        id: 'a_${levelNumber}_0',
        row: mid,
        col: mid,
        direction: ArrowDirection.right,
        path: [
          [mid, mid],
          [mid, max(0, mid - 1)]
        ],
      ));
      occupied.add('$mid,$mid');
      occupied.add('$mid,${max(0, mid - 1)}');
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

        while (nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize) {
          final keyPacked = nr * 1000 + nc;
          if (visited.contains(keyPacked)) break;
          visited.add(keyPacked);

          if (emptyKeysPacked.contains(keyPacked)) {
            if (!orphanMap.containsKey(keyPacked)) {
              final bool shouldColor = rng.nextDouble() < colorProb;
              if (shouldColor) {
                
                bool tooClose = false;
                for (final entry in orphanMap.entries) {
                  if (entry.value == OrphanDotType.neutral) continue;
                  final pk = entry.key;
                  final er = pk ~/ 1000, ec = pk % 1000;
                  if ((er - nr).abs() + (ec - nc).abs() < 3) {
                    tooClose = true;
                    break;
                  }
                }

                int redirectorChainCount = 0;
                for (final val in orphanMap.values) {
                  if (val != OrphanDotType.neutral) redirectorChainCount++;
                }

                final int maxRedirectorsForLevel;
                if (levelNumber <= 30) {
                  maxRedirectorsForLevel = 2;
                } else if (levelNumber <= 100) {
                  maxRedirectorsForLevel = 4;
                } else {
                  maxRedirectorsForLevel = 8;
                }

                if (!tooClose && redirectorChainCount < maxRedirectorsForLevel) {
                  final turns = rng.nextBool()
                      ? [currentDir.turnRight, currentDir.turnLeft]
                      : [currentDir.turnLeft, currentDir.turnRight];

                  bool assigned = false;
                  for (final candDir in turns) {
                    orphanMap[keyPacked] = _dotTypeForDir(candDir);

                    final isSolvable = _isValidRedirectorMap(orphanMap, gridSize, arrows) &&
                        _greedySolveWithMap(gridSize, arrows, orphanMap) !=
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
                    final isSolvable = _isValidRedirectorMap(orphanMap, gridSize, arrows) &&
                        _greedySolveWithMap(gridSize, arrows, orphanMap) !=
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

      if (!_isValidRedirectorMap(orphanMap, gridSize, arrows) ||
          _greedySolveWithMap(gridSize, arrows, orphanMap) == null) {
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
        gridSize: gridSize,
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
      gridSize: gridSize,
      arrows: arrows,
      maskShape: maskShape,
      mask: mask,
      orphanDots: orphanDots,
    );
  }

  static void _shuffleCandidatesFromCenter(
      List<_Cand> candidates, int gridSize, Random rng) {
    final centerRow = gridSize / 2;
    final centerCol = gridSize / 2;
    candidates.sort((a, b) {
      final distA = (a.row - centerRow).abs() + (a.col - centerCol).abs();
      final distB = (b.row - centerRow).abs() + (b.col - centerCol).abs();
      final scoreA = distA + (rng.nextDouble() * 2.0 - 1.0);
      final scoreB = distB + (rng.nextDouble() * 2.0 - 1.0);
      return scoreA.compareTo(scoreB);
    });
  }

  static List<_Cand> _exitCandidates(
    List<List<int>> maskCells,
    Set<int> occupiedPacked,
    int gridSize,
  ) {
    final out = <_Cand>[];
    for (final cell in maskCells) {
      final r = cell[0], c = cell[1];
      if (occupiedPacked.contains(r * 1000 + c)) continue;
      for (final dir in ArrowDirection.values) {
        if (_canExitClean(r, c, dir, occupiedPacked, gridSize)) {
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
    required int gridSize,
    double tangleFactor = 0.0,
  }) {
    final exitPath = _getExitPathPacked(startRow, startCol, exitDir, gridSize);
    final path = <List<int>>[
      [startRow, startCol]
    ];
    final pathPacked = <int>{startRow * 1000 + startCol};
    int cr = startRow, cc = startCol;
    var growDir = exitDir.opposite; 
    int straight = 0;

    final double turnBias = 0.65 + tangleFactor * 0.20;
    final int maxStraight = tangleFactor >= 0.7 ? 2 : 3;

    for (int step = 1; step < targetLen; step++) {
      final valid = <ArrowDirection>[];
      for (final d in ArrowDirection.values) {
        if (d == growDir.opposite) continue; 
        final nd = d.delta;
        final nr = cr + nd[0], nc = cc + nd[1];
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

      if (step == 1 && !valid.contains(growDir)) {
        return null; 
      }

      final mustTurn = straight >= maxStraight;
      final turns = valid.where((d) => d != growDir).toList();
      final straights = valid.where((d) => d == growDir).toList();

      ArrowDirection chosen;
      if (step == 1) {
        chosen = growDir;
      } else if (mustTurn && turns.isNotEmpty) {
        chosen = _packedPick(turns, cr, cc, occupiedPacked, rng);
      } else if (valid.length == 1) {
        chosen = valid[0];
      } else if (rng.nextDouble() < turnBias && turns.isNotEmpty) {
        chosen = _packedPick(turns, cr, cc, occupiedPacked, rng);
      } else if (straights.isNotEmpty) {
        chosen = straights[0];
      } else {
        chosen = _packedPick(turns, cr, cc, occupiedPacked, rng);
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

  static ArrowDirection _packedPick(List<ArrowDirection> dirs, int cr, int cc,
      Set<int> occupiedPacked, Random rng) {
    if (dirs.length == 1) return dirs[0];
    int best = -1;
    final bestDirs = <ArrowDirection>[];
    for (final d in dirs) {
      final nd = d.delta;
      final nr = cr + nd[0], nc = cc + nd[1];
      int score = 0;
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
      Map<int, OrphanDotType> orphanMap, int gridSize) {
    for (final entry in orphanMap.entries) {
      if (entry.value == OrphanDotType.neutral) continue;
      final startPacked = entry.key;
      int r = startPacked ~/ 1000;
      int c = startPacked % 1000;
      ArrowDirection dir = _dirForDotType(entry.value);

      final visited = <int>{startPacked};
      int steps = 0;
      final maxSteps = gridSize * gridSize;

      while (true) {
        final d = dir.delta;
        r += d[0];
        c += d[1];
        if (r < 0 || r >= gridSize || c < 0 || c >= gridSize) {
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
      ArrowModel arrow, Map<int, OrphanDotType> orphanMap, int gridSize) {
    ArrowDirection currentDir = arrow.direction;
    final head = arrow.path[0];
    var d = currentDir.delta;
    int nr = head[0] + d[0];
    int nc = head[1] + d[1];
    final visited = <int>{};

    while (nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize) {
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
      Map<int, OrphanDotType> orphanMap, int gridSize, List<ArrowModel> arrows) {
    if (_hasRedirectorCycle(orphanMap, gridSize)) return false;
    for (final a in arrows) {
      if (_arrowHitsOwnBody(a, orphanMap, gridSize)) return false;
    }
    return true;
  }

  static _Params _paramsFor(
      int level, LevelType type, int gridSize, Set<String> mask) {
    int avgLen;
    int arrowCount;

    if (level <= 3) {
      avgLen = 2;
      arrowCount = 4;
    } else {
      final int cyclePhase = (level - 1) % 5;
      final bool isFlowLevel = cyclePhase == 4;

      if (level == 395 || level == 437) {
        avgLen = 6;
      } else if (isFlowLevel) {
        avgLen = (gridSize > 20) ? 4 : 3;
      } else if (level <= 15) {
        avgLen = 3;
      } else if (level <= 50) {
        avgLen = 4;
      } else {
        avgLen = 5;
      }

      final totalCells = mask.length;
      final double fillRate = isFlowLevel ? 0.88 : 1.0;

      final targetOccupiedCells = (totalCells * fillRate).round();
      arrowCount = (targetOccupiedCells / avgLen).round().clamp(4, 800);
    }

    return _Params(arrowCount, avgLen);
  }

  static Set<int> _getExitPathPacked(
      int startRow, int startCol, ArrowDirection exitDir, int gridSize) {
    final path = <int>{};
    final d = exitDir.delta;
    int nr = startRow + d[0];
    int nc = startCol + d[1];
    while (nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize) {
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
      Set<int> occupiedPacked, Set<String> mask, int gridSize) {
    bool madeProgress = true;
    while (madeProgress) {
      madeProgress = false;
      final orphans = mask.where((k) => !occupied.contains(k)).toList();
      for (final cellKey in orphans) {
        final parts = cellKey.split(',');
        final r = int.parse(parts[0]), c = int.parse(parts[1]);

        for (int i = 0; i < arrows.length; i++) {
          final arrow = arrows[i];
          final tail = arrow.path.last;
          final dist = (tail[0] - r).abs() + (tail[1] - c).abs();
          if (dist == 1) {
            final ptPacked = r * 1000 + c;
            final exitPath = _getExitPathPacked(arrow.path[0][0],
                arrow.path[0][1], arrow.direction, gridSize);
            if (exitPath.contains(ptPacked)) continue;

            bool blocksOther = false;
            for (int j = i + 1; j < arrows.length; j++) {
              final otherExit = _getExitPathPacked(
                arrows[j].path[0][0],
                arrows[j].path[0][1],
                arrows[j].direction,
                gridSize,
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
            occupiedPacked.add(r * 1000 + c);
            madeProgress = true;
            break;
          }
        }
      }
    }
  }

  static bool _canExitClean(int headRow, int headCol, ArrowDirection dir,
      Set<int> occupiedPacked, int gridSize) {
    final d = dir.delta;
    int nr = headRow + d[0];
    int nc = headCol + d[1];
    while (nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize) {
      if (occupiedPacked.contains(nr * 1000 + nc)) return false;
      nr += d[0];
      nc += d[1];
    }
    return true;
  }

  static List<String>? _greedySolveWithMap(int gridSize,
      List<ArrowModel> arrows, Map<int, OrphanDotType> orphanMap) {
    final board = Uint16List(gridSize * gridSize);
    for (int i = 0; i < arrows.length; i++) {
      for (final pt in arrows[i].path) {
        board[pt[0] * gridSize + pt[1]] = i + 1;
      }
    }

    final orphanTypes = Uint8List(gridSize * gridSize);
    final orphanActive = List<bool>.filled(gridSize * gridSize, false);
    orphanMap.forEach((packed, type) {
      final r = packed ~/ 1000;
      final c = packed % 1000;
      final idx = r * gridSize + c;
      orphanTypes[idx] = type.index;
      orphanActive[idx] = true;
    });

    final active = List<bool>.filled(arrows.length, true);
    final order = <String>[];
    int remaining = arrows.length;

    final exitVisited = Uint16List(gridSize * gridSize);
    int exitToken = 0;

    List<int>? tryExit(int ai) {
      exitToken++;
      ArrowDirection dir = arrows[ai].direction;
      final h = arrows[ai].path[0];
      var d = dir.delta;
      int nr = h[0] + d[0], nc = h[1] + d[1];
      final consumed = <int>[];
      while (nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize) {
        final idx = nr * gridSize + nc;
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
        board[pt[0] * gridSize + pt[1]] = 0;
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
    return _greedySolveWithMap(level.gridSize, level.arrows, orphanMap);
  }
}

enum _LenTier { veryLong, long, medium }

class _Cand {
  final int row, col;
  final ArrowDirection dir;
  _Cand(this.row, this.col, this.dir);
}

class _Params {
  final int arrowCount, avgLen;
  _Params(this.arrowCount, this.avgLen);
}