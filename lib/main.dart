import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/utils/hive_setup.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prevent red/white screens on render crashes
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('Global UI Error: \${details.exception}');
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                SizedBox(height: 16),
                Text(
                  'Something went wrong.',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'An unexpected error occurred. Please refresh or restart the app.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };
  
  // Load env variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  String uid = 'local_user';
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseAnonKey,
      );
      
      final supabase = Supabase.instance.client;
      uid = supabase.auth.currentUser?.id ?? 'local_user';
    } catch (e) {
      debugPrint('Supabase init/auth failed, falling back to local storage: $e');
    }
  } else {
    debugPrint('Supabase keys not found in .env, running in local-only mode');
  }
  

  // Initialize Hive for offline cache
  await Hive.initFlutter();
  
  // Open boxes namespaced by UID
  await openHiveBoxes(uid);

  runApp(
    const ProviderScope(
      child: ClosetOSApp(),
    ),
  );
}

class ClosetOSApp extends ConsumerWidget {
  const ClosetOSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    
    return MaterialApp.router(
      title: 'VYBE Ai',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
