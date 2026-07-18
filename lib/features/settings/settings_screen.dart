import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/components/glass_container.dart';
import '../../providers/user_provider.dart';
import '../../core/components/ambient_background.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isUploading = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Account', style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: AmbientBackground(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.margin),
          children: [
            _buildSettingsTile(
              'Edit Profile', 
              LucideIcons.user, 
              () {
                final uid = Supabase.instance.client.auth.currentUser?.id;
                final profile = ref.read(userProfileProvider(uid ?? 'local')).valueOrNull;
                if (profile != null) {
                  _showEditProfileDialog(context, ref, profile);
                }
              }
            ),
            const SizedBox(height: 12),
            _buildSettingsTile(
              'Reset Password', 
              LucideIcons.lock, 
              () async {
                final email = Supabase.instance.client.auth.currentUser?.email;
                if (email != null) {
                  try {
                    await Supabase.instance.client.auth.resetPasswordForEmail(email);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent!')));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                }
              }
            ),
            const SizedBox(height: 12),
            _buildSettingsTile(
              'Change Email', 
              LucideIcons.mail, 
              () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please contact support to change your email.')));
              }
            ),
            const SizedBox(height: 12),
            _buildSettingsTile(
              'Connected Accounts', 
              LucideIcons.smartphone, 
              () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google/Apple integration coming soon!')));
              }
            ),
            const SizedBox(height: 32),
            _buildSettingsTile(
              'Sign Out', 
              LucideIcons.logOut, 
              () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) {
                  context.go('/auth');
                }
              },
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(String title, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return Material(
      color: isDestructive ? Colors.red.withValues(alpha: 0.1) : AppColors.card,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(icon, color: isDestructive ? Colors.red : AppColors.textPrimary, size: 24),
        title: Text(
          title,
          style: AppTypography.bodyMedium.copyWith(color: isDestructive ? Colors.red : AppColors.textPrimary),
        ),
        trailing: Icon(LucideIcons.chevronRight, color: isDestructive ? Colors.red.withValues(alpha: 0.5) : AppColors.textSecondary, size: 20),
        onTap: onTap,
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, dynamic profile) {
    final nameController = TextEditingController(text: profile.name);
    String selectedGender = profile.gender ?? 'Unspecified';
    String selectedAgeGroup = profile.ageGroup ?? '25-34';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: GlassContainer(
                padding: const EdgeInsets.all(24),
                borderRadius: 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Edit Profile', style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary)),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Name',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedGender,
                      dropdownColor: const Color(0xFF1E1E1E),
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Gender (Optional)',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                      items: ['Unspecified', 'Male', 'Female', 'Non-binary', 'Prefer not to say']
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedGender = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedAgeGroup,
                      dropdownColor: const Color(0xFF1E1E1E),
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Age Group (Optional)',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                      items: ['Under 18', '18-24', '25-34', '35-44', '45-54', '55+']
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedAgeGroup = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isUploading ? null : () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setModalState(() => _isUploading = true);
                          try {
                            final bytes = await pickedFile.readAsBytes();
                            final extension = pickedFile.name.split('.').last;
                            final userRepo = ref.read(userRepositoryProvider);
                            final uploadedUrl = await userRepo.uploadProfileImage(bytes, extension);
                            
                            if (uploadedUrl != null) {
                              final uid = Supabase.instance.client.auth.currentUser!.id;
                              final currentProfile = await ref.read(userRepositoryProvider).getProfile(uid).first;
                              if (currentProfile != null) {
                                await userRepo.updateProfile(currentProfile.copyWith(
                                  profileImageUrl: uploadedUrl,
                                  name: nameController.text,
                                  gender: selectedGender,
                                  ageGroup: selectedAgeGroup,
                                ));
                              }
                            }
                          } catch (e) {
                            debugPrint('Error uploading image: $e');
                          } finally {
                            setModalState(() => _isUploading = false);
                            if (ctx.mounted) ctx.pop();
                          }
                        }
                      },
                      icon: _isUploading 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(LucideIcons.camera),
                      label: Text(_isUploading ? 'Uploading...' : 'Update Picture'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.card,
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final uid = Supabase.instance.client.auth.currentUser!.id;
                          final currentProfile = await ref.read(userRepositoryProvider).getProfile(uid).first;
                          if (currentProfile != null) {
                            await ref.read(userRepositoryProvider).updateProfile(
                              currentProfile.copyWith(
                                name: nameController.text,
                                gender: selectedGender,
                                ageGroup: selectedAgeGroup,
                              ),
                            );
                          }
                          if (ctx.mounted) ctx.pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Save Changes', style: AppTypography.bodyMedium.copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }
}
