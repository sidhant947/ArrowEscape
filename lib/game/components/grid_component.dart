import 'dart:async';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../data/models/level.dart';
import '../../data/models/arrow.dart';
import '../../core/app_themes.dart';
import '../game_state.dart';
import 'arrow_component.dart';

class GridComponent extends PositionComponent {
  final GameState gameState;
  double gridPixelSize;

  final Map<String, ArrowComponent> _arrowComponents = {};
  late Set<String> _mask;

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
    required this.gridPixelSize,
    required Vector2 position,
  }) : super(position: position);

  double get cellSize => gridPixelSize / gameState.level.gridSize;

  @override
  Future<void> onLoad() async {
    size = Vector2.all(gridPixelSize);
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
      )..position = Vector2(0, 0);
      _arrowComponents[arrow.id] = comp;
      add(comp);
    }
  }

  void rebuild() {
    _refreshMask();
    _buildArrows();
    _invalidateDotGrid();
  }

  void resize(double newGridPixelSize) {
    gridPixelSize = newGridPixelSize;
    size = Vector2.all(gridPixelSize);
    for (final child in children) {
      if (child is ArrowComponent) child.updateCellSize(cellSize);
    }
    _invalidateDotGrid();
  }

  void _recacheDotGrid() {
    _cachedDotGridPicture?.dispose();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final gridSize = gameState.level.gridSize;
    final cs = cellSize;
    final baseDot = (cs * 0.045).clamp(0.6, 1.6);
    final inR = baseDot;
    final outR = inR * 0.55;

    final themeColors = AppThemes.getThemeColors(gameState.theme);
    final dotColor = themeColors.arrowColor;

    final inPaint = Paint()
      ..color = dotColor.withValues(alpha: 0.24)
      ..style = PaintingStyle.fill;
    final outPaint = Paint()
      ..color = dotColor.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;

    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        final inMask = _mask.contains('$r,$c');
        canvas.drawCircle(
          Offset((c + 0.5) * cs, (r + 0.5) * cs),
          inMask ? inR : outR,
          inMask ? inPaint : outPaint,
        );
      }
    }

    _cachedDotGridPicture = recorder.endRecording();
  }

  @override
  void render(Canvas canvas) {
    final cs = cellSize;

    if (_cachedDotGridPicture == null) {
      _recacheDotGrid();
    }
    canvas.drawPicture(_cachedDotGridPicture!);

    final themeColors = AppThemes.getThemeColors(gameState.theme);
    final orphanDots = gameState.orphanDots;
    for (final entry in orphanDots.entries) {
      final parts = entry.key.split(',');
      final dotR = int.parse(parts[0]);
      final dotC = int.parse(parts[1]);
      _drawOrphanDot(canvas, Offset((dotC + 0.5) * cs, (dotR + 0.5) * cs),
          entry.value, cs, themeColors);
    }

    super.render(canvas);
  }

  static void _drawOrphanDot(
      Canvas canvas, Offset center, OrphanDotType type, double cs, ThemeColors themeColors) {
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
        ..color = themeColors.arrowColor.withValues(alpha: 0.4)
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
      ..color = themeColors.arrowColor
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
        ..color = themeColors.arrowColor
        ..style = PaintingStyle.fill,
    );

    canvas.restore();
  }

  @override
  void update(double dt) {
    super.update(dt);
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