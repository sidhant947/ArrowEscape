import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_themes.dart';
import '../../core/constants.dart';
import '../../core/audio_haptic_helper.dart';
import '../../core/game_mode.dart';
import '../../main.dart';
import '../game/game_screen.dart';
import '../level_select/level_select_screen.dart';
import '../settings/settings_screen.dart';

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

  void _showArcadeModesSelection(BuildContext context, int currentLevel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'ARCADE MODES',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              ...[GameMode.zen, GameMode.timeAttack].map((mode) {
                IconData icon;
                Color color;
                switch (mode) {
                  case GameMode.zen:
                    icon = Icons.spa;
                    color = Colors.greenAccent;
                    break;
                  case GameMode.timeAttack:
                    icon = Icons.timer;
                    color = Colors.orangeAccent;
                    break;
                  default:
                    icon = Icons.play_arrow;
                    color = AppColors.primary;
                }

                return GestureDetector(
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (!mounted) return;
                    setState(() => _isNavigating = true);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GameScreen(
                          level: mode == GameMode.timeAttack ? 1 : currentLevel,
                          gameMode: mode,
                        ),
                      ),
                    );
                    if (mounted) setState(() => _isNavigating = false);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mode.label.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                mode.description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressRepositoryProvider);
    final themeColors = AppThemes.getThemeColors(progress.selectedTheme);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        leadingWidth: 110,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () async {
              try {
                await launchUrl(Uri.parse('https://github.com/sidhant947/ArrowEscape'), mode: LaunchMode.externalApplication);
              } catch (_) {}
            },
            child: Container(
              margin: const EdgeInsets.only(left: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.yellow, size: 18),
                  SizedBox(width: 4),
                  Text(
                    'Github',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
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
              onTap: () async {
                try {
                  await launchUrl(Uri.parse('https://liberapay.com/sidhant947'), mode: LaunchMode.externalApplication);
                } catch (_) {}
              },
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite, color: Colors.pink, size: 18),
                    SizedBox(width: 4),
                    Text(
                      'Support',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: themeColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              Icon(
                Icons.arrow_upward,
                size: 48,
                color: AppColors.textPrimary,
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .slideY(begin: 0, end: -0.15, duration: 1500.ms, curve: Curves.easeInOut)
               .then()
               .shimmer(duration: 1000.ms),

              const SizedBox(height: 20),

              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  AppConstants.appName,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: 2,
                  ),
                ),
              ).animate()
               .fadeIn(duration: 800.ms)
               .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0), curve: Curves.easeOutBack),

              const SizedBox(height: 12),

              const Text(
                'Slide. Solve. Escape.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                  letterSpacing: 2,
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 600.ms).slideY(begin: 0.5, end: 0),

              const Spacer(flex: 3),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: AnimateList(
                    interval: 100.ms,
                    effects: [
                      FadeEffect(duration: 500.ms),
                      SlideEffect(begin: const Offset(0, 0.2), end: Offset.zero, curve: Curves.easeOutQuad),
                    ],
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
                                    builder: (_) => GameScreen(
                                      level: progress.currentLevel,
                                      gameMode: GameMode.classic,
                                    ),
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
                        label: 'ARCADE MODES',
                        onTap: _isNavigating
                            ? null
                            : () => _showArcadeModesSelection(context, progress.currentLevel),
                      ),

                      const SizedBox(height: 14),

                      _MenuButton(
                        label: 'RANDOM',
                        onTap: _isNavigating ? null : _showRandomPuzzleDialog,
                      ),

                      const SizedBox(height: 14),

                      _MenuButton(
                        label: 'SETTINGS',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        ),
                      ),
                    ],
                  ),
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

class _MenuButton extends ConsumerWidget {
  final String label;
  final VoidCallback? onTap;
  final bool showBorder;

  const _MenuButton({
    required this.label,
    required this.onTap,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressRepositoryProvider);
    final themeColors = AppThemes.getThemeColors(progress.selectedTheme);

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          AudioHapticHelper.playClick();
          onTap!();
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: themeColors.accentColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: themeColors.accentDark,
              offset: const Offset(0, 5),
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

class _DifficultyButton extends ConsumerWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _DifficultyButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressRepositoryProvider);
    final themeColors = AppThemes.getThemeColors(progress.selectedTheme);

    return GestureDetector(
      onTap: () {
        AudioHapticHelper.playClick();
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: themeColors.accentColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: themeColors.accentDark,
              offset: const Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: themeColors.accentColor, size: 20),
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