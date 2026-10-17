import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Jronix Pro VPN';
  static const String appTagline = 'Your Digital Shield · by Jronix';
  static const String companyName = 'Jronix - Software Solutions';
  static const String appVersion = '1.0.0';

  // Default Node.js API endpoint (Hosted or local)
  // For Android emulator: 10.0.2.2:3000, for physical devices: your machine IP or VPS IP
  static const String defaultApiUrl = 'http://35.223.35.45:3000';

  // Fallback Google Cloud VPS WireGuard configuration
  static const String fallbackServerHost = '35.223.35.45';
  static const int fallbackServerPort = 51820;
  static const String fallbackServerPublicKey =
      'NFwVhrxOOqz74MEaZ79rJ+a7hOwqc8YuQnsMOuNsJ20=';
  static const String fallbackDns = '1.1.1.1, 8.8.8.8';

  // Colors
  static const Color background = Color(0xFF0D0F18);
  static const Color surface = Color(0xFF161A26);
  static const Color surfaceLight = Color(0xFF1E2333);
  static const Color cardBg = Color(0xFF181D2D);
  static const Color border = Color(0xFF272F45);

  // Vibrant Accents
  static const Color primaryNeon = Color(0xFF00F0FF); // Cyber Cyan
  static const Color successNeon = Color(0xFF00FF87); // Matrix Green
  static const Color warningNeon = Color(0xFFFFB800); // Amber Yellow
  static const Color errorNeon = Color(0xFFFF3366); // Neon Red
  static const Color purpleNeon = Color(0xFF8B5CF6); // Electric Purple

  // Luxury Golden Theme (Figma design adapted)
  static const Color goldPrimary = Color(0xFFF59E0B);
  static const Color goldDark = Color(0xFFD97706);
  static const Color goldLight = Color(0xFFFDE68A);
  static const Color goldDeep = Color(0xFF92400E);
  static const Color goldAccent = Color(0xFFEAB308);
  static const Color goldGlow = Color(0xFFFFB703);

  // Clean Light UI Palette (matching Figma 1:2 & 6:175)
  static const Color scaffoldWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textBody = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textSubtle = Color(0xFFAAAAAA);
  static const Color dividerGray = Color(0xFFE5E7EB);
  static const Color statusGreen = Color(0xFF10B981);
  static const Color statusRed = Color(0xFFEF4444);

  // Gradients
  static const LinearGradient goldConnectedGradient = LinearGradient(
    colors: [
      Color(0xFFFBBF24), // radiant amber gold
      Color(0xFFF59E0B), // rich warm gold
      Color(0xFFD97706), // deep golden amber
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient goldDisconnectedGradient = LinearGradient(
    colors: [
      Color(0xFFF59E0B),
      Color(0xFFD97706),
      Color(0xFFB45309),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00F0FF), Color(0xFF7000FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00FF87), Color(0xFF60EFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A1F30), Color(0xFF131724)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
