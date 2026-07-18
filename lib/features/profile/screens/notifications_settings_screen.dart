import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/ambient_background.dart';
import '../../../providers/user_provider.dart';
import '../../../data/models/user_profile.dart';

class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = Supabase.instance.client.auth.currentUser?.id ?? 'local';
    final userProfileAsync = ref.watch(userProfileProvider(uid));
    final profile = userProfileAsync.valueOrNull ?? UserProfile(
      userId: uid,
      name: 'User',
      calendarSyncEnabled: false,
      weatherContextEnabled: false,
      hapticsEnabled: true,
      hapticIntensity: 0.5,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Notifications', style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary)),
      ),
      body: AmbientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Daily Updates', 'Morning routine alerts.'),
              GlassContainer(
                padding: EdgeInsets.zero,
                borderRadius: 16,
                child: Material(
                  color: Colors.transparent,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _buildSettingsToggle(
                        'Outfit ready every morning', 
                        profile.notifOutfitReady, 
                        (val) {
                          ref.read(userRepositoryProvider).updateProfile(
                            profile.copyWith(notifOutfitReady: val)
                          );
                        }
                      ),
                      _buildDivider(),
                      _buildSettingsToggle(
                        'Weather changed alerts', 
                        profile.notifWeather, 
                        (val) {
                          ref.read(userRepositoryProvider).updateProfile(
                            profile.copyWith(notifWeather: val)
                          );
                        }
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Wardrobe Management', 'Keep your closet healthy.'),
              GlassContainer(
                padding: EdgeInsets.zero,
                borderRadius: 16,
                child: Material(
                  color: Colors.transparent,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _buildSettingsToggle(
                        'Laundry reminders', 
                        profile.notifLaundry, 
                        (val) {
                          ref.read(userRepositoryProvider).updateProfile(
                            profile.copyWith(notifLaundry: val)
                          );
                        }
                      ),
                      _buildDivider(),
                      _buildSettingsToggle(
                        'Unworn item alerts (25+ days)', 
                        profile.notifUnworn, 
                        (val) {
                          ref.read(userRepositoryProvider).updateProfile(
                            profile.copyWith(notifUnworn: val)
                          );
                        }
                      ),
                      _buildDivider(),
                      _buildSettingsToggle(
                        'Weekly wardrobe report', 
                        profile.notifWeekly, 
                        (val) {
                          ref.read(userRepositoryProvider).updateProfile(
                            profile.copyWith(notifWeekly: val)
                          );
                        }
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Travel & Events', 'Smart suggestions based on your calendar.'),
              GlassContainer(
                padding: EdgeInsets.zero,
                borderRadius: 16,
                child: Material(
                  color: Colors.transparent,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _buildSettingsToggle(
                        'Packing reminders', 
                        profile.notifPacking, 
                        (val) {
                          ref.read(userRepositoryProvider).updateProfile(
                            profile.copyWith(notifPacking: val)
                          );
                        }
                      ),
                      _buildDivider(),
                      _buildSettingsToggle(
                        'New AI Features', 
                        profile.notifNewAi, 
                        (val) {
                          ref.read(userRepositoryProvider).updateProfile(
                            profile.copyWith(notifNewAi: val)
                          );
                        }
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Offers & Updates', 'Stay in the loop.'),
              GlassContainer(
                padding: EdgeInsets.zero,
                borderRadius: 16,
                child: Material(
                  color: Colors.transparent,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _buildSettingsToggle(
                        'Sale Alerts', 
                        profile.notifSale, 
                        (val) {
                          ref.read(userRepositoryProvider).updateProfile(
                            profile.copyWith(notifSale: val)
                          );
                        }
                      ),
                      _buildDivider(),
                      _buildSettingsToggle(
                        'Beta Features', 
                        profile.notifBeta, 
                        (val) {
                          ref.read(userRepositoryProvider).updateProfile(
                            profile.copyWith(notifBeta: val)
                          );
                        }
                      ),
                    ],
                  ),
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
      padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.captionBold.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.white.withValues(alpha: 0.05),
      margin: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  Widget _buildSettingsToggle(String title, bool value, Function(bool) onChanged) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        activeTrackColor: AppColors.primary.withValues(alpha: 0.2),
      ),
    );
  }
}
