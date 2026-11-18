import 'package:flutter/material.dart';

class AppColors {
  static const scaffoldBackground = Color(0xFF09120F);
  static const surface = Color(0xFF111E1A);
  static const surfaceElevated = Color(0xFF162722);
  static const surfaceCard = Color(0xFF13221E);
  static const surfaceInput = Color(0xFF0E1A16);
  static const border = Color(0xFF1F352C);
  static const borderLight = Color(0xFF2C493D);
  static const accent = Color(0xFFFF5C00);
  static const accentLight = Color(0xFFFF7A29);
  static const accentDark = Color(0xFFE04F00);

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF7300), Color(0xFFFF4500)],
  );

  static const heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x0009120F),
      Color(0xCC09120F),
      Color(0xFF09120F),
    ],
  );

  static const amberBadgeBg = Color(0xFF352213);
  static const amberBadgeBorder = Color(0xFF784518);
  static const amberBadgeText = Color(0xFFFBAA52);

  static const textPrimary = Color(0xFFF1F5F2);
  static const textSecondary = Color(0xFF98AAA1);
  static const textMuted = Color(0xFF5A6E64);

  static const statusOnline = Color(0xFF34D399);
  static const statusOffline = Color(0xFFFF5C00);
}

ThemeData buildLumioTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.scaffoldBackground,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.accent,
    secondary: AppColors.accentLight,
    surface: AppColors.surface,
    onPrimary: Colors.white,
    onSurface: AppColors.textPrimary,
  ),
  fontFamily: 'Roboto',
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.scaffoldBackground,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
    centerTitle: true,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceInput,
    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
    ),
  ),
);
