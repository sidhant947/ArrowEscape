import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/audio_haptic_helper.dart';
import '../../core/app_themes.dart';
import '../../data/models/arrow.dart';
import '../../data/models/level.dart';
import '../game_state.dart';

class ArrowComponent extends PositionComponent with TapCallbacks {
  ArrowModel arrowModel;
  double cellSize;
  final GameState gameState;
  final VoidCallback? onExitCompleted;

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
  double _previewPulseTime = 0.0;   

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
  ui.Picture? _cachedStaticPicture;

  void _invalidateCache() {
    _cachedPathPx = null;
    _cachedTrack = null;
    _cachedDist = null;
    _cachedHeadDist = null;
    _cachedTailDist = null;
    _cachedBodyPath = null;
    _cachedCaretPath = null;
    _cachedStaticPicture?.dispose();
    _cachedStaticPicture = null;
    _computeBounds();
  }

  @override
  void onRemove() {
    _cachedStaticPicture?.dispose();
    _cachedStaticPicture = null;
    super.onRemove();
  }

  static final Paint _bodyPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static final Paint _trailPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static final Paint _headPaint = Paint()..style = PaintingStyle.fill;

  static final Paint _headStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  ArrowComponent({
    required this.arrowModel,
    required this.cellSize,
    required this.gameState,
    this.onExitCompleted,
  }) : super(size: Vector2(cellSize * gameState.level.cols, cellSize * gameState.level.rows)) {
    _computeBounds();
  }

  void updateCellSize(double newSize) {
    cellSize = newSize;
    size = Vector2(newSize * gameState.level.cols, newSize * gameState.level.rows);
    _invalidateCache();
  }

  int _minR = 0, _maxR = 0, _minC = 0, _maxC = 0;

  void _computeBounds() {
    if (arrowModel.path.isEmpty) return;
    _minR = arrowModel.path[0][0];
    _maxR = _minR;
    _minC = arrowModel.path[0][1];
    _maxC = _minC;
    for (int i = 1; i < arrowModel.path.length; i++) {
      final r = arrowModel.path[i][0];
      final c = arrowModel.path[i][1];
      if (r < _minR) _minR = r;
      if (r > _maxR) _maxR = r;
      if (c < _minC) _minC = c;
      if (c > _maxC) _maxC = c;
    }
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    if (_isExiting) return false;
    final col = (point.x / cellSize).floor();
    final row = (point.y / cellSize).floor();
    if (row < _minR || row > _maxR || col < _minC || col > _maxC) {
      return false;
    }
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
    triggerMove();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _pressScale = 1.0;
    _isTouchDown = false;
    _longPressAccum = 0.0;
    _isPreviewMode = false;
    _previewPath = null;
  }

  void triggerMove() {
    if (_isAnimating) return;
    _isAnimating = true;

    final result = gameState.tapArrow(arrowModel.id);
    switch (result) {
      case TapResult.exited:
        AudioHapticHelper.playSuccess(combo: gameState.comboCount);
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
    final rows = gameState.level.rows;
    final cols = gameState.level.cols;
    final pts = <Offset>[];
    var d = currentDir.delta;
    int nr = head[0] + d[0];
    int nc = head[1] + d[1];
    final visited = <String>{};
    bool hasDeflection = false;

    while (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
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

    final int exitExtCount = (rows > cols ? rows : cols) + 5;
    for (int i = 0; i <= exitExtCount; i++) {
      pts.add(Offset((nc + d[1] * i + 0.5) * cellSize,
                     (nr + d[0] * i + 0.5) * cellSize));
    }

    return pts.reversed.toList(); 
  }

  List<Offset> _buildBlockedExtension() {
    ArrowDirection currentDir = arrowModel.direction;
    final head = arrowModel.path[0];
    final rows = gameState.level.rows;
    final cols = gameState.level.cols;
    final pts = <Offset>[];
    var d = currentDir.delta;
    int nr = head[0] + d[0];
    int nc = head[1] + d[1];
    final visited = <String>{};

    while (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
      final key = '$nr,$nc';
      if (visited.contains(key)) break;
      visited.add(key);

      if (gameState.isCellOccupied(nr, nc, arrowModel.id)) {
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
      if (_isPreviewMode) {
        _previewPulseTime += dt * 4.0;
      }
    } else {
      _previewPulseTime = 0.0;
    }

    if (_isExiting) {
      _exitProgress += dt / _exitDuration;
      if (_exitProgress >= 1.0) {
        removeFromParent();
        gameState.handleArrowExitCompleted(arrowModel.id);
        onExitCompleted?.call();
        return;
      }
    }

    if (_isBlockedAnimating) {
      _blockTime += dt;
      final half = _blockDuration * 0.4;
      if (_blockTime < half) {
        final t = _blockTime / half;
        _slideOffset = Curves.easeOutBack.transform(t) * _maxBlockSlide;
      } else if (_blockTime < _blockDuration) {
        final t = (_blockTime - half) / (_blockDuration - half);
        _slideOffset = (1.0 - Curves.elasticOut.transform(t)) * _maxBlockSlide;
      } else {
        _slideOffset = 0.0;
        _isBlockedAnimating = false;
        _isAnimating = false;
        _invalidateCache();
      }
    }
  }

  void _renderStaticArrow(Canvas canvas) {
    _cachedPathPx ??= arrowModel.path
        .map((pt) => Offset((pt[1] + 0.5) * cellSize, (pt[0] + 0.5) * cellSize))
        .toList();
    final pts = _cachedPathPx!;
    if (pts.isEmpty) return;

    final mainColor = _color();
    final sw = cellSize * 0.13;

    if (_cachedBodyPath == null) {
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (int i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      _cachedBodyPath = path;
    }

    _bodyPaint
      ..color = mainColor
      ..strokeWidth = sw;
    canvas.drawPath(_cachedBodyPath!, _bodyPaint);

    _drawHead(canvas, pts, mainColor, sw);
  }

  @override
  void render(Canvas canvas) {
    if (arrowModel.path.isEmpty) return;

    final bool isAnimatingNow = _isExiting || _isBlockedAnimating;
    final bool hasPressScale = _pressScale != 1.0;

    if (!isAnimatingNow && !hasPressScale && !_isPreviewMode) {
      if (_cachedStaticPicture == null) {
        final recorder = ui.PictureRecorder();
        final recCanvas = Canvas(recorder);
        _renderStaticArrow(recCanvas);
        _cachedStaticPicture = recorder.endRecording();
      }
      canvas.drawPicture(_cachedStaticPicture!);
      return;
    }

    if (hasPressScale) {
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
          final maxDim = gameState.level.rows > gameState.level.cols
              ? gameState.level.rows
              : gameState.level.cols;
          extCount = maxDim + 2;
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
            final themeColors = AppThemes.getThemeColors(gameState.theme);
            _drawOrphanDot(canvas, dotPx, dot.type, cellSize, themeColors);
          }
        }
      }
    } else {
      pts = pathPx;
    }

    if (pts.isEmpty) return;

    final mainColor = _color();
    final sw = cellSize * 0.13; 

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

    if (isAnimatingNow) {
      _trailPaint
        ..color = mainColor.withValues(alpha: 0.15)
        ..strokeWidth = sw * 2.0;
      canvas.drawPath(bodyPath, _trailPaint);
    }

    _bodyPaint
      ..color = mainColor
      ..strokeWidth = sw;
    canvas.drawPath(bodyPath, _bodyPaint);

    _drawHead(canvas, pts, mainColor, sw);

    if (_isPreviewMode) {
      final preview = _previewPath;
      if (preview != null && preview.length >= 2) {
        final isBlocked = gameState.isArrowBlocked(arrowModel.id);
        _drawPreviewPath(canvas, preview, isBlocked);
      }
    }

    if (hasPressScale) {
      canvas.restore();
    }
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

    _headPaint.color = mainColor;
    canvas.drawPath(caretPath, _headPaint);

    _headStrokePaint
      ..color = mainColor
      ..strokeWidth = cellSize * 0.035;
    canvas.drawPath(caretPath, _headStrokePaint);
  }

  Path _buildCaretPath(List<Offset> pts, double sw) {
    final double dx, dy;
    if (_isExiting || _isBlockedAnimating) {
      final prev = pts.length > 1 ? pts[1] : pts.first;
      final dv = pts.first - prev;
      final len = dv.distance;
      if (len > 0.01) {
        dx = dv.dx / len;
        dy = dv.dy / len;
      } else {
        final d = arrowModel.direction.delta;
        dx = d[1].toDouble();
        dy = d[0].toDouble();
      }
    } else {
      final d = arrowModel.direction.delta;
      dx = d[1].toDouble();
      dy = d[0].toDouble();
    }

    final tip = pts.first + Offset(dx * cellSize * 0.35, dy * cellSize * 0.35);
    final px = -dy, py = dx;
    final hw = cellSize * 0.22;
    final wingBase = pts.first - Offset(dx * cellSize * 0.04, dy * cellSize * 0.04);
    final notch = pts.first + Offset(dx * cellSize * 0.04, dy * cellSize * 0.04);

    return Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(wingBase.dx + px * hw, wingBase.dy + py * hw)
      ..lineTo(notch.dx, notch.dy)
      ..lineTo(wingBase.dx - px * hw, wingBase.dy - py * hw)
      ..close();
  }

  List<Offset>? _buildPreviewPath() {
    final orphanDots = gameState.orphanDots;
    ArrowDirection currentDir = arrowModel.direction;
    final head = arrowModel.path[0];
    final rows = gameState.level.rows;
    final cols = gameState.level.cols;
    final pts = <Offset>[];

    final headPx = Offset((head[1] + 0.5) * cellSize, (head[0] + 0.5) * cellSize);
    pts.add(headPx);

    var d = currentDir.delta;
    int nr = head[0] + d[0];
    int nc = head[1] + d[1];
    final visited = <String>{};

    while (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
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

    final themeColors = AppThemes.getThemeColors(gameState.theme);
    final Color shadowColor = isBlocked
        ? (themeColors.isLight ? const Color(0xFFCBD5E1) : const Color(0xFF808080))
        : (themeColors.isLight
            ? themeColors.accentColor.withValues(alpha: 0.3)
            : Colors.white);

    final Color coreColor = isBlocked
        ? (themeColors.isLight ? const Color(0xFF94A3B8) : const Color(0xFF606060))
        : (themeColors.isLight ? themeColors.accentColor : Colors.white);

    final double pulse = 0.85 + 0.15 * (1.0 + (0.5 * _previewPulseTime).abs());

    canvas.drawPath(
      rawPath,
      Paint()
        ..color = shadowColor.withValues(alpha: (0.25 * pulse).clamp(0.05, 0.4))
        ..style = PaintingStyle.stroke
        ..strokeWidth = cellSize * 0.45 * pulse
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
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
  }

  Color _color() {
    final themeColors = AppThemes.getThemeColors(gameState.theme);
    if (arrowModel.state == ArrowState.blocked || _isBlockedAnimating) {
      return themeColors.isLight
          ? const Color(0xFF94A3B8)
          : const Color(0xFF606060);
    }
    final palette = themeColors.arrowPalette;
    if (palette != null && palette.isNotEmpty) {
      final idx = arrowModel.id.hashCode.abs() % palette.length;
      return palette[idx];
    }
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

  static void _drawOrphanDot(Canvas canvas, Offset center, OrphanDotType type,
      double cs, ThemeColors themeColors) {
    if (type == OrphanDotType.neutral) return;

    canvas.drawCircle(
      center,
      cs * 0.38,
      Paint()
        ..color = themeColors.isLight
            ? const Color(0xFFE2E8F0)
            : const Color(0xFF2A2A2A)
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      center,
      cs * 0.38,
      Paint()
        ..color = themeColors.arrowColor
            .withValues(alpha: themeColors.isLight ? 0.25 : 0.4)
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
      ..color = themeColors.isLight ? themeColors.arrowColor : Colors.white
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
        ..color = themeColors.isLight ? themeColors.arrowColor : Colors.white
        ..style = PaintingStyle.fill,
    );

    canvas.restore();
  }
}