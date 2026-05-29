import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  
  // ========== PRIMARY COLORS (SAME FOR LIGHT & DARK) ==========
  static const Color primary = Color(0xFF007BFF);
  static const Color primaryDark = Color(0xFF0056b3);
  static const Color primaryLight = Color(0xFF4dabf7);
  
  static const Color secondary = Color(0xFF00C896);
  static const Color secondaryDark = Color(0xFF00a077);
  static const Color secondaryLight = Color(0xFF4dd4ac);
  
  static const Color accent = Color(0xFF00C896);
  
  // ========== LIGHT THEME COLORS ==========
  static const Color background = Color(0xFFF8F9FA);
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F5);
  
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF495057);
  static const Color textDisabled = Color(0xFFADB5BD);
  static const Color textHint = Color(0xFF9CA3AF);
  
  static const Color border = Color(0xFFDEE2E6);
  static const Color borderLight = Color(0xFFE9ECEF);
  static const Color borderDark = Color(0xFFCED4DA);
  
  // ⭐ NEW: DARK THEME COLORS
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkBackgroundElevated = Color(0xFF1E1E1E);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);
  
  static const Color darkTextPrimary = Color(0xFFE1E1E1);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkTextDisabled = Color(0xFF6C6C6C);
  static const Color darkTextHint = Color(0xFF808080);
  
  static const Color darkBorder = Color(0xFF3A3A3A);
  static const Color darkBorderLight = Color(0xFF2C2C2C);
  static const Color darkBorderDark = Color(0xFF4A4A4A);
  
  static const Color darkDivider = Color(0xFF2C2C2C);
  
  // ========== STATUS COLORS (SAME FOR LIGHT & DARK) ==========
  static const Color success = Color(0xFF28A745);
  static const Color successLight = Color(0xFFD4EDDA);
  static const Color warning = Color(0xFFFFC107);
  static const Color warningLight = Color(0xFFFFF3CD);
  static const Color error = Color(0xFFDC3545);
  static const Color errorLight = Color(0xFFF8D7DA);
  static const Color info = Color(0xFF17A2B8);
  static const Color infoLight = Color(0xFFD1ECF1);
  
  // ========== UTILITY COLORS ==========
  static const Color divider = Color(0xFFE9ECEF);
  static const Color shadow = Color(0x1A000000);
  static const Color overlay = Color(0x80000000);
}