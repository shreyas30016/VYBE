import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  static const _themeKey = 'app_theme_mode';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey);
    if (themeString != null) {
      if (themeString == 'light') {
        state = ThemeMode.light;
      } else if (themeString == 'dark') {
        state = ThemeMode.dark;
      } else {
        state = ThemeMode.system;
      }
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    String themeString = 'system';
    if (mode == ThemeMode.light) themeString = 'light';
    if (mode == ThemeMode.dark) themeString = 'dark';
    await prefs.setString(_themeKey, themeString);
  }
}
