import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      fontFamilyFallback: const ['NotoSans'],
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.card,
        error: AppColors.error,
        onSurfaceVariant: AppColors.textSecondary,
        outlineVariant: AppColors.stroke,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.hero.copyWith(color: AppColors.textPrimary),
        displayMedium: AppTypography.headingLarge.copyWith(color: AppColors.textPrimary),
        bodyLarge: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
        bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        labelLarge: AppTypography.buttonLabel.copyWith(color: AppColors.background),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      useMaterial3: false,
    );
  }
}

extension ThemeColors on BuildContext {
  Color get primary => Theme.of(this).colorScheme.primary;
  Color get background => Theme.of(this).scaffoldBackgroundColor;
  Color get surface => Theme.of(this).colorScheme.surface;
  Color get textPrimary => Theme.of(this).textTheme.bodyMedium?.color ?? Colors.white;
  Color get textMuted => Theme.of(this).colorScheme.onSurfaceVariant;
  Color get accent => Theme.of(this).colorScheme.primary;
  Color get strokeSubtle => Theme.of(this).colorScheme.outlineVariant;
}
