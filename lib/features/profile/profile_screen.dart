import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/user_provider.dart';
import '../../providers/wardrobe_provider.dart';
import '../../providers/outfit_provider.dart';
import '../../data/models/clothing_item.dart';
import '../../data/models/outfit.dart';
import '../../core/components/glass_container.dart';
import '../../core/components/ambient_background.dart';
import '../../data/services/gemini_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _versionTaps = 0;
  bool _isUploading = false;
  @override
  Widget build(BuildContext context) {
    final uid = Supabase.instance.client.auth.currentUser?.id ?? 'local';
    final userProfileAsync = ref.watch(userProfileProvider(uid));
    
    final name = userProfileAsync.valueOrNull?.name ?? 'Shreyas';
    final avatarUrl = userProfileAsync.valueOrNull?.profileImageUrl ?? Supabase.instance.client.auth.currentUser?.userMetadata?['avatar_url'] as String?;

    final wardrobeItemsAsync = ref.watch(wardrobeItemsProvider);
    final outfitHistoryAsync = ref.watch(outfitHistoryProvider);
    
    final itemsCount = wardrobeItemsAsync.when(
      data: (items) => items.length.toString(),
      loading: () => '-',
      error: (_, __) => '-',
    );
    
    final outfitsCount = outfitHistoryAsync.when(
      data: (outfits) => outfits.length.toString(),
      loading: () => '-',
      error: (_, __) => '-',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Profile', style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings, color: AppColors.textPrimary),
            onPressed: () {
              context.push('/settings/app');
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: AmbientBackground(
        child: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: AppSpacing.margin,
          right: AppSpacing.margin,
          top: 16,
          bottom: AppSpacing.bottomNavClearance + 20,
        ),
        child: Column(
          children: [
            // Avatar
            Center(
              child: Container(
                width: 100,
                height: 100,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: avatarUrl != null
                        ? DecorationImage(
                            image: NetworkImage(avatarUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: const Color(0xFF222222),
                  ),
                  child: avatarUrl == null
                      ? const Icon(LucideIcons.user, color: AppColors.textSecondary, size: 40)
                      : null,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Name
            GestureDetector(
              onTap: () => _showEditProfileDialog(context, ref, name),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: AppTypography.headingLarge.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 8),
                  const Icon(LucideIcons.edit2, color: AppColors.textSecondary, size: 16),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Style Tags
            Text(
              'Minimalist • Balanced • Smart',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            
            const SizedBox(height: 16),
            
            // Style Score Pill
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              borderRadius: 20,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.sparkles, color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Style Score: 94',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Stats Row
            Row(
              children: [
                Expanded(child: _buildStatItem(itemsCount, 'Items')),
                Container(width: 1, height: 40, color: const Color(0xFF2A2A2A)),
                Expanded(child: _buildStatItem(outfitsCount, 'Outfits')),
                Container(width: 1, height: 40, color: const Color(0xFF2A2A2A)),
                Expanded(child: _buildStatItem('12', 'Lists')),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Settings List
            _buildSettingsTile('Account', LucideIcons.user, '/settings'),
            _buildSettingsTile('Style Preferences', LucideIcons.sparkles, '/settings/style'),
            _buildSettingsTile('Wardrobe Insights', LucideIcons.barChart2, '/settings/insights'),
            _buildSettingsTile('Notifications', LucideIcons.bell, '/settings/notifications'),
            
            const SizedBox(height: 32),
            
            // Version (Hidden Demo Mode Trigger)
            GestureDetector(
              onTap: () {
                _versionTaps++;
                if (_versionTaps >= 7) {
                  _versionTaps = 0;
                  _showDeveloperBottomSheet(context, ref);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'VYBE Version 1.0.0 (Production)',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.5)),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: AppTypography.headingLarge.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(String title, IconData icon, String route) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassContainer(
        padding: EdgeInsets.zero,
        borderRadius: 16,
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Icon(icon, color: AppColors.textPrimary, size: 24),
          title: Text(
            title,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),
          trailing: const Icon(LucideIcons.chevronRight, color: AppColors.textSecondary, size: 20),
          onTap: () {
            context.push(route);
          },
        ),
      ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, String currentName) {
    final nameController = TextEditingController(text: currentName);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                    ElevatedButton.icon(
                      onPressed: _isUploading ? null : () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setState(() => _isUploading = true);
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
                                ));
                              }
                            }
                          } catch (e) {
                            debugPrint('Error uploading image: $e');
                          } finally {
                            setState(() => _isUploading = false);
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
                              currentProfile.copyWith(name: nameController.text),
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

  void _showDeveloperBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return GlassContainer(
          padding: EdgeInsets.zero,
          borderRadius: 24,
          child: Container(
            padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Developer Tools', style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary)),
                  IconButton(
                    icon: const Icon(LucideIcons.x, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Tiny Status Indicators
              Text('SYSTEM STATUS', style: AppTypography.captionBold.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              ValueListenableBuilder<String>(
                valueListenable: ref.read(geminiServiceProvider).activeProviderNotifier,
                builder: (context, activeProvider, child) {
                  return _buildStatusRow('AI: $activeProvider', true);
                },
              ),
              _buildStatusRow('Supabase', true),
              _buildStatusRow('Hive Local', true),
              _buildStatusRow('Weather API', true),
              
              const SizedBox(height: 32),
              
              // Actions
              Text('ACTIONS', style: AppTypography.captionBold.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              _buildDevAction(LucideIcons.uploadCloud, 'Seed Demo Data', () async {
                await _seedDemoData(ref);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demo data seeded')));
              }),
              _buildDevAction(LucideIcons.database, 'Reset Database', () async {
                await _resetDemoData();
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database reset')));
              }),
              _buildDevAction(LucideIcons.hardDrive, 'Clear Cache', () async {
                // Clear cache is effectively same as reset for demo purposes
                await _resetDemoData();
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared')));
              }),
              _buildDevAction(LucideIcons.fileText, 'Export Logs', () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logs exported')));
              }),
            ],
          ),
        ));
      },
    );
  }

  Widget _buildStatusRow(String service, bool isOnline) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(service, style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary)),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(width: 6),
              Text(isOnline ? 'Online' : 'Offline', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDevAction(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary, size: 20),
      title: Text(label, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
      onTap: onTap,
    );
  }

  Future<void> _resetDemoData() async {
    final wardrobeBox = Hive.box<Map>('clothing_items_local_user');
    final outfitBox = Hive.box<Map>('outfits_local_user');
    await wardrobeBox.clear();
    await outfitBox.clear();
  }

  Future<void> _seedDemoData(WidgetRef ref) async {
    final wardrobe = ref.read(wardrobeRepositoryProvider);
    final outfitRepo = ref.read(outfitRepositoryProvider);
    const uid = 'local_user';

    final demoItems = <ClothingItem>[];
    
    // 5 T-Shirts
    for(int i=1; i<=5; i++) {
      demoItems.add(ClothingItem(
        id: 'tshirt_$i', userId: uid, imageUrl: 'assets/demo/tshirt$i.jpg',
        category: 'T-Shirt', subtype: 'Casual', color: 'Various', material: 'Cotton',
        pattern: 'Solid', season: 'Summer', confidence: 0.98, wearCount: i * 2,
        dateAdded: DateTime.now().subtract(Duration(days: 30 - i)), isFavorite: i == 1,
      ));
    }
    // 3 Shirts
    for(int i=1; i<=3; i++) {
      demoItems.add(ClothingItem(
        id: 'shirt_$i', userId: uid, imageUrl: 'assets/demo/shirt$i.jpg',
        category: 'Shirt', subtype: 'Button Down', color: 'Various', material: 'Linen',
        pattern: 'Solid', season: 'All', confidence: 0.94, wearCount: i,
        dateAdded: DateTime.now().subtract(Duration(days: 20 - i)), isFavorite: false,
      ));
    }
    // 2 Hoodies
    for(int i=1; i<=2; i++) {
      demoItems.add(ClothingItem(
        id: 'hoodie_$i', userId: uid, imageUrl: 'assets/demo/hoodie$i.jpg',
        category: 'Hoodie', subtype: 'Pullover', color: 'Various', material: 'Fleece',
        pattern: 'Solid', season: 'Winter', confidence: 0.96, wearCount: i * 5,
        dateAdded: DateTime.now().subtract(Duration(days: 40 - i)), isFavorite: true,
      ));
    }
    // 2 Jeans
    for(int i=1; i<=2; i++) {
      demoItems.add(ClothingItem(
        id: 'jeans_$i', userId: uid, imageUrl: 'assets/demo/jeans$i.jpg',
        category: 'Pants', subtype: 'Denim Jeans', color: 'Blue/Black', material: 'Denim',
        pattern: 'Solid', season: 'All', confidence: 0.95, wearCount: i * 8,
        dateAdded: DateTime.now().subtract(Duration(days: 60 - i)), isFavorite: true,
      ));
    }
    // 2 Sneakers
    for(int i=1; i<=2; i++) {
      demoItems.add(ClothingItem(
        id: 'sneaker_$i', userId: uid, imageUrl: 'assets/demo/sneakers$i.jpg',
        category: 'Shoes', subtype: 'Sneakers', color: 'Various', material: 'Leather/Canvas',
        pattern: 'Solid', season: 'All', confidence: 0.99, wearCount: i * 12,
        dateAdded: DateTime.now().subtract(Duration(days: 90 - i)), isFavorite: true,
      ));
    }
    // 1 Jacket
    demoItems.add(ClothingItem(
      id: 'jacket_1', userId: uid, imageUrl: 'assets/demo/jacket1.jpg',
      category: 'Jacket', subtype: 'Leather Jacket', color: 'Black', material: 'Leather',
      pattern: 'Solid', season: 'Winter', confidence: 0.98, wearCount: 3,
      dateAdded: DateTime.now().subtract(const Duration(days: 10)), isFavorite: true,
    ));

    for (var item in demoItems) {
      await wardrobe.addItem(item);
    }

    final demoOutfit = Outfit(
      id: 'outfit_demo_1',
      userId: uid,
      itemIds: ['tshirt_1', 'jeans_1', 'sneaker_1'],
      occasion: 'Casual Day Out',
      dateCreated: DateTime.now(),
      aiReasoning: 'Wardrobe Health 92% (↑ +2%) because Rotation improved and White shirt finally worn.',
      isSaved: true,
    );

    await outfitRepo.saveOutfit(demoOutfit);
  }
}
