class Outfit {
  final String id;
  final String userId;
  final List<String> itemIds;
  final String? occasion;
  final String? weatherContext;
  final String? aiReasoning;
  final DateTime dateCreated;
  final DateTime? dateWorn;
  final bool isSaved;

  Outfit({
    required this.id,
    required this.userId,
    required this.itemIds,
    this.occasion,
    this.weatherContext,
    this.aiReasoning,
    required this.dateCreated,
    this.dateWorn,
    required this.isSaved,
  });

  Outfit copyWith({
    String? id,
    String? userId,
    List<String>? itemIds,
    String? occasion,
    String? weatherContext,
    String? aiReasoning,
    DateTime? dateCreated,
    DateTime? dateWorn,
    bool? isSaved,
  }) {
    return Outfit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      itemIds: itemIds ?? this.itemIds,
      occasion: occasion ?? this.occasion,
      weatherContext: weatherContext ?? this.weatherContext,
      aiReasoning: aiReasoning ?? this.aiReasoning,
      dateCreated: dateCreated ?? this.dateCreated,
      dateWorn: dateWorn ?? this.dateWorn,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'itemIds': itemIds,
      'occasion': occasion,
      'weatherContext': weatherContext,
      'aiReasoning': aiReasoning,
      'dateCreated': dateCreated.toIso8601String(),
      'dateWorn': dateWorn?.toIso8601String(),
      'isSaved': isSaved,
    };
  }

  factory Outfit.fromJson(Map<String, dynamic> json) {
    return Outfit(
      id: json['id'] as String,
      userId: json['userId'] as String,
      itemIds: (json['itemIds'] as List<dynamic>).map((e) => e as String).toList(),
      occasion: json['occasion'] as String?,
      weatherContext: json['weatherContext'] as String?,
      aiReasoning: json['aiReasoning'] as String?,
      dateCreated: DateTime.parse(json['dateCreated'] as String),
      dateWorn: json['dateWorn'] != null
          ? DateTime.parse(json['dateWorn'] as String)
          : null,
      isSaved: json['isSaved'] as bool,
    );
  }
}
