import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/services/gemini_service.dart';
import '../../providers/wardrobe_provider.dart';
import '../../providers/weather_provider.dart';
import '../../providers/user_provider.dart';
import '../../core/utils/analytics.dart';
import '../../core/components/glass_container.dart';
import '../../core/components/ambient_background.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final List<dynamic>? outfits;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.outfits,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'outfits': outfits,
    };
  }

  factory ChatMessage.fromJson(Map<dynamic, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      isUser: json['isUser'] as bool? ?? false,
      outfits: json['outfits'] as List<dynamic>?,
    );
  }
}

class AiStylistChatScreen extends ConsumerStatefulWidget {
  const AiStylistChatScreen({super.key});

  @override
  ConsumerState<AiStylistChatScreen> createState() => _AiStylistChatScreenState();
}

class _AiStylistChatScreenState extends ConsumerState<AiStylistChatScreen> {
  List<ChatMessage> _messages = [];

  final List<String> _suggestions = [
    '✨ Style me for college',
    '💼 Dress for an interview',
    '🎉 Pick a party outfit',
    '☔ Outfit for today\'s weather',
    '🧳 Pack for my trip',
    '👟 Style these sneakers',
    '🛍 Build a capsule wardrobe',
    '❤️ Plan my date night look'
  ];
  
  final List<String> _loadingPhrases = [
    'outfit gods fetching images 😎',
    'summoning the drip 💧',
    'cooking up some fresh looks 🍳',
    'analyzing the aura ✨',
    'finding your main character energy 🌟',
    'unlocking premium style 💎',
    'doing fashion math 🧮',
  ];
  int _currentPhraseIndex = 0;
  Timer? _phraseTimer;
  String _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (val) => debugPrint('onError: $val'),
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );
    setState(() {});
  }

  void _startListening() async {
    if (!_speechEnabled) {
      _initSpeech();
    }
    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _textController.text = result.recognizedWords;
        });
      },
    );
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }



  void _saveCurrentSession() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final box = Hive.box<Map>('chats_$uid');
      box.put(_sessionId, {
        'timestamp': DateTime.now().toIso8601String(),
        'messages': _messages.map((m) => m.toJson()).toList(),
      });
    } catch (e) {
      debugPrint('Error saving chat session: $e');
    }
  }

  void _showChatHistory() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    
    List<dynamic> keys = [];
    Box<Map>? box;
    try {
      box = Hive.box<Map>('chats_$uid');
      keys = box.keys.toList()..sort((a, b) => b.toString().compareTo(a.toString()));
    } catch (e) {
      debugPrint('Error reading history: $e');
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chat History', style: AppTypography.headingMedium.copyWith(color: Colors.white)),
              const SizedBox(height: 16),
              Expanded(
                child: keys.isEmpty || box == null
                    ? const Center(child: Text('No previous chats', style: TextStyle(color: Colors.grey)))
                    : _buildHistoryContent(keys, box),
              ),
              const SizedBox(height: 16),
              SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      setState(() {
                        _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
                        _messages = [];
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Start New Chat', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryContent(List<dynamic> keys, Box<Map> box) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final lastWeekStart = todayStart.subtract(const Duration(days: 7));

    List<Widget> today = [];
    List<Widget> yesterday = [];
    List<Widget> lastWeek = [];
    List<Widget> older = [];

    for (var key in keys) {
      final session = box.get(key);
      if (session == null) continue;
      
      final messages = session['messages'] as List<dynamic>? ?? [];
      if (messages.isEmpty) continue; // Skip empty chats
      final firstUserMsg = messages.firstWhere((m) => (m['isUser'] as bool?) == true, orElse: () => {'text': 'Stylist Session'});
      
      DateTime date = DateTime.fromMillisecondsSinceEpoch(0);
      try {
        date = DateTime.parse(session['timestamp'] as String? ?? '');
      } catch (_) {}
      
      final tile = ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(LucideIcons.messageSquare, color: AppColors.primary),
        title: Text(
          firstUserMsg['text'] as String? ?? 'Stylist Session',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white),
        ),
        onTap: () {
          setState(() {
            _sessionId = key.toString();
            _messages = messages.map((m) => ChatMessage.fromJson(m as Map)).toList();
          });
          Navigator.pop(context);
          _scrollToBottom();
        },
      );

      if (date.isAfter(todayStart) || date.isAtSameMomentAs(todayStart)) {
        today.add(tile);
      } else if (date.isAfter(yesterdayStart) || date.isAtSameMomentAs(yesterdayStart)) {
        yesterday.add(tile);
      } else if (date.isAfter(lastWeekStart) || date.isAtSameMomentAs(lastWeekStart)) {
        lastWeek.add(tile);
      } else {
        older.add(tile);
      }
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (today.isNotEmpty) ...[
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Today', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary))),
            ...today,
            const SizedBox(height: 16),
          ],
          if (yesterday.isNotEmpty) ...[
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Yesterday', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary))),
            ...yesterday,
            const SizedBox(height: 16),
          ],
          if (lastWeek.isNotEmpty) ...[
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Last Week', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary))),
            ...lastWeek,
            const SizedBox(height: 16),
          ],
          if (older.isNotEmpty) ...[
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Older', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary))),
            ...older,
          ],
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  void _sendSuggestion(String text) {
    _textController.text = text;
    _sendMessage();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        isUser: true,
      ));
      _isLoading = true;
      _currentPhraseIndex = 0;
    });

    _phraseTimer?.cancel();
    _phraseTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentPhraseIndex = (_currentPhraseIndex + 1) % _loadingPhrases.length;
        });
      }
    });
    
    _saveCurrentSession();
    _textController.clear();
    _scrollToBottom();

    try {
      final geminiService = ref.read(geminiServiceProvider);
      var wardrobe = ref.read(wardrobeItemsProvider).valueOrNull;
      if (wardrobe == null || wardrobe.isEmpty) {
        try {
          wardrobe = await ref.read(wardrobeItemsProvider.future);
        } catch (_) {}
      }
      wardrobe ??= [];
      
      if (wardrobe.isEmpty) {
        setState(() {
          _messages.add(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: "Your wardrobe is empty! Please add some items using the Magic Scan first.",
            isUser: false,
          ));
          _isLoading = false;
        });
        _scrollToBottom();
        return;
      }

      final weather = ref.read(currentWeatherProvider).valueOrNull;
      final weatherStr = weather != null ? "${weather.temperature}°C, ${weather.condition}" : null;
      
      final wardrobeJson = wardrobe.map((item) {
        final json = item.toJson();
        json.remove('imageUrl');
        json.remove('userId');
        json.remove('dateAdded');
        json.remove('lastWorn');
        return json;
      }).toList();

      final uid = Supabase.instance.client.auth.currentUser?.id ?? 'local';
      final profile = ref.read(userProfileProvider(uid)).valueOrNull;
      final styleBaseline = profile?.styleBaseline;

      final suggestion = await geminiService.generateOutfitRecommendation(
        text,
        wardrobeJson,
        weatherStr,
        styleBaseline,
      );

      if (mounted) {
        _phraseTimer?.cancel();
        setState(() {
          if (suggestion != null) {
            _messages.add(ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              text: suggestion['aiReasoning'] ?? "Here is what I recommend:",
              isUser: false,
              outfits: suggestion['outfits'] as List<dynamic>?,
            ));
          } else {
            _messages.add(ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              text: "Sorry, I couldn't generate a recommendation. Please try again.",
              isUser: false,
            ));
          }
          _isLoading = false;
        });
        _saveCurrentSession();
        _scrollToBottom();
      }
    } catch (e) {
      Analytics.logError('chat generation failed', e);
      if (mounted) {
        _phraseTimer?.cancel();
        setState(() {
          String errorText = "Oops, something went wrong. Please try again.";
          if (e is RateLimitException || e.toString().contains('RateLimit')) {
            errorText = "API Rate Limit Exceeded. Please try again in 30 seconds.";
          } else if (e.toString().contains('Failed to generate recommendation')) {
             errorText = "Sorry, I couldn't generate a recommendation. Please try again.";
          } else {
             errorText = "Oops, something went wrong: $e";
          }
          
          _messages.add(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: errorText,
            isUser: false,
          ));
          _isLoading = false;
        });
        _saveCurrentSession();
        _scrollToBottom();
      }
    }
  }

  @override
  void dispose() {
    _phraseTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wardrobe = ref.watch(wardrobeItemsProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary),
          onPressed: () => context.go('/home'),
        ),
        title: Text('AI Stylist', style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(LucideIcons.history, color: AppColors.textPrimary),
            onPressed: _showChatHistory,
          ),
        ],
      ),
      body: AmbientBackground(
        child: wardrobe.isEmpty
            ? _buildEmptyState()
            : _messages.isEmpty
                ? _buildHomeState()
                : Column(
                    children: [
                      Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(
                        left: AppSpacing.margin,
                        right: AppSpacing.margin,
                        top: 16,
                        bottom: 16,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageBubble(_messages[index]);
                      },
                    ),
                  ),
                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: Text(
                              _loadingPhrases[_currentPhraseIndex],
                              key: ValueKey<int>(_currentPhraseIndex),
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  _buildChatInput(),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.shirt, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Your wardrobe is empty',
              style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan your first item to start chatting with your AI Stylist.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/magic-scan'),
              icon: const Icon(LucideIcons.scan, color: Colors.black),
              label: const Text('Open Magic Scan', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeState() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                Text(
                  'AI Stylist',
                  style: AppTypography.headingLarge.copyWith(color: AppColors.textPrimary, fontSize: 32),
                ),
                const SizedBox(height: 8),
                Text(
                  'What should I wear today?',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 48),
                
                // Prompt Cards
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _suggestions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GestureDetector(
                        onTap: () {
                          _sendSuggestion(suggestion);
                        },
                        child: GlassContainer(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          borderRadius: 16,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  suggestion,
                                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                                ),
                              ),
                              Icon(LucideIcons.chevronRight, color: AppColors.textSecondary, size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        _buildChatInput(),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final align = message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bgColor = message.isUser ? AppColors.primary : Color(0xFF222222);
    final textColor = message.isUser ? Colors.black : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(20),
                bottomLeft: !message.isUser ? const Radius.circular(4) : const Radius.circular(20),
              ),
              boxShadow: !message.isUser
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Text(
              message.text,
              style: AppTypography.bodyMedium.copyWith(color: textColor),
            ),
          ),
          if (message.outfits != null && message.outfits!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: message.outfits!.map((outfit) => _buildOutfitCard(outfit)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOutfitCard(dynamic outfit) {
    final String title = outfit['title'] ?? 'Recommendation';
    final List<dynamic> itemIds = outfit['itemIds'] ?? [];
    
    // Fetch items from wardrobe
    final wardrobe = ref.read(wardrobeItemsProvider).valueOrNull ?? [];
    final items = wardrobe.where((item) => itemIds.contains(item.id)).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text('No items found.', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary))
          else
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Container(
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildItemImage(item.imageUrl),
                  );
                },
              ),
            ),
        ],
      ),
    ),
  );
}

  Widget _buildItemImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      final base64String = imageUrl.split(',').last;
      return Image.memory(
        base64Decode(base64String),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(LucideIcons.imageOff, color: AppColors.textSecondary),
      );
    } else if (imageUrl.startsWith('http') || imageUrl.startsWith('blob:')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(LucideIcons.imageOff, color: AppColors.textSecondary),
      );
    } else {
      return Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(LucideIcons.imageOff, color: AppColors.textSecondary),
      );
    }
  }

  Widget _buildChatInput() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        // Crucial fix: Add 100px of padding at the bottom to sit above the floating nav bar.
        // When the keyboard opens (bottomInset > 0), the Scaffold resizes, so we drop the padding.
        bottom: bottomInset > 0 ? 12 : (MediaQuery.of(context).padding.bottom + 100),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Visual Search coming soon! 📸')),
              );
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF2A2A2A),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.camera, color: AppColors.textSecondary, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF2A2A2A),
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ask me what to wear...',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isListening ? LucideIcons.micOff : LucideIcons.mic,
                      color: _isListening ? AppColors.primary : AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () {
                      if (!_speechEnabled) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Speech recognition not available or permission denied.')),
                        );
                        return;
                      }
                      if (_isListening) {
                        _stopListening();
                      } else {
                        _startListening();
                      }
                    },
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.send, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}