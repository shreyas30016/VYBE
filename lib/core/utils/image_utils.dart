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
    return CachedNetworkImageProvider(imageUrl);
  }
}
