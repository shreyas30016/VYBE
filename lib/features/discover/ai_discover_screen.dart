import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_typography.dart';
import '../../core/components/bento_card.dart';
import '../../providers/wardrobe_provider.dart';
import '../../data/services/gemini_service.dart';
import '../../core/theme/app_theme.dart';

final gapAnalysisProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final wardrobeItems = await ref.watch(wardrobeItemsProvider.future);
  
  if (wardrobeItems.length < 5) {
    return {"error": "not_enough_data"};
  }
  
  final List<Map<String, dynamic>> itemsForGemini = wardrobeItems.map((item) {
    return {
      "category": item.category,
      "color": item.color,
      "material": item.material,
      "pattern": item.pattern,
      "season": item.season,
    };
  }).toList();
  
  final geminiService = ref.read(geminiServiceProvider);
  return await geminiService.generateGapAnalysis(itemsForGemini);
});

class AiDiscoverScreen extends ConsumerStatefulWidget {
  const AiDiscoverScreen({super.key});

  @override
  ConsumerState<AiDiscoverScreen> createState() => _AiDiscoverScreenState();
}

class _AiDiscoverScreenState extends ConsumerState<AiDiscoverScreen> {
  
  void _openShopLink(String category) async {
    final query = Uri.encodeComponent(category);
    final url = Uri.parse('https://www.google.com/search?tbm=shop&q=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open shop link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysisAsync = ref.watch(gapAnalysisProvider);

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        title: Text('AI Discover', style: AppTypography.headingMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: analysisAsync.when(
        loading: () => const _MatrixLoader(),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error analyzing gaps', style: AppTypography.bodyMedium.copyWith(color: context.accent)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(gapAnalysisProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) {
          if (data == null) {
            return Center(
              child: Text('Failed to generate analysis', style: AppTypography.bodyMedium.copyWith(color: context.textMuted)),
            );
          }
          
          if (data['error'] == 'not_enough_data') {
            return _buildNotEnoughData();
          }

          final headline = data['gapHeadline'] as String? ?? 'Analysis Complete';
          final reasoning = data['gapReasoning'] as String? ?? '';
          final suggestedItem = data['suggestedItemCategory'] as String? ?? 'Essentials';

          return _buildAnalysisContent(headline, reasoning, suggestedItem);
        },
      ),
    );
  }
  
  Widget _buildNotEnoughData() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: context.textMuted),
            const SizedBox(height: 24),
            Text(
              'Not enough data yet.',
              style: AppTypography.headingMedium.copyWith(color: context.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Scan a few more items so I can spot the gaps in your closet.',
              style: AppTypography.bodyMedium.copyWith(color: context.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisContent(String headline, String reasoning, String suggestedItem) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        BentoCard(
          child: Stack(
            children: [
              Positioned(
                right: -60,
                top: -60,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.accent.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: AppTypography.headingMedium.copyWith(fontSize: 20, color: context.accent, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      reasoning,
                      style: AppTypography.bodyMedium.copyWith(fontSize: 15, height: 1.5, color: context.textPrimary),
                    ),
                    const SizedBox(height: 24),

                    InkWell(
                      onTap: () => _openShopLink(suggestedItem),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: context.primary),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Shop $suggestedItem',
                              style: AppTypography.buttonLabel.copyWith(color: context.primary),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 18, color: context.primary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MatrixLoader extends StatefulWidget {
  const _MatrixLoader();

  @override
  State<_MatrixLoader> createState() => _MatrixLoaderState();
}

class _MatrixLoaderState extends State<_MatrixLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.background,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Text(
                'ANALYZING GAPS...',
                style: AppTypography.headingMedium.copyWith(
                  letterSpacing: 4,
                  color: Color.lerp(context.textMuted, context.primary, _controller.value),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
