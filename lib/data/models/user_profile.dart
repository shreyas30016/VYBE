class UserProfile {
  final String userId;
  final String name;
  final String? profileImageUrl;
  final String? styleBaseline;
  final String? gender;
  final String? ageGroup;
  
  // Style Preferences
  final List<String> styles;
  final List<String> favoriteBrands;
  final double outfitCreativity;
  final String weatherPreference;

  // Settings & Privacy
  final String appTheme;
  final bool saveAiChats;
  final bool uploadAnalytics;
  final bool personalization;
  final bool crashReports;

  // App Features
  final bool calendarSyncEnabled;
  final bool weatherContextEnabled;
  final bool hapticsEnabled;
  final double hapticIntensity;

  // Notifications
  final bool notifOutfitReady;
  final bool notifWeather;
  final bool notifLaundry;
  final bool notifUnworn;
  final bool notifWeekly;
  final bool notifPacking;
  final bool notifSale;
  final bool notifBeta;
  final bool notifNewAi;

  UserProfile({
    required this.userId,
    required this.name,
    this.profileImageUrl,
    this.styleBaseline,
    this.gender,
    this.ageGroup,
    this.styles = const [],
    this.favoriteBrands = const [],
    this.outfitCreativity = 0.5,
    this.weatherPreference = 'Auto Detect',
    this.appTheme = 'System',
    this.saveAiChats = true,
    this.uploadAnalytics = true,
    this.personalization = true,
    this.crashReports = true,
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
    this.notifSale = true,
    this.notifBeta = false,
    this.notifNewAi = true,
  });

  UserProfile copyWith({
    String? userId,
    String? name,
    String? profileImageUrl,
    String? styleBaseline,
    String? gender,
    String? ageGroup,
    List<String>? styles,
    List<String>? favoriteBrands,
    double? outfitCreativity,
    String? weatherPreference,
    String? appTheme,
    bool? saveAiChats,
    bool? uploadAnalytics,
    bool? personalization,
    bool? crashReports,
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
    bool? notifSale,
    bool? notifBeta,
    bool? notifNewAi,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      styleBaseline: styleBaseline ?? this.styleBaseline,
      gender: gender ?? this.gender,
      ageGroup: ageGroup ?? this.ageGroup,
      styles: styles ?? this.styles,
      favoriteBrands: favoriteBrands ?? this.favoriteBrands,
      outfitCreativity: outfitCreativity ?? this.outfitCreativity,
      weatherPreference: weatherPreference ?? this.weatherPreference,
      appTheme: appTheme ?? this.appTheme,
      saveAiChats: saveAiChats ?? this.saveAiChats,
      uploadAnalytics: uploadAnalytics ?? this.uploadAnalytics,
      personalization: personalization ?? this.personalization,
      crashReports: crashReports ?? this.crashReports,
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
      notifSale: notifSale ?? this.notifSale,
      notifBeta: notifBeta ?? this.notifBeta,
      notifNewAi: notifNewAi ?? this.notifNewAi,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'styleBaseline': styleBaseline,
      'gender': gender,
      'ageGroup': ageGroup,
      'styles': styles,
      'favoriteBrands': favoriteBrands,
      'outfitCreativity': outfitCreativity,
      'weatherPreference': weatherPreference,
      'appTheme': appTheme,
      'saveAiChats': saveAiChats,
      'uploadAnalytics': uploadAnalytics,
      'personalization': personalization,
      'crashReports': crashReports,
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
      'notifSale': notifSale,
      'notifBeta': notifBeta,
      'notifNewAi': notifNewAi,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as String,
      name: json['name'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      styleBaseline: json['styleBaseline'] as String?,
      gender: json['gender'] as String?,
      ageGroup: json['ageGroup'] as String?,
      styles: (json['styles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      favoriteBrands: (json['favoriteBrands'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      outfitCreativity: (json['outfitCreativity'] as num?)?.toDouble() ?? 0.5,
      weatherPreference: json['weatherPreference'] as String? ?? 'Auto Detect',
      appTheme: json['appTheme'] as String? ?? 'System',
      saveAiChats: json['saveAiChats'] as bool? ?? true,
      uploadAnalytics: json['uploadAnalytics'] as bool? ?? true,
      personalization: json['personalization'] as bool? ?? true,
      crashReports: json['crashReports'] as bool? ?? true,
      calendarSyncEnabled: json['calendarSyncEnabled'] as bool? ?? false,
      weatherContextEnabled: json['weatherContextEnabled'] as bool? ?? false,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? false,
      hapticIntensity: (json['hapticIntensity'] as num?)?.toDouble() ?? 0.5,
      notifOutfitReady: json['notifOutfitReady'] as bool? ?? true,
      notifWeather: json['notifWeather'] as bool? ?? true,
      notifLaundry: json['notifLaundry'] as bool? ?? true,
      notifUnworn: json['notifUnworn'] as bool? ?? false,
      notifWeekly: json['notifWeekly'] as bool? ?? true,
      notifPacking: json['notifPacking'] as bool? ?? false,
      notifSale: json['notifSale'] as bool? ?? true,
      notifBeta: json['notifBeta'] as bool? ?? false,
      notifNewAi: json['notifNewAi'] as bool? ?? true,
    );
  }
}
