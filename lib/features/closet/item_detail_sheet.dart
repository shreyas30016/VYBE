import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/image_utils.dart';
import '../../core/components/glass_container.dart';
import '../../core/components/ghost_button.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/clothing_item.dart';
import '../../providers/wardrobe_provider.dart';
import '../../core/theme/app_theme.dart';

class ItemDetailSheet extends ConsumerWidget {
  final ClothingItem item;

  const ItemDetailSheet({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassContainer(
      borderRadius: AppSpacing.radiusCard,
      padding: EdgeInsets.zero,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image header
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: context.background,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusCard)),
                  image: item.imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: ImageUtils.getImageProvider(item.imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: item.imageUrl.isEmpty
                    ? Center(
                        child: Icon(
                          Icons.checkroom,
                          size: 64,
                          color: context.textMuted,
                        ),
                      )
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.subtype != null ? '${item.subtype} (${item.category})' : item.category,
                          style: AppTypography.headingMedium,
                        ),
                        IconButton(
                          icon: Icon(
                            item.isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: item.isFavorite ? context.accent : context.textMuted,
                          ),
                          onPressed: () {
                            ref
                                .read(wardrobeRepositoryProvider)
                                .toggleFavorite(item.id, !item.isFavorite);
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    // Details Grid
                    _buildDetailRow('Color', item.color ?? 'Unknown'),
                    if (item.subtype != null) _buildDetailRow('Subtype', item.subtype!),
                    _buildDetailRow('Material', item.material ?? 'Unknown'),
                    _buildDetailRow('Pattern', item.pattern ?? 'Unknown'),
                    _buildDetailRow('Season', item.season),
                    _buildDetailRow('Wear Count', '${item.wearCount}x'),
                    _buildDetailRow('Added', '${item.dateAdded.year}-${item.dateAdded.month}-${item.dateAdded.day}'),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Matches well with (Placeholder)
                    Text(
                      'Matches well with',
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // TODO: Deferred - Real matching logic comes with AI Stylist in a later phase
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: context.background,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                      ),
                      child: Center(
                        child: Text(
                          '[AI Match Placeholder]',
                          style: AppTypography.bodySmall,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Delete Button
                    GhostButton(
                      label: 'Delete Item',
                      onPressed: () {
                        ref.read(wardrobeRepositoryProvider).deleteItem(item.id);
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(height: AppSpacing.md), // Bottom padding for safe area
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.bodySmall),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value, 
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}