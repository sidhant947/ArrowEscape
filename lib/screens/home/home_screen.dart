import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../main.dart';
import '../game/game_screen.dart';
import '../level_select/level_select_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _preWarmLevels();
    });
  }

  void _preWarmLevels() {
    final progress = ref.read(progressRepositoryProvider);
    final levelRepo = ref.read(levelRepositoryProvider);
    final currentLevel = progress.currentLevel;
    for (int i = 0; i < 4; i++) {
      levelRepo.preGenerateAsync(currentLevel + i);
    }
  }

  int _randomLevelForDifficulty(String difficulty) {
    final rng = Random();
    switch (difficulty) {
      case 'easy':
        return AppConstants.randomEasyMin +
            rng.nextInt(AppConstants.randomEasyMax - AppConstants.randomEasyMin + 1);
      case 'medium':
        return AppConstants.randomMediumMin +
            rng.nextInt(AppConstants.randomMediumMax - AppConstants.randomMediumMin + 1);
      case 'hard':
        return AppConstants.randomHardMin +
            rng.nextInt(AppConstants.randomHardMax - AppConstants.randomHardMin + 1);
      default:
        return 1;
    }
  }

  void _showRandomPuzzleDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Random Puzzle',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pick a difficulty',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              _DifficultyButton(
                label: 'Easy',
                icon: Icons.bolt,
                onTap: () => _playRandom('easy'),
              ),
              const SizedBox(height: 12),
              _DifficultyButton(
                label: 'Medium',
                icon: Icons.bolt,
                onTap: () => _playRandom('medium'),
              ),
              const SizedBox(height: 12),
              _DifficultyButton(
                label: 'Hard',
                icon: Icons.bolt,
                onTap: () => _playRandom('hard'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _playRandom(String difficulty) async {
    Navigator.pop(context); 
    final levelNum = _randomLevelForDifficulty(difficulty);
    if (!mounted) return;
    setState(() => _isNavigating = true);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(level: levelNum, isRandom: true),
      ),
    );
    if (mounted) setState(() => _isNavigating = false);
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressRepositoryProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () => launchUrl(Uri.parse('https://github.com/sidhant947/ArrowEscape')),
            child: Container(
              margin: const EdgeInsets.only(left: 16),
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.star, color: Colors.yellow, size: 22),
            ),
          ),
        ),
        centerTitle: true,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'LEVEL ${progress.currentLevel}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: 1,
            ),
          ),
        ),
        actions: [
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => launchUrl(Uri.parse('https://ko-fi.com/sidhant947')),
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.favorite, color: Colors.pink, size: 22),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              const Icon(
                Icons.arrow_upward,
                size: 48,
                color: AppColors.textPrimary,
              ),

              const SizedBox(height: 20),

              const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: 2,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Slide. Solve. Escape.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                  letterSpacing: 2,
                ),
              ),

              const Spacer(flex: 3),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    
                    _MenuButton(
                      label: 'PLAY',
                      onTap: _isNavigating
                          ? null
                          : () async {
                              if (!mounted) return;
                              setState(() => _isNavigating = true);
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GameScreen(level: progress.currentLevel),
                                ),
                              );
                              if (mounted) setState(() => _isNavigating = false);
                            },
                      showBorder: false,
                    ),

                    const SizedBox(height: 14),

                    _MenuButton(
                      label: 'LEVELS',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LevelSelectScreen()),
                      ),
                    ),

                    const SizedBox(height: 14),

                    _MenuButton(
                      label: 'RANDOM',
                      onTap: _isNavigating ? null : _showRandomPuzzleDialog,
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool showBorder;

  const _MenuButton({
    required this.label,
    required this.onTap,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.lightImpact();
          onTap!();
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: AppColors.accentDark,
              offset: Offset(0, 5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _DifficultyButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _DifficultyButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: AppColors.accentDark,
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.accent, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}