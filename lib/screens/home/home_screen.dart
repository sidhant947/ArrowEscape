import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_themes.dart';
import '../../core/audio_haptic_helper.dart';
import '../../core/game_mode.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../game/game_screen.dart';
import '../level_select/level_select_screen.dart';
import '../how_to_play/how_to_play_screen.dart';
import '../multiplayer/multiplayer_seed_screen.dart';
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

  void _showRandomPuzzleDialog() {
    final progress = ref.read(progressRepositoryProvider);
    final themeColors = AppThemes.getThemeColors(progress.selectedTheme);
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: themeColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: themeColors.accentColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.randomPuzzleTitle,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: themeColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.randomPuzzleSubtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: themeColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                _DifficultyButton(
                  label: l10n.difficultyEasy,
                  icon: Icons.bolt,
                  onTap: () => _playRandom('easy'),
                ),
                const SizedBox(height: 10),
                _DifficultyButton(
                  label: l10n.difficultyMedium,
                  icon: Icons.speed,
                  onTap: () => _playRandom('medium'),
                ),
                const SizedBox(height: 10),
                _DifficultyButton(
                  label: l10n.difficultyHard,
                  icon: Icons.local_fire_department,
                  onTap: () => _playRandom('hard'),
                ),
                const SizedBox(height: 10),
                _DifficultyButton(
                  label: l10n.difficultyMaster,
                  icon: Icons.psychology,
                  onTap: () => _playRandom('master'),
                ),
                const SizedBox(height: 10),
                _DifficultyButton(
                  label: l10n.difficultyExpert,
                  icon: Icons.military_tech,
                  onTap: () => _playRandom('expert'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    l10n.dialogCancel,
                    style: TextStyle(
                      color: themeColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _playRandom(String difficulty) async {
    Navigator.pop(context);
    if (!mounted) return;
    setState(() => _isNavigating = true);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            GameScreen(level: 0, isRandom: true, randomDifficulty: difficulty),
      ),
    );
    if (mounted) setState(() => _isNavigating = false);
  }

  void _showModesSelection(BuildContext context, int currentLevel) {
    final progress = ref.read(progressRepositoryProvider);
    final themeColors = AppThemes.getThemeColors(progress.selectedTheme);
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: themeColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: themeColors.surfaceLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.modesTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: themeColors.textPrimary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                ...[
                  (
                    label: l10n.modeLevelsTitle,
                    description: l10n.modeLevelsDesc,
                    icon: Icons.grid_view_rounded,
                    color: Colors.amberAccent,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LevelSelectScreen(),
                        ),
                      );
                    },
                  ),
                  (
                    label: l10n.modeZenTitle,
                    description: l10n.modeZenDesc,
                    icon: Icons.spa,
                    color: Colors.greenAccent,
                    onTap: () async {
                      Navigator.pop(ctx);
                      if (!mounted) return;
                      setState(() => _isNavigating = true);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GameScreen(
                            level: currentLevel,
                            gameMode: GameMode.zen,
                          ),
                        ),
                      );
                      if (mounted) setState(() => _isNavigating = false);
                    },
                  ),
                  (
                    label: l10n.modeTimeAttackTitle,
                    description: l10n.modeTimeAttackDesc,
                    icon: Icons.timer,
                    color: Colors.orangeAccent,
                    onTap: () async {
                      Navigator.pop(ctx);
                      if (!mounted) return;
                      setState(() => _isNavigating = true);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GameScreen(
                            level: 1,
                            gameMode: GameMode.timeAttack,
                          ),
                        ),
                      );
                      if (mounted) setState(() => _isNavigating = false);
                    },
                  ),
                  (
                    label: l10n.modeMultiplayerTitle,
                    description: l10n.modeMultiplayerDesc,
                    icon: Icons.groups_rounded,
                    color: Colors.cyanAccent,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MultiplayerSeedScreen(),
                        ),
                      );
                    },
                  ),
                ].map(
                  (item) => GestureDetector(
                    onTap: item.onTap,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: themeColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: themeColors.isLight
                              ? themeColors.surfaceLight
                              : Colors.white10,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(item.icon, color: item.color, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: themeColors.textPrimary,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: themeColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: themeColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressRepositoryProvider);
    final themeColors = AppThemes.getThemeColors(progress.selectedTheme);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _AppBarIconButton(
                  icon: Icons.star_rounded,
                  iconColor: const Color(0xFFFFD700),
                  themeColors: themeColors,
                  onTap: () async {
                    try {
                      await launchUrl(
                        Uri.parse('https://github.com/sidhant947/ArrowEscape'),
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (_) {}
                  },
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flag_rounded,
                        color: themeColors.accentColor,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.levelHeader(progress.currentLevel),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: themeColors.textPrimary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                _AppBarIconButton(
                      icon: Icons.favorite_rounded,
                      iconColor: const Color(0xFFFF4D6D),
                      themeColors: themeColors,
                      onTap: () async {
                        try {
                          await launchUrl(
                            Uri.parse('https://ko-fi.com/sidhant947'),
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (_) {}
                      },
                    )
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .scaleXY(
                      begin: 0.95,
                      end: 1.06,
                      duration: 900.ms,
                      curve: Curves.easeInOut,
                    ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: themeColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              Icon(Icons.arrow_upward, size: 48, color: themeColors.textPrimary)
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .slideY(
                    begin: 0,
                    end: -0.15,
                    duration: 1500.ms,
                    curve: Curves.easeInOut,
                  )
                  .then()
                  .shimmer(duration: 1000.ms),

              const SizedBox(height: 20),

              FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      l10n.appTitle,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: themeColors.textPrimary,
                        letterSpacing: 2,
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 800.ms)
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.0, 1.0),
                    curve: Curves.easeOutBack,
                  ),

              const SizedBox(height: 12),

              Text(
                    l10n.appTagline,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: themeColors.textMuted,
                      letterSpacing: 2,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 600.ms)
                  .slideY(begin: 0.5, end: 0),

              const Spacer(flex: 3),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _MenuButton(
                      label: l10n.menuPlay,
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
                              if (mounted) {
                                setState(() => _isNavigating = false);
                              }
                            },
                      showBorder: false,
                    ),

                    const SizedBox(height: 10),

                    _MenuButton(
                      label: l10n.menuRandom,
                      onTap: _isNavigating ? null : _showRandomPuzzleDialog,
                    ),

                    const SizedBox(height: 10),

                    _MenuButton(
                      label: l10n.menuGameModes,
                      onTap: _isNavigating
                          ? null
                          : () => _showModesSelection(
                              context,
                              progress.currentLevel,
                            ),
                    ),

                    const SizedBox(height: 10),

                    _MenuButton(
                      label: l10n.menuHowToPlay,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HowToPlayScreen(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    _MenuButton(
                      label: l10n.menuSettings,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ),
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
        padding: const EdgeInsets.symmetric(vertical: 15),
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
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: themeColors.textPrimary,
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
          color: themeColors.surface,
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: themeColors.textPrimary,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final ThemeColors themeColors;
  final VoidCallback onTap;

  const _AppBarIconButton({
    required this.icon,
    required this.iconColor,
    required this.themeColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AudioHapticHelper.playClick();
        onTap();
      },
      child: Center(child: Icon(icon, color: iconColor, size: 22)),
    );
  }
}
