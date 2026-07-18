import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/image_utils.dart';
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
  bool _isSearching = false;
  String _searchQuery = '';
  String? _selectedSeason;
  String? _selectedColor;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = ['All', 'Tops', 'Bottoms', 'Outerwear', 'Shoes'];
  final List<String> _seasons = ['Summer', 'Winter', 'Spring', 'Fall', 'All Season'];
  // Colors are generated dynamically now

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search items...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              )
            : Text('Wardrobe', style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? LucideIcons.x : LucideIcons.search, color: AppColors.textPrimary),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: Icon(LucideIcons.slidersHorizontal, color: (_selectedSeason != null || _selectedColor != null) ? AppColors.primary : AppColors.textPrimary),
            onPressed: () {
              final items = ref.read(wardrobeItemsProvider).valueOrNull ?? [];
              _showFilterSheet(items);
            },
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
                  Icon(LucideIcons.wifiOff, size: 12, color: AppColors.warning),
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
              data: (rawItems) {
                final items = rawItems.where((item) {
                  if (_searchQuery.isNotEmpty) {
                    final query = _searchQuery.toLowerCase();
                    if (!item.category.toLowerCase().contains(query) &&
                        !(item.color?.toLowerCase().contains(query) ?? false) &&
                        !(item.subtype?.toLowerCase().contains(query) ?? false)) {
                      return false;
                    }
                  }
                  if (_selectedSeason != null && item.season != _selectedSeason) return false;
                  if (_selectedColor != null && item.color != _selectedColor) return false;
                  return true;
                }).toList();

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
                      '${(item.confidence * 100).round()}%',
                      _formatLastWorn(item.lastWorn, item.dateAdded),
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
    return GestureDetector(
      onLongPress: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.card,
            title: const Text('Delete Item', style: TextStyle(color: Colors.white)),
            content: const Text('Are you sure you want to delete this item from your wardrobe?', style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              ),
              TextButton(
                onPressed: () {
                  ref.read(wardrobeRepositoryProvider).deleteItem(item.id);
                  Navigator.of(context).pop();
                },
                child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        );
      },
      child: GlassContainer(
        enableBlur: false,
        padding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Image Placeholder
            Positioned.fill(
              child: Image(
                image: ImageUtils.getImageProvider(item.imageUrl),
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
              lastWorn,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  String _formatLastWorn(DateTime? lastWorn, DateTime dateAdded) {
    if (lastWorn == null) {
      final days = DateTime.now().difference(dateAdded).inDays;
      if (days == 0) return 'Added today';
      if (days == 1) return 'Added yesterday';
      return 'Added ${days}d ago';
    }
    
    final days = DateTime.now().difference(lastWorn).inDays;
    if (days == 0) return 'Worn today';
    if (days == 1) return 'Worn yesterday';
    return 'Worn ${days}d ago';
  }

  void _showFilterSheet(List<ClothingItem> items) {
    final Set<String> dynamicColors = {'Black', 'White', 'Blue', 'Red', 'Green', 'Brown', 'Grey', 'Navy'};
    for (var item in items) {
      if (item.color != null && item.color!.isNotEmpty) {
        final c = item.color!.trim();
        if (c.isNotEmpty) {
           dynamicColors.add(c[0].toUpperCase() + c.substring(1).toLowerCase());
        }
      }
    }
    final allColors = dynamicColors.toList()..sort();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true, // Allow it to be taller if needed
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filters', style: AppTypography.headingMedium.copyWith(color: Colors.white)),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedSeason = null;
                            _selectedColor = null;
                          });
                          setState(() {
                            _selectedSeason = null;
                            _selectedColor = null;
                          });
                        },
                        child: Text('Clear All', style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Season', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _seasons.map((season) {
                      final isSelected = _selectedSeason == season;
                      return ChoiceChip(
                        label: Text(season, style: TextStyle(color: isSelected ? Colors.black : Colors.white)),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.black45,
                        onSelected: (val) {
                          setModalState(() => _selectedSeason = val ? season : null);
                          setState(() => _selectedSeason = val ? season : null);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text('Color', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allColors.map((color) {
                      final isSelected = _selectedColor == color;
                      return ChoiceChip(
                        label: Text(color, style: TextStyle(color: isSelected ? Colors.black : Colors.white)),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.black45,
                        onSelected: (val) {
                          setModalState(() => _selectedColor = val ? color : null);
                          setState(() => _selectedColor = val ? color : null);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(height: 16 + AppSpacing.bottomNavClearance),
                ],
              ),
            );
          },
        );
      },
    );
  }
}