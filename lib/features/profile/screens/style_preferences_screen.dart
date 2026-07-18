import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/ambient_background.dart';
import '../../../providers/user_provider.dart';
import '../../../data/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StylePreferencesScreen extends ConsumerStatefulWidget {
  const StylePreferencesScreen({super.key});

  @override
  ConsumerState<StylePreferencesScreen> createState() => _StylePreferencesScreenState();
}

class _StylePreferencesScreenState extends ConsumerState<StylePreferencesScreen> {
  List<String> _selectedStyles = [];
  List<String> _selectedBrands = [];
  
  final List<String> _availableStyles = [
    'Casual', 'Streetwear', 'Minimal', 'Old Money', 'Formal', 
    'Athleisure', 'Y2K', 'Traditional', 'Boho', 'Luxury'
  ];

  final List<String> _availableBrands = [
    'Nike', 'Adidas', 'H&M', 'Uniqlo', 'Zara', 'Levis', 'Puma', 'Rare Rabbit'
  ];
  
  double _creativity = 0.5;
  String _weatherPref = 'Auto Detect';

  final List<String> _weatherOptions = [
    'Auto Detect', 'Use Current Weather', 'Ignore Weather', 'Manual Temperature'
  ];

  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    final uid = Supabase.instance.client.auth.currentUser?.id ?? 'local';
    final userProfileAsync = ref.watch(userProfileProvider(uid));
    
    if (!_isInitialized && userProfileAsync.valueOrNull != null) {
      final profile = userProfileAsync.valueOrNull!;
      _selectedStyles = List.from(profile.styles);
      _selectedBrands = List.from(profile.favoriteBrands);
      _creativity = profile.outfitCreativity;
      _weatherPref = profile.weatherPreference;
      
      // Fallback if old data existed
      if (_selectedStyles.isEmpty && profile.styleBaseline != null) {
        _selectedStyles = profile.styleBaseline!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      _isInitialized = true;
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
                children: _availableStyles.map((style) {
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
                children: _availableBrands.map((brand) {
                  final isSelected = _selectedBrands.contains(brand);
                  return FilterChip(
                    label: Text(brand),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedBrands.add(brand);
                        } else {
                          _selectedBrands.remove(brand);
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
                  children: _weatherOptions.map((option) {
                    return Column(
                      children: [
                        ListTile(
                          title: Text(option, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
                          trailing: Radio<String>(
                            value: option,
                            groupValue: _weatherPref,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              if (val != null) setState(() => _weatherPref = val);
                            },
                          ),
                          onTap: () => setState(() => _weatherPref = option),
                        ),
                        if (option != _weatherOptions.last)
                          Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                      ],
                    );
                  }).toList(),
                ),
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final uid = Supabase.instance.client.auth.currentUser?.id ?? 'local';
                    final currentProfile = await ref.read(userRepositoryProvider).getProfile(uid).first;
                    if (currentProfile != null) {
                      await ref.read(userRepositoryProvider).updateProfile(
                        currentProfile.copyWith(
                          styles: _selectedStyles,
                          favoriteBrands: _selectedBrands,
                          outfitCreativity: _creativity,
                          weatherPreference: _weatherPref,
                          styleBaseline: _selectedStyles.join(', '), // fallback
                        ),
                      );
                    } else {
                      await ref.read(userRepositoryProvider).updateProfile(
                        UserProfile(
                          userId: uid,
                          name: 'User',
                          styles: _selectedStyles,
                          favoriteBrands: _selectedBrands,
                          outfitCreativity: _creativity,
                          weatherPreference: _weatherPref,
                          styleBaseline: _selectedStyles.join(', '),
                          calendarSyncEnabled: false,
                          weatherContextEnabled: false,
                          hapticsEnabled: true,
                          hapticIntensity: 0.5,
                        ),
                      );
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Preferences Saved!'), backgroundColor: AppColors.success),
                      );
                      context.pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Save Preferences', style: AppTypography.bodyMedium.copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
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
