import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: Colors.black,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: false,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.black),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.black),
      bodySmall: TextStyle(fontSize: 12, color: Colors.black),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: const Size(double.infinity, 50),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}
