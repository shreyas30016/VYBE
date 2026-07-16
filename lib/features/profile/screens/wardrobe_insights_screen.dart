import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/ambient_background.dart';

class WardrobeInsightsScreen extends ConsumerWidget {
  const WardrobeInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Wardrobe Insights', style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary)),
      ),
      body: AmbientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Most Worn', 'Black Hoodie', '12 wears', LucideIcons.flame, AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard('Least Worn', 'Red Checkered Shirt', '0 wears', LucideIcons.snowflake, Colors.blueAccent),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              Text('Style Score Trend', style: AppTypography.headingSmall.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              GlassContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildBar(0.4, 'Mon'),
                        _buildBar(0.5, 'Tue'),
                        _buildBar(0.3, 'Wed'),
                        _buildBar(0.7, 'Thu'),
                        _buildBar(0.6, 'Fri'),
                        _buildBar(0.9, 'Sat'),
                        _buildBar(0.8, 'Sun'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              Text('Closet Health', style: AppTypography.headingSmall.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildHealthItem('Unworn Items (30+ days)', '24 items', 0.6),
                    const SizedBox(height: 16),
                    _buildHealthItem('Color Variety', 'High', 0.85),
                    const SizedBox(height: 16),
                    _buildHealthItem('Seasonal Coverage', 'Needs winter coats', 0.4),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String item, String stat, IconData icon, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(title, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          Text(item, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(stat, style: AppTypography.captionBold.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildBar(double percentage, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 24,
          height: 100 * percentage,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: percentage + 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 10)),
      ],
    );
  }

  Widget _buildHealthItem(String title, String value, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
            Text(value, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          valueColor: AlwaysStoppedAnimation<Color>(
            progress > 0.7 ? AppColors.success : progress > 0.4 ? Colors.amber : AppColors.error,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
