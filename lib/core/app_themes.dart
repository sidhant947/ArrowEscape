import 'package:flutter/material.dart';

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
}

class ThemeColors {
  final Color background;
  final Color surface;
  final Color arrowColor;
  final Color accentColor;
  final Color accentDark;
  final LinearGradient bgGradient;
  final bool hasGlow;

  const ThemeColors({
    required this.background,
    required this.surface,
    required this.arrowColor,
    required this.accentColor,
    required this.accentDark,
    required this.bgGradient,
    this.hasGlow = false,
  });
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
    }
  }
}
