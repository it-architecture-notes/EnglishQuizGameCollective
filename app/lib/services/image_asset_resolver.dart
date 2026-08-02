import 'package:flutter/services.dart';

import '../app_flavor.dart';
import 'image_quiz_level_loader.dart';

/// Finds an existing asset path for [imageName] under the image quiz level folder.
///
/// Tries `{levelKey}/{flavor}/{imageName}.{ext}` first (e.g.
/// `greetings/kids/smile.png`), then falls back to the level's root
/// `{levelKey}/{imageName}.{ext}` when no flavor-specific illustration exists
/// yet — the shared/legacy image pool used by both flavors.
Future<String?> resolveQuizImageAsset(String levelKey, String imageName) async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final rootPrefix = imageQuizLevelAssetPrefix(levelKey);
  final flavorPrefix = '$rootPrefix${AppConfig.flavorDir}/';
  final assets = manifest.listAssets();
  for (final prefix in [flavorPrefix, rootPrefix]) {
    for (final ext in ['.png', '.jpg', '.jpeg', '.webp']) {
      final p = '$prefix$imageName$ext';
      if (assets.contains(p)) return p;
    }
  }
  return null;
}
