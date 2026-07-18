import 'package:hive_flutter/hive_flutter.dart';
import '../models/trip.dart';
import '../../core/utils/hive_setup.dart';

abstract class TripRepository {
  Stream<List<Trip>> watchTrips();
  Future<void> saveTrip(Trip trip);
  Future<void> deleteTrip(String tripId);
  Future<Trip?> getTrip(String tripId);
}

class TripRepositoryImpl implements TripRepository {
  final String uid;

  TripRepositoryImpl({required this.uid});

  Future<Box<Map>> get _box async {
    await openHiveBoxes(uid);
    return Hive.box<Map>('trips_$uid');
  }

  @override
  Stream<List<Trip>> watchTrips() async* {
    final box = await _box;
    yield _getTrips(box);
    yield* box.watch().map((_) => _getTrips(box));
  }

  List<Trip> _getTrips(Box<Map> box) {
    return box.values
        .map((e) => Trip.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  @override
  Future<void> saveTrip(Trip trip) async {
    final box = await _box;
    await box.put(trip.id, trip.toJson());
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    final box = await _box;
    await box.delete(tripId);
  }

  @override
  Future<Trip?> getTrip(String tripId) async {
    final box = await _box;
    final data = box.get(tripId);
    if (data != null) {
      return Trip.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }
}
