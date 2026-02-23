import 'package:flutter/material.dart';

class AppTheme {
  // ── Colors ─────────────────────────────────────────────────────────────
  static const Color background = Color(0xFF050505);
  static const Color cardColor = Color(0xFF121212);
  static const Color primaryColor = Color(0xFFf4879a); // Brand Pink
  static const Color secondaryColor = Color(0xFF00C853); // Success Green
  static const Color surface = Color(0xFF1C1C1E);
  static const Color surfaceVariant = Color(0xFF2C2C2E);
  static const Color outline = Color(0xFF3A3A3C);
  static const Color onBackground = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color errorColor = Color(0xFFFF6B6B);
  static const Color successColor = Color(0xFF00C853);
  static const Color warningColor = Color(0xFFFFA500);

  // ── Theme ──────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      // Core colors
      scaffoldBackgroundColor: background,
      cardColor: cardColor,
      primaryColor: primaryColor,
      
      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surface,
        error: errorColor,
        onBackground: onBackground,
        onSurface: onSurface,
      ),

      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: onBackground,
        elevation: 0,
        centerTitle: false,
      ),

      // TextField theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
        labelStyle: const TextStyle(color: onSurface),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        titleTextStyle: const TextStyle(
          color: onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(
          color: onSurface.withValues(alpha: 0.8),
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceVariant,
        contentTextStyle: const TextStyle(color: onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // FloatingActionButton theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Checkbox & Radio theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) =>
            states.contains(MaterialState.selected) ? primaryColor : surfaceVariant),
      ),

      // BottomSheet theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
    );
  }
}