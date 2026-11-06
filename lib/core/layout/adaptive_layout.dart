import 'package:flutter/material.dart';

/// Global Viewport Breakpoints & Responsive Grid Control
/// SMARTPHONES: < 600px
/// TABLETS: 600px - 1024px
/// DESKTOPS: > 1024px
class ViewportBreakpoints {
  ViewportBreakpoints._();

  static const double mobileMax = 599.9;
  static const double tabletMin = 600.0;
  static const double tabletMax = 1024.0;
  static const double desktopMin = 1024.1;
  static const double sidebarWidth = 280.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < tabletMin;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= tabletMin && width <= tabletMax;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width > tabletMax;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletMin;
}

/// System Theme Matrix (Adaptive Dark/Light Logic)
/// LIGHT MODE:
///   - Surface: #F8F9FA
///   - Layout Card: #FFFFFF
///   - Text Primary: #1A1A1A
///   - Eco Accent: #2E7D32
/// DARK MODE:
///   - Surface: #121212
///   - Layout Card: #1E1E1E
///   - Text Primary: #E0E0E0
///   - Eco Accent: #4CAF50
class AntigravityTheme {
  AntigravityTheme._();

  // Light Mode Tokens
  static const Color lightSurface = Color(0xFFF8F9FA);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF555555);
  static const Color lightEcoAccent = Color(0xFF2E7D32);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Dark Mode Tokens
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFFA0A0A0);
  static const Color darkEcoAccent = Color(0xFF4CAF50);
  static const Color darkBorder = Color(0xFF2A2A2A);

  // Context-aware token accessors
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color surface(BuildContext context) =>
      isDark(context) ? darkSurface : lightSurface;

  static Color card(BuildContext context) =>
      isDark(context) ? darkCard : lightCard;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? darkTextPrimary : lightTextPrimary;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? darkTextSecondary : lightTextSecondary;

  static Color ecoAccent(BuildContext context) =>
      isDark(context) ? darkEcoAccent : lightEcoAccent;

  static Color border(BuildContext context) =>
      isDark(context) ? darkBorder : lightBorder;

  static ThemeData buildTheme({required bool isDarkMode}) {
    final bg = isDarkMode ? darkSurface : lightSurface;
    final cardBg = isDarkMode ? darkCard : lightCard;
    final text = isDarkMode ? darkTextPrimary : lightTextPrimary;
    final accent = isDarkMode ? darkEcoAccent : lightEcoAccent;

    return ThemeData(
      useMaterial3: true,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bg,
      cardColor: cardBg,
      primaryColor: accent,
      colorScheme: ColorScheme(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        primary: accent,
        onPrimary: Colors.white,
        secondary: accent,
        onSecondary: Colors.white,
        error: const Color(0xFFE53935),
        onError: Colors.white,
        surface: cardBg,
        onSurface: text,
      ),
      fontFamily: 'Satoshi',
      textTheme: TextTheme(
        headlineLarge: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 28),
        headlineMedium: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 22),
        titleLarge: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 18),
        titleMedium: TextStyle(color: text, fontWeight: FontWeight.w600, fontSize: 15),
        bodyLarge: TextStyle(color: text, fontSize: 14),
        bodyMedium: TextStyle(color: isDarkMode ? darkTextSecondary : lightTextSecondary, fontSize: 13),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: text),
        titleTextStyle: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }
}
