import 'package:flutter/material.dart';

class ColorUtils {
  static const Map<String, Color> _colorMap = {
    'black': Colors.black,
    'white': Colors.white,
    'gray': Colors.grey,
    'grey': Colors.grey,
    'charcoal': Color(0xFF36454F),
    'silver': Color(0xFFC0C0C0),
    'red': Colors.red,
    'burgundy': Color(0xFF800020),
    'maroon': Color(0xFF800000),
    'crimson': Color(0xFFDC143C),
    'blue': Colors.blue,
    'navy': Color(0xFF000080),
    'navy blue': Color(0xFF000080),
    'royal blue': Color(0xFF4169E1),
    'light blue': Colors.lightBlue,
    'cyan': Colors.cyan,
    'teal': Colors.teal,
    'green': Colors.green,
    'olive': Color(0xFF808000),
    'olive green': Color(0xFF808000),
    'emerald': Color(0xFF50C878),
    'mint': Color(0xFF3EB489),
    'yellow': Colors.yellow,
    'mustard': Color(0xFFFFDB58),
    'gold': Color(0xFFFFD700),
    'orange': Colors.orange,
    'rust': Color(0xFFB7410E),
    'coral': Color(0xFFFF7F50),
    'purple': Colors.purple,
    'lavender': Color(0xFFE6E6FA),
    'lilac': Color(0xFFC8A2C8),
    'pink': Colors.pink,
    'magenta': Color(0xFFFF00FF),
    'rose': Color(0xFFFF007F),
    'brown': Colors.brown,
    'khaki': Color(0xFFF0E68C),
    'tan': Color(0xFFD2B48C),
    'beige': Color(0xFFF5F5DC),
    'cream': Color(0xFFFFFDD0),
    'ivory': Color(0xFFFFFFF0),
    'nude': Color(0xFFE3BC9A),
    'camel': Color(0xFFC19A6B),
  };

  /// Parses a string like 'Navy Blue' or 'Dark Olive' and returns the closest Color.
  static Color getColorFromName(String colorName) {
    String cleanName = colorName.toLowerCase().trim();
    
    // Exact match
    if (_colorMap.containsKey(cleanName)) {
      return _colorMap[cleanName]!;
    }
    
    // Partial match (e.g. "Dark Navy" -> finds "navy")
    for (final key in _colorMap.keys) {
      if (cleanName.contains(key)) {
        return _colorMap[key]!;
      }
    }
    
    // Fallback if nothing matches
    return Colors.grey.shade800;
  }
}
