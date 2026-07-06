import 'package:flutter/material.dart';

/// Paleta de colores estricta de Queen Bodys Boutique
class AppColors {
  AppColors._();

  static const Color crimson = Color(0xFFC8005A); // Magenta/Crimson del logo
  static const Color gold = Color(0xFFD4AF37);    // Dorado
  static const Color white = Color(0xFFFFFFFF);   // Blanco puro
  static const Color textPrimary = Color(0xFF1A1A1A); // Gris muy oscuro/Negro
  static const Color textSecondary = Color(0xFF4A4A4A); // Gris medio
  static const Color textHint = Color(0xFF757575);      // Gris claro para hints
  static const Color borderLight = Color(0xFFE0E0E0); // Gris claro para bordes sutiles
  static const Color background = Color(0xFFFFFFFF);  // Mismo que white
  static const Color surfaceLight = Color(0xFFF5F5F5); // Gris muy tenue para placeholders
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'serif', // Fuente elegante (puedes cambiarla luego)
      scaffoldBackgroundColor: AppColors.white,
      colorScheme: const ColorScheme.light(
        primary: AppColors.crimson,
        secondary: AppColors.gold,
        surface: AppColors.white,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.crimson,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.crimson,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: AppColors.crimson),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.crimson,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.crimson,
          side: const BorderSide(color: AppColors.crimson, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.crimson, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textPrimary),
        prefixIconColor: AppColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
    );
  }
}
