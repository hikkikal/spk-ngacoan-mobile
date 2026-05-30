import 'package:flutter/material.dart';

class AppTheme {
  // Colors — disesuaikan dengan logo Ngacoan (oranye + hitam)
  static const Color primary = Color(0xFFE8500A);        // Oranye Ngacoan
  static const Color primaryDark = Color(0xFFC94008);    // Oranye gelap
  static const Color accent = Color(0xFF1A1A1A);         // Hitam aksen
  static const Color background = Color(0xFFF8F9FA);     // Abu sangat terang
  static const Color surface = Color(0xFFFFFFFF);        // Putih
  static const Color error = Color(0xFFEF4444);          // Merah error
  static const Color textPrimary = Color(0xFF1A1A1A);    // Hitam teks
  static const Color textSecondary = Color(0xFF6B7280);  // Abu teks
  static const Color divider = Color(0xFFE5E7EB);        // Abu divider

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: surface,
        error: error,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}