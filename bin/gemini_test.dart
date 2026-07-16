import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  try {
    final envFile = File('.env');
    if (!envFile.existsSync()) {
      print('.env not found!');
      return;
    }
    
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
    
    if (key == null || key.isEmpty) {
      print('GEMINI_API_KEY not found in .env');
      return;
    }

    print('Testing gemini-pro...');
    final model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: key,
    );

    final response = await model.generateContent([
      Content.text('Say hello world in json format: {"message": "hello world"}')
    ]);

    print('Response: ${response.text}');
  } catch (e) {
    print('Error: $e');
  }
}
