import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.outfit().fontFamily,
      scaffoldBackgroundColor: AppConstants.background,
      primaryColor: AppConstants.primaryNeon,
      colorScheme: const ColorScheme.dark(
        primary: AppConstants.primaryNeon,
        secondary: AppConstants.purpleNeon,
        surface: AppConstants.surface,
        error: AppConstants.errorNeon,
      ),
      cardTheme: CardThemeData(
        color: AppConstants.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppConstants.border, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      useMaterial3: true,
    );
  }
}
