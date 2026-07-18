class Trip {
  final String id;
  final String userId;
  final String name;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final String purpose;
  final String weatherPreference;
  final List<TripDay> days;
  final List<PackingItem> packingList;

  Trip({
    required this.id,
    required this.userId,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.purpose,
    required this.weatherPreference,
    this.days = const [],
    this.packingList = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'destination': destination,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'purpose': purpose,
      'weatherPreference': weatherPreference,
      'days': days.map((x) => x.toJson()).toList(),
      'packingList': packingList.map((x) => x.toJson()).toList(),
    };
  }

  factory Trip.fromJson(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      destination: map['destination'] ?? '',
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : DateTime.now(),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : DateTime.now(),
      purpose: map['purpose'] ?? '',
      weatherPreference: map['weatherPreference'] ?? '',
      days: map['days'] != null ? List<TripDay>.from(map['days']?.map((x) => TripDay.fromJson(Map<String, dynamic>.from(x)))) : [],
      packingList: map['packingList'] != null ? List<PackingItem>.from(map['packingList']?.map((x) => PackingItem.fromJson(Map<String, dynamic>.from(x)))) : [],
    );
  }

  Trip copyWith({
    String? id,
    String? userId,
    String? name,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? purpose,
    String? weatherPreference,
    List<TripDay>? days,
    List<PackingItem>? packingList,
  }) {
    return Trip(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      purpose: purpose ?? this.purpose,
      weatherPreference: weatherPreference ?? this.weatherPreference,
      days: days ?? this.days,
      packingList: packingList ?? this.packingList,
    );
  }
}

class TripDay {
  final DateTime date;
  final String weatherDescription;
  final String weatherIconUrl;
  final String outfitSuggestion;
  final String? mappedOutfitId;
  final List<String> mappedClothingItemIds;
  final List<String> plannedActivities;

  TripDay({
    required this.date,
    required this.weatherDescription,
    this.weatherIconUrl = '',
    required this.outfitSuggestion,
    this.mappedOutfitId,
    this.mappedClothingItemIds = const [],
    this.plannedActivities = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'weatherDescription': weatherDescription,
      'weatherIconUrl': weatherIconUrl,
      'outfitSuggestion': outfitSuggestion,
      'mappedOutfitId': mappedOutfitId,
      'mappedClothingItemIds': mappedClothingItemIds,
      'plannedActivities': plannedActivities,
    };
  }

  factory TripDay.fromJson(Map<String, dynamic> map) {
    return TripDay(
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      weatherDescription: map['weatherDescription'] ?? '',
      weatherIconUrl: map['weatherIconUrl'] ?? '',
      outfitSuggestion: map['outfitSuggestion'] ?? '',
      mappedOutfitId: map['mappedOutfitId'],
      mappedClothingItemIds: map['mappedClothingItemIds'] != null ? List<String>.from(map['mappedClothingItemIds']) : [],
      plannedActivities: map['plannedActivities'] != null ? List<String>.from(map['plannedActivities']) : [],
    );
  }
}

class PackingItem {
  final String id;
  final String name;
  final int quantity;
  final bool isMissing;
  final bool isPacked;
  final String? category;
  final String? mappedClothingItemId;

  PackingItem({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.isMissing = false,
    this.isPacked = false,
    this.category,
    this.mappedClothingItemId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'isMissing': isMissing,
      'isPacked': isPacked,
      'category': category,
      'mappedClothingItemId': mappedClothingItemId,
    };
  }

  factory PackingItem.fromJson(Map<String, dynamic> map) {
    return PackingItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      quantity: map['quantity']?.toInt() ?? 1,
      isMissing: map['isMissing'] ?? false,
      isPacked: map['isPacked'] ?? false,
      category: map['category'],
      mappedClothingItemId: map['mappedClothingItemId'],
    );
  }

  PackingItem copyWith({
    String? id,
    String? name,
    int? quantity,
    bool? isMissing,
    bool? isPacked,
    String? category,
    String? mappedClothingItemId,
  }) {
    return PackingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      isMissing: isMissing ?? this.isMissing,
      isPacked: isPacked ?? this.isPacked,
      category: category ?? this.category,
      mappedClothingItemId: mappedClothingItemId ?? this.mappedClothingItemId,
    );
  }
}
