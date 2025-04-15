import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1A5F7A);
  static const Color secondaryColor = Color(0xFF159895);
  static const Color accentColor = Color(0xFF57C5B6);
  static const Color neutralLightColor = Color(0xFFDEF5E5);
  static const Color warningColor = Color(0xFFEF6262);
  static const Color textDarkColor = Color(0xFF2B2B2B);
  static const Color textLightColor = Color(0xFFF9F9F9);
  static const Color cardBackgroundColor = Color(0xFFFFFFFF);
  static const Color disabledColor = Color(0xFFCCCCCC);

  // Dark theme colors
  static const Color darkPrimaryColor = Color(0xFF0D3B4F);
  static const Color darkSecondaryColor = Color(0xFF0E6563);
  static const Color darkAccentColor = Color(0xFF3A7C72);
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color darkCardColor = Color(0xFF272727);

  static BorderRadius cardBorderRadius = BorderRadius.circular(12.0);
  static BorderRadius buttonBorderRadius = BorderRadius.circular(8.0);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      error: warningColor,
      onPrimary: textLightColor,
      onSecondary: textLightColor,
      onSurface: textDarkColor,
      onError: textLightColor,
    ),
    textTheme: GoogleFonts.nunitoSansTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: textLightColor,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: secondaryColor,
        foregroundColor: textLightColor,
        shape: RoundedRectangleBorder(borderRadius: buttonBorderRadius),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    cardTheme: CardTheme(
      color: cardBackgroundColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: textDarkColor,
      contentTextStyle: TextStyle(color: textLightColor),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: darkPrimaryColor,
      secondary: darkSecondaryColor,
      tertiary: darkAccentColor,
      surface: darkSurfaceColor,
      error: warningColor,
      onPrimary: textLightColor,
      onSecondary: textLightColor,
      onSurface: textLightColor,
      onError: textLightColor,
    ),
    textTheme: GoogleFonts.nunitoSansTextTheme(ThemeData.dark().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkPrimaryColor,
      foregroundColor: textLightColor,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkSecondaryColor,
        foregroundColor: textLightColor,
        shape: RoundedRectangleBorder(borderRadius: buttonBorderRadius),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    cardTheme: CardTheme(
      color: darkCardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: darkSurfaceColor,
      contentTextStyle: TextStyle(color: textLightColor),
    ),
  );
}