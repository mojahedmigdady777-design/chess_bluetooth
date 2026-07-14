// lib/core/theme.dart

import 'package:flutter/material.dart';

class ChessTheme {
  static const Color primaryDark = Color(0xFF4E3629);  
  static const Color primaryLight = Color(0xFFD7CCC8); 
  static const Color accentGold = Color(0xFFFFD700);    
  static const Color background = Color(0xFF3E2723);    
  
  static const Color lightSquare = Color(0xFFF0D9B5);   
  static const Color darkSquare = Color(0xFFB58863);    

  static ThemeData get themeData {
    return ThemeData(
      primaryColor: primaryDark,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryDark,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGold,
          foregroundColor: primaryDark,
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}