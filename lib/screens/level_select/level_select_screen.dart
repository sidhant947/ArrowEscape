import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../core/audio_haptic_helper.dart';
import '../../main.dart';
import '../game/game_screen.dart';

class LevelSelectScreen extends ConsumerWidget {
  const LevelSelectScreen({super.key});

  static int _calculateTotalVisible(int highestUnlocked) {
    if (highestUnlocked < 40) return 60;
    
    final extra = ((highestUnlocked - 40) ~/ 20) * 20;
    return 60 + extra;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressRepositoryProvider);
    final totalVisible = _calculateTotalVisible(progress.highestUnlockedLevel);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Stack(
                  children: [
                    
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.arrow_back_ios_new_rounded,
                              color: AppColors.textPrimary, size: 20),
                        ),
                      ),
                    ),
                    
                    const Center(
                      child: Text('Levels',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: GridView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: totalVisible,
                  itemBuilder: (context, index) {
                    final levelNum = index + 1;
                    final isUnlocked = progress.isLevelUnlocked(levelNum);
                    final isCompleted = progress.isLevelCompleted(levelNum);
                    final isCurrentLevel = levelNum == progress.currentLevel;

                    return _LevelCell(
                      levelNumber: levelNum,
                      isUnlocked: isUnlocked,
                      isCompleted: isCompleted,
                      isCurrentLevel: isCurrentLevel,
                      onTap: isUnlocked
                          ? () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GameScreen(level: levelNum),
                                ),
                              );
                            }
                          : null,
                    )
                        .animate(
                            delay: Duration(milliseconds: (index % 20) * 20))
                        .fadeIn(duration: 200.ms)
                        .scale(
                            begin: const Offset(0.7, 0.7),
                            end: const Offset(1, 1));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelCell extends StatelessWidget {
  final int levelNumber;
  final bool isUnlocked;
  final bool isCompleted;
  final bool isCurrentLevel;
  final VoidCallback? onTap;

  const _LevelCell({
    required this.levelNumber,
    required this.isUnlocked,
    required this.isCompleted,
    required this.isCurrentLevel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color shadowColor;
    Color textColor;

    if (isCurrentLevel) {
      bgColor = AppColors.surface;
      borderColor = AppColors.accent;
      shadowColor = AppColors.accentDark;
      textColor = AppColors.accent;
    } else if (isCompleted) {
      bgColor = AppColors.accent;
      borderColor = AppColors.accent;
      shadowColor = AppColors.accentDark;
      textColor = const Color(0xFF101114);
    } else if (isUnlocked) {
      bgColor = AppColors.surface;
      borderColor = AppColors.surfaceLight;
      shadowColor = const Color(0xFF1B1C20);
      textColor = AppColors.textPrimary;
    } else {
      bgColor = AppColors.background;
      borderColor = Colors.transparent;
      shadowColor = Colors.transparent;
      textColor = AppColors.textMuted;
    }

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          AudioHapticHelper.playClick();
          onTap!();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: isUnlocked ? Border.all(color: borderColor, width: 1.5) : null,
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: shadowColor,
                    offset: const Offset(0, 3),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isUnlocked)
              const Icon(Icons.lock_outline_rounded,
                  color: AppColors.textMuted, size: 20)
            else
              Text(
                '$levelNumber',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}