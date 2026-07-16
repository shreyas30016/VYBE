import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/user_provider.dart';
import '../../providers/weather_provider.dart';
import '../../providers/outfit_provider.dart';
import '../../providers/wardrobe_provider.dart';
import '../../data/models/outfit.dart';
import '../../core/utils/analytics.dart';
import '../../core/components/glass_container.dart';
import '../../core/components/ambient_background.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final uid = Supabase.instance.client.auth.currentUser?.id ?? 'local';
    final userProfileAsync = ref.watch(userProfileProvider(uid));
    
    final userMetadata = Supabase.instance.client.auth.currentUser?.userMetadata;
    final fallbackName = userMetadata?['full_name'] ?? userMetadata?['name'] ?? 'There';
    final firstName = userProfileAsync.valueOrNull?.name.split(' ').first ?? fallbackName.split(' ').first;
    
    final avatarUrl = userMetadata?['avatar_url'] as String?;
    
    final hour = DateTime.now().hour;
    String greeting = 'Good morning,';
    if (hour >= 12 && hour < 17) {
      greeting = 'Good afternoon,';
    } else if (hour >= 17) {
      greeting = 'Good evening,';
    }

    final weatherAsync = ref.watch(currentWeatherProvider);
    final outfitHistoryAsync = ref.watch(outfitHistoryProvider);
    final todayOutfit = outfitHistoryAsync.when(
      data: (outfits) => outfits.isNotEmpty ? outfits.first : null,
      loading: () => null,
      error: (_, __) => null,
    );
    final wardrobeItemsAsync = ref.watch(wardrobeItemsProvider);

    final weatherText = weatherAsync.when(
      data: (info) => 'Local, ${info.temperature}°C',
      loading: () => 'Loading weather...',
      error: (_, __) => 'Weather unavailable',
    );

    final wardrobeHealth = wardrobeItemsAsync.when(
      data: (items) {
        final outfitCount = outfitHistoryAsync.valueOrNull?.length ?? 0;
        if (items.isEmpty && outfitCount == 0) return 0;
        // Simple logic: more items + worn outfits = better health, capped at 100 for now.
        final score = (items.length * 5 + outfitCount * 2).clamp(0, 100);
        return score;
      },
      loading: () => 94,
      error: (_, __) => 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: AppSpacing.margin,
            right: AppSpacing.margin,
            top: AppSpacing.margin,
            bottom: AppSpacing.bottomNavClearance + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            firstName,
                            style: AppTypography.hero.copyWith(color: AppColors.textPrimary),
                          ),
                          const SizedBox(width: 8),
                          const Text('👋', style: TextStyle(fontSize: 28)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('🌤️', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            weatherText,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 4),
                          const Text('☁️', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showNotificationsBottomSheet(context, ref),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(LucideIcons.bell, color: AppColors.textSecondary, size: 24),
                            // Simple red dot if items exist
                            if (wardrobeItemsAsync.valueOrNull?.isNotEmpty ?? false)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.textSecondary, width: 1),
                          image: avatarUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(avatarUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: avatarUrl == null
                            ? const Icon(LucideIcons.user, color: AppColors.textSecondary, size: 20)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // 2. Today's Outfit Card
              GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TODAY\'S OUTFIT',
                      style: AppTypography.captionBold.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Image Collage Placeholder
                    Builder(
                      builder: (context) {
                        final outfit = todayOutfit;
                        final allItems = wardrobeItemsAsync.valueOrNull;

                        if (outfit == null || allItems == null || allItems.isEmpty) {
                          return Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF222222),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(LucideIcons.shirt, color: AppColors.textSecondary, size: 48),
                                const SizedBox(height: 16),
                                Text(
                                  'No outfit logged today.',
                                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Use the AI Stylist to get one!',
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                                ),
                              ],
                            ),
                          );
                        }

                        final items = allItems.where((item) => outfit.itemIds.contains(item.id)).toList();

                        if (items.isEmpty) {
                          return Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: const Color(0xFF222222),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(child: Text('Items not found', style: TextStyle(color: Colors.white))),
                          );
                        }

                        return SizedBox(
                          height: 180,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ...items.take(3).toList().asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;

                                // We directly assign the values based on index inside the Positioned widget
                                double? width = index == 0 ? 140 : (index == 1 ? 120 : 100);
                                double? height = index == 2 ? 60 : null;

                                return Positioned(
                                  left: index == 0 ? 0 : null,
                                  right: index == 1 ? 0 : (index == 2 ? 20 : null),
                                  top: index == 2 ? null : 0,
                                  bottom: index == 2 ? 0 : 20,
                                  width: width,
                                  height: height,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF222222),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: _buildItemImage(item.imageUrl),
                                  ),
                                );
                              }),

                              // Harmony Badge
                              Positioned(
                                left: -10,
                                bottom: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFF2A2A2A)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      )
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '96%',
                                        style: AppTypography.headingLarge.copyWith(color: AppColors.primary),
                                      ),
                                      Text(
                                        'AI HARMONY',
                                        style: AppTypography.captionBold.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 10,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    ),
                    
                    if (todayOutfit != null) ...[
                      const SizedBox(height: 24),
                      
                      Text(
                        'Why this outfit?',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      _buildReasonBullet('Perfect for partly cloudy weather'),
                      _buildReasonBullet('Balanced style for your meetings'),
                      _buildReasonBullet('You haven\'t worn this in 8 days'),
                      
                      const SizedBox(height: 24),
                      
                      // Wear Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            final newOutfit = Outfit(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              userId: 'local_user',
                              itemIds: todayOutfit.itemIds, // Using actual itemIds instead of []
                              dateCreated: DateTime.now(),
                              isSaved: true,
                              occasion: 'Worn Today',
                            );
                            Analytics.logEvent('Wear Logged', parameters: {'outfitId': newOutfit.id});
                            ref.read(outfitRepositoryProvider).saveOutfit(newOutfit);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Outfit logged! Wardrobe Health increased.')),
                            );
                          },
                          child: const Text('WEAR THIS OUTFIT'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // 3. Quick Actions
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      'Magic Scan',
                      'Add new item',
                      LucideIcons.scan,
                      const Color(0xFF9B7DFF),
                      () => context.push('/magic-scan'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildQuickActionCard(
                      'Ask AI Stylist',
                      'Get suggestions',
                      LucideIcons.sparkles,
                      const Color(0xFF9B7DFF),
                      () => context.push('/stylist'),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // 4. Wardrobe Health
              GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wardrobe Health',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$wardrobeHealth%',
                          style: AppTypography.hero.copyWith(color: AppColors.textPrimary, fontSize: 36),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2A2A2A),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: wardrobeHealth / 100.0,
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: -6,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.5),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        )
                                      ],
                                    ),
                                    child: const Icon(LucideIcons.sparkles, color: Colors.black, size: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Great job! Keep it up.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildReasonBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6.0),
            child: CircleAvatar(radius: 3, backgroundColor: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemImage(String imageUrl) {
    if (imageUrl.startsWith('http') || imageUrl.startsWith('blob:')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.imageOff, color: AppColors.textSecondary),
      );
    } else {
      return Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.imageOff, color: AppColors.textSecondary),
      );
    }
  }

  Widget _buildQuickActionCard(String title, String subtitle, IconData icon, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: iconColor, size: 20),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final items = ref.watch(wardrobeItemsProvider).valueOrNull ?? [];
            final outfits = ref.watch(outfitHistoryProvider).valueOrNull ?? [];
            
            final List<Map<String, dynamic>> notifications = [];
            
            if (items.isNotEmpty) {
              notifications.add({
                'title': '${items.last.category} added',
                'body': 'A new item was saved to your wardrobe.',
                'icon': LucideIcons.archive,
              });
            }
            if (outfits.isNotEmpty) {
              notifications.add({
                'title': 'Outfit Logged',
                'body': 'Your wardrobe health improved!',
                'icon': LucideIcons.sparkles,
              });
            }
            if (notifications.isEmpty) {
              notifications.add({
                'title': 'Welcome to VYBE',
                'body': 'Start by adding items to your wardrobe.',
                'icon': LucideIcons.info,
              });
            }
            
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Activity', style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary)),
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final n = notifications[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppColors.background,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              n['icon'] as IconData,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(n['title'] as String, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
                          subtitle: Text(n['body'] as String, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
