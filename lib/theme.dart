import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary      = Color(0xFF1a237e);
  static const Color primaryLight = Color(0xFF283593);
  static const Color accent       = Color(0xFFc97a3a);
  static const Color success      = Color(0xFF2e7d32);
  static const Color danger       = Color(0xFFc62828);

  static ThemeData get theme => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      isDense: true,
    ),
    cardTheme: CardTheme(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
    ),
  );
}
