import 'package:flutter/foundation.dart';

class Analytics {
  static void logEvent(String eventName, {Map<String, dynamic>? parameters}) {
    if (kDebugMode) {
      final time = DateTime.now().toIso8601String().split('T').last.substring(0, 8);
      final paramsStr = parameters != null ? ' | $parameters' : '';
      debugPrint('📊 [ANALYTICS] [$time] $eventName$paramsStr');
    }
  }

  static void logError(String eventName, dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      final time = DateTime.now().toIso8601String().split('T').last.substring(0, 8);
      debugPrint('❌ [ANALYTICS ERROR] [$time] $eventName | $error');
    }
  }

  static void logApiDuration(String apiName, Duration duration) {
    if (kDebugMode) {
      final time = DateTime.now().toIso8601String().split('T').last.substring(0, 8);
      final ms = duration.inMilliseconds;
      final durationStr = ms > 1000 ? '${(ms / 1000).toStringAsFixed(1)} seconds' : '$ms ms';
      debugPrint('⏱️ [API TIMING] [$time] $apiName took $durationStr');
    }
  }
}
