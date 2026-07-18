import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/ambient_background.dart';

class BetaPlanScreen extends StatelessWidget {
  const BetaPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('VYBE Beta Plan', style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary)),
      ),
      body: AmbientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(24),
                borderRadius: 24,
                child: Column(
                  children: [
                    const Icon(LucideIcons.sparkles, color: AppColors.primary, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'VYBE Pro (Coming Soon)',
                      style: AppTypography.headingLarge.copyWith(color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You are currently on the Free Beta plan. All features are free during the Beta period.',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text('What to expect in Pro', style: AppTypography.headingSmall.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              _buildFeatureRow(LucideIcons.infinity, 'Unlimited AI Generations'),
              _buildFeatureRow(LucideIcons.calendar, 'Advanced Calendar Syncing'),
              _buildFeatureRow(LucideIcons.shoppingBag, 'Exclusive Shopping Discounts'),
              _buildFeatureRow(LucideIcons.zap, 'Priority Model Access'),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You are already enjoying all Beta features for free!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.card,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  child: Text('Join Pro Waitlist', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 16),
            Text(title, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}