import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/services/gemini_service.dart';
import '../../core/components/glass_container.dart';
import '../../core/components/ambient_background.dart';

class PackingPlannerScreen extends ConsumerStatefulWidget {
  const PackingPlannerScreen({super.key});

  @override
  ConsumerState<PackingPlannerScreen> createState() => _PackingPlannerScreenState();
}

class _PackingPlannerScreenState extends ConsumerState<PackingPlannerScreen> {
  String _destination = 'Tokyo';
  String _duration = '7 Days';
  bool _isLoading = false;
  List<Map<String, dynamic>> _checklist = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generatePackingList();
    });
  }

  Future<void> _generatePackingList() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(geminiServiceProvider);
      final list = await service.generatePackingList(_destination, _duration);
      if (list != null && mounted) {
        setState(() {
          _checklist = list.map((e) => {
            'item': '${e['quantity']}x ${e['item']}',
            'checked': false,
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _promptNewTrip() async {
    final destController = TextEditingController(text: _destination);
    final durController = TextEditingController(text: _duration);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('New Trip', style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: destController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Destination', labelStyle: TextStyle(color: Colors.white54)),
            ),
            TextField(
              controller: durController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Duration (e.g. 7 Days)', labelStyle: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _destination = destController.text;
        _duration = durController.text;
      });
      _generatePackingList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary),
          onPressed: () => context.go('/home'),
        ),
        title: Text('Packing List', style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus, color: AppColors.textPrimary),
            onPressed: _promptNewTrip,
          ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Card
            GlassContainer(
              padding: EdgeInsets.zero,
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.flight_takeoff, color: AppColors.textSecondary.withValues(alpha: 0.3), size: 80),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_destination Trip',
                          style: AppTypography.headingLarge.copyWith(color: AppColors.textPrimary, fontSize: 28),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_duration • ${_checklist.length} Items',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
            
            const SizedBox(height: 32),
            
            Text(
              'AI Recommended',
              style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary),
            ),
            
            const SizedBox(height: 16),
            
            // Checklist
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _checklist.isEmpty
                    ? const Center(child: Text('No items to pack.', style: TextStyle(color: Colors.white54)))
                    : GlassContainer(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: _checklist.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final isChecked = item['checked'] as bool;
                            
                            return Padding(
                              padding: EdgeInsets.only(bottom: index == _checklist.length - 1 ? 0 : 20.0),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _checklist[index]['checked'] = !isChecked;
                                  });
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isChecked ? AppColors.success : Colors.transparent,
                                        border: Border.all(
                                          color: isChecked ? AppColors.success : AppColors.textSecondary,
                                          width: 2,
                                        ),
                                      ),
                                      child: isChecked
                                          ? const Icon(LucideIcons.check, color: Colors.black, size: 16)
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    
                                    // Thumbnail placeholder
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF222222),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.checkroom, color: AppColors.textSecondary, size: 20),
                                    ),
                                    
                                    const SizedBox(width: 16),
                                    
                                    Expanded(
                                      child: Text(
                                        item['item'] as String,
                                        style: AppTypography.bodyMedium.copyWith(
                                          color: isChecked ? AppColors.textPrimary : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
            
            const SizedBox(height: 32),
            
            // Save Button
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
                onPressed: () {},
                child: const Text('SAVE PACKING LIST'),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
