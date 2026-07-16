import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageUtils {
  static ImageProvider getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      final base64String = imageUrl.split(',').last;
      return MemoryImage(base64Decode(base64String));
    } else if (imageUrl.startsWith('assets/')) {
      return AssetImage(imageUrl);
    }
    else if (imageUrl.startsWith('blob:')) {
      return NetworkImage(imageUrl);
    } else if (imageUrl.startsWith('http')) {
      return CachedNetworkImageProvider(imageUrl);
    }
    // Fallback for unexpected formats (like local file paths if not on Web)
    // Note: To properly support mobile, you would use FileImage(File(imageUrl)) here
    return NetworkImage(imageUrl);
  }
}
