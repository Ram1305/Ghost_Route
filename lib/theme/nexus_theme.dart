import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tron VPN design system - dark theme
class NexusTheme {
  NexusTheme._();

  // Colors from HTML CSS variables
  static const Color bg = Color(0xFF03060A);
  static const Color bg2 = Color(0xFF060D14);
  static const Color surface = Color(0x0AFFFFFF);
  static const Color surface2 = Color(0x12FFFFFF);
  static const Color border = Color(0x14FFFFFF);
  static const Color border2 = Color(0x24FFFFFF);
  static const Color teal = Color(0xFF00F5C3);
  static const Color teal2 = Color(0xFF00C49A);
  static const Color blue = Color(0xFF0095FF);
  static const Color purple = Color(0xFF9B5CFF);
  static const Color gold = Color(0xFFFFB830);
  static const Color red = Color(0xFFFF4D6A);
  static const Color text = Color(0xFFF0FAF6);
  static const Color text2 = Color(0xFF7A9A90);
  static const Color text3 = Color(0xFF3A5A50);
  static const Color glowTeal = Color(0x5900F5C3);
  static const Color glowBlue = Color(0x4D0095FF);
  static const Color glowGold = Color(0x59FFB830);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: false,
      scaffoldBackgroundColor: bg,
      primaryColor: teal,
      colorScheme: const ColorScheme.dark(
        primary: teal,
        secondary: blue,
        surface: surface,
        error: red,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: text,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: text,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 30,
          fontWeight: FontWeight.w900,
          color: text,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: text,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: text,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 13,
          color: text2,
        ),
        labelLarge: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          letterSpacing: 2,
          color: text2,
        ),
      ),
      fontFamily: GoogleFonts.outfit().fontFamily,
    );
  }

  static TextTheme get textTheme => darkTheme.textTheme;
}
