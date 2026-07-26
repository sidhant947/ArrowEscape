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

    LevelModel? level;
    
    final bool isLargeGrid = gridSize > 20;
    
    final int maxAttempts =
        isLargeGrid ? (type == LevelType.normal ? 150 : 200) : 120;
    for (int attempt = 0; attempt < maxAttempts && level == null; attempt++) {
      level = _attempt(
        levelNumber: levelNumber,
        gridSize: gridSize,
        mask: mask,
        params: params,
        type: type,
        rng: rng,
        maskShape: maskShape,
        attempt: attempt,
      );
    }

    if (level != null && !isLargeGrid) {
      final strictSolution = LevelSolver.solve(level, 10000);
      if (strictSolution == null) {
        level = null; 
      }
    }

    return level ?? _fallback(levelNumber, gridSize, mask, type);
  }

  static LevelModel? _attempt({
    required int levelNumber,
    required int gridSize,
    required Set<String> mask,
    required _Params params,
    required LevelType type,
    required Random rng,
    required MaskShape maskShape,
    required int attempt,
  }) {
    final arrows = <ArrowModel>[];
    final occupied = <String>{};
    final occupiedPacked = <int>{};
    int counter = 0;

    final maskCells = mask.map((k) {
      final parts = k.split(',');
      return [int.parse(parts[0]), int.parse(parts[1])];
    }).toList();

    final maskPacked = <int>{};
    for (final cell in maskCells) {
      maskPacked.add(cell[0] * 1000 + cell[1]);
    }

    bool fillEntireGrid = attempt < 12;
    if (levelNumber == 213 || levelNumber == 395 || levelNumber == 437) {
      fillEntireGrid = false; 
    }

    int targetCount = fillEntireGrid ? mask.length : params.arrowCount;
    if (!fillEntireGrid) {
      double fillRate = 0.60;
      if (levelNumber == 213 || levelNumber == 395 || levelNumber == 437) {
        fillRate = 0.55; 
      } else {
        fillRate = (1.0 - (attempt - 12) * 0.02).clamp(0.68, 0.95);
      }
      final targetOccupied = (mask.length * fillRate).round();
      targetCount = (targetOccupied / params.avgLen).round().clamp(4, 300);
    }

    {
      int failures = 0;
      int veryLongCount = 0;
      int longCount = 0;
      int medCount = 0;
      const int maxFailures = 80;

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
      int veryLongMax = max(veryLongMin + 1,
          (veryLongMin + 4).clamp(veryLongMin + 1, mask.length));

      if (maskShape != MaskShape.square) {
        veryLongMin = max(5, (veryLongMin * 0.8).round());
        longMin = max(3, (longMin * 0.8).round());
        veryLongMax = max(veryLongMin + 1, (veryLongMax * 0.8).round());
      }

      final int maxAllowedBlocks =
          (gridSize > 20) ? 0 : 1;

      while (failures < maxFailures &&
          (fillEntireGrid
              ? occupiedPacked.length < mask.length
              : arrows.length < targetCount)) {
        
        final int relaxation = failures ~/ 8;
        final int curVeryLongMin = max(5, veryLongMin - relaxation);
        final int curLongMin = max(3, longMin - relaxation);
        final int curVeryLongMax =
            max(curVeryLongMin + 1, veryLongMax - relaxation);

        final candidates = _exitCandidates(
            maskCells, occupiedPacked, gridSize, maxAllowedBlocks);
        if (candidates.isEmpty) break;

        bool anyCanFit3 = false;
        for (final cell in maskCells) {
          final r = cell[0], c = cell[1];
          if (occupiedPacked.contains(r * 1000 + c)) continue;
          int freeNeighbours = 0;
          for (final nb in [
            [-1, 0],
            [1, 0],
            [0, -1],
            [0, 1]
          ]) {
            final nr = r + nb[0], nc = c + nb[1];
            if (maskPacked.contains(nr * 1000 + nc) &&
                !occupiedPacked.contains(nr * 1000 + nc)) {
              freeNeighbours++;
            }
          }
          if (freeNeighbours >= 2) {
            anyCanFit3 = true;
            break;
          }
        }
        if (!anyCanFit3) break; 

        _shuffleCandidatesFromCenter(candidates, gridSize, rng);

        _Cand? bestCand;
        List<List<int>>? bestPath;
        int minBlocked = 9999;

        final _LenTier wantTier;
        if (failures > 15) {
          wantTier = _LenTier.medium; 
        } else {
          final total = veryLongCount + longCount + medCount;
          if (total == 0) {
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
        }

        for (final cand in candidates.take(15)) {
          final int len;
          if (wantTier == _LenTier.veryLong) {
            final range = max(1, curVeryLongMax - curVeryLongMin + 1);
            len = curVeryLongMin + rng.nextInt(range);
          } else if (wantTier == _LenTier.long) {
            final longMax = max(curLongMin, curVeryLongMin - 1);
            final range = max(1, longMax - curLongMin + 1);
            len = curLongMin + rng.nextInt(range);
          } else {
            len = 3 + rng.nextInt(3); 
          }

          final path = _growPath(
            startRow: cand.row,
            startCol: cand.col,
            exitDir: cand.dir,
            maskPacked: maskPacked,
            occupiedPacked: occupiedPacked,
            targetLen: len,
            rng: rng,
            gridSize: gridSize,
            tangleFactor: wantTier == _LenTier.veryLong ? tangleFactor : 0.0,
          );

          final int minAcceptableLen;
          if (wantTier == _LenTier.veryLong) {
            minAcceptableLen = curVeryLongMin;
          } else if (wantTier == _LenTier.long) {
            minAcceptableLen = curLongMin;
          } else {
            minAcceptableLen = 3;
          }

          if (path != null && path.length >= minAcceptableLen) {
            final blockedCount = _evalPlacement(
              maskCells: maskCells,
              maskPacked: maskPacked,
              currentOccupiedPacked: occupiedPacked,
              newPath: path,
              gridSize: gridSize,
            );
            
            if (blockedCount == 0) {
              bestCand = cand;
              bestPath = path;
              minBlocked = 0;
              break;
            }
            if (blockedCount < minBlocked) {
              minBlocked = blockedCount;
              bestCand = cand;
              bestPath = path;
            }
          }
        }

        if (bestPath == null) {
          
          if (wantTier == _LenTier.veryLong) {
            for (final cand in candidates.take(15)) {
              final longMax = max(curLongMin, curVeryLongMin - 1);
              final range = max(1, longMax - curLongMin + 1);
              final len = curLongMin + rng.nextInt(range);
              final path = _growPath(
                startRow: cand.row,
                startCol: cand.col,
                exitDir: cand.dir,
                maskPacked: maskPacked,
                occupiedPacked: occupiedPacked,
                targetLen: len,
                rng: rng,
                gridSize: gridSize,
                tangleFactor: 0.0,
              );
              if (path != null && path.length >= curLongMin) {
                final blockedCount = _evalPlacement(
                  maskCells: maskCells,
                  maskPacked: maskPacked,
                  currentOccupiedPacked: occupiedPacked,
                  newPath: path,
                  gridSize: gridSize,
                );
                if (blockedCount == 0) {
                  bestCand = cand;
                  bestPath = path;
                  minBlocked = 0;
                  break;
                }
                if (blockedCount < minBlocked) {
                  minBlocked = blockedCount;
                  bestCand = cand;
                  bestPath = path;
                }
              }
            }
          }
          
          if (bestPath == null &&
              (wantTier == _LenTier.veryLong || wantTier == _LenTier.long)) {
            for (final cand in candidates.take(15)) {
              final len = 3 + rng.nextInt(3);
              final path = _growPath(
                startRow: cand.row,
                startCol: cand.col,
                exitDir: cand.dir,
                maskPacked: maskPacked,
                occupiedPacked: occupiedPacked,
                targetLen: len,
                rng: rng,
                gridSize: gridSize,
                tangleFactor: 0.0,
              );
              if (path != null && path.length >= 3) {
                final blockedCount = _evalPlacement(
                  maskCells: maskCells,
                  maskPacked: maskPacked,
                  currentOccupiedPacked: occupiedPacked,
                  newPath: path,
                  gridSize: gridSize,
                );
                if (blockedCount == 0) {
                  bestCand = cand;
                  bestPath = path;
                  minBlocked = 0;
                  break;
                }
                if (blockedCount < minBlocked) {
                  minBlocked = blockedCount;
                  bestCand = cand;
                  bestPath = path;
                }
              }
            }
          }
        }

        if (bestCand != null && bestPath != null && minBlocked < 1000) {
          _placeArrow(arrows, bestPath, bestCand.dir, levelNumber, counter++,
              occupied, occupiedPacked);
          if (bestPath.length >= curVeryLongMin) {
            veryLongCount++;
          } else if (bestPath.length >= curLongMin) {
            longCount++;
          } else if (bestPath.length >= 3) {
            medCount++;
          }
          failures = 0;
        } else {
          failures++;
          
          if (failures > 50 &&
              bestPath == null &&
              occupiedPacked.length >= maskPacked.length * 0.5) {
            break;
          }
        }
      }
    }

    
    const int maxAllowedBlocks = 0;

      {
        int failures = 0;
        while (failures < 60) {
          final candidates = _exitCandidates(
              maskCells, occupiedPacked, gridSize, maxAllowedBlocks);

          if (candidates.isEmpty) break;

          _shuffleCandidatesFromCenter(candidates, gridSize, rng);

          _Cand? bestCand;
          List<List<int>>? bestPath;
          int minBlocked = 9999;

          for (final cand in candidates.take(20)) {
            final path = _growPath(
              startRow: cand.row,
              startCol: cand.col,
              exitDir: cand.dir,
              maskPacked: maskPacked,
              occupiedPacked: occupiedPacked,
              targetLen: 2,
              rng: rng,
              gridSize: gridSize,
            );
            if (path != null && path.length == 2) {
              final blockedCount = _evalPlacement(
                maskCells: maskCells,
                maskPacked: maskPacked,
                currentOccupiedPacked: occupiedPacked,
                newPath: path,
                gridSize: gridSize,
              );
              if (blockedCount == 0) {
                bestCand = cand;
                bestPath = path;
                minBlocked = 0;
                break;
              }
              if (blockedCount < minBlocked) {
                minBlocked = blockedCount;
                bestCand = cand;
                bestPath = path;
              }
            }
          }

          if (bestCand != null && bestPath != null && minBlocked < 1000) {
            _placeArrow(arrows, bestPath, bestCand.dir, levelNumber, counter++,
                occupied, occupiedPacked);
            failures = 0;
          } else {
            failures++;
          }
        }
      }

      {
        bool madeProgress = true;
        while (madeProgress) {
          madeProgress = false;

          final emptyCells = maskCells
              .where(
                  (cell) => !occupiedPacked.contains(cell[0] * 1000 + cell[1]))
              .toList()
            ..shuffle(rng);

          for (final cell in emptyCells) {
            final r = cell[0], c = cell[1];
            if (occupiedPacked.contains(r * 1000 + c)) continue;

            final nbOffsets = [
              [-1, 0],
              [1, 0],
              [0, -1],
              [0, 1]
            ]..shuffle(rng);
            for (final nb in nbOffsets) {
              final tr = r + nb[0], tc = c + nb[1];
              if (!maskPacked.contains(tr * 1000 + tc)) continue;
              if (occupiedPacked.contains(tr * 1000 + tc)) continue;

              final ArrowDirection dir1; 
              final ArrowDirection dir2; 
              if (nb[0] == 1) {
                
                dir1 = ArrowDirection.up;
                dir2 = ArrowDirection.down;
              } else if (nb[0] == -1) {
                
                dir1 = ArrowDirection.down;
                dir2 = ArrowDirection.up;
              } else if (nb[1] == 1) {
                
                dir1 = ArrowDirection.left;
                dir2 = ArrowDirection.right;
              } else {
                
                dir1 = ArrowDirection.right;
                dir2 = ArrowDirection.left;
              }

              int headRow, headCol, tailRow, tailCol;
              ArrowDirection chosenDir;

              if (_canExitClean(r, c, dir1, occupiedPacked, gridSize)) {
                headRow = r;
                headCol = c;
                tailRow = tr;
                tailCol = tc;
                chosenDir = dir1;
              } else if (_canExitClean(
                  tr, tc, dir2, occupiedPacked, gridSize)) {
                headRow = tr;
                headCol = tc;
                tailRow = r;
                tailCol = c;
                chosenDir = dir2;
              } else {
                continue; 
              }

              arrows.add(ArrowModel(
                id: 'a_${levelNumber}_${counter++}',
                row: headRow,
                col: headCol,
                direction: chosenDir,
                path: [
                  [headRow, headCol],
                  [tailRow, tailCol]
                ],
              ));
              occupied.add('$r,$c');
              occupied.add('$tr,$tc');
              occupiedPacked.add(r * 1000 + c);
              occupiedPacked.add(tr * 1000 + tc);
              madeProgress = true;
              break; 
            }
          }
        }
      }

      {
        bool madeProgress = true;
        while (madeProgress) {
          madeProgress = false;

          final emptyCells = maskCells
              .where(
                  (cell) => !occupiedPacked.contains(cell[0] * 1000 + cell[1]))
              .toList()
            ..shuffle(rng);

          for (final cell in emptyCells) {
            final r = cell[0], c = cell[1];
            if (occupiedPacked.contains(r * 1000 + c)) continue;

            final nbOffsets = [
              [-1, 0],
              [1, 0],
              [0, -1],
              [0, 1]
            ]..shuffle(rng);
            for (final nb in nbOffsets) {
              final tr = r + nb[0], tc = c + nb[1];
              if (!maskPacked.contains(tr * 1000 + tc)) continue;
              if (occupiedPacked.contains(tr * 1000 + tc)) continue;

              final ArrowDirection dir1;
              final ArrowDirection dir2;
              if (nb[0] == 1) {
                dir1 = ArrowDirection.up;
                dir2 = ArrowDirection.down;
              } else if (nb[0] == -1) {
                dir1 = ArrowDirection.down;
                dir2 = ArrowDirection.up;
              } else if (nb[1] == 1) {
                dir1 = ArrowDirection.left;
                dir2 = ArrowDirection.right;
              } else {
                dir1 = ArrowDirection.right;
                dir2 = ArrowDirection.left;
              }

              final tries = rng.nextBool()
                  ? [
                      [r, c, tr, tc, dir1],
                      [tr, tc, r, c, dir2]
                    ]
                  : [
                      [tr, tc, r, c, dir2],
                      [r, c, tr, tc, dir1]
                    ];

              bool placedSolvably = false;
              for (final t in tries) {
                final hr = t[0] as int;
                final hc = t[1] as int;
                final tailR = t[2] as int;
                final tailC = t[3] as int;
                final dir = t[4] as ArrowDirection;

                final newArrow = ArrowModel(
                  id: 'a_${levelNumber}_$counter',
                  row: hr,
                  col: hc,
                  direction: dir,
                  path: [
                    [hr, hc],
                    [tailR, tailC]
                  ],
                );

                final isSolvable =
                    _canExitClean(hr, hc, dir, occupiedPacked, gridSize);

                if (isSolvable) {
                  arrows.add(newArrow);
                  counter++;
                  occupied.add('$hr,$hc');
                  occupied.add('$tailR,$tailC');
                  occupiedPacked.add(hr * 1000 + hc);
                  occupiedPacked.add(tailR * 1000 + tailC);
                  madeProgress = true;
                  placedSolvably = true;
                  break;
                }
              }

              if (placedSolvably) break;
            }
          }
        }
      }

      if (attempt < 10) {
        bool hasAdjacentEmpty = false;
        final remainingEmpty = maskCells
            .where((cell) => !occupiedPacked.contains(cell[0] * 1000 + cell[1]))
            .toList();
        final remainingEmptyPacked =
            remainingEmpty.map((c) => c[0] * 1000 + c[1]).toSet();
        for (final cell in remainingEmpty) {
          final r = cell[0], c = cell[1];
          for (final nb in [
            [-1, 0],
            [1, 0],
            [0, -1],
            [0, 1]
          ]) {
            final nr = r + nb[0], nc = c + nb[1];
            if (remainingEmptyPacked.contains(nr * 1000 + nc)) {
              hasAdjacentEmpty = true;
              break;
            }
          }
          if (hasAdjacentEmpty) break;
        }
        if (hasAdjacentEmpty) {
          return null;
        }
      }

    if (occupied.length < mask.length) {
      _absorbOrphans(arrows, occupied, occupiedPacked, mask);
    }

    if (arrows.isEmpty) return null;

    final minArrowCoverage = (mask.length * 0.30).floor();
    if (occupied.length < minArrowCoverage) {
      return null;
    }

    final emptyCount = mask.length - occupied.length;
    const double maxOrphansPct = 0.26;
    final maxOrphans = (mask.length * maxOrphansPct).ceil().clamp(5, 300);

    if (fillEntireGrid && emptyCount > maxOrphans) {
      return null;
    }

    final orphanDots = <OrphanDot>[];
    if (emptyCount > 0) {
      final emptyKeysPacked = maskCells
          .where((cell) => !occupiedPacked.contains(cell[0] * 1000 + cell[1]))
          .map((cell) => cell[0] * 1000 + cell[1])
          .toSet();
      final orphanMap = <int, OrphanDotType>{};

      final double colorProb;
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

      for (int i = arrows.length - 1; i >= 0; i--) {
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
                  if ((er - nr).abs() + (ec - nc).abs() < 2) {
                    tooClose = true;
                    break;
                  }
                }

                if (!tooClose) {
                  final turns = rng.nextBool()
                      ? [currentDir.turnRight, currentDir.turnLeft]
                      : [currentDir.turnLeft, currentDir.turnRight];

                  bool assigned = false;
                  for (final candDir in turns) {
                    orphanMap[keyPacked] = _dotTypeForDir(candDir);

                    final isSolvable =
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
                    final isSolvable =
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

      for (final entry in orphanMap.entries) {
        final r = entry.key ~/ 1000;
        final c = entry.key % 1000;
        orphanDots.add(OrphanDot(
          row: r,
          col: c,
          type: entry.value,
        ));
        occupied.add('$r,$c');
      }
    }

    final level = LevelModel(
      levelNumber: levelNumber,
      gridSize: gridSize,
      arrows: arrows,
      maskShape: maskShape,
      mask: mask,
      orphanDots: orphanDots,
    );

    if (gridSize > 20) {
      final greedyOrder = _greedySolve(level);
      if (greedyOrder == null) {
        return null;
      }
      return level;
    }

    final quickSolution = LevelSolver.solve(level, 5000);
    if (quickSolution == null) {
      return null;
    }
    return level;
  }

  static void _placeArrow(
    List<ArrowModel> arrows,
    List<List<int>> path,
    ArrowDirection dir,
    int levelNumber,
    int counter,
    Set<String> occupied,
    Set<int> occupiedPacked,
  ) {
    arrows.add(ArrowModel(
      id: 'a_${levelNumber}_$counter',
      row: path[0][0],
      col: path[0][1],
      direction: dir,
      path: path,
    ));
    for (final pt in path) {
      occupied.add('${pt[0]},${pt[1]}');
      occupiedPacked.add(pt[0] * 1000 + pt[1]);
    }
  }

  static void _shuffleCandidatesFromCenter(
      List<_Cand> candidates, int gridSize, Random rng) {
    final centerRow = gridSize / 2;
    final centerCol = gridSize / 2;
    candidates.sort((a, b) {
      final distA = (a.row - centerRow).abs() + (a.col - centerCol).abs();
      final distB = (b.row - centerRow).abs() + (b.col - centerCol).abs();
      final scoreA =
          distA + a.blockedCount * 3.0 + (rng.nextDouble() * 3.0 - 1.5);
      final scoreB =
          distB + b.blockedCount * 3.0 + (rng.nextDouble() * 3.0 - 1.5);
      return scoreA.compareTo(scoreB);
    });
  }

  static List<_Cand> _exitCandidates(List<List<int>> maskCells,
      Set<int> occupiedPacked, int gridSize, int maxAllowedBlocks) {
    final out = <_Cand>[];
    for (final cell in maskCells) {
      final r = cell[0], c = cell[1];
      if (occupiedPacked.contains(r * 1000 + c)) continue;
      for (final dir in ArrowDirection.values) {
        final d = dir.delta;
        int nr = r + d[0];
        int nc = c + d[1];
        int blockedCount = 0;
        while (nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize) {
          if (occupiedPacked.contains(nr * 1000 + nc)) {
            blockedCount++;
          }
          nr += d[0];
          nc += d[1];
        }
        if (blockedCount <= maxAllowedBlocks) {
          out.add(_Cand(r, c, dir, blockedCount: blockedCount));
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

  static int _evalPlacement({
    required List<List<int>> maskCells,
    required Set<int> maskPacked,
    required Set<int> currentOccupiedPacked,
    required List<List<int>> newPath,
    required int gridSize,
  }) {
    
    final bool runLookAhead = gridSize < 20 &&
        currentOccupiedPacked.length >= maskPacked.length * 0.7;
    if (!runLookAhead) return 0;

    return _countBlockedEmptyCells(
      maskCells: maskCells,
      maskPacked: maskPacked,
      currentOccupiedPacked: currentOccupiedPacked,
      newPath: newPath,
      gridSize: gridSize,
    );
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

  static _Params _paramsFor(
      int level, LevelType type, int gridSize, Set<String> mask) {
    int avgLen;
    int arrowCount;

    if (level <= 3) {
      avgLen = 2;
      arrowCount = 4;
    } else {
      if (level == 395 || level == 437) {
        avgLen = 6; 
      } else if (level <= 15) {
        avgLen = 3;
      } else if (level <= 50) {
        avgLen = 4;
      } else {
        avgLen = 5;
      }

      final totalCells = mask.length;
      const double fillRate = 1.0;

      final targetOccupiedCells = (totalCells * fillRate).round();
      arrowCount = (targetOccupiedCells / avgLen).round().clamp(4, 300);
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

  static LevelModel _fallback(
      int levelNumber, int gridSize, Set<String> mask, LevelType type) {
    final arrows = <ArrowModel>[];
    final maskCells = mask.map((k) {
      final parts = k.split(',');
      return [int.parse(parts[0]), int.parse(parts[1])];
    }).toList();

    int arrowIdCounter = 0;
    final occupied = <String>{};

    for (final cell in maskCells) {
      final r = cell[0];
      final c = cell[1];
      final key = '$r,$c';
      if (occupied.contains(key)) continue;

      for (final dir in ArrowDirection.values) {
        final d = dir.delta;
        final nr = r + d[0];
        final nc = c + d[1];

        if (nr < 0 || nr >= gridSize || nc < 0 || nc >= gridSize || !mask.contains('$nr,$nc')) {
          arrows.add(ArrowModel(
            id: 'fb_${levelNumber}_${arrowIdCounter++}',
            row: r,
            col: c,
            direction: dir,
            path: [[r, c]],
          ));
          occupied.add(key);
          break;
        }
      }
    }

    if (arrows.isEmpty) {
      final mid = gridSize ~/ 2;
      arrows.add(ArrowModel(
        id: 'fb_${levelNumber}_0',
        row: mid,
        col: mid,
        direction: ArrowDirection.right,
        path: [[mid, mid]],
      ));
    }

    return LevelModel(
      levelNumber: levelNumber,
      gridSize: gridSize,
      arrows: arrows,
      mask: mask,
    );
  }

  static int _countBlockedEmptyCells({
    required List<List<int>> maskCells,
    required Set<int> maskPacked,
    required Set<int> currentOccupiedPacked,
    required List<List<int>> newPath,
    required int gridSize,
  }) {
    final newPathPacked = <int>{};
    for (final pt in newPath) {
      newPathPacked.add(pt[0] * 1000 + pt[1]);
    }
    bool isOccupied(int packed) {
      return currentOccupiedPacked.contains(packed) ||
          newPathPacked.contains(packed);
    }

    final rowsToCheck = newPath.map((pt) => pt[0]).toSet();
    final colsToCheck = newPath.map((pt) => pt[1]).toSet();
    final adjacentKeys = <int>{};
    for (final pt in newPath) {
      for (final offset in [
        [-1, 0],
        [1, 0],
        [0, -1],
        [0, 1]
      ]) {
        adjacentKeys.add((pt[0] + offset[0]) * 1000 + (pt[1] + offset[1]));
      }
    }

    int blocked = 0;
    for (final cell in maskCells) {
      final r = cell[0], c = cell[1];
      final packed = r * 1000 + c;
      if (isOccupied(packed)) continue;

      final isNear = rowsToCheck.contains(r) ||
          colsToCheck.contains(c) ||
          adjacentKeys.contains(packed);
      if (!isNear) continue;

      int emptyNeighbors = 0;
      for (final nb in [
        [-1, 0],
        [1, 0],
        [0, -1],
        [0, 1]
      ]) {
        final nr = r + nb[0];
        final nc = c + nb[1];
        final np = nr * 1000 + nc;
        if (maskPacked.contains(np) && !isOccupied(np)) {
          emptyNeighbors++;
        }
      }

      if (emptyNeighbors == 0) {
        blocked += 100; 
        continue;
      }

      bool hasExit = false;
      for (final dir in ArrowDirection.values) {
        final d = dir.delta;

        final backRow = r - d[0];
        final backCol = c - d[1];
        final backPacked = backRow * 1000 + backCol;
        if (!maskPacked.contains(backPacked) || isOccupied(backPacked)) {
          continue;
        }

        int nr = r + d[0];
        int nc = c + d[1];
        bool pathClear = true;

        while (nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize) {
          if (isOccupied(nr * 1000 + nc)) {
            pathClear = false;
            break;
          }
          nr += d[0];
          nc += d[1];
        }

        if (pathClear) {
          hasExit = true;
          break;
        }
      }

      if (!hasExit) {
        blocked += 100;
      }
    }
    return blocked;
  }

  static void _absorbOrphans(List<ArrowModel> arrows, Set<String> occupied,
      Set<int> occupiedPacked, Set<String> mask) {
    final orphans = mask.where((k) => !occupied.contains(k)).toList();
    for (final cellKey in orphans) {
      final parts = cellKey.split(',');
      final r = int.parse(parts[0]), c = int.parse(parts[1]);

      for (int i = 0; i < arrows.length; i++) {
        final arrow = arrows[i];
        final tail = arrow.path.last;
        final dist = (tail[0] - r).abs() + (tail[1] - c).abs();
        if (dist == 1) {
          
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
          break;
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

  static List<String>? _greedySolve(LevelModel level) {
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
  final int blockedCount;
  _Cand(this.row, this.col, this.dir, {this.blockedCount = 0});
}

class _Params {
  final int arrowCount, avgLen;
  _Params(this.arrowCount, this.avgLen);
}