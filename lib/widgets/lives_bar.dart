import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class LivesBar extends StatefulWidget {
  final int lives;
  final int maxLives;

  const LivesBar({super.key, required this.lives, required this.maxLives});

  @override
  State<LivesBar> createState() => _LivesBarState();
}

class _LivesBarState extends State<LivesBar> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void didUpdateWidget(LivesBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lives <= 1) {
      _animationController.duration = const Duration(milliseconds: 400);
    } else {
      _animationController.duration = const Duration(milliseconds: 1000);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLowLives = widget.lives == 1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.maxLives, (i) {
        final isFull = i < widget.lives;

        final heartWidget = Stack(
          alignment: Alignment.center,
          children: [
            if (isFull)
              Icon(
                Icons.favorite,
                color: isLowLives
                    ? Colors.redAccent.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.15),
                size: 27,
              ),
            isFull
                ? ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: isLowLives
                          ? [const Color(0xFFFF5252), const Color(0xFFFF1744)]
                          : [Colors.white, const Color(0xFFB0B0B0)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 25,
                    ),
                  )
                : const Icon(
                    Icons.favorite_border,
                    color: AppColors.surfaceLight,
                    size: 24,
                  ),
            if (isFull)
              Positioned(
                top: 5,
                left: 5,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
              child: child,
            ),
            child: isFull
                ? ScaleTransition(
                    key: ValueKey('heart_${i}_full'),
                    scale: _scaleAnimation,
                    child: heartWidget,
                  )
                : SizedBox(
                    key: ValueKey('heart_${i}_empty'),
                    child: heartWidget,
                  ),
          ),
        );
      }),
    );
  }
}