import 'package:flutter/material.dart';

class AppTheme {
  // Paleta extraída del diseño de Figma
  static const Color darkBackground = Color(0xFF16101E);
  static const Color darkSurface = Color(0xFF241838);
  static const Color darkCard = Color(0xFF2E184D);
  static const Color primaryPurple = Color(0xFF4F378B);
  static const Color lavenderBanner = Color(0xFFE8DEF8);
  static const Color lavenderText = Color(0xFFD0BCFF);
  static const Color accentLilac = Color(0xFF7953AC);
  static const Color searchBarBg = Color(0xFF261D33);
  static const Color textMuted = Color(0xFFCAC4D0);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: lavenderText,
        secondary: primaryPurple,
        surface: darkSurface,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: searchBarBg,
        hintStyle: const TextStyle(color: textMuted, fontSize: 15),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }
}
