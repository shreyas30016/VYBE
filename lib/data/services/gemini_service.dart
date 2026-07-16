import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../core/utils/analytics.dart';

final geminiServiceProvider = Provider((ref) => GeminiService());

class GeminiService {
  Future<Map<String, dynamic>?> analyzeClothingImage(XFile file) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY is missing');
      }

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      // Read image
      Uint8List imageBytes = await file.readAsBytes();

      // Compress if not on Web (flutter_image_compress has limited web support)
      if (!kIsWeb) {
        try {
          final compressed = await FlutterImageCompress.compressWithList(
            imageBytes,
            minWidth: 800,
            minHeight: 800,
            quality: 80,
          );
          if (compressed.isNotEmpty) {
            imageBytes = compressed;
          }
        } catch (e) {
          debugPrint('Compression failed, using original: $e');
        }
      }

      final prompt = TextPart('''
        Analyze this clothing or accessory item. Return ONLY a valid JSON object with no markdown formatting or extra text.
        The JSON must match this structure exactly:
        {
          "category": "String (e.g. Tops, Bottoms, Outerwear, Footwear, Accessories)",
          "subtype": "String (e.g. Watch, Bracelet, Bag, Belt, Necklace, Sunglasses) or null if not an accessory",
          "color": "String (e.g. Navy Blue, Red)",
          "material": "String (e.g. Cotton, Denim) or null",
          "pattern": "String (e.g. Solid, Striped) or null",
          "season": "String (e.g. Summer, Winter, All) or null",
          "confidence": number (0.0 to 1.0)
        }
      ''');

      final imageParts = [
        DataPart('image/jpeg', imageBytes),
      ];

      final stopwatch = Stopwatch()..start();
      final response = await model.generateContent([
        Content.multi([prompt, ...imageParts])
      ]);
      stopwatch.stop();
      Analytics.logApiDuration('Gemini (analyzeClothingImage)', stopwatch.elapsed);

      if (response.text != null) {
        // Clean up markdown code blocks if the model ignored the instruction
        var jsonText = response.text!.trim();
        if (jsonText.startsWith('```json')) {
          jsonText = jsonText.substring(7);
        } else if (jsonText.startsWith('```')) {
          jsonText = jsonText.substring(3);
        }
        if (jsonText.endsWith('```')) {
          jsonText = jsonText.substring(0, jsonText.length - 3);
        }
        jsonText = jsonText.trim();
        
        final parsedJson = jsonDecode(jsonText) as Map<String, dynamic>;
        debugPrint('--- GEMINI PARSED RESPONSE ---');
        debugPrint(parsedJson.toString());
        debugPrint('------------------------------');
        return parsedJson;
      }
      return null;
    } catch (e) {
      debugPrint('Gemini analysis error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> analyzeClothingImagesBatch(List<XFile> files) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY is missing');
      }

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      List<DataPart> imageParts = [];
      for (var file in files) {
        Uint8List imageBytes = await file.readAsBytes();
        if (!kIsWeb) {
          try {
            final compressed = await FlutterImageCompress.compressWithList(
              imageBytes,
              minWidth: 800,
              minHeight: 800,
              quality: 80,
            );
            if (compressed.isNotEmpty) {
              imageBytes = compressed;
            }
          } catch (e) {
            debugPrint('Compression failed for batch item: $e');
          }
        }
        imageParts.add(DataPart('image/jpeg', imageBytes));
      }

      final prompt = TextPart('''
        Analyze these ${files.length} clothing or accessory items. 
        Return ONLY a valid JSON ARRAY of objects with no markdown formatting or extra text.
        The JSON array must contain exactly ${files.length} objects matching this structure exactly, in the exact same order as the images:
        [
          {
            "category": "String (e.g. Tops, Bottoms, Outerwear, Footwear, Accessories)",
            "subtype": "String (e.g. Watch, Bracelet, Bag, Belt, Necklace, Sunglasses) or null if not an accessory",
            "color": "String (e.g. Navy Blue, Red)",
            "material": "String (e.g. Cotton, Denim) or null",
            "pattern": "String (e.g. Solid, Striped) or null",
            "season": "String (e.g. Summer, Winter, All) or null",
            "confidence": number (0.0 to 1.0)
          }
        ]
      ''');

      final stopwatch = Stopwatch()..start();
      final response = await model.generateContent([
        Content.multi([prompt, ...imageParts])
      ]);
      stopwatch.stop();
      Analytics.logApiDuration('Gemini (analyzeClothingImagesBatch)', stopwatch.elapsed);

      if (response.text != null) {
        var jsonText = response.text!.trim();
        if (jsonText.startsWith('```json')) {
          jsonText = jsonText.substring(7);
        } else if (jsonText.startsWith('```')) {
          jsonText = jsonText.substring(3);
        }
        if (jsonText.endsWith('```')) {
          jsonText = jsonText.substring(0, jsonText.length - 3);
        }
        jsonText = jsonText.trim();
        
        final parsedJson = jsonDecode(jsonText) as List<dynamic>;
        debugPrint('--- GEMINI BATCH RESPONSE ---');
        debugPrint(parsedJson.toString());
        debugPrint('------------------------------');
        return parsedJson.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      debugPrint('Gemini batch analysis error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> generateOutfitRecommendation(
    String userPrompt,
    List<Map<String, dynamic>> wardrobeItems,
    String? weatherContext,
  ) async {
    int maxRetries = 1;
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final apiKey = dotenv.env['GEMINI_API_KEY'];
        if (apiKey == null || apiKey.isEmpty) {
          throw Exception('GEMINI_API_KEY is missing');
        }

        final model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
          ),
        );

        final systemPrompt = '''
You are an expert AI fashion stylist. The user is asking for outfit recommendations based on their real wardrobe.
Here is the user's wardrobe inventory as a JSON list of items:
\${jsonEncode(wardrobeItems)}

INSTRUCTIONS:
1. Recommend one or more cohesive outfits composed ONLY of items from the provided wardrobe list. If the user asks for a specific number of days (e.g. "3 days"), provide exactly that many distinct outfits. If not specified, provide 1 outfit.
2. DO NOT hallucinate or invent item IDs that are not in the list.
3. Keep your reasoning brief, friendly, and directly tied to the occasion and weather.
4. WEATHER/LOCATION LOGIC: 
   - The user's CURRENT PHYSICAL LOCAL weather is: \${weatherContext ?? 'Unknown'}.
   - CRITICAL: If the user's prompt mentions a specific destination or trip (e.g., "Iceland", "Manali", "Tokyo"), you MUST COMPLETELY IGNORE their local weather. Instead, use your general knowledge of that destination's typical climate.
   - Only use the local weather if they are dressing for today where they currently are.
5. Return ONLY a valid JSON object matching this structure exactly (no markdown formatting, no extra text):
{
  "aiReasoning": "Your friendly 1-2 sentence explanation...",
  "outfits": [
    {
      "title": "Day 1 - City Tour",
      "itemIds": ["id1", "id2"]
    }
  ]
}
''';

        final chat = model.startChat(history: [
          Content.text(systemPrompt),
          Content.model([TextPart('Understood. I will strictly follow the JSON structure and only use valid IDs.')])
        ]);

        final stopwatch = Stopwatch()..start();
        final finalPrompt = attempt > 0 
            ? "PREVIOUS ERROR: You hallucinated item IDs. Return ONLY valid IDs from the provided JSON list.\\n\\nUser prompt: \$userPrompt" 
            : userPrompt;
            
        final response = await chat.sendMessage(Content.text(finalPrompt));
        stopwatch.stop();
        Analytics.logApiDuration('Gemini (generateOutfitRecommendation_attempt_\$attempt)', stopwatch.elapsed);

        if (response.text != null) {
          var jsonText = response.text!.trim();
          final jsonStart = jsonText.indexOf('{');
          final jsonEnd = jsonText.lastIndexOf('}');
          if (jsonStart != -1 && jsonEnd != -1) {
            jsonText = jsonText.substring(jsonStart, jsonEnd + 1);
          } else {
            throw Exception('No JSON found in response');
          }
          
          final parsedJson = jsonDecode(jsonText) as Map<String, dynamic>;
          
          // Validate against hallucinated IDs
          final validIds = wardrobeItems.map((item) => item['id']).toSet();
          
          final List<dynamic> rawOutfits = parsedJson['outfits'] ?? [];
          final List<Map<String, dynamic>> cleanOutfits = [];
          
          for (var outfit in rawOutfits) {
            final List<dynamic> recommendedIds = outfit['itemIds'] ?? [];
            final cleanIds = recommendedIds.where((id) => validIds.contains(id)).toList();
            
            if (cleanIds.isNotEmpty) {
              cleanOutfits.add({
                'title': outfit['title'] ?? 'Outfit Recommendation',
                'itemIds': cleanIds,
              });
            }
          }
          
          if (cleanOutfits.isEmpty) {
             throw Exception('Gemini hallucinated all item IDs or provided none.');
          }
          
          parsedJson['outfits'] = cleanOutfits;
          return parsedJson;
        }
      } catch (e) {
        debugPrint('Gemini styling error (attempt \$attempt): \$e');
        if (attempt == maxRetries) {
          throw Exception('Failed to generate recommendation. Please try again.');
        }
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> generateGapAnalysis(
    List<Map<String, dynamic>> wardrobeItems,
  ) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY is missing');
      }

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      const systemPrompt = '''
You are an expert AI fashion stylist. The user wants to know what key item is missing or underrepresented in their wardrobe that would unlock the most new outfit combinations.
Here is the user's real wardrobe inventory as a JSON list of items:
\${jsonEncode(wardrobeItems)}

INSTRUCTIONS:
1. Analyze the wardrobe to find a genuine gap (a missing category, color, or style of item). Do NOT fabricate items.
2. Based ONLY on the real items they have, suggest exactly ONE item to buy that would unlock the most new outfit combinations.
3. Estimate roughly how many new combinations it would unlock.
4. Keep the headline short and punchy.
5. Return ONLY a valid JSON object matching this structure exactly (no markdown formatting, no backticks, no extra text):
{
  "gapHeadline": "String (e.g. You're missing a staple.)",
  "gapReasoning": "String (e.g. You have 4 blue jeans but 0 white sneakers. White sneakers could unlock 12 new outfits based on your current closet.)",
  "suggestedItemCategory": "String (e.g. White Sneakers)"
}
''';

      final chat = model.startChat(history: [
        Content.text(systemPrompt),
        Content.model([TextPart('Understood. I will strictly follow the JSON structure based on the provided wardrobe data.')])
      ]);

      final response = await chat.sendMessage(Content.text('Analyze my wardrobe and identify the biggest gap.'));

      if (response.text != null) {
        var jsonText = response.text!.trim();
        if (jsonText.startsWith('```json')) {
          jsonText = jsonText.substring(7);
        } else if (jsonText.startsWith('```')) {
          jsonText = jsonText.substring(3);
        }
        if (jsonText.endsWith('```')) {
          jsonText = jsonText.substring(0, jsonText.length - 3);
        }
        jsonText = jsonText.trim();
        
        final parsedJson = jsonDecode(jsonText) as Map<String, dynamic>;
        
        debugPrint('--- GEMINI GAP ANALYSIS RESPONSE ---');
        debugPrint(parsedJson.toString());
        debugPrint('------------------------------------');
        
        return parsedJson;
      }
      return null;
    } catch (e) {
      debugPrint('Gemini gap analysis error: $e');
      throw Exception('Failed to generate gap analysis. Please try again.');
    }
  }

  Future<List<Map<String, dynamic>>?> generatePackingList(String destination, String duration) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY is missing');
      }

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      const systemPrompt = '''
You are an expert travel planner. Create a minimal, practical packing checklist based on the user's destination and duration.
Return ONLY a valid JSON ARRAY of objects (no markdown, no backticks).
Each object should be:
{
  "item": "String (e.g. T-Shirts)",
  "quantity": number,
  "category": "String (e.g. Clothing, Toiletries, Electronics, Documents)"
}
''';

      final chat = model.startChat(history: [
        Content.text(systemPrompt),
        Content.model([TextPart('Understood. I will strictly return the JSON array of packing items.')])
      ]);

      final response = await chat.sendMessage(Content.text('Destination: $destination, Duration: $duration'));

      if (response.text != null) {
        var jsonText = response.text!.trim();
        if (jsonText.startsWith('```json')) {
          jsonText = jsonText.substring(7);
        } else if (jsonText.startsWith('```')) {
          jsonText = jsonText.substring(3);
        }
        if (jsonText.endsWith('```')) {
          jsonText = jsonText.substring(0, jsonText.length - 3);
        }
        jsonText = jsonText.trim();
        
        final parsedJson = jsonDecode(jsonText) as List<dynamic>;
        return parsedJson.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      debugPrint('Gemini packing list error: $e');
      throw Exception('Failed to generate packing list.');
    }
  }

  Future<OutfitSuggestion> generateOutfitSuggestion(
    List<dynamic> wardrobe, 
    {dynamic weatherInfo, String? occasion}
  ) async {
    if (wardrobe.isEmpty) {
      throw Exception('Wardrobe is empty');
    }

    int maxRetries = 1;
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
        );
        
        final weatherStr = weatherInfo != null ? "Weather is ${weatherInfo.temperature}C and ${weatherInfo.condition}." : "Weather unknown.";
        final validIds = wardrobe.map((item) => item.id).toSet();
        final wardrobeStr = wardrobe.map((item) => "{id: ${item.id}, category: ${item.category}, color: ${item.color}}").join(", ");

        final basePrompt = '''
        You are an AI Fashion Stylist.
        $weatherStr
        Occasion: ${occasion ?? 'casual'}
        Wardrobe: $wardrobeStr
        
        Choose exactly 2-4 items from the wardrobe to make a perfect outfit.
        Return ONLY a JSON object with this exact structure, no markdown, no other text:
        {
          "itemIds": ["id1", "id2"],
          "reasoning": "A 1-sentence explanation."
        }
        ''';
        
        final prompt = attempt > 0
            ? "$basePrompt\nCRITICAL: In your last attempt you hallucinated item IDs. Return ONLY valid IDs from the provided Wardrobe list."
            : basePrompt;

        final stopwatch = Stopwatch()..start();
        final response = await model.generateContent([Content.text(prompt)]);
        stopwatch.stop();
        Analytics.logApiDuration('Gemini (generateOutfitSuggestion_attempt_$attempt)', stopwatch.elapsed);
        var jsonText = response.text ?? '';
        
        final jsonStart = jsonText.indexOf('{');
        final jsonEnd = jsonText.lastIndexOf('}');
        if (jsonStart != -1 && jsonEnd != -1) {
          jsonText = jsonText.substring(jsonStart, jsonEnd + 1);
        } else {
          throw Exception('No JSON found in response');
        }

        final parsed = jsonDecode(jsonText);
        final List<dynamic> rawIds = parsed['itemIds'] ?? [];
        final cleanIds = rawIds.where((id) => validIds.contains(id)).map((id) => id.toString()).toList();
        
        if (cleanIds.isEmpty) {
          throw Exception('Gemini hallucinated all item IDs.');
        }

        return OutfitSuggestion(
          itemIds: cleanIds,
          reasoning: parsed['reasoning'] ?? 'Here is an outfit.',
        );
      } catch (e) {
        debugPrint('Gemini outfit error (attempt \$attempt): \$e');
        if (attempt == maxRetries) {
          throw Exception('Failed to generate outfit. Please try again.');
        }
      }
    }
    throw Exception('Failed to generate outfit after retries.');
  }
}

class OutfitSuggestion {
  final List<String> itemIds;
  final String reasoning;
  OutfitSuggestion({required this.itemIds, required this.reasoning});
}
