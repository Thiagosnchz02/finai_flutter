import 'package:flutter/material.dart';

class AppTheme {
  // --- Colores base ---
  static const Color _primaryColor = Color(0xFF5A67D8); // Un azul/morado vibrante
  static const Color _accentColor = Color(0xFF9F7AEA); // Un morado más claro

  // --- Tema Claro ---
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: _primaryColor,
    scaffoldBackgroundColor: const Color(0xFFF7F7FA), // Un gris muy claro
    cardColor: Colors.white,
    dividerColor: Colors.grey.shade200,
    fontFamily: 'Inter', // Asegúrate de añadir esta fuente si la quieres
    colorScheme: const ColorScheme.light(
      primary: _primaryColor,
      secondary: _accentColor,
      surface: Colors.white,
      background: Color(0xFFF7F7FA),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF1A202C), // Texto oscuro
      onBackground: Color(0xFF1A202C),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF4A5568)),
      titleTextStyle: TextStyle(
        color: Color(0xFF1A202C),
        fontSize: 22,
        fontWeight: FontWeight.bold,
        fontFamily: 'Inter',
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
      bodyMedium: TextStyle(color: Color(0xFF4A5568)),
      labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFEDF2F7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );

  // --- Tema Oscuro ---
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: _primaryColor,
    scaffoldBackgroundColor: const Color(0xFF1A202C), // Fondo oscuro
    cardColor: const Color(0xFF2D3748), // Color de las tarjetas
    dividerColor: Colors.grey.shade800,
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.dark(
      primary: _primaryColor,
      secondary: _accentColor,
      surface: Color(0xFF2D3748), // Superficies como tarjetas
      background: Color(0xFF1A202C),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFFEDF2F7), // Texto claro
      onBackground: Color(0xFFEDF2F7),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFFE2E8F0)),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        fontFamily: 'Inter',
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      bodyMedium: TextStyle(color: Color(0xFFA0AEC0)), // Gris claro para texto secundario
      labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
     elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2D3748),
      hintStyle: TextStyle(color: Colors.grey.shade500),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}