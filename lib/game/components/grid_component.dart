import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../../data/models/level.dart';
import '../../data/models/arrow.dart';
import '../../core/app_themes.dart';
import '../game_state.dart';
import 'arrow_component.dart';

class GridComponent extends PositionComponent with TapCallbacks {
  final GameState gameState;
  double cellSize;

  final Map<String, ArrowComponent> _arrowComponents = {};
  late Set<String> _mask;
  int _lastOrphanDotsLength = -1;
  final List<({int r, int c, OrphanDotType type})> _parsedOrphanDots = [];

  static final Paint _orphanFillPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _orphanStrokePaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _orphanLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _orphanArrowheadPaint = Paint()..style = PaintingStyle.fill;

  ui.Picture? _cachedDotGridPicture;
  double _entryTime = 0.0;
  bool _entryCompleted = false;

  void _invalidateDotGrid() {
    _cachedDotGridPicture?.dispose();
    _cachedDotGridPicture = null;
  }

  @override
  void onRemove() {
    _invalidateDotGrid();
    super.onRemove();
  }

  GridComponent({
    required this.gameState,
    required this.cellSize,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(gameState.level.cols * cellSize, gameState.level.rows * cellSize),
        );

  @override
  bool containsLocalPoint(Vector2 point) {
    if (!gameState.assistMode) {
      return super.containsLocalPoint(point);
    }
    return point.x >= -cellSize &&
        point.x <= size.x + cellSize &&
        point.y >= -cellSize &&
        point.y <= size.y + cellSize;
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (!gameState.assistMode) return;

    final localPos = event.localPosition;
    final c = (localPos.x / cellSize).floor();
    final r = (localPos.y / cellSize).floor();
    final rows = gameState.level.rows;
    final cols = gameState.level.cols;

    if (r < -1 || r > rows || c < -1 || c > cols) return;

    if (r >= 0 && r < rows && c >= 0 && c < cols) {
      for (final arrow in gameState.arrows) {
        if (arrow.path.any((pt) => pt[0] == r && pt[1] == c)) {
          return;
        }
      }
    }

    const neighbors = [
      [-1, -1],
      [-1, 0],
      [-1, 1],
      [0, -1],
      [0, 1],
      [1, -1],
      [1, 0],
      [1, 1],
    ];

    final maxDistSq = cellSize * cellSize;
    String? closestArrowId;
    double minDistanceSq = double.infinity;

    for (final n in neighbors) {
      final nr = r + n[0];
      final nc = c + n[1];
      if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;

      for (final arrow in gameState.arrows) {
        for (final pt in arrow.path) {
          if (pt[0] == nr && pt[1] == nc) {
            final minX = nc * cellSize;
            final maxX = minX + cellSize;
            final minY = nr * cellSize;
            final maxY = minY + cellSize;

            final dx = localPos.x < minX
                ? minX - localPos.x
                : (localPos.x > maxX ? localPos.x - maxX : 0.0);
            final dy = localPos.y < minY
                ? minY - localPos.y
                : (localPos.y > maxY ? localPos.y - maxY : 0.0);
            final distSq = dx * dx + dy * dy;

            if (distSq <= maxDistSq && distSq < minDistanceSq) {
              minDistanceSq = distSq;
              closestArrowId = arrow.id;
            }
          }
        }
      }
    }

    if (closestArrowId != null) {
      final arrowComp = _arrowComponents[closestArrowId];
      arrowComp?.triggerMove();
    }
  }

  @override
  Future<void> onLoad() async {
    size = Vector2(gameState.level.cols * cellSize, gameState.level.rows * cellSize);
    scale = Vector2.all(0.0);
    _refreshMask();
    _buildArrows();
  }

  void _refreshMask() {
    _mask = gameState.level.mask;
  }

  void _buildArrows() {
    removeAll(children.whereType<ArrowComponent>());
    _arrowComponents.clear();

    for (final arrow in gameState.arrows) {
      final comp = ArrowComponent(
        arrowModel: arrow,
        cellSize: cellSize,
        gameState: gameState,
        onExitCompleted: () => _arrowComponents.remove(arrow.id),
      )..position = Vector2(0, 0);
      _arrowComponents[arrow.id] = comp;
      add(comp);
    }
  }

  void rebuild() {
    _refreshMask();
    _buildArrows();
    _lastOrphanDotsLength = -1;
    _invalidateDotGrid();
  }

  void resize(double newCellSize) {
    cellSize = newCellSize;
    size = Vector2(gameState.level.cols * cellSize, gameState.level.rows * cellSize);
    for (final child in children) {
      if (child is ArrowComponent) child.updateCellSize(cellSize);
    }
    _invalidateDotGrid();
  }

  void _recacheDotGrid() {
    _cachedDotGridPicture?.dispose();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final cs = cellSize;
    final themeColors = AppThemes.getThemeColors(gameState.theme);
    final dotColor = themeColors.arrowColor;

    final isShaped = gameState.level.maskShape != MaskShape.square;
    if (isShaped) {
      final tilePaint = Paint()
        ..color = dotColor.withValues(alpha: 0.04)
        ..style = PaintingStyle.fill;
      for (final cellKey in _mask) {
        final parts = cellKey.split(',');
        final r = int.parse(parts[0]);
        final c = int.parse(parts[1]);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
                c * cs + cs * 0.04, r * cs + cs * 0.04, cs * 0.92, cs * 0.92),
            Radius.circular(cs * 0.16),
          ),
          tilePaint,
        );
      }
    }

    _cachedDotGridPicture = recorder.endRecording();
  }

  final List<_Shockwave> _shockwaves = [];

  void addShockwave(Offset center, Color color) {
    _shockwaves.add(_Shockwave(center: center, color: color));
  }

  @override
  void render(Canvas canvas) {
    final cs = cellSize;

    if (_cachedDotGridPicture == null) {
      _recacheDotGrid();
    }
    canvas.drawPicture(_cachedDotGridPicture!);

    for (final sw in _shockwaves) {
      sw.render(canvas, cs);
    }

    final themeColors = AppThemes.getThemeColors(gameState.theme);
    _updateParsedOrphanDots();
    for (final dot in _parsedOrphanDots) {
      _drawOrphanDot(
        canvas,
        Offset((dot.c + 0.5) * cs, (dot.r + 0.5) * cs),
        dot.type,
        cs,
        themeColors,
      );
    }

    super.render(canvas);
  }

  void _updateParsedOrphanDots() {
    final orphanDots = gameState.orphanDots;
    if (_lastOrphanDotsLength == orphanDots.length) return;
    _lastOrphanDotsLength = orphanDots.length;
    _parsedOrphanDots.clear();
    for (final entry in orphanDots.entries) {
      final parts = entry.key.split(',');
      _parsedOrphanDots.add((
        r: int.parse(parts[0]),
        c: int.parse(parts[1]),
        type: entry.value,
      ));
    }
  }

  static void _drawOrphanDot(
      Canvas canvas, Offset center, OrphanDotType type, double cs, ThemeColors themeColors) {
    if (type == OrphanDotType.neutral) return;

    _orphanFillPaint.color =
        themeColors.isLight ? const Color(0xFFE2E8F0) : const Color(0xFF2A2A2A);
    canvas.drawCircle(center, cs * 0.38, _orphanFillPaint);

    _orphanStrokePaint
      ..color = themeColors.arrowColor
          .withValues(alpha: themeColors.isLight ? 0.25 : 0.4)
      ..strokeWidth = cs * 0.04;
    canvas.drawCircle(center, cs * 0.38, _orphanStrokePaint);

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

    _orphanLinePaint
      ..color = themeColors.arrowColor
      ..strokeWidth = cs * 0.06;
    canvas.drawLine(Offset(-cs * 0.18, 0), Offset(cs * 0.08, 0), _orphanLinePaint);

    final arrowheadPath = Path()
      ..moveTo(cs * 0.24, 0)
      ..lineTo(cs * 0.02, -cs * 0.14)
      ..lineTo(cs * 0.08, 0)
      ..lineTo(cs * 0.02, cs * 0.14)
      ..close();

    _orphanArrowheadPaint.color = themeColors.arrowColor;
    canvas.drawPath(arrowheadPath, _orphanArrowheadPaint);

    canvas.restore();
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (int i = _shockwaves.length - 1; i >= 0; i--) {
      _shockwaves[i].update(dt);
      if (_shockwaves[i].isFinished) {
        _shockwaves.removeAt(i);
      }
    }
    if (!_entryCompleted) {
      _entryTime += dt;
      if (_entryTime >= 0.5) {
        scale = Vector2.all(1.0);
        _entryCompleted = true;
      } else {
        final t = _entryTime / 0.5;
        final double bounce = Curves.easeOutBack.transform(t);
        scale = Vector2.all(bounce);
      }
    }
    if (_arrowComponents.length != gameState.arrows.length) {
      final current = gameState.arrows.map((a) => a.id).toSet();
      final gone =
          _arrowComponents.keys.where((id) => !current.contains(id)).toList();
      for (final id in gone) {
        _arrowComponents[id]?.removeFromParent();
        _arrowComponents.remove(id);
      }
    }
  }
}

class _Shockwave {
  final Offset center;
  final Color color;
  double progress = 0.0;
  final double duration = 0.35;

  _Shockwave({required this.center, required this.color});

  bool get isFinished => progress >= 1.0;

  void update(double dt) {
    progress += dt / duration;
  }

  void render(Canvas canvas, double cs) {
    final t = progress.clamp(0.0, 1.0);
    final radius = cs * (0.3 + 1.2 * t);
    final alpha = (1.0 - t).clamp(0.0, 1.0);

    final paint = Paint()
      ..color = color.withValues(alpha: alpha * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = cs * 0.08 * (1.0 - t * 0.5);

    canvas.drawCircle(center, radius, paint);
  }
}