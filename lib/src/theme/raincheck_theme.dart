import 'package:flutter/material.dart';

final class RainCheckColors {
  static const sky = Color(0xFF2397D8);
  static const deepSky = Color(0xFF0E6EA6);
  static const cloud = Color(0xFFF7FAFC);
  static const ink = Color(0xFF153246);
  static const mutedInk = Color(0xFF5C7486);
  static const warning = Color(0xFF4B5FA7);
  static const warningDeep = Color(0xFF37447D);
  static const sun = Color(0xFFFFD166);
  static const success = Color(0xFF2E9D73);
  static const surface = Color(0xFFFFFFFF);
}

final class RainCheckSpacing {
  static const xs = 6.0;
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

final class RainCheckRadii {
  static const card = 8.0;
  static const control = 12.0;
  static const pill = 999.0;
}

ThemeData buildRainCheckTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: RainCheckColors.sky,
    brightness: Brightness.light,
    primary: RainCheckColors.deepSky,
    secondary: RainCheckColors.success,
    surface: RainCheckColors.surface,
    error: const Color(0xFFB84747),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: RainCheckColors.cloud,
    fontFamily: 'Arial',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 42,
        height: 1,
        fontWeight: FontWeight.w800,
        color: RainCheckColors.ink,
      ),
      headlineMedium: TextStyle(
        fontSize: 30,
        height: 1.08,
        fontWeight: FontWeight.w800,
        color: RainCheckColors.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: RainCheckColors.ink,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: RainCheckColors.ink,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.45,
        color: RainCheckColors.ink,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.4,
        color: RainCheckColors.mutedInk,
      ),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RainCheckRadii.control),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      color: RainCheckColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RainCheckRadii.card),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RainCheckRadii.control),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RainCheckRadii.control),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
  );
}
