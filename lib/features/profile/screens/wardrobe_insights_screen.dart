import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/ambient_background.dart';
import '../../../providers/wardrobe_provider.dart';
import '../../../providers/outfit_provider.dart';
import '../../../data/models/clothing_item.dart';

class WardrobeInsightsScreen extends ConsumerWidget {
  const WardrobeInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wardrobe = ref.watch(wardrobeItemsProvider).valueOrNull ?? [];
    final outfits = ref.watch(outfitHistoryProvider).valueOrNull ?? [];

    // Calculate item frequencies in outfits
    final Map<String, int> itemFrequency = {};
    for (var item in wardrobe) {
      itemFrequency[item.id] = 0;
    }
    
    for (var outfit in outfits) {
      for (var itemId in outfit.itemIds) {
        if (itemFrequency.containsKey(itemId)) {
          itemFrequency[itemId] = itemFrequency[itemId]! + 1;
        }
      }
    }

    // Find Most Worn
    ClothingItem? mostWornItem;
    int maxWears = 0;
    
    // Find Least Worn
    ClothingItem? leastWornItem;
    int minWears = 999999;
    
    int unwornCount = 0;

    for (var item in wardrobe) {
      final wears = itemFrequency[item.id] ?? 0;
      if (wears > maxWears) {
        maxWears = wears;
        mostWornItem = item;
      }
      if (wears < minWears) {
        minWears = wears;
        leastWornItem = item;
      }
      if (wears == 0) {
        unwornCount++;
      }
    }
    
    if (wardrobe.isEmpty) {
      minWears = 0;
    }

    final unwornProgress = wardrobe.isEmpty ? 0.0 : 1.0 - (unwornCount / wardrobe.length);
    final colorVariety = wardrobe.map((e) => e.color).toSet().length;
    final colorProgress = wardrobe.isEmpty ? 0.0 : (colorVariety / 10.0).clamp(0.0, 1.0);

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
                    child: _buildStatCard(
                      'Most Worn', 
                      mostWornItem?.subtype ?? (wardrobe.isEmpty ? 'No Items' : 'Tie'), 
                      '$maxWears wears', 
                      LucideIcons.flame, 
                      AppColors.primary
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Least Worn', 
                      leastWornItem?.subtype ?? (wardrobe.isEmpty ? 'No Items' : 'Tie'), 
                      '$minWears wears', 
                      LucideIcons.snowflake, 
                      Colors.blueAccent
                    ),
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
                    _buildHealthItem('Unworn Items (0 wears)', '$unwornCount items', unwornProgress),
                    const SizedBox(height: 16),
                    _buildHealthItem('Color Variety', '$colorVariety distinct colors', colorProgress),
                    const SizedBox(height: 16),
                    _buildHealthItem('Seasonal Coverage', 'Balanced', 0.8),
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
