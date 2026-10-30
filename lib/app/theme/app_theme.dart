import 'package:flutter/material.dart';

class EcoRouteTheme {
  EcoRouteTheme._();

  static const richJade = Color(0xFF72B08D);
  static const primaryInk = Color(0xFF0D2618);
  static const secondaryInk = Color(0xFF1A3A28);
  static const surfaceTint = Color(0x1F0D2618);
  static const terracottaAccent = Color(0xFF9C3D18);
  static const onlineGreen = Color(0xFF22C55E);

  // Backward-compatibility aliases
  static const green = primaryInk;
  static const darkGreen = primaryInk;
  static const lightBg = richJade;
  static const darkBg = Color(0xFF12281B);
  static const darkSurface = Color(0xFF162E20);

  static ThemeData build({Brightness brightness = Brightness.light}) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? darkBg : richJade;
    final primary = isDark ? Colors.white : primaryInk;
    final secondary = isDark ? const Color(0xFFC7E2D0) : secondaryInk;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Satoshi',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryInk,
        primary: primaryInk,
        secondary: terracottaAccent,
        brightness: brightness,
        surface: bg,
      ),
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      dividerColor: Colors.transparent,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bg,
        elevation: 0,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary);
          }
          return IconThemeData(color: secondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontFamily: 'Satoshi',
              color: primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            );
          }
          return TextStyle(
            fontFamily: 'Satoshi',
            color: secondary,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          );
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bg,
        elevation: 0,
        selectedItemColor: primary,
        unselectedItemColor: secondary,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Satoshi',
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Satoshi',
          fontWeight: FontWeight.w500,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: primary),
        actionsIconTheme: IconThemeData(color: primary),
        titleTextStyle: TextStyle(
          fontFamily: 'Satoshi',
          color: primary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide.none,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1D3B29) : const Color(0x1F0D2618),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF2E4633) : const Color(0x2E0D2618),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }

  static ThemeData buildDark() => build(brightness: Brightness.dark);
}
