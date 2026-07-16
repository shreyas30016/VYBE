import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/clothing_item.dart';
import '../../core/utils/analytics.dart';
import '../../core/utils/hive_setup.dart';
abstract class WardrobeRepository {
  Future<void> addItem(ClothingItem item);
  Future<void> updateItem(ClothingItem item);
  Future<void> deleteItem(String id);
  Stream<List<ClothingItem>> getAllItems();
  Stream<List<ClothingItem>> getItemsByCategory(String category);
  Future<void> toggleFavorite(String id, bool isFavorite);
  Future<void> incrementWearCount(String id);
}

class WardrobeRepositoryImpl implements WardrobeRepository {
  final SupabaseClient? supabase;
  final String uid;
  Future<Box<Map>> get _box async {
    await openHiveBoxes(uid);
    return Hive.box<Map>('clothing_items_$uid');
  }

  final Function(bool)? onOfflineStatusChanged;

  WardrobeRepositoryImpl({this.supabase, required this.uid, this.onOfflineStatusChanged});

  Map<String, dynamic> _toSupabaseMap(ClothingItem item) {
    return {
      'id': item.id,
      'user_id': uid,
      'image_url': item.imageUrl,
      'category': item.category,
      'subtype': item.subtype,
      'color': item.color,
      'material': item.material,
      'pattern': item.pattern,
      'season': item.season,
      'is_favorite': item.isFavorite,
      'wear_count': item.wearCount,
      'last_worn': item.lastWorn?.toIso8601String(),
      'created_at': item.dateAdded.toIso8601String(),
    };
  }

  @override
  Future<void> addItem(ClothingItem item) async {
    final box = await _box;
    final json = item.toJson();
    // Offline-first: save to Hive
    await box.put(item.id, json);

    // Sync to Supabase
    try {
      if (supabase != null) {
        await supabase!.from('clothing_items').upsert(_toSupabaseMap(item));
      } else {
        debugPrint('Supabase not initialized. Skipped sync for addItem.');
      }
    } catch (e) {
      debugPrint('Failed to sync addItem to Supabase: $e');
    }
  }

  @override
  Future<void> updateItem(ClothingItem item) async {
    final box = await _box;
    final json = item.toJson();
    await box.put(item.id, json);

    try {
      if (supabase != null) {
        await supabase!.from('clothing_items').upsert(_toSupabaseMap(item));
      } else {
        debugPrint('Supabase not initialized. Skipped sync for updateItem.');
      }
    } catch (e) {
      debugPrint('Failed to sync updateItem to Supabase: $e');
    }
  }

  @override
  Future<void> deleteItem(String id) async {
    final box = await _box;
    await box.delete(id);

    try {
      if (supabase != null) {
        await supabase!.from('clothing_items').delete().eq('id', id);
      } else {
        debugPrint('Supabase not initialized. Skipped sync for deleteItem.');
      }
    } catch (e) {
      debugPrint('Failed to sync deleteItem to Supabase: $e');
    }
  }

  @override
  Stream<List<ClothingItem>> getAllItems() async* {
    final box = await _box;
    yield _getItemsFromBox(box);

    if (supabase != null && uid != 'local_user') {
      try {
        final stopwatch = Stopwatch()..start();
        final response = await supabase!.from('clothing_items').select().eq('user_id', uid);
        stopwatch.stop();
        Analytics.logApiDuration('Supabase (Wardrobe)', stopwatch.elapsed);
        
        for (var row in response) {
          final item = ClothingItem(
            id: row['id'],
            userId: row['user_id'],
            imageUrl: row['image_url'],
            category: row['category'],
            subtype: row['subtype'],
            color: row['color'],
            material: row['material'],
            pattern: row['pattern'],
            season: row['season'],
            confidence: 1.0, 
            wearCount: row['wear_count'] ?? 0,
            dateAdded: DateTime.parse(row['created_at']),
            lastWorn: row['last_worn'] != null ? DateTime.parse(row['last_worn']) : null,
            isFavorite: row['is_favorite'] ?? false,
          );
          await box.put(item.id, item.toJson());
        }
        if (response.isNotEmpty) {
          yield _getItemsFromBox(box);
        }
        onOfflineStatusChanged?.call(false);
      } catch (e) {
        debugPrint('Failed to sync down from Supabase: $e');
        onOfflineStatusChanged?.call(true);
      }
    }

    yield* box.watch().map((_) => _getItemsFromBox(box));
  }

  @override
  Stream<List<ClothingItem>> getItemsByCategory(String category) async* {
    final box = await _box;
    yield _getItemsFromBox(box).where((item) => item.category == category).toList();

    yield* box.watch().map((_) {
      return _getItemsFromBox(box).where((item) => item.category == category).toList();
    });
  }

  @override
  Future<void> toggleFavorite(String id, bool isFavorite) async {
    final box = await _box;
    final raw = box.get(id);
    if (raw != null) {
      final item = ClothingItem.fromJson(Map<String, dynamic>.from(raw));
      final updated = item.copyWith(isFavorite: isFavorite);
      await updateItem(updated);
    }
  }

  @override
  Future<void> incrementWearCount(String id) async {
    final box = await _box;
    final raw = box.get(id);
    if (raw != null) {
      final item = ClothingItem.fromJson(Map<String, dynamic>.from(raw));
      final updated = item.copyWith(wearCount: item.wearCount + 1, lastWorn: DateTime.now());
      await updateItem(updated);
    }
  }

  List<ClothingItem> _getItemsFromBox(Box<Map> box) {
    return box.values
        .map((e) => ClothingItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
