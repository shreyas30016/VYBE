import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/clothing_item.dart';
import '../data/repositories/wardrobe_repository.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_provider.dart';

final isOfflineProvider = StateProvider<bool>((ref) => false);

final wardrobeRepositoryProvider = Provider<WardrobeRepository>((ref) {
  final user = ref.watch(authProvider).value;
  final uid = user?.id ?? 'local_user';
  return WardrobeRepositoryImpl(
    supabase: Supabase.instance.client, 
    uid: uid,
    onOfflineStatusChanged: (isOffline) {
      // Defer state update to avoid build phase errors
      Future.microtask(() {
        ref.read(isOfflineProvider.notifier).state = isOffline;
      });
    },
  );
});

final wardrobeItemsProvider = StreamProvider<List<ClothingItem>>((ref) {
  final repo = ref.watch(wardrobeRepositoryProvider);
  return repo.getAllItems();
});

final wardrobeByCategory = StreamProvider.family<List<ClothingItem>, String>((ref, category) {
  final repo = ref.watch(wardrobeRepositoryProvider);
  return repo.getItemsByCategory(category);
});
