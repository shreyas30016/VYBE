import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/trip_provider.dart';
import '../../../data/models/trip.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/ambient_background.dart';

class TripCalendarScreen extends ConsumerStatefulWidget {
  final String tripId;
  const TripCalendarScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripCalendarScreen> createState() => _TripCalendarScreenState();
}

class _TripCalendarScreenState extends ConsumerState<TripCalendarScreen> {
  int _selectedDayIndex = 0;
  bool _isPackingView = false;

  Future<void> _addToGoogleCalendar(Trip trip) async {
    final start = DateFormat("yyyyMMdd'T'HHmmss'Z'").format(trip.startDate.toUtc());
    final end = DateFormat("yyyyMMdd'T'HHmmss'Z'").format(trip.endDate.toUtc().add(const Duration(days: 1)));
    
    final details = 'Planned with VYBE AI Stylist.';
    final urlStr = 'https://calendar.google.com/calendar/render?action=TEMPLATE&text=${Uri.encodeComponent(trip.name)}&dates=$start/$end&details=${Uri.encodeComponent(details)}&location=${Uri.encodeComponent(trip.destination)}';
    
    final uri = Uri.parse(urlStr);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open Google Calendar')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(tripsProvider);

    return tripsAsync.when(
      data: (trips) {
        final trip = trips.firstWhere((t) => t.id == widget.tripId, orElse: () => throw Exception('Trip not found'));
        return Scaffold(
          backgroundColor: AppColors.background,
          body: AmbientBackground(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, trip),
                  _buildTabs(),
                  Expanded(
                    child: _isPackingView ? _buildPackingList(trip) : _buildTimeline(trip),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, st) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Error loading trip', style: TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Trip trip) {
    final daysCount = trip.endDate.difference(trip.startDate).inDays + 1;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Text(trip.name, style: AppTypography.headingMedium.copyWith(color: Colors.white), overflow: TextOverflow.ellipsis),
              ),
              IconButton(
                icon: Icon(LucideIcons.calendarPlus, color: AppColors.primary),
                onPressed: () => _addToGoogleCalendar(trip),
                tooltip: 'Add to Google Calendar',
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text('${trip.destination} • $daysCount Days', style: AppTypography.bodyMedium.copyWith(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isPackingView = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isPackingView ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: !_isPackingView ? AppColors.primary : Colors.white24),
                ),
                alignment: Alignment.center,
                child: Text('Timeline', style: TextStyle(color: !_isPackingView ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isPackingView = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isPackingView ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _isPackingView ? AppColors.primary : Colors.white24),
                ),
                alignment: Alignment.center,
                child: Text('Checklist', style: TextStyle(color: _isPackingView ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(Trip trip) {
    if (trip.days.isEmpty) return const Center(child: Text('No timeline available.', style: TextStyle(color: Colors.white)));
    
    final currentDay = trip.days[_selectedDayIndex];

    return Column(
      children: [
        const SizedBox(height: 16),
        // Days horizontal selector
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: trip.days.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final day = trip.days[index];
              final isSelected = index == _selectedDayIndex;
              return GestureDetector(
                onTap: () => setState(() => _selectedDayIndex = index),
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Day ${index + 1}', style: TextStyle(color: isSelected ? AppColors.primary : Colors.white54, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(DateFormat('d MMM').format(day.date), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weather Card
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(LucideIcons.cloudSun, color: AppColors.primary, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Expected Weather', style: AppTypography.bodySmall.copyWith(color: Colors.white70)),
                            const SizedBox(height: 4),
                            Text(currentDay.weatherDescription.isNotEmpty ? currentDay.weatherDescription : 'Auto-detected by AI', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Suggested Outfit', style: AppTypography.headingSmall.copyWith(color: Colors.white)),
                const SizedBox(height: 12),
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.sparkles, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text('AI Stylist Choice', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(currentDay.outfitSuggestion, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
                      if (currentDay.plannedActivities.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 8),
                        Text('Planned for: ${currentDay.plannedActivities.join(', ')}', style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPackingList(Trip trip) {
    if (trip.packingList.isEmpty) return const Center(child: Text('No items to pack.', style: TextStyle(color: Colors.white)));

    final ownedItems = trip.packingList.where((p) => !p.isMissing).toList();
    final missingItems = trip.packingList.where((p) => p.isMissing).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (missingItems.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.alertTriangle, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 8),
                      Text('Missing Essentials', style: AppTypography.headingSmall.copyWith(color: Colors.redAccent)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...missingItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.shoppingBag, color: Colors.white54, size: 16),
                        const SizedBox(width: 12),
                        Expanded(child: Text('${item.quantity}x ${item.name}', style: const TextStyle(color: Colors.white))),
                        Icon(LucideIcons.externalLink, color: AppColors.primary, size: 16),
                      ],
                    ),
                  )).toList(),
                  const SizedBox(height: 8),
                  Text('Tap items to shop via affiliate partners (Coming Soon)', style: TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          Text('From Your Wardrobe', style: AppTypography.headingSmall.copyWith(color: Colors.white)),
          const SizedBox(height: 12),
          GlassContainer(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: ownedItems.map((item) => CheckboxListTile(
                value: item.isPacked,
                onChanged: (val) {
                  // In a real app we'd update the item via tripRepository
                  // Skipping deep state update for brevity in hackathon
                },
                title: Text('${item.quantity}x ${item.name}', style: TextStyle(color: Colors.white, decoration: item.isPacked ? TextDecoration.lineThrough : null)),
                activeColor: AppColors.primary,
                checkColor: Colors.black,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
