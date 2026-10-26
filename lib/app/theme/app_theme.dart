import 'package:flutter/material.dart';

class EcoRouteTheme {
  EcoRouteTheme._();

  static const green = Color(0xFF2E7D32);
  static const darkGreen = Color(0xFF1B5E20);
  static const lightBg = Color(0xFFF7FAF5);
  static const darkBg = Color(0xFF111E14);
  static const darkSurface = Color(0xFF192A1D);

  static ThemeData build({Brightness brightness = Brightness.light}) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? darkBg : lightBg;
    final surface = isDark ? darkSurface : Colors.white;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: green,
        primary: green,
        secondary: darkGreen,
        brightness: brightness,
        surface: surface,
      ),
      scaffoldBackgroundColor: bg,
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: const Color(0xFFDCEFE0),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: green);
          }
          return const IconThemeData(color: Color(0xFF647568));
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: green,
        unselectedItemColor: Color(0xFF647568),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF123B1A),
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? const Color(0xFF2A3F2F) : const Color(0xFFE2EAE1),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF2E4633) : const Color(0xFFDCE8DB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: green, width: 2),
        ),
      ),
    );
  }

  static ThemeData buildDark() => build(brightness: Brightness.dark);
}
