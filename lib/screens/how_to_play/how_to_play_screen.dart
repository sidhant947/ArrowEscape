import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_colors.dart';
import '../../core/app_themes.dart';
import '../../main.dart';

class HowToPlayScreen extends ConsumerWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressRepositoryProvider);
    final themeColors = AppThemes.getThemeColors(progress.selectedTheme);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'HOW TO PLAY',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: themeColors.bgGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              _buildSectionHeader('THE BASICS'),
              const SizedBox(height: 12),
              _buildGuideCard(
                themeColors: themeColors,
                icon: Icons.flag_rounded,
                iconColor: themeColors.accentColor,
                title: 'Core Objective',
                description:
                    'Your goal is to clear the entire puzzle grid by guiding every arrow off the board. When no arrows remain on the board, the level is complete.',
              ),
              const SizedBox(height: 12),
              _buildGuideCard(
                themeColors: themeColors,
                icon: Icons.navigation_rounded,
                iconColor: Colors.blueAccent,
                title: 'Arrow Movement',
                description:
                    'Tap any arrow to launch it. Arrows slide forward in the exact direction their arrowhead points: Up, Down, Left, or Right. Even if an arrow has a bent or winding body, it always exits following its tip.',
              ),
              const SizedBox(height: 12),
              _buildGuideCard(
                themeColors: themeColors,
                icon: Icons.block_rounded,
                iconColor: Colors.redAccent,
                title: 'Obstacles & Collisions',
                description:
                    'An arrow can only escape if its entire exit path is completely clear. If another arrow stands in the way, the tapped arrow will shake and stay in place.',
              ),
              const SizedBox(height: 12),
              _buildGuideCard(
                themeColors: themeColors,
                icon: Icons.favorite_rounded,
                iconColor: const Color(0xFFFF4D6D),
                title: 'Lives & Health',
                description:
                    'In Classic mode, you start with 3 hearts. Tapping a blocked arrow costs 1 heart. If you deplete all 3 hearts, you must restart the level. You can toggle Infinite Lives in Settings anytime.',
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('BOARD ELEMENTS'),
              const SizedBox(height: 12),
              _buildGuideCard(
                themeColors: themeColors,
                icon: Icons.change_circle_rounded,
                iconColor: Colors.amberAccent,
                title: 'Turn Dots (Redirectors)',
                description:
                    'Look for circular dots on empty grid cells marked with small arrows. When a sliding arrow crosses a Turn Dot, it instantly pivots in the dot\'s direction and consumes it, opening unexpected exit routes.',
              ),
              const SizedBox(height: 12),
              _buildGuideCard(
                themeColors: themeColors,
                icon: Icons.bolt_rounded,
                iconColor: Colors.orangeAccent,
                title: 'Combos & Streaks',
                description:
                    'Release arrows in quick succession (within 1.5 seconds) to trigger combos. Chaining consecutive escapes builds momentum and scores combo multipliers.',
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('GAME MODES'),
              const SizedBox(height: 12),
              _buildGuideCard(
                themeColors: themeColors,
                icon: Icons.play_arrow_rounded,
                iconColor: AppColors.primary,
                title: 'Classic Mode',
                description:
                    'The standard campaign progression. Advance through handcrafted and procedural stages of escalating size, shape masks, and path complexity with 3 hearts.',
              ),
              const SizedBox(height: 12),
              _buildGuideCard(
                themeColors: themeColors,
                icon: Icons.spa_rounded,
                iconColor: Colors.greenAccent,
                title: 'Zen Mode',
                description:
                    'Pure relaxation with zero stress. No hearts to lose, no time limits, and no failure states. Ideal for unwinding and practicing complex boards.',
              ),
              const SizedBox(height: 12),
              _buildGuideCard(
                themeColors: themeColors,
                icon: Icons.timer_rounded,
                iconColor: Colors.orangeAccent,
                title: 'Time Attack',
                description:
                    'Fast-paced race against the clock! Every arrow you successfully escape awards precious bonus seconds back onto your countdown timer.',
              ),
              const SizedBox(height: 12),
              _buildGuideCard(
                themeColors: themeColors,
                icon: Icons.groups_rounded,
                iconColor: Colors.cyanAccent,
                title: 'Multiplayer Rooms',
                description:
                    'Host or join with room seed codes. Both players compete on the exact same randomized layout to see who can solve and escape the board fastest.',
              ),
              const SizedBox(height: 12),
              _buildGuideCard(
                themeColors: themeColors,
                icon: Icons.casino_rounded,
                iconColor: Colors.purpleAccent,
                title: 'Random Puzzles',
                description:
                    'Generate infinite on-demand puzzles across Easy, Medium, Hard, Master, and Expert difficulties without affecting your campaign level progress.',
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('PRO STRATEGIES'),
              const SizedBox(height: 12),
              _buildGuideCard(
                themeColors: themeColors,
                icon: Icons.lightbulb_rounded,
                iconColor: const Color(0xFFFFD700),
                title: 'Unpeel From the Perimeter',
                description:
                    'Start by scanning the outer borders. Arrows pointing straight outward into empty space can always escape immediately, freeing up critical lanes.',
              ),
              const SizedBox(height: 12),
              _buildGuideCard(
                themeColors: themeColors,
                icon: Icons.account_tree_rounded,
                iconColor: Colors.tealAccent,
                title: 'Trace Blockers in Reverse',
                description:
                    'When an arrow is blocked, find which arrow blocks it, then find what blocks that second arrow. Unlocking the final blocker in the chain frees everything behind it.',
              ),
              const SizedBox(height: 12),
              _buildGuideCard(
                themeColors: themeColors,
                icon: Icons.touch_app_rounded,
                iconColor: Colors.pinkAccent,
                title: 'Enable Tap Assist',
                description:
                    'If you play on smaller screens or tend to tap between tight arrow segments, turn on Tap Assist in Settings to automatically map nearby taps to the nearest arrow.',
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppColors.textSecondary,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildGuideCard({
    required ThemeColors themeColors,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeColors.accentColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: themeColors.accentDark.withValues(alpha: 0.25),
            offset: const Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
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
