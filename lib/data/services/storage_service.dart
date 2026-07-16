import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final storageServiceProvider = Provider((ref) => StorageService());

class StorageService {
  Future<String?> uploadItemImage(String uid, String itemId, XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final path = '$uid/$itemId.jpg';
      
      final storage = Supabase.instance.client.storage.from('clothing-images');
      
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );
      
      return storage.getPublicUrl(path);
    } catch (e) {
      debugPrint('Storage error: $e');
      return null;
    }
  }
}
