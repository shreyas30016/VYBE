import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/wardrobe_provider.dart';
import '../../data/models/clothing_item.dart';
import '../../core/components/glass_container.dart';
import '../../core/components/ambient_background.dart';

class ClosetHubScreen extends ConsumerStatefulWidget {
  const ClosetHubScreen({super.key});

  @override
  ConsumerState<ClosetHubScreen> createState() => _ClosetHubScreenState();
}

class _ClosetHubScreenState extends ConsumerState<ClosetHubScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Tops', 'Bottoms', 'Outerwear', 'Shoes'];

  @override
  Widget build(BuildContext context) {
    final wardrobeAsync = _selectedCategory == 'All' 
        ? ref.watch(wardrobeItemsProvider)
        : ref.watch(wardrobeByCategory(_selectedCategory));
    
    final isOffline = ref.watch(isOfflineProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Wardrobe', style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search, color: AppColors.textPrimary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(LucideIcons.slidersHorizontal, color: AppColors.textPrimary),
            onPressed: () {},
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: AmbientBackground(
        child: Column(
          children: [
          if (isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: AppColors.warning.withValues(alpha: 0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.wifiOff, size: 12, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Text(
                    'Offline: Using cached wardrobe',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.warning, fontSize: 11),
                  ),
                ],
              ),
            ),
          // Categories
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin, vertical: AppSpacing.sm),
            child: Row(
              children: _categories.map((category) {
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    child: isSelected
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
                            ),
                            child: Text(
                              category,
                              style: AppTypography.buttonLabel.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : GlassContainer(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            borderRadius: AppSpacing.radiusButton,
                            child: Text(
                              category,
                              style: AppTypography.buttonLabel.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Grid
          Expanded(
            child: wardrobeAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('No items found.', style: TextStyle(color: Colors.white54)),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.margin,
                    right: AppSpacing.margin,
                    bottom: AppSpacing.bottomNavClearance + 20,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildGridItem(
                      item,
                      '95%', // Hardcoded fallback for UI
                      '2d ago', // Hardcoded fallback for UI
                      Icons.checkroom,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(
                child: Text('Failed to load wardrobe', style: TextStyle(color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildGridItem(ClothingItem item, String score, String lastWorn, IconData placeholderIcon) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Image Placeholder
          Positioned.fill(
            child: item.imageUrl.startsWith('http') 
              ? CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => Icon(placeholderIcon, color: AppColors.textSecondary, size: 64),
                )
              : Image.asset(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(placeholderIcon, color: AppColors.textSecondary, size: 64),
                ),
          ),
          
          // Harmony Badge (Top Right)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                score,
                style: AppTypography.captionBold.copyWith(color: AppColors.primary),
              ),
            ),
          ),
          
          // Last Worn (Bottom Left)
          Positioned(
            bottom: 12,
            left: 12,
            child: Text(
              'Last worn: $lastWorn',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}