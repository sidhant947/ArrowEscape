import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF161719);
  static const Color surface = Color(0xFF222428);
  static const Color surfaceLight = Color(0xFF2E3137);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textMuted = Color(0xFF6E727A);

  static const Color primary = Color(0xFF76ED12);
  static const Color accent = Color(0xFF76ED12);
  static const Color accentDark = Color(0xFF5CB80D);
  static const Color accentOrange = Color(0xFFFF9800);

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF1C1D21), Color(0xFF121315)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}