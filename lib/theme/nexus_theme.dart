import 'package:flutter/material.dart';

import '../helpers/pref.dart';

/// Tron VPN design system - dark theme (default) with a light variant.
///
/// Colors are resolved dynamically from [Pref.isDarkMode] so every existing
/// call site (`NexusTheme.bg`, `NexusTheme.text`, ...) keeps working as-is
/// and repaints correctly once the Settings screen toggles appearance and
/// triggers a rebuild (see `Get.forceAppUpdate()` in SettingsController).
class NexusTheme {
  NexusTheme._();

  static const String outfitFamily = 'Outfit';
  static const String jetBrainsMonoFamily = 'JetBrainsMono';

  static bool get _dark => Pref.isDarkMode;

  // Colors from HTML CSS variables (dark palette)
  static const Color _bgDark = Color(0xFF03060A);
  static const Color _bg2Dark = Color(0xFF060D14);
  static const Color _surfaceDark = Color(0x0AFFFFFF);
  static const Color _surface2Dark = Color(0x12FFFFFF);
  static const Color _borderDark = Color(0x14FFFFFF);
  static const Color _border2Dark = Color(0x24FFFFFF);
  static const Color _tealDark = Color(0xFF00F5C3);
  static const Color _teal2Dark = Color(0xFF00C49A);
  static const Color _blueDark = Color(0xFF0095FF);
  static const Color _purpleDark = Color(0xFF9B5CFF);
  static const Color _goldDark = Color(0xFFFFB830);
  static const Color _redDark = Color(0xFFFF4D6A);
  static const Color _textDark = Color(0xFFF0FAF6);
  static const Color _text2Dark = Color(0xFF7A9A90);
  static const Color _text3Dark = Color(0xFF3A5A50);
  static const Color _glowTealDark = Color(0x5900F5C3);
  static const Color _glowBlueDark = Color(0x4D0095FF);
  static const Color _glowGoldDark = Color(0x59FFB830);

  // Light palette — same accent hues, re-tuned for contrast on a light bg.
  static const Color _bgLight = Color(0xFFF4F7F7);
  static const Color _bg2Light = Color(0xFFFFFFFF);
  static const Color _surfaceLight = Color(0x08000000);
  static const Color _surface2Light = Color(0x0F000000);
  static const Color _borderLight = Color(0x14000000);
  static const Color _border2Light = Color(0x24000000);
  static const Color _tealLight = Color(0xFF00A884);
  static const Color _teal2Light = Color(0xFF008F6D);
  static const Color _blueLight = Color(0xFF0077CC);
  static const Color _purpleLight = Color(0xFF7C4DFF);
  static const Color _goldLight = Color(0xFFC98A00);
  static const Color _redLight = Color(0xFFE0304F);
  static const Color _textLight = Color(0xFF0B1210);
  static const Color _text2Light = Color(0xFF4A5C56);
  static const Color _text3Light = Color(0xFF8AA098);
  static const Color _glowTealLight = Color(0x3300A884);
  static const Color _glowBlueLight = Color(0x330077CC);
  static const Color _glowGoldLight = Color(0x33C98A00);

  static Color get bg => _dark ? _bgDark : _bgLight;
  static Color get bg2 => _dark ? _bg2Dark : _bg2Light;
  static Color get surface => _dark ? _surfaceDark : _surfaceLight;
  static Color get surface2 => _dark ? _surface2Dark : _surface2Light;
  static Color get border => _dark ? _borderDark : _borderLight;
  static Color get border2 => _dark ? _border2Dark : _border2Light;
  static Color get teal => _dark ? _tealDark : _tealLight;
  static Color get teal2 => _dark ? _teal2Dark : _teal2Light;
  static Color get blue => _dark ? _blueDark : _blueLight;
  static Color get purple => _dark ? _purpleDark : _purpleLight;
  static Color get gold => _dark ? _goldDark : _goldLight;
  static Color get red => _dark ? _redDark : _redLight;
  static Color get text => _dark ? _textDark : _textLight;
  static Color get text2 => _dark ? _text2Dark : _text2Light;
  static Color get text3 => _dark ? _text3Dark : _text3Light;
  static Color get glowTeal => _dark ? _glowTealDark : _glowTealLight;
  static Color get glowBlue => _dark ? _glowBlueDark : _glowBlueLight;
  static Color get glowGold => _dark ? _glowGoldDark : _glowGoldLight;

  static TextStyle outfit({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: outfitFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle jetBrainsMono({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: jetBrainsMonoFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static ThemeData _themeFor({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color teal,
    required Color blue,
    required Color red,
    required Color text,
    required Color text2,
    required Color onSurface,
    required Color onPrimary,
  }) {
    return ThemeData(
      brightness: brightness,
      useMaterial3: false,
      scaffoldBackgroundColor: bg,
      primaryColor: teal,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: teal,
        secondary: blue,
        surface: surface,
        error: red,
        onPrimary: onPrimary,
        onSecondary: onPrimary,
        onSurface: onSurface,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: text,
        titleTextStyle: outfit(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: outfit(
          fontSize: 30,
          fontWeight: FontWeight.w900,
          color: text,
        ),
        displayMedium: outfit(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: text,
        ),
        bodyLarge: outfit(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: text,
        ),
        bodyMedium: outfit(
          fontSize: 13,
          color: text2,
        ),
        labelLarge: jetBrainsMono(
          fontSize: 11,
          letterSpacing: 2,
          color: text2,
        ),
      ),
      fontFamily: outfitFamily,
    );
  }

  static ThemeData get darkTheme => _themeFor(
        brightness: Brightness.dark,
        bg: _bgDark,
        surface: _surfaceDark,
        teal: _tealDark,
        blue: _blueDark,
        red: _redDark,
        text: _textDark,
        text2: _text2Dark,
        onSurface: _textDark,
        onPrimary: Colors.black,
      );

  static ThemeData get lightTheme => _themeFor(
        brightness: Brightness.light,
        bg: _bgLight,
        surface: _surfaceLight,
        teal: _tealLight,
        blue: _blueLight,
        red: _redLight,
        text: _textLight,
        text2: _text2Light,
        onSurface: _textLight,
        onPrimary: Colors.white,
      );

  /// ThemeData matching the current [Pref.isDarkMode] setting.
  static ThemeData get currentTheme => _dark ? darkTheme : lightTheme;

  static TextTheme get textTheme => currentTheme.textTheme;
}
