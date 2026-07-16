import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../core/utils/analytics.dart';

class WeatherInfo {
  final String temperature;
  final String condition;

  WeatherInfo({required this.temperature, required this.condition});
}

class WeatherService {
  Future<WeatherInfo> getCurrentWeather() async {
    final stopwatch = Stopwatch()..start();
    try {
      // 1. Get Location instantly via IP to avoid Geolocator permission hangs on Web
      final ipResponse = await http.get(Uri.parse('https://ipwho.is/')).timeout(
        const Duration(seconds: 4),
      );
      
      if (ipResponse.statusCode != 200) {
        throw Exception('Failed to get location');
      }
      
      final ipData = json.decode(ipResponse.body);
      final double lat = ipData['latitude'];
      final double lon = ipData['longitude'];

      // 2. Fetch Weather from Open-Meteo (No API key required, highly reliable)
      final weatherUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true'
      );
      
      final weatherResponse = await http.get(weatherUrl).timeout(
        const Duration(seconds: 4),
      );
      
      if (weatherResponse.statusCode == 200) {
        final weatherData = json.decode(weatherResponse.body);
        final temp = weatherData['current_weather']['temperature'].round().toString();
        final code = weatherData['current_weather']['weathercode'];
        
        stopwatch.stop();
        Analytics.logApiDuration('Weather', stopwatch.elapsed);
        return WeatherInfo(
          temperature: temp, 
          condition: _getWeatherCondition(code),
        );
      } else {
        stopwatch.stop();
        Analytics.logApiDuration('Weather (Failed)', stopwatch.elapsed);
        return WeatherInfo(temperature: '--', condition: 'Error');
      }
    } catch (e) {
      stopwatch.stop();
      Analytics.logApiDuration('Weather (Error)', stopwatch.elapsed);
      debugPrint('Weather API Error: $e');
      return WeatherInfo(temperature: '--', condition: 'Error');
    }
  }

  String _getWeatherCondition(int code) {
    if (code == 0) return 'Clear';
    if (code >= 1 && code <= 3) return 'Cloudy';
    if (code == 45 || code == 48) return 'Fog';
    if (code >= 51 && code <= 67) return 'Rain';
    if (code >= 71 && code <= 77) return 'Snow';
    if (code >= 80 && code <= 82) return 'Rain Showers';
    if (code >= 85 && code <= 86) return 'Snow Showers';
    if (code >= 95) return 'Thunderstorm';
    return 'Unknown';
  }
}
