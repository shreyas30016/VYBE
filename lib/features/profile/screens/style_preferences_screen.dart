import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/ambient_background.dart';

class StylePreferencesScreen extends ConsumerStatefulWidget {
  const StylePreferencesScreen({super.key});

  @override
  ConsumerState<StylePreferencesScreen> createState() => _StylePreferencesScreenState();
}

class _StylePreferencesScreenState extends ConsumerState<StylePreferencesScreen> {
  final List<String> _selectedStyles = ['Minimalist', 'Streetwear'];
  final List<String> _styles = [
    'Minimalist', 'Streetwear', 'Old Money', 'Quiet Luxury', 
    'Casual', 'Business', 'Korean', 'Y2K', 'Techwear', 'Vintage'
  ];

  final List<String> _brands = ['Nike', 'Uniqlo', 'Zara', 'H&M'];
  
  double _creativity = 0.5;

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
        title: Text('Style Preferences', style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary)),
      ),
      body: AmbientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Fashion Style', 'Select the aesthetics that match your vibe.'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _styles.map((style) {
                  final isSelected = _selectedStyles.contains(style);
                  return FilterChip(
                    label: Text(style),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedStyles.add(style);
                        } else {
                          _selectedStyles.remove(style);
                        }
                      });
                    },
                    backgroundColor: Colors.black45,
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 32),
              
              _buildSectionTitle('Favorite Brands', 'Brands you wear most often.'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._brands.map((brand) => Chip(
                    label: Text(brand, style: const TextStyle(color: AppColors.textPrimary)),
                    backgroundColor: Colors.black45,
                    deleteIcon: const Icon(LucideIcons.x, size: 16, color: AppColors.textSecondary),
                    onDeleted: () {},
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                  )),
                  ActionChip(
                    label: const Text('Add Brand', style: TextStyle(color: AppColors.primary)),
                    avatar: const Icon(LucideIcons.plus, size: 16, color: AppColors.primary),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    onPressed: () {},
                  )
                ],
              ),
              
              const SizedBox(height: 32),
              
              _buildSectionTitle('Outfit Creativity', 'How experimental should the AI Stylist be?'),
              GlassContainer(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Safe', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                        Text('Bold', style: AppTypography.bodySmall.copyWith(color: AppColors.primary)),
                      ],
                    ),
                    Slider(
                      value: _creativity,
                      onChanged: (val) => setState(() => _creativity = val),
                      activeColor: AppColors.primary,
                      inactiveColor: Colors.white.withValues(alpha: 0.1),
                    ),
                    Text(
                      _creativity < 0.3 ? 'Classic & Reliable' : _creativity < 0.7 ? 'Balanced & Trendy' : 'Avant-Garde & Experimental',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 32),

              _buildSectionTitle('Weather Preference', 'Helps the AI suggest better layers.'),
              GlassContainer(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      title: Text('I get cold easily (Prefer layers)', style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
                      // ignore: deprecated_member_use
                      trailing: Radio<int>(
                        value: 0,
                        groupValue: 0,
                        activeColor: AppColors.primary,
                        onChanged: (val) {},
                      ),
                      onTap: () {},
                    ),
                    Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                    ListTile(
                      title: Text('Neutral', style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
                      // ignore: deprecated_member_use
                      trailing: Radio<int>(
                        value: 1,
                        groupValue: 0,
                        activeColor: AppColors.primary,
                        onChanged: (val) {},
                      ),
                      onTap: () {},
                    ),
                    Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                    ListTile(
                      title: Text('I run hot (Prefer breathable)', style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
                      // ignore: deprecated_member_use
                      trailing: Radio<int>(
                        value: 2,
                        groupValue: 0,
                        activeColor: AppColors.primary,
                        onChanged: (val) {},
                      ),
                      onTap: () {},
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

  Widget _buildSectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.headingSmall.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
