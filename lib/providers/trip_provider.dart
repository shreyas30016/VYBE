import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/trip.dart';
import '../data/repositories/trip_repository.dart';

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  final uid = Supabase.instance.client.auth.currentUser?.id ?? 'local_user';
  return TripRepositoryImpl(uid: uid);
});

final tripsProvider = StreamProvider<List<Trip>>((ref) {
  return ref.watch(tripRepositoryProvider).watchTrips();
});
