import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/ambient_background.dart';

class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

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
                      _buildSettingsToggle('Outfit ready every morning', true, (val) {}),
                      _buildDivider(),
                      _buildSettingsToggle('Weather changed alerts', true, (val) {}),
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
                      _buildSettingsToggle('Laundry reminders', true, (val) {}),
                      _buildDivider(),
                      _buildSettingsToggle('Unworn item alerts (25+ days)', false, (val) {}),
                      _buildDivider(),
                      _buildSettingsToggle('Weekly wardrobe report', true, (val) {}),
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
                      _buildSettingsToggle('Packing reminders', false, (val) {}),
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
