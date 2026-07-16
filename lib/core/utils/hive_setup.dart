import 'package:hive_flutter/hive_flutter.dart';

Future<void> openHiveBoxes(String uid) async {
  if (!Hive.isBoxOpen('clothing_items_$uid')) {
    await Hive.openBox<Map>('clothing_items_$uid');
  }
  if (!Hive.isBoxOpen('outfits_$uid')) {
    await Hive.openBox<Map>('outfits_$uid');
  }
  if (!Hive.isBoxOpen('user_profiles_$uid')) {
    await Hive.openBox<Map>('user_profiles_$uid');
  }
}
