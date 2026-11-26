import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_colors.dart';
import '../../core/app_themes.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

class HowToPlayScreen extends ConsumerWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressRepositoryProvider);
    final themeColors = AppThemes.getThemeColors(progress.selectedTheme);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.howToPlayTitle,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: themeColors.textPrimary,
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
              _buildSectionHeader(l10n.sectionTheBasics, themeColors),
              const SizedBox(height: 12),
              _buildGuideCard(
                themeColors: themeColors,
                icon: Icons.flag_rounded,
                iconColor: themeColors.accentColor,
                title: l10n.guideCoreObjectiveTitle,
                description: l10n.guideCoreObjectiveDesc,
              ),
              const SizedBox(height: 12),
              _buildGuideCard(
                themeColors: themeColors,
                icon: Icons.navigation_rounded,
                iconColor: Colors.blueAccent,
                title: l10n.guideMovementTitle,
                description: l10n.guideMovementDesc,
              ),
              const SizedBox(height: 12),
              _buildGuideCard(
                themeColors: themeColors,
                icon: Icons.block_rounded,
                iconColor: Colors.redAccent,
                title: l10n.guideObstaclesTitle,
                description: l10n.guideObstaclesDesc,
              ),
              const SizedBox(height: 12),
              _buildGuideCard(
                themeColors: themeColors,
                icon: Icons.favorite_rounded,
                iconColor: const Color(0xFFFF4D6D),
                title: l10n.guideLivesTitle,
                description: l10n.guideLivesDesc,
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(l10n.sectionBoardElements, themeColors),
              const SizedBox(height: 12),
              _buildGuideCard(
                themeColors: themeColors,
                icon: Icons.change_circle_rounded,
                iconColor: Colors.amberAccent,
                title: l10n.guideTurnDotsTitle,
                description: l10n.guideTurnDotsDesc,
              ),
              const SizedBox(height: 12),
              _buildGuideCard(
                themeColors: themeColors,
                icon: Icons.bolt_rounded,
                iconColor: Colors.orangeAccent,
                title: l10n.guideCombosTitle,
                description: l10n.guideCombosDesc,
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(l10n.sectionGameModes, themeColors),
              const SizedBox(height: 12),
              _buildGuideCard(
                themeColors: themeColors,
                icon: Icons.play_arrow_rounded,
                iconColor: AppColors.primary,
                title: l10n.guideClassicModeTitle,
                description: l10n.guideClassicModeDesc,
              ),
              const SizedBox(height: 12),
              _buildGuideCard(
                themeColors: themeColors,
                icon: Icons.spa_rounded,
                iconColor: Colors.greenAccent,
                title: l10n.guideZenModeTitle,
                description: l10n.guideZenModeDesc,
              ),
              const SizedBox(height: 12),
              _buildGuideCard(
                themeColors: themeColors,
                icon: Icons.timer_rounded,
                iconColor: Colors.orangeAccent,
                title: l10n.guideTimeAttackTitle,
                description: l10n.guideTimeAttackDesc,
              ),
              const SizedBox(height: 12),
              _buildGuideCard(
                themeColors: themeColors,
                icon: Icons.groups_rounded,
                iconColor: Colors.cyanAccent,
                title: l10n.guideMultiplayerTitle,
                description: l10n.guideMultiplayerDesc,
              ),
              const SizedBox(height: 12),
              _buildGuideCard(
                themeColors: themeColors,
                icon: Icons.casino_rounded,
                iconColor: Colors.purpleAccent,
                title: l10n.guideRandomPuzzlesTitle,
                description: l10n.guideRandomPuzzlesDesc,
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(l10n.sectionProStrategies, themeColors),
              const SizedBox(height: 12),
              _buildGuideCard(
                themeColors: themeColors,
                icon: Icons.lightbulb_rounded,
                iconColor: const Color(0xFFFFD700),
                title: l10n.guideUnpeelTitle,
                description: l10n.guideUnpeelDesc,
              ),
              const SizedBox(height: 12),
              _buildGuideCard(
                themeColors: themeColors,
                icon: Icons.account_tree_rounded,
                iconColor: Colors.tealAccent,
                title: l10n.guideTraceBlockersTitle,
                description: l10n.guideTraceBlockersDesc,
              ),
              const SizedBox(height: 12),
              _buildGuideCard(
                themeColors: themeColors,
                icon: Icons.touch_app_rounded,
                iconColor: Colors.pinkAccent,
                title: l10n.guideEnableTapAssistTitle,
                description: l10n.guideEnableTapAssistDesc,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeColors themeColors) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: themeColors.textSecondary,
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
        color: themeColors.surface,
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: themeColors.textPrimary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: themeColors.textSecondary,
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
