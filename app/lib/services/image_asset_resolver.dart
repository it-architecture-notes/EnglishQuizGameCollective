import 'package:flutter/services.dart';

import 'image_quiz_level_loader.dart';

/// Finds an existing asset path for [imageName] under the image quiz level folder.
Future<String?> resolveQuizImageAsset(String levelKey, String imageName) async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final prefix = imageQuizLevelAssetPrefix(levelKey);
  final assets = manifest.listAssets();
  for (final ext in ['.png', '.jpg', '.jpeg', '.webp']) {
    final p = '$prefix$imageName$ext';
    if (assets.contains(p)) return p;
  }
  return null;
}
