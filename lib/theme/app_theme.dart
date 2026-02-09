import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF050505);
  static const Color cardColor = Color(0xFF121212);
  static const Color primaryColor = Color(0xFFf4879a); // Brand Pink
  static const Color secondaryColor = Color(0xFF00C853); // Success Green

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: background,
      cardColor: cardColor,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: cardColor,
      ),
    );
  }
}