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

class AppSettingsScreen extends ConsumerStatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  ConsumerState<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends ConsumerState<AppSettingsScreen> {
  int _versionTapCount = 0;
  String _cacheSize = '124 MB';

  @override
  Widget build(BuildContext context) {
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
                      _buildSettingsSelector(
                        'Theme', 
                        profile.appTheme, 
                        () {
                          _showSelectionModal('Theme', ['System', 'Light', 'Dark'], profile.appTheme, (val) {
                            ref.read(userRepositoryProvider).updateProfile(profile.copyWith(appTheme: val));
                          });
                        }
                      ),
                      _buildDivider(),
                      _buildSettingsSelector(
                        'Accent Color', 
                        profile.accentColor, 
                        () {
                          _showSelectionModal('Accent Color', ['Neon Green', 'Purple', 'Blue', 'Orange', 'Pink'], profile.accentColor, (val) {
                            ref.read(userRepositoryProvider).updateProfile(profile.copyWith(accentColor: val));
                          });
                        }
                      ),
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
                      _buildSettingsToggle(
                        'Save AI Chats', 
                        profile.saveAiChats, 
                        (val) {
                          ref.read(userRepositoryProvider).updateProfile(profile.copyWith(saveAiChats: val));
                        }
                      ),
                      _buildDivider(),
                      _buildSettingsToggle(
                        'Personalization', 
                        profile.personalization, 
                        (val) {
                          ref.read(userRepositoryProvider).updateProfile(profile.copyWith(personalization: val));
                        }
                      ),
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
                      _buildSettingsToggle(
                        'Upload Analytics', 
                        profile.uploadAnalytics, 
                        (val) {
                          ref.read(userRepositoryProvider).updateProfile(profile.copyWith(uploadAnalytics: val));
                        }
                      ),
                      _buildDivider(),
                      _buildSettingsToggle(
                        'Crash Reports', 
                        profile.crashReports, 
                        (val) {
                          ref.read(userRepositoryProvider).updateProfile(profile.copyWith(crashReports: val));
                        }
                      ),
                      _buildDivider(),
                      _buildSettingsSelector('Cache Size', _cacheSize, () {}),
                      _buildDivider(),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        title: Text(
                          'Clear Cache',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                        ),
                        trailing: const Icon(LucideIcons.trash2, color: AppColors.error, size: 20),
                        onTap: () {
                          setState(() {
                            _cacheSize = '0 MB';
                          });
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
                child: GestureDetector(
                  onTap: () {
                    _versionTapCount++;
                    if (_versionTapCount >= 7) {
                      _versionTapCount = 0;
                      _showDeveloperBottomSheet();
                    } else if (_versionTapCount > 3) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('You are ${7 - _versionTapCount} steps away from being a developer.'),
                          duration: const Duration(seconds: 1),
                        )
                      );
                    }
                  },
                  child: Text(
                    'VYBE Version 1.0.0',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.5)),
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

  void _showSelectionModal(String title, List<String> options, String currentValue, Function(String) onSelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Select $title', style: AppTypography.headingSmall.copyWith(color: AppColors.textPrimary)),
              ),
              ...options.map((opt) => ListTile(
                title: Text(opt, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
                trailing: opt == currentValue ? const Icon(LucideIcons.check, color: AppColors.primary) : null,
                onTap: () {
                  onSelected(opt);
                  ctx.pop();
                },
              )),
              const SizedBox(height: 16),
            ],
          ),
        );
      }
    );
  }

  void _showDeveloperBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Developer Options', style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: 24),
              ListTile(
                title: const Text('Simulate Crash', style: TextStyle(color: AppColors.textPrimary)),
                leading: const Icon(LucideIcons.alertTriangle, color: AppColors.error),
                onTap: () {
                  ctx.pop();
                  throw Exception('Simulated Crash');
                },
              ),
              ListTile(
                title: const Text('Reset All Settings', style: TextStyle(color: AppColors.textPrimary)),
                leading: const Icon(LucideIcons.refreshCw, color: AppColors.textPrimary),
                onTap: () {
                  ctx.pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings Reset (Mock)')));
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }
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
