import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/services/gemini_service.dart';
import '../../providers/trip_provider.dart';
import '../../providers/wardrobe_provider.dart';
import '../../data/models/trip.dart';
import '../../core/components/glass_container.dart';
import '../../core/components/ambient_background.dart';

class TripPlannerScreen extends ConsumerStatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  ConsumerState<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends ConsumerState<TripPlannerScreen> {
  bool _isLoading = false;

  void _promptNewTrip() async {
    final destinationController = TextEditingController();
    final nameController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;
    String purpose = 'Vacation';
    final purposes = ['Vacation', 'Business', 'Wedding', 'College Tour', 'Trek'];

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.card,
            title: Text('Plan New Trip', style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Trip Name (e.g. Goa Trip)', labelStyle: TextStyle(color: Colors.white54)),
                  ),
                  TextField(
                    controller: destinationController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Destination', labelStyle: TextStyle(color: Colors.white54)),
                  ),
                  const SizedBox(height: 16),
                  Text('Dates', style: TextStyle(color: Colors.white70)),
                  InkWell(
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          startDate = picked.start;
                          endDate = picked.end;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.white24)),
                      ),
                      child: Text(
                        startDate == null ? 'Select Dates' : '${DateFormat('MMM d').format(startDate!)} - ${DateFormat('MMM d').format(endDate!)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: purpose,
                    dropdownColor: AppColors.card,
                    items: purposes.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(color: Colors.white)))).toList(),
                    onChanged: (v) => setState(() => purpose = v!),
                    decoration: const InputDecoration(labelText: 'Purpose', labelStyle: TextStyle(color: Colors.white54)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
                onPressed: () {
                  if (nameController.text.isNotEmpty && destinationController.text.isNotEmpty && startDate != null && endDate != null) {
                    Navigator.pop(ctx, true);
                  }
                },
                child: const Text('Generate AI Plan'),
              ),
            ],
          );
        }
      ),
    );

    if (result == true && mounted && startDate != null && endDate != null) {
      _generateAndSaveTrip(
        nameController.text,
        destinationController.text,
        startDate!,
        endDate!,
        purpose,
      );
    }
  }

  Future<void> _generateAndSaveTrip(String name, String destination, DateTime start, DateTime end, String purpose) async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(geminiServiceProvider);
      final wardrobe = ref.read(wardrobeItemsProvider).valueOrNull ?? [];
      
      final planData = await service.generateTripPlan(
        destination: destination,
        startDate: start,
        endDate: end,
        purpose: purpose,
        wardrobe: wardrobe,
      );

      final uid = Supabase.instance.client.auth.currentUser?.id ?? 'local';
      
      final tripDays = (planData['days'] as List).map((d) => TripDay(
        date: DateTime.parse(d['date']),
        weatherDescription: d['weatherDescription'] ?? '',
        outfitSuggestion: d['outfitSuggestion'] ?? '',
        mappedClothingItemIds: List<String>.from(d['mappedClothingItemIds'] ?? []),
        plannedActivities: List<String>.from(d['plannedActivities'] ?? []),
      )).toList();

      final packingList = (planData['packingList'] as List).map((p) => PackingItem(
        id: const Uuid().v4(),
        name: p['name'] ?? '',
        quantity: p['quantity'] ?? 1,
        category: p['category'],
        isMissing: p['isMissing'] ?? false,
      )).toList();

      final newTrip = Trip(
        id: const Uuid().v4(),
        userId: uid,
        name: name,
        destination: destination,
        startDate: start,
        endDate: end,
        purpose: purpose,
        weatherPreference: 'Auto Detect',
        days: tripDays,
        packingList: packingList,
      );

      await ref.read(tripRepositoryProvider).saveTrip(newTrip);

      if (mounted) {
        setState(() => _isLoading = false);
        context.push('/pack/trip/${newTrip.id}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating trip: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(tripsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AmbientBackground(
        child: SafeArea(
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    pinned: true,
                    expandedHeight: 120,
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                      title: Text('Upcoming Trips', style: AppTypography.headingLarge.copyWith(color: AppColors.textPrimary)),
                    ),
                  ),
                  tripsAsync.when(
                    data: (trips) {
                      if (trips.isEmpty) {
                        return SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(LucideIcons.plane, size: 64, color: Colors.white24),
                                const SizedBox(height: 16),
                                Text('No trips planned yet', style: AppTypography.bodyMedium.copyWith(color: Colors.white54)),
                              ],
                            ),
                          ),
                        );
                      }
                      return SliverPadding(
                        padding: const EdgeInsets.all(16.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final trip = trips[index];
                              final days = trip.endDate.difference(trip.startDate).inDays + 1;
                              final dateStr = '${DateFormat('MMM d').format(trip.startDate)} - ${DateFormat('MMM d').format(trip.endDate)}';
                              return GestureDetector(
                                onTap: () => context.push('/pack/trip/${trip.id}'),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: GlassContainer(
                                    padding: const EdgeInsets.all(20),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: const Icon(LucideIcons.plane, color: AppColors.primary, size: 32),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(trip.name, style: AppTypography.headingMedium.copyWith(color: Colors.white)),
                                              const SizedBox(height: 4),
                                              Text('$dateStr • $days Days', style: AppTypography.bodySmall.copyWith(color: Colors.white70)),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text('Ready', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                        ),
                                        const Icon(LucideIcons.chevronRight, color: Colors.white38),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: trips.length,
                          ),
                        ),
                      );
                    },
                    loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
                    error: (e, st) => SliverFillRemaining(child: Center(child: Text('Error loading trips', style: TextStyle(color: Colors.white)))),
                  ),
                ],
              ),
              if (_isLoading)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.primary),
                        const SizedBox(height: 20),
                        Text('Crafting your perfect trip plan...', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _promptNewTrip,
        backgroundColor: AppColors.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.black),
        label: const Text('Plan New Trip', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
