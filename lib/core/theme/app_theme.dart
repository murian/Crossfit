import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern 2025 design system with yellow and black color scheme
/// Designed to be bold but not tiring for the eyes
class AppTheme {
  // Primary Colors - Yellow variations for different contexts
  static const Color primaryYellow = Color(0xFFFFC107); // Warm yellow
  static const Color accentYellow = Color(0xFFFFD54F); // Lighter yellow for accents
  static const Color darkYellow = Color(0xFFFFA000); // Darker yellow for emphasis

  // Dark Theme Colors - Blacks and grays
  static const Color deepBlack = Color(0xFF0A0A0A); // Almost pure black
  static const Color surfaceBlack = Color(0xFF141414); // Card/surface background
  static const Color containerBlack = Color(0xFF1E1E1E); // Container background
  static const Color borderGray = Color(0xFF2A2A2A); // Subtle borders

  // Accent Colors for variety (not tiring)
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFEF5350);
  static const Color infoBlue = Color(0xFF42A5F5);
  static const Color warningOrange = Color(0xFFFF9800);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textTertiary = Color(0xFF707070);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: primaryYellow,
        secondary: accentYellow,
        surface: surfaceBlack,
        background: deepBlack,
        error: errorRed,
        onPrimary: deepBlack,
        onSecondary: deepBlack,
        onSurface: textPrimary,
        onBackground: textPrimary,
      ),

      scaffoldBackgroundColor: deepBlack,

      // Typography - Modern, clean fonts
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.25),
          displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: textPrimary),
          displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: textPrimary),
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary),
          headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary),
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: textPrimary),
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
          titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: textPrimary),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: textSecondary),
          bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: textTertiary),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
          labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
          labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary),
        ),
      ),

      // App Bar Theme - Clean and modern
      appBarTheme: AppBarTheme(
        backgroundColor: deepBlack,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: primaryYellow),
      ),

      // Card Theme - Modern glass-morphism inspired
      cardTheme: CardTheme(
        color: surfaceBlack,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderGray, width: 1),
        ),
      ),

      // Elevated Button - Bold and modern
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryYellow,
          foregroundColor: deepBlack,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryYellow,
          side: const BorderSide(color: primaryYellow, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration - Clean and minimal
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: containerBlack,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryYellow, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: textTertiary),
        labelStyle: const TextStyle(color: textSecondary),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceBlack,
        selectedItemColor: primaryYellow,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryYellow,
        foregroundColor: deepBlack,
        elevation: 4,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: borderGray,
        thickness: 1,
      ),
    );
  }

  static ThemeData get lightTheme {
    // Light theme (optional, keeping dark as primary)
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: darkYellow,
        secondary: primaryYellow,
        surface: Colors.white,
        background: Color(0xFFFAFAFA),
      ),
      textTheme: GoogleFonts.interTextTheme(),
    );
  }
}
