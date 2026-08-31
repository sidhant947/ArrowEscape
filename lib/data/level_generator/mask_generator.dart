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

  static bool _inEllipse(
      double x, double y, double cx, double cy, double rx, double ry) {
    final dx = (x - cx) / rx;
    final dy = (y - cy) / ry;
    return dx * dx + dy * dy <= 1.0;
  }

  static Set<String> _fromPredicate(
      int side, bool Function(double x, double y, double absDx) predicate) {
    final mask = <String>{};
    final s = side.toDouble();
    for (int r = 0; r < side; r++) {
      final y = (r + 0.5) / s;
      for (int c = 0; c < side; c++) {
        final x = (c + 0.5) / s;
        final absDx = (x - 0.5).abs();
        if (predicate(x, y, absDx)) {
          mask.add('$r,$c');
        }
      }
    }
    return _clean(mask, side);
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
        for (final d in [
          [-1, 0],
          [1, 0],
          [0, -1],
          [0, 1]
        ]) {
          final nk = '${r + d[0]},${c + d[1]}';
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
    return _fromPredicate(side, (x, y, absDx) {
      if (_inEllipse(absDx, y, 0.0, 0.58, 0.38, 0.32)) return true;
      if (_inEllipse(absDx, y, 0.28, 0.24, 0.14, 0.18)) return true;
      if (y >= 0.14 && y <= 0.38 && absDx >= 0.16 && absDx <= 0.40) {
        final t = (y - 0.14) / 0.24;
        if (absDx <= 0.28 + t * 0.12 && absDx >= 0.28 - t * 0.12) return true;
      }
      return false;
    });
  }

  static Set<String> dogMask(int side) {
    return _fromPredicate(side, (x, y, absDx) {
      if (_inEllipse(absDx, y, 0.0, 0.48, 0.32, 0.28)) return true;
      if (_inEllipse(absDx, y, 0.35, 0.52, 0.13, 0.30)) return true;
      if (_inEllipse(absDx, y, 0.0, 0.68, 0.22, 0.20)) return true;
      if (_inEllipse(absDx, y, 0.0, 0.30, 0.22, 0.14)) return true;
      return false;
    });
  }

  static Set<String> frogMask(int side) {
    return _fromPredicate(side, (x, y, absDx) {
      if (_inEllipse(absDx, y, 0.0, 0.62, 0.44, 0.28)) return true;
      if (_inEllipse(absDx, y, 0.26, 0.32, 0.17, 0.18)) return true;
      if (_inEllipse(absDx, y, 0.0, 0.42, 0.24, 0.14)) return true;
      if (_inEllipse(absDx, y, 0.36, 0.82, 0.10, 0.08)) return true;
      return false;
    });
  }

  static Set<String> foxMask(int side) {
    return _fromPredicate(side, (x, y, absDx) {
      if (_inEllipse(absDx, y, 0.0, 0.46, 0.38, 0.24)) return true;
      if (_inEllipse(absDx, y, 0.30, 0.24, 0.14, 0.20)) return true;
      if (y >= 0.12 && y <= 0.40 && absDx >= 0.16 && absDx <= 0.44) {
        final t = (y - 0.12) / 0.28;
        if (absDx <= 0.30 + t * 0.14 && absDx >= 0.30 - t * 0.14) return true;
      }
      if (y >= 0.44 && y <= 0.86) {
        final t = (y - 0.44) / 0.42;
        if (absDx <= (1.0 - t * 0.82) * 0.36) return true;
      }
      return false;
    });
  }

  static Set<String> tigerMask(int side) {
    return _fromPredicate(side, (x, y, absDx) {
      if (_inEllipse(absDx, y, 0.0, 0.52, 0.40, 0.34)) return true;
      if (_inEllipse(absDx, y, 0.30, 0.22, 0.14, 0.14)) return true;
      if (_inEllipse(absDx, y, 0.36, 0.60, 0.12, 0.16)) return true;
      if (_inEllipse(absDx, y, 0.0, 0.72, 0.24, 0.16)) return true;
      return false;
    });
  }

  static Set<String> pandaMask(int side) {
    return _fromPredicate(side, (x, y, absDx) {
      if (_inEllipse(absDx, y, 0.0, 0.54, 0.42, 0.36)) return true;
      if (_inEllipse(absDx, y, 0.32, 0.22, 0.16, 0.15)) return true;
      if (_inEllipse(absDx, y, 0.34, 0.62, 0.12, 0.16)) return true;
      return false;
    });
  }

  static Set<String> fishMask(int side) {
    return _fromPredicate(side, (x, y, absDx) {
      if (_inEllipse(x, y, 0.44, 0.50, 0.32, 0.24)) return true;
      if (x <= 0.44) {
        final t = (0.44 - x) / 0.34;
        if (t <= 1.0 && (y - 0.50).abs() <= (1.0 - t * 0.8) * 0.24) return true;
      }
      if (_inEllipse(x, y, 0.46, 0.24, 0.16, 0.12) && y <= 0.50) return true;
      if (_inEllipse(x, y, 0.46, 0.76, 0.12, 0.10) && y >= 0.50) return true;
      if (x >= 0.66 && x <= 0.90) {
        final t = (x - 0.66) / 0.24;
        final spread = 0.08 + t * 0.28;
        if ((y - 0.50).abs() <= spread) {
          if (x > 0.82 && (y - 0.50).abs() < (x - 0.82) * 1.5) return false;
          return true;
        }
      }
      return false;
    });
  }

  static Set<String> birdMask(int side) {
    return _fromPredicate(side, (x, y, absDx) {
      if (_inEllipse(absDx, y, 0.0, 0.52, 0.14, 0.30)) return true;
      if (_inEllipse(absDx, y, 0.0, 0.22, 0.10, 0.12)) return true;
      if (y >= 0.10 && y <= 0.22 && absDx <= (y - 0.10) * 0.6) return true;
      if (y >= 0.24 && y <= 0.64) {
        final t = (y - 0.24) / 0.40;
        final wingSpan = 0.12 + sin(t * pi) * 0.36;
        if (absDx <= wingSpan) return true;
      }
      if (y >= 0.72 && y <= 0.92 && absDx <= (0.92 - y) * 0.6 + 0.06) return true;
      return false;
    });
  }

  static Set<String> butterflyMask(int side) {
    return _fromPredicate(side, (x, y, absDx) {
      if (_inEllipse(absDx, y, 0.0, 0.50, 0.06, 0.38)) return true;
      if (_inEllipse(absDx, y, 0.28, 0.34, 0.20, 0.22)) return true;
      if (_inEllipse(absDx, y, 0.24, 0.68, 0.16, 0.18)) return true;
      if (_inEllipse(absDx, y, 0.12, 0.14, 0.05, 0.05)) return true;
      return false;
    });
  }

  static Set<String> guitarMask(int side) {
    return _fromPredicate(side, (x, y, absDx) {
      if (_inEllipse(absDx, y, 0.0, 0.72, 0.32, 0.22)) return true;
      if (_inEllipse(absDx, y, 0.0, 0.46, 0.24, 0.16)) return true;
      if (absDx <= 0.18 && y >= 0.44 && y <= 0.74) return true;
      if (absDx <= 0.08 && y >= 0.18 && y <= 0.46) return true;
      if (_inEllipse(absDx, y, 0.0, 0.12, 0.12, 0.08)) return true;
      return false;
    });
  }

  static Set<String> treeMask(int side) {
    return _fromPredicate(side, (x, y, absDx) {
      if (_inEllipse(absDx, y, 0.0, 0.26, 0.24, 0.18)) return true;
      if (_inEllipse(absDx, y, 0.0, 0.46, 0.36, 0.20)) return true;
      if (_inEllipse(absDx, y, 0.0, 0.64, 0.44, 0.20)) return true;
      if (absDx <= 0.11 && y >= 0.60 && y <= 0.94) return true;
      return false;
    });
  }

  static Set<String> houseMask(int side) {
    return _fromPredicate(side, (x, y, absDx) {
      if (y >= 0.12 && y <= 0.46 && absDx <= (y - 0.12) / 0.34 * 0.46) return true;
      if (absDx <= 0.38 && y >= 0.44 && y <= 0.88) return true;
      if (x >= 0.64 && x <= 0.76 && y >= 0.18 && y <= 0.44) return true;
      return false;
    });
  }

  static Set<String> crownMask(int side) {
    return _fromPredicate(side, (x, y, absDx) {
      if (absDx <= 0.42 && y >= 0.62 && y <= 0.84) return true;
      if (y >= 0.18 && y <= 0.64 && absDx <= (y - 0.18) / 0.46 * 0.16) return true;
      if (y >= 0.28 && y <= 0.64 && (absDx - 0.34).abs() <= (y - 0.28) / 0.36 * 0.12) return true;
      if (y >= 0.48 && y <= 0.64 && absDx <= 0.38) return true;
      return false;
    });
  }

  static Set<String> heartMask(int side) {
    return _fromPredicate(side, (x, y, absDx) {
      if (_inEllipse(absDx, y, 0.22, 0.36, 0.22, 0.22)) return true;
      if (y >= 0.36 && y <= 0.90 && absDx <= 0.44 * (1.0 - (y - 0.36) / 0.54)) return true;
      if (absDx <= 0.22 && y >= 0.24 && y <= 0.50) return true;
      return false;
    });
  }

  static Set<String> starMask(int side, int points) {
    final mask = <String>{};
    final s = side.toDouble();
    const cx = 0.5, cy = 0.5;
    const outerR = 0.46, innerR = 0.20;
    for (int r = 0; r < side; r++) {
      for (int c = 0; c < side; c++) {
        final x = (c + 0.5) / s - cx;
        final y = (r + 0.5) / s - cy;
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
    return _fromPredicate(side, (x, y, absDx) {
      return (absDx / 0.45) + ((y - 0.5).abs() / 0.45) <= 1.0;
    });
  }

  static Set<String> hexagonMask(int side) {
    return _fromPredicate(side, (x, y, absDx) {
      final dy = (y - 0.5).abs();
      return dy <= 0.42 && (absDx * 0.866 + dy * 0.5) <= 0.42 && absDx <= 0.44;
    });
  }

  static Set<String> blobMask(int side, int seed) {
    final rng = Random(seed);
    final offsets = List.generate(6, (i) {
      final angle = (i / 6.0) * 2 * pi;
      final dist = 0.16 + rng.nextDouble() * 0.12;
      final r = 0.14 + rng.nextDouble() * 0.08;
      return [0.5 + cos(angle) * dist, 0.5 + sin(angle) * dist, r];
    });

    return _fromPredicate(side, (x, y, absDx) {
      if (_inEllipse(x, y, 0.5, 0.5, 0.30, 0.28)) return true;
      for (final o in offsets) {
        if (_inEllipse(x, y, o[0], o[1], o[2], o[2])) return true;
      }
      return false;
    });
  }

  static Set<String> circleMask(int side) {
    return _fromPredicate(side, (x, y, absDx) {
      final dx = x - 0.5, dy = y - 0.5;
      return dx * dx + dy * dy <= 0.45 * 0.45;
    });
  }
}