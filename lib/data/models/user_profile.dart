class UserProfile {
  final String userId;
  final String name;
  final String? styleBaseline;
  final bool calendarSyncEnabled;
  final bool weatherContextEnabled;
  final bool hapticsEnabled;
  final double hapticIntensity;

  UserProfile({
    required this.userId,
    required this.name,
    this.styleBaseline,
    required this.calendarSyncEnabled,
    required this.weatherContextEnabled,
    required this.hapticsEnabled,
    required this.hapticIntensity,
  });

  UserProfile copyWith({
    String? userId,
    String? name,
    String? styleBaseline,
    bool? calendarSyncEnabled,
    bool? weatherContextEnabled,
    bool? hapticsEnabled,
    double? hapticIntensity,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      styleBaseline: styleBaseline ?? this.styleBaseline,
      calendarSyncEnabled: calendarSyncEnabled ?? this.calendarSyncEnabled,
      weatherContextEnabled: weatherContextEnabled ?? this.weatherContextEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      hapticIntensity: hapticIntensity ?? this.hapticIntensity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'styleBaseline': styleBaseline,
      'calendarSyncEnabled': calendarSyncEnabled,
      'weatherContextEnabled': weatherContextEnabled,
      'hapticsEnabled': hapticsEnabled,
      'hapticIntensity': hapticIntensity,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as String,
      name: json['name'] as String,
      styleBaseline: json['styleBaseline'] as String?,
      calendarSyncEnabled: json['calendarSyncEnabled'] as bool,
      weatherContextEnabled: json['weatherContextEnabled'] as bool,
      hapticsEnabled: json['hapticsEnabled'] as bool,
      hapticIntensity: (json['hapticIntensity'] as num).toDouble(),
    );
  }
}
