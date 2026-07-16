import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/outfit.dart';
import '../data/repositories/outfit_repository.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_provider.dart';

final outfitRepositoryProvider = Provider<OutfitRepository>((ref) {
  final user = ref.watch(authProvider).value;
  final uid = user?.id ?? 'local_user';
  return OutfitRepositoryImpl(supabase: Supabase.instance.client, uid: uid);
});

final outfitHistoryProvider = StreamProvider<List<Outfit>>((ref) {
  final repo = ref.watch(outfitRepositoryProvider);
  return repo.getOutfitHistory();
});
