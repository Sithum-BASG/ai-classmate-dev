import 'package:flutter/material.dart';

class AppTheme {
  // Color tokens
  static const Color brandPrimary = Color(0xFF2563EB);
  static const Color brandSecondary = Color(0xFF10B981);
  static const Color brandSurface = Color(0xFFF7F8FA);
  static const Color brandText = Color(0xFF0F172A);
  static const Color subtleBorder = Color(0xFFE5E7EB);
  static const Color backgroundGrey = Color(0xFF404040);
  static const Color mutedText = Color(0xFF6B7280);
  static const Color lightBlueBackground = Color(0xFFE0F2FE);
  static const Color lightGreenBackground = Color(0xFFD1FAE5);
  static const Color brandPrimaryDark = Color(0xFF1976D2);
  static const Color brandSecondaryDark = Color(0xFF388E3C);
  static const Color borderSubtle = Color(0xFFE0E0E0);

  // Spacing tokens
  static const double baseHorizontalPadding = 16.0;
  static const double verticalRhythm = 12.0;
  static const double largeSpacing = 24.0;
  static const double extraLargeSpacing = 32.0;

  // Corner radii
  static const double primaryCardRadius = 16.0;
  static const double containerRadius = 28.0;
  static const double iconContainerRadius = 12.0;

  // Component sizes
  static const double minTapTarget = 48.0;
  static const double iconCircleSize = 84.0;
  static const double adminButtonSize = 48.0;
  static const double roleCardIconSize = 48.0;

  // Typography
  static const TextStyle headlineStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: Color(0xFF0F172A), // brandText
    height: 1.2,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Color(0xFF6B7280), // mutedText
    height: 1.5,
  );

  static const TextStyle cardTitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Color(0xFF0F172A), // brandText
    height: 1.3,
  );

  static const TextStyle cardSubtitleStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Color(0xFF6B7280), // mutedText
    height: 1.4,
  );

  static const TextStyle footerStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Color(0xFF6B7280), // mutedText
    height: 1.4,
  );

  static ThemeData lightTheme = ThemeData(
    primaryColor: brandPrimary,
    scaffoldBackgroundColor: backgroundGrey,
    colorScheme: const ColorScheme.light(
      primary: brandPrimary,
      secondary: brandSecondary,
      surface: Colors.white,
    ),
    fontFamily: 'Roboto',
    useMaterial3: true,
  );

  // Helper function to check if device is tablet
  static bool isTablet(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide >= 600;
  }

  // Responsive spacing
  static double getHorizontalPadding(BuildContext context) {
    return isTablet(context) ? 32.0 : baseHorizontalPadding;
  }

  static double getContentMaxWidth(BuildContext context) {
    return isTablet(context) ? 600.0 : double.infinity;
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      primaryColor: brandPrimary,
      scaffoldBackgroundColor: brandSurface,
      colorScheme: const ColorScheme.light(
        primary: brandPrimary,
        secondary: brandSecondary,
        surface: Colors.white,
        error: Color(0xFFEF4444),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: brandText,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            fontSize: 28, fontWeight: FontWeight.w700, color: brandText),
        headlineMedium: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w600, color: brandText),
        headlineSmall: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w600, color: brandText),
        titleLarge: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: brandText),
        titleMedium: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w500, color: brandText),
        titleSmall: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: brandText),
        bodyLarge: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w400, color: brandText),
        bodyMedium: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w400, color: brandText),
        bodySmall: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w400, color: brandText),
        labelLarge: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: brandText),
        labelMedium: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, color: brandText),
        labelSmall: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w500, color: brandText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: brandPrimary, width: 2),
        ),
      ),
    );
  }
}

class AppBreakpoints {
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= 600;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= 900;
  }
}