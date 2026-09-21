import 'package:flutter/material.dart';

class LumiAppTheme {
  LumiAppTheme._();

  static const _primary = Color(0xFF9C27B0);
  static const _secondary = Color(0xFFE040FB);
  static const _darkBackground = Color(0xFF080D2B);
  static const _darkSurface = Color(0xFF17123A);
  static const _lightBackground = Color(0xFFF8F5FC);
  static const _lightSurface = Colors.white;

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: _secondary,
      onPrimary: Colors.white,
      secondary: _primary,
      onSecondary: Colors.white,
      surface: _darkSurface,
      onSurface: Colors.white,
      error: Color(0xFFFF6B81),
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: _darkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkBackground,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: _darkSurface,
      border: OutlineInputBorder(),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: _darkSurface,
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFF33285D)),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: _darkSurface,
      indicatorColor: Color(0xFF342263),
    ),
    cardTheme: const CardThemeData(
      color: _darkSurface,
      surfaceTintColor: Colors.transparent,
    ),
  );

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF7B1FA2),
      onPrimary: Colors.white,
      secondary: _primary,
      onSecondary: Colors.white,
      surface: _lightSurface,
      onSurface: Color(0xFF251A2E),
      error: Color(0xFFB3261E),
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: _lightBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: _lightBackground,
      foregroundColor: Color(0xFF251A2E),
      elevation: 0,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: _lightSurface,
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFD8C9E2)),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: _lightSurface,
      indicatorColor: Color(0xFFE9D5F2),
    ),
    cardTheme: const CardThemeData(
      color: _lightSurface,
      surfaceTintColor: Colors.transparent,
    ),
  );

    static Color pageBackground(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

    static Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

    static Color surfaceVariant(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;

    static Color primaryText(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

    static Color secondaryText(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

    static Color outline(BuildContext context) =>
      Theme.of(context).colorScheme.outline;

    static Color accent(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

    static LinearGradient pageGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
        ? const [Color(0xFF0F1D8A), Color(0xFF16003A), Color(0xFF080010)]
        : const [Color(0xFFF8F5FC), Color(0xFFF0E4F8), Color(0xFFF8F5FC)],
    );
    }
}