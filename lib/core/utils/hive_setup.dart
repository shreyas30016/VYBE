import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

final Map<String, Future<void>> _initFutures = {};

Future<void> openHiveBoxes(String uid) async {
  if (_initFutures.containsKey(uid)) {
    return _initFutures[uid];
  }

  _initFutures[uid] = () async {
    try {
      if (!Hive.isBoxOpen('clothing_items_$uid')) {
        await Hive.openBox<Map>('clothing_items_$uid');
      }
      if (!Hive.isBoxOpen('outfits_$uid')) {
        await Hive.openBox<Map>('outfits_$uid');
      }
      if (!Hive.isBoxOpen('user_profiles_$uid')) {
        await Hive.openBox<Map>('user_profiles_$uid');
      }
    } catch (e) {
      debugPrint('Error opening Hive boxes for uid $uid: $e');
      _initFutures.remove(uid); // Allow retry on failure
      rethrow;
    }
  }();

  return _initFutures[uid];
}
