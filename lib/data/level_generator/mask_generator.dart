import 'dart:math';

class MaskGenerator {
  MaskGenerator._();

  static Set<String> shapeByName(String name, int side, Random rng) {
    switch (name) {
      
      case 'cat':       return catMask(side);
      case 'dog':       return dogMask(side);
      case 'frog':      return frogMask(side);
      case 'fox':       return foxMask(side);
      case 'tiger':     return tigerMask(side);
      case 'panda':     return pandaMask(side);
      case 'fish':      return fishMask(side);
      case 'bird':      return birdMask(side);
      case 'butterfly': return butterflyMask(side);
      
      case 'guitar':    return guitarMask(side);
      case 'tree':      return treeMask(side);
      case 'house':     return houseMask(side);
      case 'crown':     return crownMask(side);
      
      case 'heart':     return heartMask(side);
      case 'star':      return starMask(side, 5);
      case 'diamond':   return diamondMask(side);
      case 'hexagon':   return hexagonMask(side);
      case 'blob':      return blobMask(side, rng.nextInt(9999));
      case 'circle':    return circleMask(side);
      default:          return squareMask(side);
    }
  }

  static void _ellipse(Set<String> mask, int side,
      double cx, double cy, double rx, double ry) {
    for (int r = 0; r < side; r++) {
      for (int c = 0; c < side; c++) {
        final dx = (c + 0.5 - cx) / rx;
        final dy = (r + 0.5 - cy) / ry;
        if (dx * dx + dy * dy <= 1.0) mask.add('$r,$c');
      }
    }
  }

  static Set<String> _clean(Set<String> mask, int side) {
    if (mask.isEmpty) return mask;
    final visited = <String>{};
    final regions = <Set<String>>[];
    for (final cell in mask) {
      if (visited.contains(cell)) continue;
      final region = <String>{};
      final stack = [cell];
      while (stack.isNotEmpty) {
        final cur = stack.removeLast();
        if (!mask.contains(cur) || visited.contains(cur)) continue;
        visited.add(cur);
        region.add(cur);
        final parts = cur.split(',');
        final r = int.parse(parts[0]), c = int.parse(parts[1]);
        for (final d in [[-1,0],[1,0],[0,-1],[0,1]]) {
          final nk = '${r+d[0]},${c+d[1]}';
          if (mask.contains(nk) && !visited.contains(nk)) stack.add(nk);
        }
      }
      if (region.isNotEmpty) regions.add(region);
    }
    if (regions.isEmpty) return mask;
    regions.sort((a, b) => b.length.compareTo(a.length));
    return regions.first;
  }

  static Set<String> squareMask(int side) {
    final mask = <String>{};
    for (int r = 0; r < side; r++) {
      for (int c = 0; c < side; c++) {
        mask.add('$r,$c');
      }
    }
    return mask;
  }

  static Set<String> catMask(int side) {
    final mask = <String>{};
    final s = side.toDouble();
    
    _ellipse(mask, side, s*0.5, s*0.55, s*0.35, s*0.32);
    
    _ellipse(mask, side, s*0.22, s*0.2, s*0.15, s*0.18);
    
    _ellipse(mask, side, s*0.78, s*0.2, s*0.15, s*0.18);
    return _clean(mask, side);
  }

  static Set<String> dogMask(int side) {
    final mask = <String>{};
    final s = side.toDouble();
    
    _ellipse(mask, side, s*0.5, s*0.5, s*0.35, s*0.3);
    
    _ellipse(mask, side, s*0.15, s*0.45, s*0.12, s*0.25);
    
    _ellipse(mask, side, s*0.85, s*0.45, s*0.12, s*0.25);
    
    _ellipse(mask, side, s*0.5, s*0.65, s*0.15, s*0.12);
    return _clean(mask, side);
  }

  static Set<String> frogMask(int side) {
    final mask = <String>{};
    final s = side.toDouble();
    
    _ellipse(mask, side, s*0.5, s*0.6, s*0.42, s*0.3);
    
    _ellipse(mask, side, s*0.25, s*0.3, s*0.14, s*0.14);
    
    _ellipse(mask, side, s*0.75, s*0.3, s*0.14, s*0.14);
    return _clean(mask, side);
  }

  static Set<String> foxMask(int side) {
    final mask = <String>{};
    final s = side.toDouble();
    
    _ellipse(mask, side, s*0.5, s*0.45, s*0.3, s*0.35);
    
    _ellipse(mask, side, s*0.5, s*0.72, s*0.12, s*0.15);
    
    _ellipse(mask, side, s*0.82, s*0.35, s*0.15, s*0.22);
    return _clean(mask, side);
  }

  static Set<String> tigerMask(int side) {
    final mask = <String>{};
    final s = side.toDouble();
    
    _ellipse(mask, side, s*0.5, s*0.5, s*0.4, s*0.38);
    
    _ellipse(mask, side, s*0.18, s*0.18, s*0.12, s*0.12);
    _ellipse(mask, side, s*0.82, s*0.18, s*0.12, s*0.12);
    
    _ellipse(mask, side, s*0.5, s*0.62, s*0.14, s*0.1);
    return _clean(mask, side);
  }

  static Set<String> pandaMask(int side) {
    final mask = <String>{};
    final s = side.toDouble();
    
    _ellipse(mask, side, s*0.5, s*0.5, s*0.38, s*0.36);
    
    _ellipse(mask, side, s*0.32, s*0.42, s*0.1, s*0.1);
    _ellipse(mask, side, s*0.68, s*0.42, s*0.1, s*0.1);
    
    _ellipse(mask, side, s*0.2, s*0.2, s*0.1, s*0.1);
    _ellipse(mask, side, s*0.8, s*0.2, s*0.1, s*0.1);
    return _clean(mask, side);
  }

  static Set<String> fishMask(int side) {
    final mask = <String>{};
    final s = side.toDouble();
    
    _ellipse(mask, side, s*0.42, s*0.5, s*0.32, s*0.22);
    
    _ellipse(mask, side, s*0.82, s*0.5, s*0.14, s*0.25);
    return _clean(mask, side);
  }

  static Set<String> birdMask(int side) {
    final mask = <String>{};
    final s = side.toDouble();
    
    _ellipse(mask, side, s*0.5, s*0.6, s*0.3, s*0.22);
    
    _ellipse(mask, side, s*0.5, s*0.28, s*0.16, s*0.16);
    
    _ellipse(mask, side, s*0.5, s*0.18, s*0.06, s*0.06);
    
    _ellipse(mask, side, s*0.22, s*0.5, s*0.15, s*0.18);
    return _clean(mask, side);
  }

  static Set<String> butterflyMask(int side) {
    final mask = <String>{};
    final s = side.toDouble();
    
    _ellipse(mask, side, s*0.5, s*0.5, s*0.06, s*0.35);
    
    _ellipse(mask, side, s*0.28, s*0.35, s*0.22, s*0.18);
    _ellipse(mask, side, s*0.72, s*0.35, s*0.22, s*0.18);
    
    _ellipse(mask, side, s*0.3, s*0.65, s*0.18, s*0.15);
    _ellipse(mask, side, s*0.7, s*0.65, s*0.18, s*0.15);
    return _clean(mask, side);
  }

  static Set<String> guitarMask(int side) {
    final mask = <String>{};
    final s = side.toDouble();
    
    _ellipse(mask, side, s*0.5, s*0.65, s*0.28, s*0.25);
    
    _ellipse(mask, side, s*0.5, s*0.38, s*0.2, s*0.15);
    
    for (int r = (s*0.18).toInt(); r < (s*0.35).toInt(); r++) {
      for (int c = (s*0.44).toInt(); c < (s*0.56).toInt(); c++) {
        mask.add('$r,$c');
      }
    }
    
    _ellipse(mask, side, s*0.5, s*0.12, s*0.1, s*0.08);
    return _clean(mask, side);
  }

  static Set<String> treeMask(int side) {
    final mask = <String>{};
    final s = side.toDouble();
    
    _ellipse(mask, side, s*0.5, s*0.38, s*0.35, s*0.3);
    
    for (int r = (s*0.65).toInt(); r < (s*0.92).toInt(); r++) {
      for (int c = (s*0.4).toInt(); c < (s*0.6).toInt(); c++) {
        mask.add('$r,$c');
      }
    }
    return _clean(mask, side);
  }

  static Set<String> houseMask(int side) {
    final mask = <String>{};
    final s = side.toDouble();
    
    for (int i = 0; i < (s*0.35).toInt(); i++) {
      final frac = i / (s * 0.35);
      final halfW = (s * 0.45 * (1 - frac * 0.8)).toInt();
      final center = (s * 0.5).toInt();
      final row = (s * 0.1 + i).toInt();
      for (int c = center - halfW; c <= center + halfW; c++) {
        if (c >= 0 && c < side) mask.add('$row,$c');
      }
    }
    
    _ellipse(mask, side, s*0.5, s*0.7, s*0.38, s*0.25);
    return _clean(mask, side);
  }

  static Set<String> crownMask(int side) {
    final mask = <String>{};
    final s = side.toDouble();
    
    for (int r = (s*0.55).toInt(); r < (s*0.8).toInt(); r++) {
      for (int c = (s*0.15).toInt(); c < (s*0.85).toInt(); c++) {
        mask.add('$r,$c');
      }
    }
    
    _ellipse(mask, side, s*0.2, s*0.35, s*0.08, s*0.18);
    _ellipse(mask, side, s*0.5, s*0.3, s*0.08, s*0.22);
    _ellipse(mask, side, s*0.8, s*0.35, s*0.08, s*0.18);
    return _clean(mask, side);
  }

  static Set<String> heartMask(int side) {
    final mask = <String>{};
    final s = side.toDouble();
    
    _ellipse(mask, side, s*0.33, s*0.35, s*0.22, s*0.2);
    
    _ellipse(mask, side, s*0.67, s*0.35, s*0.22, s*0.2);
    
    final tipY = s * 0.88;
    final centerX = s * 0.5;
    for (int r = 0; r < side; r++) {
      final y = r + 0.5;
      if (y < s * 0.4 || y > tipY) continue;
      final frac = (y - s * 0.4) / (tipY - s * 0.4);
      final halfW = s * 0.35 * (1 - frac);
      for (int c = 0; c < side; c++) {
        final x = c + 0.5;
        if ((x - centerX).abs() <= halfW) mask.add('$r,$c');
      }
    }
    return _clean(mask, side);
  }

  static Set<String> starMask(int side, int points) {
    final mask = <String>{};
    final s = side.toDouble();
    final cx = s * 0.5, cy = s * 0.5;
    final outerR = s * 0.45, innerR = s * 0.2;
    for (int r = 0; r < side; r++) {
      for (int c = 0; c < side; c++) {
        final x = c + 0.5 - cx, y = r + 0.5 - cy;
        final angle = (atan2(y, x) + pi * 2) % (2 * pi);
        final sector = (angle / (2 * pi / points)).floor();
        final dist = sqrt(x * x + y * y);
        final edgeAngle = angle - sector * (2 * pi / points);
        final t = (edgeAngle / (2 * pi / points)).clamp(0.0, 1.0);
        final radiusAtAngle = t < 0.5
            ? outerR - (outerR - innerR) * (t * 2)
            : innerR + (outerR - innerR) * ((t - 0.5) * 2);
        if (dist <= radiusAtAngle) mask.add('$r,$c');
      }
    }
    return _clean(mask, side);
  }

  static Set<String> diamondMask(int side) {
    final mask = <String>{};
    final cx = side / 2.0, cy = side / 2.0;
    final r = side * 0.45;
    for (int row = 0; row < side; row++) {
      for (int col = 0; col < side; col++) {
        if ((col + 0.5 - cx).abs() / r + (row + 0.5 - cy).abs() / r <= 1.0) {
          mask.add('$row,$col');
        }
      }
    }
    return _clean(mask, side);
  }

  static Set<String> hexagonMask(int side) {
    final mask = <String>{};
    final cx = side / 2.0, cy = side / 2.0;
    final r = side * 0.45;
    for (int row = 0; row < side; row++) {
      for (int col = 0; col < side; col++) {
        final dx = (col + 0.5 - cx).abs();
        final dy = (row + 0.5 - cy).abs();
        if (dy <= r * 0.866 && dx <= r * 0.5 + (r - dy / 0.866) * 0.5) {
          mask.add('$row,$col');
        }
      }
    }
    return _clean(mask, side);
  }

  static Set<String> blobMask(int side, int seed) {
    final mask = <String>{};
    final rng = Random(seed);
    final s = side.toDouble();
    
    _ellipse(mask, side, s*0.5, s*0.5, s*0.32, s*0.3);
    
    for (int i = 0; i < 5; i++) {
      final cx = s * (0.25 + rng.nextDouble() * 0.5);
      final cy = s * (0.25 + rng.nextDouble() * 0.5);
      final rx = s * (0.12 + rng.nextDouble() * 0.15);
      final ry = s * (0.12 + rng.nextDouble() * 0.15);
      _ellipse(mask, side, cx, cy, rx, ry);
    }
    return _clean(mask, side);
  }

  static Set<String> circleMask(int side) {
    final mask = <String>{};
    final cx = side / 2.0, cy = side / 2.0;
    final r = side * 0.45;
    for (int row = 0; row < side; row++) {
      for (int col = 0; col < side; col++) {
        final dx = col + 0.5 - cx, dy = row + 0.5 - cy;
        if (dx * dx + dy * dy <= r * r) mask.add('$row,$col');
      }
    }
    return _clean(mask, side);
  }
}