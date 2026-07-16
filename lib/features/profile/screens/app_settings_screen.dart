import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/ambient_background.dart';

class AppSettingsScreen extends ConsumerWidget {
  const AppSettingsScreen({super.key});

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
        title: Text('App Settings', style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary)),
      ),
      body: AmbientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Appearance'),
              GlassContainer(
                padding: EdgeInsets.zero,
                borderRadius: 16,
                child: Material(
                  color: Colors.transparent,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _buildSettingsToggle('Dark Mode', true, (val) {}),
                      _buildDivider(),
                      _buildSettingsSelector('Accent Color', 'Lime', () {}),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Performance & AI'),
              GlassContainer(
                padding: EdgeInsets.zero,
                borderRadius: 16,
                child: Material(
                  color: Colors.transparent,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _buildSettingsSelector('AI Model', 'Balanced', () {}),
                      _buildDivider(),
                      _buildSettingsSelector('Camera Quality', 'High', () {}),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Data & Privacy'),
              GlassContainer(
                padding: EdgeInsets.zero,
                borderRadius: 16,
                child: Material(
                  color: Colors.transparent,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _buildSettingsToggle('Store Images Locally', true, (val) {}),
                      _buildDivider(),
                      _buildSettingsSelector('Cache Size', '124 MB', () {}),
                      _buildDivider(),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        title: Text(
                          'Clear Cache',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                        ),
                        trailing: const Icon(LucideIcons.trash2, color: AppColors.error, size: 20),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cache cleared'), backgroundColor: AppColors.success),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: Text(
                  'VYBE Version 1.0.0',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.5)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
      child: Text(
        title,
        style: AppTypography.captionBold.copyWith(color: AppColors.textSecondary),
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

  Widget _buildSettingsSelector(String title, String value, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
          const Icon(LucideIcons.chevronRight, color: AppColors.textSecondary, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }
}
