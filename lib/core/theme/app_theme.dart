import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0F0E0E);
  static const Color surface = Color(0xFF1A1818);
  static const Color cardBg = Color(0xFF221F1F);
  
  static const Color primary = Color(0xFFFF541D); // Vibrant orange
  static const Color primaryGradientStart = Color(0xFFFF541D);
  static const Color primaryGradientEnd = Color(0xFFFF7E40);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E9E9E);
  
  static const Color accentYellow = Color(0xFFFFD54F);
  static const Color border = Color(0xFF2C2929);
  
  static const Color success = Color(0xFF4CAF50);
  static const Color danger = Color(0xFFE53935);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      cardColor: AppColors.cardBg,
      dividerColor: AppColors.border,
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Outfit', color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontFamily: 'Outfit', color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontFamily: 'Outfit', color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontFamily: 'Outfit', color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontFamily: 'Outfit', color: AppColors.textPrimary, fontSize: 16),
        bodyMedium: TextStyle(fontFamily: 'Outfit', color: AppColors.textSecondary, fontSize: 14),
        labelLarge: TextStyle(fontFamily: 'Outfit', color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.danger,
      ),
    );
  }

  static TextStyle monoStyle({double fontSize = 14, FontWeight fontWeight = FontWeight.normal, Color color = AppColors.textPrimary}) {
    return TextStyle(
      fontFamily: 'Space Mono',
      fontFamilyFallback: const ['SpaceMono', 'monospace'],
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}
