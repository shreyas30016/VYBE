import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../../core/theme/app_theme.dart';

class FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterPill({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? context.primary : context.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(
            color: isSelected ? context.primary : context.strokeSubtle,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isSelected ? context.background : context.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
