import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/outfit.dart';
import '../../core/utils/analytics.dart';

abstract class OutfitRepository {
  Future<void> saveOutfit(Outfit outfit);
  Future<void> deleteOutfit(String id);
  Stream<List<Outfit>> getOutfitHistory();
}

class OutfitRepositoryImpl implements OutfitRepository {
  final SupabaseClient? supabase;
  final String uid;
  Future<Box<Map>> get _box async => await Hive.openBox<Map>('outfits_$uid');

  OutfitRepositoryImpl({this.supabase, required this.uid});

  Map<String, dynamic> _toSupabaseMap(Outfit outfit) {
    return {
      'id': outfit.id,
      'user_id': uid,
      'name': outfit.occasion ?? 'Outfit',
      'item_ids': outfit.itemIds,
      'created_at': outfit.dateCreated.toIso8601String(),
    };
  }

  @override
  Future<void> saveOutfit(Outfit outfit) async {
    final box = await _box;
    final json = outfit.toJson();
    await box.put(outfit.id, json);

    try {
      if (supabase != null) {
        await supabase!.from('outfits').upsert(_toSupabaseMap(outfit));
      } else {
        debugPrint('Supabase not initialized. Skipped sync for saveOutfit.');
      }
    } catch (e) {
      debugPrint('Failed to sync saveOutfit to Supabase: $e');
    }
  }

  @override
  Future<void> deleteOutfit(String id) async {
    final box = await _box;
    await box.delete(id);

    try {
      if (supabase != null) {
        await supabase!.from('outfits').delete().eq('id', id);
      } else {
        debugPrint('Supabase not initialized. Skipped sync for deleteOutfit.');
      }
    } catch (e) {
      debugPrint('Failed to sync deleteOutfit to Supabase: $e');
    }
  }

  @override
  Stream<List<Outfit>> getOutfitHistory() async* {
    final box = await _box;
    yield _getOutfitsFromBox(box);

    if (supabase != null && uid != 'local_user') {
      try {
        final stopwatch = Stopwatch()..start();
        final response = await supabase!.from('outfits').select().eq('user_id', uid);
        stopwatch.stop();
        Analytics.logApiDuration('Supabase (Outfits)', stopwatch.elapsed);
        for (var row in response) {
          final outfit = Outfit(
            id: row['id'],
            userId: row['user_id'] ?? uid,
            occasion: row['name'],
            itemIds: List<String>.from(row['item_ids'] ?? []),
            dateCreated: DateTime.parse(row['created_at']),
            isSaved: true,
          );
          await box.put(outfit.id, outfit.toJson());
        }
        if (response.isNotEmpty) {
          yield _getOutfitsFromBox(box);
        }
      } catch (e) {
        debugPrint('Failed to sync down outfits from Supabase: $e');
      }
    }

    yield* box.watch().map((_) => _getOutfitsFromBox(box));
  }

  List<Outfit> _getOutfitsFromBox(Box<Map> box) {
    return box.values
        .map((e) => Outfit.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
