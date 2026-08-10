import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../core/audio_haptic_helper.dart';
import '../../core/app_colors.dart';
import '../../core/app_themes.dart';
import '../../data/models/arrow.dart';
import '../../data/models/level.dart';
import '../game_state.dart';

class ArrowComponent extends PositionComponent with TapCallbacks {
  ArrowModel arrowModel;
  double cellSize;
  final GameState gameState;

  bool _isAnimating = false;
  bool _isBlockedAnimating = false;
  double _blockDuration = 0.0;
  double _blockTime = 0.0;
  double _maxBlockSlide = 0.0;
  double _slideOffset = 0.0;

  static const double _kLongPressThreshold = 0.30; 
  double _longPressAccum = 0.0;
  bool _isTouchDown = false;
  bool _isPreviewMode = false;
  List<Offset>? _previewPath;   

  bool _isExiting = false;
  double _exitProgress = 0.0;
  double _exitDuration = 0.35;
  
  List<Offset>? _deflectedExtension;

  List<Offset>? _cachedPathPx;
  List<Offset>? _cachedTrack;
  List<double>? _cachedDist;
  double? _cachedHeadDist;
  double? _cachedTailDist;
  Path? _cachedBodyPath;
  Path? _cachedCaretPath;

  void _invalidateCache() {
    _cachedPathPx = null;
    _cachedTrack = null;
    _cachedDist = null;
    _cachedHeadDist = null;
    _cachedTailDist = null;
    _cachedBodyPath = null;
    _cachedCaretPath = null;
  }

  bool _arePathsEqual(List<List<int>> a, List<List<int>> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i][0] != b[i][0] || a[i][1] != b[i][1]) return false;
    }
    return true;
  }

  ArrowComponent({
    required this.arrowModel,
    required this.cellSize,
    required this.gameState,
  }) : super(size: Vector2.all(cellSize * gameState.level.gridSize));

  void updateCellSize(double newSize) {
    cellSize = newSize;
    size = Vector2.all(newSize * gameState.level.gridSize);
    _invalidateCache();
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    if (_isExiting) return false;
    final col = (point.x / cellSize).floor();
    final row = (point.y / cellSize).floor();
    return arrowModel.path.any((pt) => pt[0] == row && pt[1] == col);
  }

  double _pressScale = 1.0;

  @override
  void onTapDown(TapDownEvent event) {
    _isTouchDown = true;
    _longPressAccum = 0.0;
    _pressScale = 0.93;
    AudioHapticHelper.playClick();
  }

  @override
  void onTapUp(TapUpEvent event) {
    _pressScale = 1.0;
    final wasPreview = _isPreviewMode;
    _isTouchDown = false;
    _longPressAccum = 0.0;
    _isPreviewMode = false;
    _previewPath = null;
    if (wasPreview) return; 
    if (_isAnimating) return;
    _triggerMove();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _pressScale = 1.0;
    _isTouchDown = false;
    _longPressAccum = 0.0;
    _isPreviewMode = false;
    _previewPath = null;
  }

  void _triggerMove() {
    if (_isAnimating) return;
    _isAnimating = true;

    final result = gameState.tapArrow(arrowModel.id);
    switch (result) {
      case TapResult.exited:
        AudioHapticHelper.playSuccess();
        _startExitAnimation();
        break;
      case TapResult.blocked:
        AudioHapticHelper.playFailure();
        _playBlockAnimation();
        break;
      case TapResult.ignored:
        _isAnimating = false;
        break;
    }
  }

  void _startExitAnimation() {
    _exitDuration = 0.4 + arrowModel.path.length * 0.08;
    _exitProgress = 0.0;
    _isExiting = true;
    _deflectedExtension = _buildDeflectedExtension();
    _invalidateCache();
  }

  List<Offset>? _buildDeflectedExtension() {
    final orphanDots = Map<String, OrphanDotType>.from(gameState.orphanDots);
    for (final dot in gameState.getConsumedDotsForArrow(arrowModel.id)) {
      orphanDots[dot.key] = dot.type;
    }
    if (orphanDots.isEmpty) return null;

    ArrowDirection currentDir = arrowModel.direction;
    final head = arrowModel.path[0];
    final gridSize = gameState.level.gridSize;
    final pts = <Offset>[];
    var d = currentDir.delta;
    int nr = head[0] + d[0];
    int nc = head[1] + d[1];
    final visited = <String>{};
    bool hasDeflection = false;

    while (nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize) {
      final key = '$nr,$nc';
      if (visited.contains(key)) break;
      visited.add(key);
      pts.add(Offset((nc + 0.5) * cellSize, (nr + 0.5) * cellSize));

      if (orphanDots.containsKey(key)) {
        final dotType = orphanDots[key]!;
        if (dotType == OrphanDotType.up) {
          hasDeflection = true;
          currentDir = ArrowDirection.up;
        } else if (dotType == OrphanDotType.down) {
          hasDeflection = true;
          currentDir = ArrowDirection.down;
        } else if (dotType == OrphanDotType.left) {
          hasDeflection = true;
          currentDir = ArrowDirection.left;
        } else if (dotType == OrphanDotType.right) {
          hasDeflection = true;
          currentDir = ArrowDirection.right;
        }
      }

      d = currentDir.delta;
      nr += d[0];
      nc += d[1];
    }

    if (!hasDeflection) return null;

    for (int i = 0; i <= 5; i++) {
      pts.add(Offset((nc + d[1] * i + 0.5) * cellSize,
                     (nr + d[0] * i + 0.5) * cellSize));
    }

    return pts.reversed.toList(); 
  }

  List<Offset> _buildBlockedExtension() {
    ArrowDirection currentDir = arrowModel.direction;
    final head = arrowModel.path[0];
    final gridSize = gameState.level.gridSize;
    final pts = <Offset>[];
    var d = currentDir.delta;
    int nr = head[0] + d[0];
    int nc = head[1] + d[1];
    final visited = <String>{};

    while (nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize) {
      final key = '$nr,$nc';
      if (visited.contains(key)) break;
      visited.add(key);

      bool occupied = false;
      for (final other in gameState.arrows) {
        if (other.id == arrowModel.id) continue;
        if (other.state == ArrowState.sliding) continue;
        for (final pt in other.path) {
          if (pt[0] == nr && pt[1] == nc) {
            occupied = true;
            break;
          }
        }
        if (occupied) break;
      }

      if (occupied) {
        break;
      }

      pts.add(Offset((nc + 0.5) * cellSize, (nr + 0.5) * cellSize));

      if (gameState.orphanDots.containsKey(key)) {
        final dotType = gameState.orphanDots[key]!;
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

      d = currentDir.delta;
      nr += d[0];
      nc += d[1];
    }

    final lastPoint = pts.isNotEmpty 
        ? pts.last 
        : Offset((head[1] + 0.5) * cellSize, (head[0] + 0.5) * cellSize);
    final overshootPoint = lastPoint + Offset(d[1] * cellSize * 0.25, d[0] * cellSize * 0.25);
    pts.add(overshootPoint);

    return pts.reversed.toList();
  }

  void _playBlockAnimation() {
    _invalidateCache();

    _cachedPathPx ??= arrowModel.path
        .map((pt) => Offset((pt[1] + 0.5) * cellSize, (pt[0] + 0.5) * cellSize))
        .toList();
    final pathPx = _cachedPathPx!;
    final blockedExt = _buildBlockedExtension();
    final track = <Offset>[...blockedExt, ...pathPx];
    final dist = <double>[0.0];
    for (int i = 1; i < track.length; i++) {
      dist.add(dist[i - 1] + (track[i] - track[i - 1]).distance);
    }

    _cachedTrack = track;
    _cachedDist = dist;
    _cachedHeadDist = dist[blockedExt.length];
    _cachedTailDist = dist[blockedExt.length + arrowModel.path.length - 1];

    _maxBlockSlide = _cachedHeadDist!;
    _blockDuration = 0.12 + (blockedExt.length - 1) * 0.06;
    _blockTime = 0.0;
    _isBlockedAnimating = true;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isTouchDown && !_isAnimating && !_isExiting) {
      _longPressAccum += dt;
      if (!_isPreviewMode && _longPressAccum >= _kLongPressThreshold) {
        _isPreviewMode = true;
        _previewPath = _buildPreviewPath();
        AudioHapticHelper.playClick();
      }
    }

    if (_isExiting) {
      _exitProgress += dt / _exitDuration;
      if (_exitProgress >= 1.0) {
        final head = arrowModel.path[0];
        final centerOffset = Offset((head[1] + 0.5) * cellSize, (head[0] + 0.5) * cellSize);
        final color = AppColors.primary;
        gameState.onParticleBurst?.call(centerOffset, color);
        removeFromParent();
        gameState.handleArrowExitCompleted(arrowModel.id);
        return;
      }
    }

    if (_isBlockedAnimating) {
      _blockTime += dt;
      final half = _blockDuration / 2;
      if (_blockTime < half) {
        final t = _blockTime / half;
        _slideOffset = Curves.easeOut.transform(t) * _maxBlockSlide;
      } else if (_blockTime < _blockDuration) {
        final t = (_blockTime - half) / half;
        _slideOffset = (1.0 - Curves.easeIn.transform(t)) * _maxBlockSlide;
      } else {
        _slideOffset = 0.0;
        _isBlockedAnimating = false;
        _isAnimating = false;
        _invalidateCache();
      }
    }

    if (_isExiting || _isBlockedAnimating) {
      return; 
    }

    ArrowModel? updated;
    final list = gameState.arrows;
    for (int i = 0; i < list.length; i++) {
      if (list[i].id == arrowModel.id) {
        updated = list[i];
        break;
      }
    }

    if (updated != null) {
      if (updated.state == ArrowState.sliding && !_isExiting && !_isAnimating) {
        _isAnimating = true;
        _startExitAnimation();
      } else if (updated.state == ArrowState.blocked && !_isAnimating) {
        _isAnimating = true;
        _playBlockAnimation();
      }
      if (updated.state != arrowModel.state ||
          updated.direction != arrowModel.direction ||
          !_arePathsEqual(updated.path, arrowModel.path)) {
        _invalidateCache();
      }
      arrowModel = updated;
    }
  }

  @override
  void render(Canvas canvas) {
    if (arrowModel.path.isEmpty) return;

    if (_pressScale != 1.0) {
      final head = arrowModel.path[0];
      final center = Offset((head[1] + 0.5) * cellSize, (head[0] + 0.5) * cellSize);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(_pressScale, _pressScale);
      canvas.translate(-center.dx, -center.dy);
    }

    _cachedPathPx ??= arrowModel.path
        .map((pt) => Offset((pt[1] + 0.5) * cellSize, (pt[0] + 0.5) * cellSize))
        .toList();
    final pathPx = _cachedPathPx!;

    final List<Offset> pts;
    final bool isAnimatingNow = _isExiting || _isBlockedAnimating;

    if (isAnimatingNow) {
      
      if (_cachedTrack == null) {
        final delta = arrowModel.direction.delta;
        final headPx = pathPx.first;

        final track = <Offset>[];
        final int extCount;
        if (_deflectedExtension != null) {
          track.addAll(_deflectedExtension!);
          extCount = _deflectedExtension!.length;
        } else {
          extCount = gameState.level.gridSize + 2;
          for (int i = extCount; i >= 1; i--) {
            track.add(headPx + Offset(delta[1] * i * cellSize, delta[0] * i * cellSize));
          }
        }
        track.addAll(pathPx);
        _cachedTrack = track;

        final dist = <double>[0.0];
        for (int i = 1; i < track.length; i++) {
          dist.add(dist[i - 1] + (track[i] - track[i - 1]).distance);
        }
        _cachedDist = dist;
        _cachedHeadDist = dist[extCount];
        _cachedTailDist = dist[extCount + arrowModel.path.length - 1];
      }

      final track = _cachedTrack!;
      final dist = _cachedDist!;
      final headDist = _cachedHeadDist!;
      final tailDist = _cachedTailDist!;

      final double animHead, animTail;
      if (_isExiting) {
        final traveled = (_exitProgress * tailDist).clamp(0.0, tailDist);
        animHead = (headDist - traveled).clamp(0.0, headDist);
        animTail = (tailDist - traveled).clamp(0.0, tailDist);
      } else {
        final traveled = _slideOffset.clamp(0.0, tailDist);
        animHead = (headDist - traveled).clamp(0.0, headDist);
        animTail = (tailDist - traveled).clamp(0.0, tailDist);
      }

      pts = _slice(track, dist, animHead, animTail);

      if (_isExiting) {
        final consumedDots = gameState.getConsumedDotsForArrow(arrowModel.id);
        for (final dot in consumedDots) {
          final dotPx = Offset((dot.col + 0.5) * cellSize, (dot.row + 0.5) * cellSize);
          double? dotDist;
          for (int i = 0; i < track.length; i++) {
            if ((track[i] - dotPx).distanceSquared < 0.01) {
              dotDist = dist[i];
              break;
            }
          }
          if (dotDist != null && animHead > dotDist) {
            _drawOrphanDot(canvas, dotPx, dot.type, cellSize);
          }
        }
      }
    } else {
      
      pts = pathPx;
    }

    if (pts.isEmpty) return;

    final mainColor = _color();
    final sw = cellSize * 0.13; 

    canvas.save();

    final Path bodyPath;
    if (isAnimatingNow) {
      bodyPath = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (int i = 1; i < pts.length; i++) {
        bodyPath.lineTo(pts[i].dx, pts[i].dy);
      }
    } else {
      if (_cachedBodyPath == null) {
        final path = Path()..moveTo(pts.first.dx, pts.first.dy);
        for (int i = 1; i < pts.length; i++) {
          path.lineTo(pts[i].dx, pts[i].dy);
        }
        _cachedBodyPath = path;
      }
      bodyPath = _cachedBodyPath!;
    }

    final themeColors = AppThemes.getThemeColors(gameState.theme);

    if (themeColors.hasGlow) {
      final glowPaint = Paint()
        ..color = mainColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw * 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawPath(bodyPath, glowPaint);
    }

    if (isAnimatingNow) {
      final trailPaint = Paint()
        ..color = mainColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw * 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(bodyPath, trailPaint);
    }

    final bodyPaint = Paint()
      ..color = mainColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(bodyPath, bodyPaint);

    _drawHead(canvas, pts, mainColor, sw);

    if (_isPreviewMode) {
      final preview = _previewPath;
      if (preview != null && preview.length >= 2) {
        final isBlocked = gameState.isArrowBlocked(arrowModel.id);
        _drawPreviewPath(canvas, preview, isBlocked);
      }
    }

    canvas.restore();
  }

  void _drawHead(Canvas canvas, List<Offset> pts, Color mainColor, double sw) {
    final Path caretPath;
    final bool isAnimatingNow = _isExiting || _isBlockedAnimating;

    if (isAnimatingNow) {
      caretPath = _buildCaretPath(pts, sw);
    } else {
      _cachedCaretPath ??= _buildCaretPath(pts, sw);
      caretPath = _cachedCaretPath!;
    }

    canvas.drawPath(
      caretPath,
      Paint()
        ..color = mainColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  Path _buildCaretPath(List<Offset> pts, double sw) {
    final prev = pts.length > 1 ? pts[1] : pts.first;
    final dv = pts.first - prev;
    final len = dv.distance;

    final d = arrowModel.direction.delta;
    final dx = len > 0.01 ? dv.dx / len : d[1].toDouble();
    final dy = len > 0.01 ? dv.dy / len : d[0].toDouble();

    final tip = pts.first + Offset(dx * cellSize * 0.3, dy * cellSize * 0.3);

    final hd = cellSize * 0.25; 
    final hw = cellSize * 0.18; 

    final base = tip - Offset(dx * hd, dy * hd);
    final px = -dy, py = dx; 

    return Path()
      ..moveTo(base.dx + px * hw, base.dy + py * hw)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(base.dx - px * hw, base.dy - py * hw);
  }

  List<Offset>? _buildPreviewPath() {
    final orphanDots = gameState.orphanDots;
    ArrowDirection currentDir = arrowModel.direction;
    final head = arrowModel.path[0];
    final gridSize = gameState.level.gridSize;
    final pts = <Offset>[];

    final headPx = Offset((head[1] + 0.5) * cellSize, (head[0] + 0.5) * cellSize);
    pts.add(headPx);

    var d = currentDir.delta;
    int nr = head[0] + d[0];
    int nc = head[1] + d[1];
    final visited = <String>{};

    while (nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize) {
      final key = '$nr,$nc';
      if (visited.contains(key)) break;
      visited.add(key);
      pts.add(Offset((nc + 0.5) * cellSize, (nr + 0.5) * cellSize));

      if (orphanDots.containsKey(key)) {
        final dotType = orphanDots[key]!;
        switch (dotType) {
          case OrphanDotType.up:    currentDir = ArrowDirection.up;    break;
          case OrphanDotType.down:  currentDir = ArrowDirection.down;  break;
          case OrphanDotType.left:  currentDir = ArrowDirection.left;  break;
          case OrphanDotType.right: currentDir = ArrowDirection.right; break;
          default: break;
        }
      }

      d = currentDir.delta;
      nr += d[0];
      nc += d[1];
    }

    for (int i = 1; i <= 2; i++) {
      pts.add(Offset((nc + d[1] * i + 0.5) * cellSize,
                     (nr + d[0] * i + 0.5) * cellSize));
    }

    return pts.isEmpty ? null : pts;
  }

  void _drawPreviewPath(Canvas canvas, List<Offset> preview, bool isBlocked) {
    if (preview.length < 2) return;

    final rawPath = Path()..moveTo(preview.first.dx, preview.first.dy);
    for (int i = 1; i < preview.length; i++) {
      rawPath.lineTo(preview[i].dx, preview[i].dy);
    }

    final Color shadowColor = isBlocked
        ? const Color(0xFF808080)
        : Colors.white;

    final Color coreColor = isBlocked
        ? const Color(0xFF606060)
        : Colors.white;

    canvas.drawPath(
      rawPath,
      Paint()
        ..color = shadowColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cellSize * 0.45 
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0),
    );

    canvas.drawPath(
      rawPath,
      Paint()
        ..color = coreColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = cellSize * 0.08
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    if (_pressScale != 1.0) {
      canvas.restore();
    }
  }

  Color _color() {
    if (arrowModel.state == ArrowState.blocked || _isBlockedAnimating) {
      return const Color(0xFF606060);
    }
    final themeColors = AppThemes.getThemeColors(gameState.theme);
    return themeColors.arrowColor;
  }

  List<Offset> _slice(
      List<Offset> track, List<double> dist, double from, double to) {
    if (from >= to) {
      if (from == to && track.isNotEmpty) {
        return [_lerp(track, dist, from)];
      }
      return [];
    }
    final pts = <Offset>[_lerp(track, dist, from)];
    for (int i = 0; i < dist.length; i++) {
      if (dist[i] > from && dist[i] < to) pts.add(track[i]);
    }
    pts.add(_lerp(track, dist, to));
    return pts;
  }

  Offset _lerp(List<Offset> track, List<double> dist, double s) {
    if (s <= dist.first) return track.first;
    if (s >= dist.last) return track.last;
    for (int i = 0; i < dist.length - 1; i++) {
      if (s >= dist[i] && s <= dist[i + 1]) {
        final t = (s - dist[i]) / (dist[i + 1] - dist[i]);
        return Offset.lerp(track[i], track[i + 1], t)!;
      }
    }
    return track.last;
  }

  static void _drawOrphanDot(
      Canvas canvas, Offset center, OrphanDotType type, double cs) {
    if (type == OrphanDotType.neutral) return;

    canvas.drawCircle(
      center,
      cs * 0.38,
      Paint()
        ..color = const Color(0xFF2A2A2A)
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      center,
      cs * 0.38,
      Paint()
        ..color = const Color(0xFF666666)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cs * 0.04,
    );

    final ArrowDirection dir;
    switch (type) {
      case OrphanDotType.up:    dir = ArrowDirection.up;    break;
      case OrphanDotType.down:  dir = ArrowDirection.down;  break;
      case OrphanDotType.left:  dir = ArrowDirection.left;  break;
      case OrphanDotType.right: dir = ArrowDirection.right; break;
      default: return;
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(dir.rotationRadians);

    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = cs * 0.06
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(-cs * 0.18, 0), Offset(cs * 0.08, 0), linePaint);

    final arrowheadPath = Path()
      ..moveTo(cs * 0.24, 0)
      ..lineTo(cs * 0.02, -cs * 0.14)
      ..lineTo(cs * 0.08, 0)
      ..lineTo(cs * 0.02, cs * 0.14)
      ..close();

    canvas.drawPath(
      arrowheadPath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    canvas.restore();
  }
}