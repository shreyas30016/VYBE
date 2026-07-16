import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';

abstract class UserRepository {
  Future<void> updateProfile(UserProfile profile);
  Stream<UserProfile?> getProfile(String userId);
}

class UserRepositoryImpl implements UserRepository {
  final SupabaseClient? supabase;
  final String uid;

  Future<Box<Map>> get _box async => await Hive.openBox<Map>('user_profiles_$uid');

  UserRepositoryImpl({this.supabase, required this.uid});

  Map<String, dynamic> _toSupabaseMap(UserProfile profile) {
    return {
      'id': profile.userId,
      'name': profile.name,
      if (profile.styleBaseline != null) 'style_preferences': [profile.styleBaseline!],
    };
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    final box = await _box;
    final json = profile.toJson();
    await box.put(profile.userId, json);

    try {
      if (supabase != null) {
        await supabase!.from('user_profiles').upsert(_toSupabaseMap(profile));
      } else {
        debugPrint('Supabase not initialized. Skipped sync for updateProfile.');
      }
    } catch (e) {
      debugPrint('Failed to sync updateProfile to Supabase: $e');
    }
  }

  @override
  Stream<UserProfile?> getProfile(String userId) async* {
    final box = await _box;
    yield _getProfileFromBox(box, userId);

    yield* box.watch(key: userId).map((_) => _getProfileFromBox(box, userId));
  }

  UserProfile? _getProfileFromBox(Box<Map> box, String userId) {
    final raw = box.get(userId);
    if (raw != null) {
      return UserProfile.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }
}
