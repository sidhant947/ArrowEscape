import 'package:material_ui/material_ui.dart';

enum GameTheme {
  neon,
  classic,
  retro,
  cyber,
  hacker,
  aurora,
  blueprint,
  forest,
  pastel,
  sunset,
  rainbow,
  paper,
  rainbowLight,
  blueprintLight,
}

class ThemeColors {
  final Color background;
  final Color surface;
  final Color arrowColor;
  final Color accentColor;
  final Color accentDark;
  final LinearGradient bgGradient;
  final bool hasGlow;
  final List<Color>? arrowPalette;

  const ThemeColors({
    required this.background,
    required this.surface,
    required this.arrowColor,
    required this.accentColor,
    required this.accentDark,
    required this.bgGradient,
    this.hasGlow = false,
    this.arrowPalette,
  });

  bool get isLight => background.computeLuminance() > 0.5;

  Color get textPrimary => isLight ? const Color(0xFF1E232A) : Colors.white;
  Color get textSecondary => isLight ? const Color(0xFF5F6876) : const Color(0xFF9E9E9E);
  Color get textMuted => isLight ? const Color(0xFF8C95A3) : const Color(0xFF6E727A);
  Color get surfaceLight => isLight ? const Color(0xFFE2E6EC) : const Color(0xFF2E3137);
}

class AppThemes {
  static ThemeColors getThemeColors(GameTheme theme) {
    switch (theme) {
      case GameTheme.neon:
        return const ThemeColors(
          background: Color(0xFF0F0C20),
          surface: Color(0xFF1A1635),
          arrowColor: Color(0xFF00FFCC),
          accentColor: Color(0xFF00FFCC),
          accentDark: Color(0xFF009977),
          bgGradient: LinearGradient(
            colors: [Color(0xFF1A0B2E), Color(0xFF0A0518)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          hasGlow: true,
        );
      case GameTheme.classic:
        return const ThemeColors(
          background: Color(0xFF161719),
          surface: Color(0xFF222428),
          arrowColor: Colors.white,
          accentColor: Color(0xFF76ED12),
          accentDark: Color(0xFF5CB80D),
          bgGradient: LinearGradient(
            colors: [Color(0xFF1C1D21), Color(0xFF121315)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          hasGlow: false,
        );
      case GameTheme.retro:
        return const ThemeColors(
          background: Color(0xFF2D1600),
          surface: Color(0xFF472D11),
          arrowColor: Color(0xFFFFB300),
          accentColor: Color(0xFFFF5252),
          accentDark: Color(0xFFB71C1C),
          bgGradient: LinearGradient(
            colors: [Color(0xFF3E2723), Color(0xFF1B0000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          hasGlow: false,
        );
      case GameTheme.cyber:
        return const ThemeColors(
          background: Color(0xFF0D0211),
          surface: Color(0xFF1D062C),
          arrowColor: Color(0xFFFF007F),
          accentColor: Color(0xFF9D00FF),
          accentDark: Color(0xFF6B00B3),
          bgGradient: LinearGradient(
            colors: [Color(0xFF14011F), Color(0xFF05000A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          hasGlow: true,
        );
      case GameTheme.hacker:
        return const ThemeColors(
          background: Color(0xFF020A02),
          surface: Color(0xFF051A05),
          arrowColor: Color(0xFF39FF14),
          accentColor: Color(0xFF39FF14),
          accentDark: Color(0xFF1F8B0B),
          bgGradient: LinearGradient(
            colors: [Color(0xFF041404), Color(0xFF010501)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          hasGlow: true,
        );
      case GameTheme.aurora:
        return const ThemeColors(
          background: Color(0xFF05161A),
          surface: Color(0xFF072A30),
          arrowColor: Color(0xFF00FFCC),
          accentColor: Color(0xFF0DF2B8),
          accentDark: Color(0xFF078061),
          bgGradient: LinearGradient(
            colors: [Color(0xFF082024), Color(0xFF020B0C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          hasGlow: true,
        );
      case GameTheme.blueprint:
        return const ThemeColors(
          background: Color(0xFF0A2540),
          surface: Color(0xFF10365C),
          arrowColor: Colors.white,
          accentColor: Color(0xFF63B3ED),
          accentDark: Color(0xFF3182CE),
          bgGradient: LinearGradient(
            colors: [Color(0xFF0A2E5C), Color(0xFF05172E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          hasGlow: false,
        );
      case GameTheme.forest:
        return const ThemeColors(
          background: Color(0xFF131A13),
          surface: Color(0xFF223022),
          arrowColor: Color(0xFF8FBC8F),
          accentColor: Color(0xFF556B2F),
          accentDark: Color(0xFF36451E),
          bgGradient: LinearGradient(
            colors: [Color(0xFF182218), Color(0xFF0B0F0B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          hasGlow: false,
        );
      case GameTheme.pastel:
        return const ThemeColors(
          background: Color(0xFF1C1B2E),
          surface: Color(0xFF2B2A44),
          arrowColor: Color(0xFFFFB7C5),
          accentColor: Color(0xFFE6E6FA),
          accentDark: Color(0xFFB5B5E6),
          bgGradient: LinearGradient(
            colors: [Color(0xFF24223A), Color(0xFF131220)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          hasGlow: false,
        );
      case GameTheme.sunset:
        return const ThemeColors(
          background: Color(0xFF140D1C),
          surface: Color(0xFF2C1E3C),
          arrowColor: Color(0xFFFFC107),
          accentColor: Color(0xFFFF5722),
          accentDark: Color(0xFFD01C00),
          bgGradient: LinearGradient(
            colors: [Color(0xFF1C0D26), Color(0xFF0D0612)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          hasGlow: true,
        );
      case GameTheme.rainbow:
        return const ThemeColors(
          background: Color(0xFF12141C),
          surface: Color(0xFF1E2130),
          arrowColor: Color(0xFFFF4081),
          accentColor: Color(0xFF00E5FF),
          accentDark: Color(0xFF00B0FF),
          bgGradient: LinearGradient(
            colors: [Color(0xFF191C2B), Color(0xFF0F1017)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          hasGlow: true,
          arrowPalette: [
            Color(0xFFFF5252), // Red
            Color(0xFFFF9100), // Orange
            Color(0xFFFFEA00), // Yellow
            Color(0xFF00E676), // Green
            Color(0xFF00E5FF), // Cyan
            Color(0xFF7C4DFF), // Purple
            Color(0xFFFF4081), // Pink
          ],
        );
      case GameTheme.paper:
        return const ThemeColors(
          background: Color(0xFFF6F7F9),
          surface: Color(0xFFFFFFFF),
          arrowColor: Color(0xFF1E232A),
          accentColor: Color(0xFF2563EB),
          accentDark: Color(0xFF1D4ED8),
          bgGradient: LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFE8ECF2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          hasGlow: false,
        );
      case GameTheme.rainbowLight:
        return const ThemeColors(
          background: Color(0xFFF7F8FA),
          surface: Color(0xFFFFFFFF),
          arrowColor: Color(0xFFD32F2F),
          accentColor: Color(0xFF0288D1),
          accentDark: Color(0xFF01579B),
          bgGradient: LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFE8ECF2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          hasGlow: false,
          arrowPalette: [
            Color(0xFFD32F2F),
            Color(0xFFE65100),
            Color(0xFFF57F17),
            Color(0xFF2E7D32),
            Color(0xFF0288D1),
            Color(0xFF6A1B9A),
            Color(0xFFC2185B),
          ],
        );
      case GameTheme.blueprintLight:
        return const ThemeColors(
          background: Color(0xFFF0F7FF),
          surface: Color(0xFFFFFFFF),
          arrowColor: Color(0xFF0F3663),
          accentColor: Color(0xFF0284C7),
          accentDark: Color(0xFF0369A1),
          bgGradient: LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFE0EFFE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          hasGlow: false,
        );
    }
  }
}
