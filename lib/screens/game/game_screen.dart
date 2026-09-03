import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_colors.dart';
import '../../core/app_themes.dart';
import '../../core/constants.dart';
import '../../core/audio_haptic_helper.dart';
import '../../core/game_mode.dart';
import '../../data/models/arrow.dart';
import '../../data/models/level.dart';
import '../../data/models/level_result.dart';
import '../../data/repositories/progress_repository.dart';
import '../../game/arrow_puzzle_game.dart';
import '../../game/game_state.dart';
import '../../widgets/lives_bar.dart';
import '../../main.dart';
import '../home/home_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  final int level;
  final bool isRandom;
  final GameMode gameMode;

  const GameScreen({
    super.key,
    required this.level,
    this.isRandom = false,
    this.gameMode = GameMode.classic,
  });

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with WidgetsBindingObserver {
  late LevelModel _level;
  late ArrowPuzzleGame _game;
  GameState? _gameState;
  bool _showingGameOver = false;
  bool _showingComplete = false;
  int _lives = AppConstants.maxLives;
  int? _loadedLevelNum;
  bool _isLoadingLevel = false;

  Timer? _levelTimer;
  int _timeRemaining = 0;
  int _totalTime = 0;
  bool _isTimeoutState = false;
  bool _isAppBackgrounded = false;

  int _timeAttackScore = 0;
  bool _showBonusAnimation = false;
  String _bonusText = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final levelNum = widget.level;
    if (_loadedLevelNum != levelNum) {
      _loadedLevelNum = levelNum;
      _loadLevelAsync(levelNum);
    }
  }

  Future<void> _loadLevelAsync(int levelNum) async {
    final levelRepo = ref.read(levelRepositoryProvider);

    if (levelRepo.isCached(levelNum)) {
      _level = levelRepo.getLevel(levelNum);
      _initGame();

      if (!widget.isRandom) {
        levelRepo.preGenerateRangeAsync(levelNum + 1, 5);
      }
      return;
    }

    if (mounted) setState(() => _isLoadingLevel = true);

    try {
      final level = await levelRepo.getLevelAsync(levelNum, preGenerateNext: !widget.isRandom);
      if (!mounted) return;
      _level = level;
      _initGame();
      setState(() => _isLoadingLevel = false);

      if (!widget.isRandom) {
        levelRepo.preGenerateRangeAsync(levelNum + 1, 5);
      }
    } catch (_) {
      if (!mounted) return;
      _level = levelRepo.getLevel(levelNum);
      _initGame();
      if (mounted) setState(() => _isLoadingLevel = false);
    }
  }

  double _shakeOffset = 0.0;
  Timer? _shakeTimer;
  
  String? _comboText;
  Timer? _comboTimer;

  final List<_Particle> _particles = [];

  void _triggerShake() {
    _shakeTimer?.cancel();
    int count = 0;
    _shakeTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      count++;
      if (count > 6) {
        timer.cancel();
        if (mounted) setState(() => _shakeOffset = 0.0);
      } else {
        if (mounted) {
          setState(() {
            _shakeOffset = (count % 2 == 0 ? 8.0 : -8.0);
          });
        }
      }
    });
  }

  void _triggerCombo() {
    if (_gameState == null) return;
    final combo = _gameState!.comboCount;
    _comboTimer?.cancel();
    setState(() {
      _comboText = '$combo x COMBO';
    });
    _comboTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _comboText = null);
    });
  }

  void _addParticleBurst(Offset offset, Color color) {
    if (!mounted) return;
    final random = Random();
    final newParticles = List.generate(18, (i) {
      final angle = random.nextDouble() * 2 * pi;
      final speed = 70.0 + random.nextDouble() * 150.0;
      return _Particle(
        position: offset,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        color: color,
        maxLife: 0.35 + random.nextDouble() * 0.25,
      );
    });
    setState(() {
      _particles.addAll(newParticles);
    });
  }

  void _triggerTimeAttackBonusAnimation() {
    setState(() {
      _bonusText = '+15s';
      _showBonusAnimation = true;
    });
    Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _showBonusAnimation = false;
        });
      }
    });
  }

  void _goToNextLevelInPlace() {
    final nextLevel = _level.levelNumber + 1;
    setState(() {
      _showingComplete = false;
      _showingGameOver = false;
      _loadedLevelNum = nextLevel;
    });
    _loadLevelAsync(nextLevel);
  }

  void _initGame() {
    final progress = ref.read(progressRepositoryProvider);
    final isLifeFree = widget.gameMode == GameMode.zen || progress.heartRemover;
    _lives = isLifeFree ? 999 : AppConstants.maxLives;
    _showingGameOver = false;
    _gameState?.removeListener(_onGameStateChanged);
    _gameState = GameState(
      level: _level,
      theme: progress.selectedTheme,
      heartRemover: progress.heartRemover,
      onLevelComplete: _onLevelComplete,
      onGameOver: isLifeFree ? () {} : _onGameOver,
      onLifeLost: isLifeFree ? () {} : _onLifeLost,
      gameMode: widget.gameMode,
      onCombo: _triggerCombo,
      onCameraShake: _triggerShake,
      onParticleBurst: _addParticleBurst,
    );
    _gameState!.addListener(_onGameStateChanged);

    _game = ArrowPuzzleGame(
      level: _level,
      gameState: _gameState!,
      onLevelComplete: _onLevelComplete,
      onGameOver: isLifeFree ? () {} : _onGameOver,
      onLifeLost: isLifeFree ? () {} : _onLifeLost,
    );

    _resetTimerForLevel();
  }

  void _onGameStateChanged() {
    if (!mounted) return;
    setState(() {
      _lives = _gameState!.lives;
    });
  }

  void _onLifeLost() {
    if (!mounted) return;
    setState(() => _lives = _gameState!.lives);
  }

  void _onLevelComplete() {
    if (!mounted || _showingComplete) return;
    _levelTimer?.cancel();
    AudioHapticHelper.playSuccess(isLast: true);
    setState(() => _showingComplete = true);

    final progress = ref.read(progressRepositoryProvider);
    final stars = ProgressRepository.calculateStars(_gameState!.livesLost);

    if (!widget.isRandom && widget.gameMode == GameMode.classic) {
      progress.recordLevelComplete(LevelResult(
        levelNumber: _level.levelNumber,
        stars: stars,
        livesLost: _gameState!.livesLost,
        completed: true,
        completedAt: DateTime.now(),
      ));
    }

    if (widget.gameMode == GameMode.timeAttack) {
      setState(() {
        _timeRemaining = (_timeRemaining + 15).clamp(0, 99);
        _timeAttackScore++;
      });
      _triggerTimeAttackBonusAnimation();
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _goToNextLevelInPlace();
        }
      });
    } else if (widget.gameMode == GameMode.zen) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _goToNextLevelInPlace();
        }
      });
    } else {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _showLevelCompleteDialog(stars);
        }
      });
    }
  }

  void _onGameOver() {
    if (!mounted || _showingGameOver) return;
    setState(() => _showingGameOver = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _showGameOverDialog();
    });
  }

  Future<void> _handleRestart() async {
    if (mounted) {
      final isLifeFree = widget.gameMode == GameMode.zen ||
          ref.read(progressRepositoryProvider).heartRemover;
      setState(() {
        _showingGameOver = false;
        _showingComplete = false;
        _game.resetLevel();
        _lives = isLifeFree ? 999 : AppConstants.maxLives;
        _resetTimerForLevel();
      });
    }
  }

  Future<bool> _confirmLeaveLevel() async {
    if (_showingComplete || _showingGameOver) return true;
    final progress = ref.read(progressRepositoryProvider);
    final themeColors = AppThemes.getThemeColors(progress.selectedTheme);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: themeColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: themeColors.accentColor.withValues(alpha: 0.35),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: themeColors.accentColor.withValues(alpha: 0.18),
                blurRadius: 32,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.exit_to_app_rounded,
                color: themeColors.accentColor,
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'Leave Level?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your current level progress will be lost.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              _DialogButton(
                label: 'Resume',
                icon: Icons.play_arrow_rounded,
                textColor: AppColors.textPrimary,
                iconColor: themeColors.accentColor,
                onTap: () => Navigator.pop(ctx, false),
              ),
              const SizedBox(height: 10),
              _DialogButton(
                label: 'Leave',
                icon: Icons.close_rounded,
                textColor: AppColors.textSecondary,
                iconColor: themeColors.accentColor,
                onTap: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  Future<void> _handleBack() async {
    final shouldLeave = await _confirmLeaveLevel();
    if (!shouldLeave || !mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  void _handleNextLevel() {
    Navigator.pop(context);
    _goToNextLevelInPlace();
  }

  void _handleMenu() {
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _showLevelCompleteDialog(int stars) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Stack(
        children: [
          _LevelCompleteDialog(
            level: _level,
            stars: stars,
            isRandom: widget.isRandom,
            onNextLevel: _handleNextLevel,
            onMenu: _handleMenu,
          ),
        ],
      ),
    );
  }

  Future<void> _handleTimeAttackRestart() async {
    setState(() {
      _showingGameOver = false;
      _showingComplete = false;
      _timeRemaining = 60;
      _timeAttackScore = 0;
      _loadedLevelNum = 1;
    });
    _loadLevelAsync(1);
  }

  Future<void> _showGameOverDialog() async {
    final levelType = AppConstants.levelTypeFor(_level.levelNumber);
    final hasTimer = (levelType == LevelType.god && _level.levelNumber > 100) ||
        (levelType == LevelType.boss && _level.levelNumber > 200);

    int continueTime = 0;
    if (hasTimer && _gameState != null) {
      final remainingArrows =
          _gameState!.arrows.where((a) => a.state != ArrowState.sliding).length;
      continueTime =
          _calculateContinueDuration(_level.levelNumber, remainingArrows);
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GameOverDialog(
        level: _level,
        isTimeout: _isTimeoutState,
        continueTime: continueTime,
        gameMode: widget.gameMode,
        score: _timeAttackScore,
        onContinue: () {
          Navigator.pop(context);
          setState(() {
            _showingGameOver = false;
            if (_isTimeoutState) {
              _timeRemaining = continueTime;
              _isTimeoutState = false;
              _gameState!.resumeFromTimeout();
              _startLevelTimer();
            } else {
              _gameState!.restoreLife();
              _lives = _gameState!.lives;
            }
          });
        },
        onRestart: () {
          Navigator.pop(context);
          if (widget.gameMode == GameMode.timeAttack) {
            _handleTimeAttackRestart();
          } else {
            _handleRestart();
          }
        },
        onMenu: () {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _levelTimer?.cancel();
    _gameState?.removeListener(_onGameStateChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _isAppBackgrounded = true;
    } else if (state == AppLifecycleState.resumed) {
      _isAppBackgrounded = false;
    }
  }

  int _calculateLevelTimerDuration(int levelNum, int totalArrows) {
    final type = AppConstants.levelTypeFor(levelNum);
    if (type == LevelType.god && levelNum > 100) {
      final baseSeconds =
          (45.0 - (levelNum - 100) * (20.0 / 400.0)).clamp(25.0, 45.0);
      final secondsPerArrow =
          (2.5 - (levelNum - 100) * (1.0 / 400.0)).clamp(1.5, 2.5);
      return (baseSeconds + secondsPerArrow * totalArrows).round();
    } else if (type == LevelType.boss && levelNum > 200) {
      final baseSeconds =
          (40.0 - (levelNum - 200) * (20.0 / 300.0)).clamp(20.0, 40.0);
      final secondsPerArrow =
          (2.2 - (levelNum - 200) * (0.8 / 300.0)).clamp(1.4, 2.2);
      return (baseSeconds + secondsPerArrow * totalArrows).round();
    }
    return 0;
  }

  int _calculateContinueDuration(int levelNum, int remainingArrows) {
    final type = AppConstants.levelTypeFor(levelNum);
    if (type == LevelType.god) {
      final secondsPerArrow =
          (2.2 - (levelNum - 100) * (0.7 / 400.0)).clamp(1.5, 2.2);
      return (20.0 + secondsPerArrow * remainingArrows).round();
    } else if (type == LevelType.boss) {
      final secondsPerArrow =
          (2.0 - (levelNum - 200) * (0.6 / 300.0)).clamp(1.4, 2.0);
      return (15.0 + secondsPerArrow * remainingArrows).round();
    }
    return 45;
  }

  void _resetTimerForLevel() {
    _levelTimer?.cancel();
    _isTimeoutState = false;

    if (widget.gameMode == GameMode.timeAttack) {
      if (_timeRemaining <= 0) {
        _timeRemaining = 60;
      }
      _totalTime = 99;
      _startLevelTimer();
    } else if (widget.gameMode == GameMode.classic) {
      final levelType = AppConstants.levelTypeFor(_level.levelNumber);
      final hasTimer = (levelType == LevelType.god && _level.levelNumber > 100) ||
          (levelType == LevelType.boss && _level.levelNumber > 200);

      if (hasTimer) {
        _totalTime = _calculateLevelTimerDuration(
            _level.levelNumber, _level.arrows.length);
        _timeRemaining = _totalTime;
        _startLevelTimer();
      } else {
        _totalTime = 0;
        _timeRemaining = 0;
      }
    } else {
      _totalTime = 0;
      _timeRemaining = 0;
    }
  }

  void _startLevelTimer() {
    _levelTimer?.cancel();
    _levelTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_showingComplete ||
          _showingGameOver ||
          _isLoadingLevel ||
          !_isLevelReady ||
          _isAppBackgrounded) {
        return;
      }

      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
          if (_timeRemaining == 0) {
            timer.cancel();
            _onTimeOut();
          }
        }
      });
    });
  }

  void _onTimeOut() {
    if (!mounted || _showingGameOver) return;
    setState(() {
      _isTimeoutState = true;
    });
    _gameState?.forceGameOver();
  }

  @override
  Widget build(BuildContext context) {
    final progressState = ref.watch(progressRepositoryProvider);
    final themeColors = AppThemes.getThemeColors(progressState.selectedTheme);

    if (_isLoadingLevel || !_isLevelReady) {
      return _LevelLoadingScreen(themeColors: themeColors);
    }

    final totalArrows = _level.arrows.length;
    final activeArrows =
        _gameState?.arrows.where((a) => a.state != ArrowState.sliding).length ??
            totalArrows;
    final clearedArrows = totalArrows - activeArrows;
    final progressVal =
        totalArrows > 0 ? (clearedArrows / totalArrows).clamp(0.0, 1.0) : 0.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: themeColors.bgGradient),
          child: SafeArea(
            child: Column(
              children: [
                _TopBar(
                  level: _level,
                  isRandom: widget.isRandom,
                  onBack: _handleBack,
                  gameMode: widget.gameMode,
                  score: _timeAttackScore,
                ),
              if (_totalTime > 0 || widget.gameMode == GameMode.timeAttack)
                RepaintBoundary(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _TimerDisplay(
                      timeRemaining: _timeRemaining,
                      totalTime: widget.gameMode == GameMode.timeAttack ? 99 : _totalTime,
                    ),
                  ),
                ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final boardSize =
                        min(constraints.maxWidth, constraints.maxHeight - 16);
                    return Transform.translate(
                      offset: Offset(_shakeOffset, 0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          RepaintBoundary(
                            child: InteractiveViewer(
                              minScale: 0.8,
                              maxScale: 4.0,
                              boundaryMargin: const EdgeInsets.all(60),
                              clipBehavior: Clip.hardEdge,
                              child: Center(
                                child: SizedBox(
                                  width: boardSize,
                                  height: boardSize,
                                  child: GameWidget(game: _game),
                                ),
                              ),
                            ),
                          ),
                          if (_comboText != null)
                            Positioned(
                              top: 20,
                              child: RepaintBoundary(
                                child: Text(
                                  _comboText!,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                    letterSpacing: 1.5,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black87,
                                        blurRadius: 12,
                                        offset: Offset(0, 2),
                                      ),
                                      Shadow(
                                        color: AppColors.primary,
                                        blurRadius: 16,
                                      ),
                                    ],
                                  ),
                                )
                                    .animate()
                                    .scale(
                                        begin: const Offset(0.5, 0.5),
                                        end: const Offset(1.15, 1.15),
                                        duration: 200.ms,
                                        curve: Curves.elasticOut)
                                    .then()
                                    .scale(
                                        begin: const Offset(1.15, 1.15),
                                        end: const Offset(1.0, 1.0),
                                        duration: 100.ms),
                              ),
                            ),
                          if (_showBonusAnimation)
                            Positioned(
                              top: 60,
                              child: Text(
                                _bonusText,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.orangeAccent,
                                  letterSpacing: 1.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black87,
                                      blurRadius: 12,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 200.ms)
                                  .slideY(
                                      begin: 0.5,
                                      end: -0.2,
                                      duration: 600.ms,
                                      curve: Curves.easeOut)
                                  .fadeOut(delay: 500.ms, duration: 300.ms),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              _BottomBar(
                lives: _lives,
                progress: progressVal,
                gameMode: widget.gameMode,
                heartRemover: progressState.heartRemover,
              ),
            ],
          ),
        ),
      ),
    ));
  }

  bool get _isLevelReady => _gameState != null;
}

class _TimerDisplay extends ConsumerWidget {
  final int timeRemaining;
  final int totalTime;

  const _TimerDisplay({
    required this.timeRemaining,
    required this.totalTime,
  });

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = (timeRemaining / totalTime).clamp(0.0, 1.0);
    final isLowTime = timeRemaining <= 15 || timeRemaining <= totalTime * 0.15;
    
    final progressState = ref.watch(progressRepositoryProvider);
    final themeColors = AppThemes.getThemeColors(progressState.selectedTheme);
    final color = isLowTime ? const Color(0xFF808080) : themeColors.accentColor;

    Widget content = Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLowTime ? const Color(0xFF808080) : AppColors.surfaceLight,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isLowTime ? 0.3 : 0.1),
            blurRadius: isLowTime ? 8 : 4,
            spreadRadius: isLowTime ? 1 : 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hourglass_top,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                _formatTime(timeRemaining),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 3,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.surfaceLight.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );

    if (isLowTime) {
      content = content
          .animate(
            onPlay: (controller) => controller.repeat(reverse: true),
          )
          .scaleXY(
              begin: 0.96,
              end: 1.04,
              duration: 400.ms,
              curve: Curves.easeInOut);
    }

    return content;
  }
}

class _TopBar extends StatelessWidget {
  final LevelModel level;
  final bool isRandom;
  final VoidCallback onBack;
  final GameMode gameMode;
  final int score;

  const _TopBar({
    required this.level,
    this.isRandom = false,
    required this.onBack,
    required this.gameMode,
    this.score = 0,
  });

  @override
  Widget build(BuildContext context) {
    String titleText;
    if (gameMode == GameMode.timeAttack) {
      titleText = 'Score: $score';
    } else if (gameMode == GameMode.zen) {
      titleText = gameMode.label;
    } else if (isRandom) {
      titleText = 'Random Mode';
    } else {
      titleText = 'Level ${level.levelNumber}';
    }

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: onBack,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.arrow_back,
                    color: AppColors.textPrimary, size: 22),
              ),
            ),
          ),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titleText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int lives;
  final double progress;
  final GameMode gameMode;
  final bool heartRemover;

  const _BottomBar({
    required this.lives,
    required this.progress,
    required this.gameMode,
    this.heartRemover = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 130,
            height: 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.surfaceLight,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
          if (heartRemover || gameMode == GameMode.timeAttack)
            const SizedBox()
          else if (gameMode == GameMode.zen)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.white, Color(0xFFB0B0B0)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  '∞',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            )
          else
            LivesBar(lives: lives, maxLives: AppConstants.maxLives),
        ],
      ),
    );
  }
}

class _LevelCompleteDialog extends ConsumerWidget {
  final LevelModel level;
  final int stars;
  final bool isRandom;
  final VoidCallback onNextLevel;
  final VoidCallback onMenu;

  const _LevelCompleteDialog({
    required this.level,
    required this.stars,
    this.isRandom = false,
    required this.onNextLevel,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressRepositoryProvider);
    final themeColors = AppThemes.getThemeColors(progress.selectedTheme);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: themeColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
              color: themeColors.accentColor.withValues(alpha: 0.35),
              width: 2.5),
          boxShadow: [
            BoxShadow(
                color: themeColors.accentColor.withValues(alpha: 0.18),
                blurRadius: 32),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Level Complete!',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  3,
                  (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          i < stars
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: i < stars
                              ? themeColors.accentColor
                              : themeColors.surface.withValues(alpha: 0.6),
                          size: 38,
                        ),
                      )
                          .animate(delay: Duration(milliseconds: 200 + i * 150))
                          .scale(
                              begin: const Offset(0, 0),
                              end: const Offset(1, 1),
                              curve: Curves.elasticOut)),
            ),
            const SizedBox(height: 24),
            if (level.levelNumber == 500) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: themeColors.accentColor,
                      size: 32,
                    ).animate(onPlay: (c) => c.repeat()).scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1.1, 1.1),
                        duration: 1.seconds,
                        curve: Curves.easeInOut),
                    const SizedBox(height: 10),
                    const Text(
                      'You Finished the Game!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Congratulations! You\'ve solved all 500 challenges. Stay tuned for more levels coming soon!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ] else if (!isRandom) ...[
              _DialogButton(
                label: 'Next Level',
                icon: Icons.play_arrow_rounded,
                onTap: onNextLevel,
              ),
              const SizedBox(height: 10),
            ],
            _DialogButton(
              label: 'Home',
              icon: Icons.home_rounded,
              textColor: AppColors.textPrimary,
              iconColor: themeColors.accentColor,
              onTap: onMenu,
            ),
            const SizedBox(height: 10),
            _DialogButton(
              label: 'Buy me a coffee',
              icon: Icons.coffee_rounded,
              textColor: AppColors.textPrimary,
              iconColor: themeColors.accentColor,
              onTap: () async {
                final uri = Uri.parse('https://ko-fi.com/sidhant947');
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (_) {}
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GameOverDialog extends ConsumerWidget {
  final LevelModel level;
  final bool isTimeout;
  final int continueTime;
  final VoidCallback onContinue;
  final VoidCallback onRestart;
  final VoidCallback onMenu;
  final GameMode gameMode;
  final int score;

  const _GameOverDialog({
    required this.level,
    this.isTimeout = false,
    this.continueTime = 0,
    required this.onContinue,
    required this.onRestart,
    required this.onMenu,
    this.gameMode = GameMode.classic,
    this.score = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTimeAttack = gameMode == GameMode.timeAttack;
    final progress = ref.watch(progressRepositoryProvider);
    final themeColors = AppThemes.getThemeColors(progress.selectedTheme);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: themeColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
              color: themeColors.accentColor.withValues(alpha: 0.35),
              width: 2.5),
          boxShadow: [
            BoxShadow(
                color: themeColors.accentColor.withValues(alpha: 0.18),
                blurRadius: 32),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isTimeAttack
                  ? Icons.timer_off_rounded
                  : (isTimeout ? Icons.hourglass_top : Icons.heart_broken),
              color:
                  isTimeAttack ? Colors.orangeAccent : themeColors.accentColor,
              size: 52,
            ).animate().shake(duration: 500.ms),
            const SizedBox(height: 12),
            Text(
              isTimeAttack
                  ? "Time's Up!"
                  : (isTimeout ? 'Out of Time!' : 'Out of Lives!'),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            if (isTimeAttack) ...[
              const SizedBox(height: 8),
              Text(
                'Puzzles Cleared: $score\nFinal Level: ${level.levelNumber}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 20),
            _DialogButton(
              label: isTimeAttack ? 'Start New Run' : 'Restart Level',
              icon: Icons.refresh_rounded,
              textColor: AppColors.textPrimary,
              iconColor: themeColors.accentColor,
              onTap: onRestart,
            ),
            const SizedBox(height: 10),
            _DialogButton(
              label: 'Home',
              icon: Icons.home_rounded,
              textColor: AppColors.textSecondary,
              iconColor: themeColors.accentColor,
              onTap: onMenu,
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogButton extends ConsumerWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color textColor;
  final Color iconColor;

  const _DialogButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.textColor = Colors.white,
    this.iconColor = Colors.white,
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: themeColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: themeColors.accentColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: themeColors.accentDark,
              offset: const Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: iconColor == Colors.white
                      ? themeColors.accentColor
                      : iconColor,
                  size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoaderAnimation extends StatefulWidget {
  final Color color;
  const _LoaderAnimation({required this.color});

  @override
  State<_LoaderAnimation> createState() => _LoaderAnimationState();
}

class _LoaderAnimationState extends State<_LoaderAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _LoaderPainter(
              progress: _controller.value,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _LoaderPainter extends CustomPainter {
  final double progress;
  final Color color;

  _LoaderPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 6) / 2;

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(center, radius, bgPaint);

    final startAngle = progress * 2 * pi;
    const sweepAngle = pi * 0.75;

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LoaderPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _LevelLoadingScreen extends StatelessWidget {
  final ThemeColors themeColors;
  const _LevelLoadingScreen({required this.themeColors});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: themeColors.bgGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LoaderAnimation(color: themeColors.accentColor),
              const SizedBox(height: 24),
              Text(
                'LOADING LEVEL...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Particle {
  Offset position;
  Offset velocity;
  Color color;
  double maxLife;
  double life = 0.0;

  _Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.maxLife,
  });
}
