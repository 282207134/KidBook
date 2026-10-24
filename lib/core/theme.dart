import 'package:flutter/material.dart';

abstract final class Palette {
  static const navy = Color(0xff222f63);
  static const green = Color(0xff08b589);
  static const greenShadow = Color(0xff009d78);
  static const pink = Color(0xffff427b);
  static const pinkShadow = Color(0xffe0356a);
  static const background = Color(0xfff7f8fb);
  static const mint = Color(0xffe4f6f1);
  static const gray = Color(0xffdfe7ee);
  static const muted = Color(0xff8994b0);
}

ThemeData buildTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: Palette.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Palette.green,
    primary: Palette.green,
    secondary: Palette.pink,
    surface: Palette.background,
  ),
  fontFamily: 'Arial',
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      height: 1.18,
      fontWeight: FontWeight.w700,
      color: Palette.navy,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      height: 1.2,
      fontWeight: FontWeight.w700,
      color: Palette.navy,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: Palette.navy,
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Palette.navy,
    ),
    bodyLarge: TextStyle(fontSize: 17, height: 1.35, color: Palette.navy),
    bodyMedium: TextStyle(fontSize: 15, height: 1.35, color: Palette.navy),
    bodySmall: TextStyle(fontSize: 13, color: Palette.muted),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Palette.background,
    foregroundColor: Palette.navy,
    elevation: 0,
    centerTitle: false,
  ),
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: Palette.navy,
    behavior: SnackBarBehavior.floating,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.all(16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide.none,
    ),
    hintStyle: const TextStyle(color: Palette.muted),
  ),
);
