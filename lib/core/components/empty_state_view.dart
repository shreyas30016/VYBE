import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'primary_button.dart';
import '../../core/theme/app_theme.dart';

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? ctaLabel;
  final VoidCallback? onCtaPressed;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.message,
    this.ctaLabel,
    this.onCtaPressed,
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
            icon,
            size: 48,
            color: context.textMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: context.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          if (ctaLabel != null && onCtaPressed != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: PrimaryButton(
                label: ctaLabel!,
                onPressed: onCtaPressed!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
