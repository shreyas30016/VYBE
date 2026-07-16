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
import '../../core/utils/analytics.dart';
import '../../core/components/glass_container.dart';
import '../../core/components/ambient_background.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  List<ChatMessage> _messages = [
    ChatMessage(
      id: '0',
      text: "Hey there! I'm your AI Stylist. Tell me what you're dressing for (e.g., 'I have a dinner date tonight' or 'What should I wear to the office tomorrow?').",
      isUser: false,
    ),
  ];
  
  bool _showSuggestions = true;
  final List<String> _suggestions = [
    'Work',
    'College',
    'Date',
    'Party',
    'Travel',
    'Gym',
    'Build today\'s outfit'
  ];
  
  final List<String> _loadingPhrases = [
    'Consulting the outfit gods...',
    'Vibing with your wardrobe...',
    'Finding the perfect drip...',
    'Slaying this look...',
    'Loading the drip...',
    'Checking the aesthetics...',
  ];
  String _currentLoadingPhrase = 'Consulting the outfit gods...';
  String _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSession();
  }

  void _loadCurrentSession() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final box = Hive.box<Map>('chats_$uid');
      if (box.isNotEmpty) {
        final keys = box.keys.toList()..sort();
        final lastKey = keys.last;
        final sessionData = box.get(lastKey);
        if (sessionData != null) {
          final messagesData = sessionData['messages'] as List<dynamic>? ?? [];
          if (messagesData.isNotEmpty) {
            setState(() {
              _sessionId = lastKey.toString();
              _messages = messagesData.map((m) => ChatMessage.fromJson(m as Map)).toList();
              _showSuggestions = _messages.length <= 1;
            });
            _scrollToBottom();
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading chat session: $e');
    }
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
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chat History', style: AppTypography.headingMedium.copyWith(color: Colors.white)),
              const SizedBox(height: 16),
              Expanded(
                child: keys.isEmpty || box == null
                    ? const Center(child: Text('No previous chats', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: keys.length,
                        itemBuilder: (context, index) {
                          final key = keys[index];
                          final session = box!.get(key);
                          final messages = session?['messages'] as List<dynamic>? ?? [];
                          final firstUserMsg = messages.firstWhere((m) => (m['isUser'] as bool?) == true, orElse: () => {'text': 'New Chat'});
                          
                          DateTime? date;
                          try {
                            date = DateTime.parse(session?['timestamp'] as String? ?? '');
                          } catch (_) {}
                          
                          final dateStr = date != null ? '\${date.month}/\${date.day}/\${date.year}' : '';
                          
                          return ListTile(
                            leading: const Icon(LucideIcons.messageSquare, color: AppColors.primary),
                            title: Text(
                              firstUserMsg['text'] as String? ?? 'Chat',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              dateStr,
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                            onTap: () {
                              setState(() {
                                _sessionId = key.toString();
                                _messages = messages.map((m) => ChatMessage.fromJson(m as Map)).toList();
                                _showSuggestions = _messages.length <= 1;
                              });
                              Navigator.pop(context);
                              _scrollToBottom();
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    setState(() {
                      _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
                      _messages = [
                        ChatMessage(
                          id: '0',
                          text: "Hey there! I'm your AI Stylist. Tell me what you're dressing for (e.g., 'I have a dinner date tonight' or 'What should I wear to the office tomorrow?').",
                          isUser: false,
                        ),
                      ];
                      _showSuggestions = true;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Start New Chat', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
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
      _showSuggestions = false;
      _currentLoadingPhrase = (_loadingPhrases.toList()..shuffle()).first;
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        isUser: true,
      ));
      _isLoading = true;
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
      
      final wardrobeJson = wardrobe.map((item) => item.toJson()).toList();

      final suggestion = await geminiService.generateOutfitRecommendation(
        text,
        wardrobeJson,
        weatherStr,
      );

      if (mounted) {
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
        setState(() {
          _messages.add(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: "Oops, something went wrong: $e",
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
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary),
          onPressed: () => context.go('/home'),
        ),
        title: Text('AI Stylist', style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.history, color: AppColors.textPrimary),
            onPressed: _showChatHistory,
          ),
        ],
      ),
      body: AmbientBackground(
        child: wardrobe.isEmpty
            ? _buildEmptyState()
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
                      itemCount: _messages.length + (_showSuggestions ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < _messages.length) {
                          return _buildMessageBubble(_messages[index]);
                        } else {
                          return _buildSuggestionChips();
                        }
                      },
                    ),
                  ),
                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(_currentLoadingPhrase, style: const TextStyle(color: AppColors.textSecondary)),
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
            const Icon(LucideIcons.shirt, size: 64, color: AppColors.textSecondary),
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

  Widget _buildSuggestionChips() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What are you dressing for?',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((suggestion) {
              return GestureDetector(
                onTap: () => _sendSuggestion(suggestion),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    suggestion,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final align = message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bgColor = message.isUser ? AppColors.primary : const Color(0xFF222222);
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
        errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.imageOff, color: AppColors.textSecondary),
      );
    } else if (imageUrl.startsWith('http') || imageUrl.startsWith('blob:')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.imageOff, color: AppColors.textSecondary),
      );
    } else {
      return Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.imageOff, color: AppColors.textSecondary),
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
            onTap: () {}, // Optional image attachment for later
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF2A2A2A),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.camera, color: AppColors.textSecondary, size: 20),
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
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  suffixIcon: IconButton(
                    icon: const Icon(LucideIcons.mic, color: AppColors.textSecondary, size: 20),
                    onPressed: () {}, // Optional voice input for later
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
              decoration: const BoxDecoration(
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