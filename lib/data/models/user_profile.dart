class UserProfile {
  final String userId;
  final String name;
  final String? profileImageUrl;
  final String? styleBaseline;
  final bool calendarSyncEnabled;
  final bool weatherContextEnabled;
  final bool hapticsEnabled;
  final double hapticIntensity;
  final bool notifOutfitReady;
  final bool notifWeather;
  final bool notifLaundry;
  final bool notifUnworn;
  final bool notifWeekly;
  final bool notifPacking;

  UserProfile({
    required this.userId,
    required this.name,
    this.profileImageUrl,
    this.styleBaseline,
    required this.calendarSyncEnabled,
    required this.weatherContextEnabled,
    required this.hapticsEnabled,
    required this.hapticIntensity,
    this.notifOutfitReady = true,
    this.notifWeather = true,
    this.notifLaundry = true,
    this.notifUnworn = false,
    this.notifWeekly = true,
    this.notifPacking = false,
  });

  UserProfile copyWith({
    String? userId,
    String? name,
    String? profileImageUrl,
    String? styleBaseline,
    bool? calendarSyncEnabled,
    bool? weatherContextEnabled,
    bool? hapticsEnabled,
    double? hapticIntensity,
    bool? notifOutfitReady,
    bool? notifWeather,
    bool? notifLaundry,
    bool? notifUnworn,
    bool? notifWeekly,
    bool? notifPacking,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      styleBaseline: styleBaseline ?? this.styleBaseline,
      calendarSyncEnabled: calendarSyncEnabled ?? this.calendarSyncEnabled,
      weatherContextEnabled: weatherContextEnabled ?? this.weatherContextEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      hapticIntensity: hapticIntensity ?? this.hapticIntensity,
      notifOutfitReady: notifOutfitReady ?? this.notifOutfitReady,
      notifWeather: notifWeather ?? this.notifWeather,
      notifLaundry: notifLaundry ?? this.notifLaundry,
      notifUnworn: notifUnworn ?? this.notifUnworn,
      notifWeekly: notifWeekly ?? this.notifWeekly,
      notifPacking: notifPacking ?? this.notifPacking,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'styleBaseline': styleBaseline,
      'calendarSyncEnabled': calendarSyncEnabled,
      'weatherContextEnabled': weatherContextEnabled,
      'hapticsEnabled': hapticsEnabled,
      'hapticIntensity': hapticIntensity,
      'notifOutfitReady': notifOutfitReady,
      'notifWeather': notifWeather,
      'notifLaundry': notifLaundry,
      'notifUnworn': notifUnworn,
      'notifWeekly': notifWeekly,
      'notifPacking': notifPacking,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as String,
      name: json['name'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      styleBaseline: json['styleBaseline'] as String?,
      calendarSyncEnabled: json['calendarSyncEnabled'] as bool,
      weatherContextEnabled: json['weatherContextEnabled'] as bool? ?? false,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? false,
      hapticIntensity: (json['hapticIntensity'] as num?)?.toDouble() ?? 0.5,
      notifOutfitReady: json['notifOutfitReady'] as bool? ?? true,
      notifWeather: json['notifWeather'] as bool? ?? true,
      notifLaundry: json['notifLaundry'] as bool? ?? true,
      notifUnworn: json['notifUnworn'] as bool? ?? false,
      notifWeekly: json['notifWeekly'] as bool? ?? true,
      notifPacking: json['notifPacking'] as bool? ?? false,
    );
  }
}
