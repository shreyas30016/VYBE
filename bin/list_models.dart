import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  try {
    final envFile = File('.env');
    if (!envFile.existsSync()) return;
    
    final lines = envFile.readAsLinesSync();
    String? key;
    for (var line in lines) {
      if (line.startsWith('GEMINI_API_KEY=')) {
        key = line.split('=')[1].trim();
        if (key.startsWith('"') && key.endsWith('"')) {
          key = key.substring(1, key.length - 1);
        }
      }
    }
    
    if (key == null || key.isEmpty) return;

    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$key');
    final response = await http.get(url);
    
    final json = jsonDecode(response.body);
    final models = json['models'] as List;
    
    print('Available models for this API key:');
    for (var model in models) {
      print('- ${model['name']} (supported methods: ${model['supportedGenerationMethods']})');
    }
  } catch (e) {
    print('Error: $e');
  }
}
