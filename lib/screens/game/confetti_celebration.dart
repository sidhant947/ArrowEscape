import 'dart:math';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

class ConfettiCelebration extends StatefulWidget {
  const ConfettiCelebration({super.key});

  @override
  State<ConfettiCelebration> createState() => _ConfettiCelebrationState();
}

class _ConfettiCelebrationState extends State<ConfettiCelebration>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final List<_Particle> _particles = [];
  final Random _rng = Random();
  Size _lastSize = Size.zero;

  static const List<Color> _colors = [
    Color(0xFFFFD700),
    Color(0xFFFF2A6D),
    Color(0xFF00F0FF),
    Color(0xFF05FFA1),
    Color(0xFFB967FF),
    Color(0xFFFF6F00),
    Color(0xFF2979FF),
    Color(0xFFFF1744),
    Color(0xFFFFEA00),
    Color(0xFFE040FB),
  ];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _initParticles(Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    _particles.clear();
    const count = 140;
    for (int i = 0; i < count; i++) {
      final isLeft = i.isEven;
      final p = _Particle();
      _spawn(p, isLeft, size, staggered: true);
      _particles.add(p);
    }
  }

  void _spawn(_Particle p, bool isLeft, Size size, {bool staggered = false}) {
    p.isLeft = isLeft;
    p.x = isLeft ? _rng.nextDouble() * 20 : size.width - _rng.nextDouble() * 20;
    p.y = size.height * (0.65 + _rng.nextDouble() * 0.25);

    final angleDeg = isLeft
        ? -20.0 - _rng.nextDouble() * 55.0
        : -160.0 + _rng.nextDouble() * 55.0;
    final angleRad = angleDeg * pi / 180.0;
    final speed = 550.0 + _rng.nextDouble() * 550.0;

    p.vx = cos(angleRad) * speed;
    p.vy = sin(angleRad) * speed;
    p.gravity = 600.0 + _rng.nextDouble() * 250.0;
    p.drag = 0.984;

    p.color = _colors[_rng.nextInt(_colors.length)];
    p.isCircle = _rng.nextDouble() < 0.25;
    p.w = p.isCircle ? 7.0 + _rng.nextDouble() * 4.0 : 7.0 + _rng.nextDouble() * 6.0;
    p.h = p.isCircle ? p.w : 10.0 + _rng.nextDouble() * 10.0;

    p.rotX = _rng.nextDouble() * 2 * pi;
    p.rotY = _rng.nextDouble() * 2 * pi;
    p.rotZ = _rng.nextDouble() * 2 * pi;
    p.vRotX = (_rng.nextDouble() * 12.0 - 6.0);
    p.vRotY = (_rng.nextDouble() * 12.0 - 6.0);
    p.vRotZ = (_rng.nextDouble() * 8.0 - 4.0);

    p.flutterSpeed = 4.0 + _rng.nextDouble() * 6.0;
    p.flutterAmp = 20.0 + _rng.nextDouble() * 30.0;

    p.lifetime = 2.4 + _rng.nextDouble() * 1.6;
    p.age = staggered ? _rng.nextDouble() * p.lifetime : 0.0;

    if (staggered) {
      final simDt = p.age;
      final steps = (simDt / 0.016).clamp(1, 100).toInt();
      final dt = simDt / steps;
      for (int s = 0; s < steps; s++) {
        p.vx *= pow(p.drag, dt * 60);
        p.vy += p.gravity * dt;
        p.x += p.vx * dt + sin(s * dt * p.flutterSpeed) * p.flutterAmp * dt;
        p.y += p.vy * dt;
      }
    }
  }

  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }
    double dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;
    if (dt > 0.05) dt = 0.05;

    if (_lastSize.width <= 0 || _lastSize.height <= 0) return;

    for (final p in _particles) {
      p.age += dt;
      if (p.age >= p.lifetime || p.y > _lastSize.height + 40) {
        _spawn(p, p.isLeft, _lastSize);
        continue;
      }

      p.vx *= pow(p.drag, dt * 60);
      p.vy += p.gravity * dt;
      p.x += p.vx * dt + sin(p.age * p.flutterSpeed) * p.flutterAmp * dt;
      p.y += p.vy * dt;

      p.rotX += p.vRotX * dt;
      p.rotY += p.vRotY * dt;
      p.rotZ += p.vRotZ * dt;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (size != _lastSize) {
          _lastSize = size;
          _initParticles(size);
        }
        return CustomPaint(
          size: size,
          painter: _ConfettiPainter(particles: _particles),
        );
      },
    );
  }
}

class _Particle {
  late bool isLeft;
  double x = 0;
  double y = 0;
  double vx = 0;
  double vy = 0;
  double gravity = 0;
  double drag = 0.985;
  late Color color;
  bool isCircle = false;
  double w = 0;
  double h = 0;
  double rotX = 0;
  double rotY = 0;
  double rotZ = 0;
  double vRotX = 0;
  double vRotY = 0;
  double vRotZ = 0;
  double flutterSpeed = 0;
  double flutterAmp = 0;
  double age = 0;
  double lifetime = 1;
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final Paint _paint = Paint()..style = PaintingStyle.fill;

  _ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      double alpha = 1.0;
      if (p.age < 0.15) {
        alpha = (p.age / 0.15).clamp(0.0, 1.0);
      } else if (p.age > p.lifetime - 0.4) {
        alpha = ((p.lifetime - p.age) / 0.4).clamp(0.0, 1.0);
      }

      _paint.color = p.color.withValues(alpha: alpha);

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotZ);

      final scaleX = cos(p.rotX);
      final scaleY = cos(p.rotY);
      canvas.scale(scaleX.abs().clamp(0.1, 1.0) * (scaleX < 0 ? -1 : 1),
                   scaleY.abs().clamp(0.1, 1.0) * (scaleY < 0 ? -1 : 1));

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.w / 2, _paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h),
            const Radius.circular(2),
          ),
          _paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
