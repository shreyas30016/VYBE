import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'ghost_button.dart';
import '../../core/theme/app_theme.dart';

class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorStateView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: context.accent,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: context.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          GhostButton(
            label: 'Retry',
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}