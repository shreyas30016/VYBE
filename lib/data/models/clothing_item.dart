class ClothingItem {
  final String id;
  final String userId;
  final String imageUrl;
  final String category;
  final String? subtype;
  final String? color;
  final String? material;
  final String? pattern;
  final String season;
  final double confidence;
  final int wearCount;
  final DateTime dateAdded;
  final DateTime? lastWorn;
  final bool isFavorite;

  ClothingItem({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.category,
    this.subtype,
    this.color,
    this.material,
    this.pattern,
    required this.season,
    required this.confidence,
    required this.wearCount,
    required this.dateAdded,
    this.lastWorn,
    required this.isFavorite,
  });

  ClothingItem copyWith({
    String? id,
    String? userId,
    String? imageUrl,
    String? category,
    String? subtype,
    String? color,
    String? material,
    String? pattern,
    String? season,
    double? confidence,
    int? wearCount,
    DateTime? dateAdded,
    DateTime? lastWorn,
    bool? isFavorite,
  }) {
    return ClothingItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      subtype: subtype ?? this.subtype,
      color: color ?? this.color,
      material: material ?? this.material,
      pattern: pattern ?? this.pattern,
      season: season ?? this.season,
      confidence: confidence ?? this.confidence,
      wearCount: wearCount ?? this.wearCount,
      dateAdded: dateAdded ?? this.dateAdded,
      lastWorn: lastWorn ?? this.lastWorn,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'imageUrl': imageUrl,
      'category': category,
      'subtype': subtype,
      'color': color,
      'material': material,
      'pattern': pattern,
      'season': season,
      'confidence': confidence,
      'wearCount': wearCount,
      'dateAdded': dateAdded.toIso8601String(),
      'lastWorn': lastWorn?.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      id: json['id'] as String,
      userId: json['userId'] as String,
      imageUrl: json['imageUrl'] as String,
      category: json['category'] as String,
      subtype: json['subtype'] as String?,
      color: json['color'] as String?,
      material: json['material'] as String?,
      pattern: json['pattern'] as String?,
      season: json['season'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      wearCount: json['wearCount'] as int,
      dateAdded: DateTime.parse(json['dateAdded'] as String),
      lastWorn: json['lastWorn'] != null
          ? DateTime.parse(json['lastWorn'] as String)
          : null,
      isFavorite: json['isFavorite'] as bool,
    );
  }
}
