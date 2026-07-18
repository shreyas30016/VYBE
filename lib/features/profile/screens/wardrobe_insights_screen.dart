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

class WardrobeInsightsScreen extends ConsumerStatefulWidget {
  const WardrobeInsightsScreen({super.key});

  @override
  ConsumerState<WardrobeInsightsScreen> createState() => _WardrobeInsightsScreenState();
}

class _WardrobeInsightsScreenState extends ConsumerState<WardrobeInsightsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animFloat;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _animFloat = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wardrobe = ref.watch(wardrobeItemsProvider).valueOrNull ?? [];
    final outfits = ref.watch(outfitHistoryProvider).valueOrNull ?? [];

    // Calculations
    final totalItems = wardrobe.length;
    
    // Most Used Color
    final Map<String, int> colorCount = {};
    for (var item in wardrobe) {
      final c = item.color?.toLowerCase() ?? 'unknown';
      colorCount[c] = (colorCount[c] ?? 0) + 1;
    }
    String mostUsedColor = 'N/A';
    int maxColorCount = 0;
    colorCount.forEach((key, value) {
      if (value > maxColorCount) {
        maxColorCount = value;
        mostUsedColor = key;
      }
    });
    final colorPercentage = wardrobe.isEmpty ? 0.0 : (maxColorCount / totalItems);

    // Least Used Category
    final Map<String, int> catCount = {};
    for (var item in wardrobe) {
      catCount[item.category] = (catCount[item.category] ?? 0) + 1;
    }
    String leastUsedCategory = 'N/A';
    int minCatCount = 9999;
    catCount.forEach((key, value) {
      if (value < minCatCount) {
        minCatCount = value;
        leastUsedCategory = key;
      }
    });

    // Seasonal Coverage (mocking seasons)
    int summerItems = 0;
    int winterItems = 0;
    for (var item in wardrobe) {
      if (item.category.toLowerCase().contains('shirt') || item.category.toLowerCase().contains('short')) {
        summerItems++;
      } else {
        winterItems++;
      }
    }
    // ensure no zero division
    final sumItems = (summerItems + winterItems == 0) ? 1 : summerItems + winterItems;

    // Outfits calculation
    final uniqueCategories = wardrobe.map((e) => e.category).toSet().length;
    final diversityScore = wardrobe.isEmpty ? 0.0 : ((uniqueCategories / 5.0) * 100).clamp(0, 100).toDouble();

    // Cost Per Wear
    // We mock cost as 2500 per item for demo
    int totalWears = outfits.fold(0, (sum, out) => sum + out.itemIds.length);
    double costPerWear = totalWears == 0 ? 2500.0 : (totalItems * 2500) / totalWears;

    // Smart Suggestion
    String smartSuggestion = 'Add more items to your wardrobe for suggestions.';
    if (totalItems > 0) {
      final shirts = catCount.entries.where((e) => e.key.toLowerCase().contains('shirt')).fold(0, (sum, e) => sum + e.value);
      final jackets = catCount.entries.where((e) => e.key.toLowerCase().contains('jacket') || e.key.toLowerCase().contains('outerwear')).fold(0, (sum, e) => sum + e.value);
      
      if (shirts > 10 && jackets < 3) {
        smartSuggestion = 'You own $shirts Shirts but only $jackets Jackets.\nRecommendation: Buy a neutral overshirt.';
      } else if (shirts < 5) {
        smartSuggestion = 'You have plenty of bottoms but need more basic tees.';
      } else {
        smartSuggestion = 'Your wardrobe is well balanced! Keep it up.';
      }
    }

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
              // Total Items (Animated Counter)
              Center(
                child: Column(
                  children: [
                    Text('Total Items', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                    AnimatedBuilder(
                      animation: _animFloat,
                      builder: (context, child) {
                        return Text(
                          (_animFloat.value * totalItems).toInt().toString(),
                          style: AppTypography.headingLarge.copyWith(fontSize: 64, color: AppColors.textPrimary),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              Row(
                children: [
                  Expanded(
                    child: GlassContainer(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text('Most Used Color', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 80,
                            width: 80,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                AnimatedBuilder(
                                  animation: _animFloat,
                                  builder: (context, child) {
                                    return CircularProgressIndicator(
                                      value: _animFloat.value * colorPercentage,
                                      strokeWidth: 8,
                                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                                      color: _getColorFromName(mostUsedColor),
                                    );
                                  }
                                ),
                                Center(
                                  child: Text(
                                    '${(colorPercentage * 100).toInt()}%',
                                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(mostUsedColor.toUpperCase(), style: AppTypography.captionBold.copyWith(color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        GlassContainer(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.arrowDownCircle, color: Colors.blueAccent),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Least Used', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                                    Text(leastUsedCategory, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text('$minCatCount items', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 10)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        GlassContainer(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.indianRupee, color: AppColors.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Cost / Wear', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                                    Text('₹${costPerWear.toInt()}', style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              Text('Seasonal Coverage', style: AppTypography.headingSmall.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildAnimatedBar('Summer', summerItems, sumItems, Colors.orangeAccent),
                    const SizedBox(height: 16),
                    _buildAnimatedBar('Winter', winterItems, sumItems, Colors.lightBlueAccent),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              
              Text('Outfit Diversity', style: AppTypography.headingSmall.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      height: 60,
                      width: 60,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AnimatedBuilder(
                            animation: _animFloat,
                            builder: (context, child) {
                              return CircularProgressIndicator(
                                value: _animFloat.value * (diversityScore / 100),
                                strokeWidth: 6,
                                backgroundColor: Colors.white.withValues(alpha: 0.1),
                                color: AppColors.primary,
                              );
                            }
                          ),
                          Center(
                            child: Text(
                              '${diversityScore.toInt()}%',
                              style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Your wardrobe covers a great mix of styles and categories!',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              
              Text('Smart Suggestions', style: AppTypography.headingSmall.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(LucideIcons.sparkles, color: AppColors.primary, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        smartSuggestion,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
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

  Widget _buildAnimatedBar(String title, int count, int total, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
            Text(count.toString(), style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _animFloat,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: total == 0 ? 0 : (_animFloat.value * (count / total)),
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              borderRadius: BorderRadius.circular(4),
              minHeight: 8,
            );
          }
        ),
      ],
    );
  }

  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'black': return Colors.black;
      case 'white': return Colors.white;
      case 'red': return Colors.red;
      case 'blue': return Colors.blue;
      case 'green': return Colors.green;
      case 'yellow': return Colors.yellow;
      case 'purple': return Colors.purple;
      case 'pink': return Colors.pink;
      case 'grey':
      case 'gray': return Colors.grey;
      case 'brown': return Colors.brown;
      case 'orange': return Colors.orange;
      default: return AppColors.primary;
    }
  }
}
