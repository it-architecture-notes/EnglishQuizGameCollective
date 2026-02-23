import 'package:flutter/services.dart';

/// Level key = iconImageName-levelNumber, e.g. plane-4.
String imageQuizLevelKey(String iconImageName, int levelNumber) {
  return '$iconImageName-$levelNumber';
}

const String _quizImagePrefix = 'assets/images/quiz/';

/// Prefix with trailing slash for listAssets filtering (e.g. "assets/images/quiz/plane-1/").
String imageQuizLevelAssetPrefix(String levelKey) {
  return '$_quizImagePrefix$levelKey/';
}

/// Discovers image asset paths for an image quiz level from the bundle.
/// Returns full asset paths (e.g. assets/images/quiz/plane-1/pilot.png).
/// Use [imageQuizLevelKey] to build the level key.
Future<List<String>> loadImageQuizLevelAssetPaths(String levelKey) async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final prefix = imageQuizLevelAssetPrefix(levelKey);
  final all = manifest.listAssets();
  final paths = all
      .where((String path) => path.startsWith(prefix))
      .toList();
  return paths;
}

/// Basename without extension from an asset path (e.g. "assets/images/quiz/plane-1/pilot.png" -> "pilot").
String assetPathToBasename(String path) {
  final name = path.split('/').last;
  final dot = name.lastIndexOf('.');
  return dot > 0 ? name.substring(0, dot) : name;
}

/// Loads vocabulary (image basenames) for an image quiz level. Returns empty list if not enough images.
Future<List<String>> loadImageQuizLevelVocabulary(String levelKey) async {
  final paths = await loadImageQuizLevelAssetPaths(levelKey);
  final basenames = paths.map(assetPathToBasename).toList();
  return basenames;
}
