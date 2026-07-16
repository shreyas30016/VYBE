import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/user_repository.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_provider.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final user = ref.watch(authProvider).value;
  final uid = user?.id ?? 'local_user';
  return UserRepositoryImpl(supabase: Supabase.instance.client, uid: uid);
});

final userProfileProvider = StreamProvider.family<UserProfile?, String>((ref, userId) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getProfile(userId);
});
