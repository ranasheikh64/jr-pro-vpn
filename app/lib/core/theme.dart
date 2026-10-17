import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      fontFamily: GoogleFonts.poppins().fontFamily,
      scaffoldBackgroundColor: AppConstants.scaffoldWhite,
      primaryColor: AppConstants.goldPrimary,
      colorScheme: const ColorScheme.light(
        primary: AppConstants.goldPrimary,
        secondary: AppConstants.goldDark,
        surface: AppConstants.scaffoldWhite,
        error: AppConstants.statusRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme => lightTheme;
}
