import 'package:flutter/material.dart';

class AppColors {
  // Figma Reference Exact Colors
  static Color background = const Color(0xFF121212);
  static Color card = const Color(0xFF1C1C1E);
  static Color primary = const Color(0xFFD2FF00);
  static Color white = const Color(0xFFFFFFFF);
  static Color textSecondary = const Color(0xFFBDBDBD);
  
  // UI Helpers 
  static Color textPrimary = white;
  static Color textMuted = textSecondary;
  static Color accent = primary;
  static Color stroke = const Color(0xFF2A2A2A); 
  
  // States
  static Color success = const Color(0xFF4ADE80);
  static Color warning = const Color(0xFFFFB020);
  static Color error = const Color(0xFFEF4444);

  static void setLightMode() {
    background = const Color(0xFFF3F4F6);
    card = const Color(0xFFFFFFFF);
    primary = const Color(0xFF9ECA00);
    white = const Color(0xFF121212); // Invert white to black
    textSecondary = const Color(0xFF6B7280);
    textPrimary = const Color(0xFF111827);
    textMuted = textSecondary;
    accent = primary;
    stroke = const Color(0xFFE5E7EB);
    
    success = const Color(0xFF22C55E);
    warning = const Color(0xFFF59E0B);
    error = const Color(0xFFEF4444);
  }

  static void setDarkMode() {
    background = const Color(0xFF121212);
    card = const Color(0xFF1C1C1E);
    primary = const Color(0xFFD2FF00);
    white = const Color(0xFFFFFFFF);
    textSecondary = const Color(0xFFBDBDBD);
    textPrimary = white;
    textMuted = textSecondary;
    accent = primary;
    stroke = const Color(0xFF2A2A2A); 
    
    success = const Color(0xFF4ADE80);
    warning = const Color(0xFFFFB020);
    error = const Color(0xFFEF4444);
  }
}
