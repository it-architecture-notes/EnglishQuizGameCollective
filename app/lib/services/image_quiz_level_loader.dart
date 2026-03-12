import 'package:flutter/services.dart';

/// Level key = iconImageName-levelNumber, e.g. plane-4.
String imageQuizLevelKey(String iconImageName, int levelNumber) {
  return '$iconImageName-$levelNumber';
}

const String _quizImagePrefix = 'assets/quiz-data/image-quiz/quiz-images/';

/// Prefix with trailing slash for listAssets filtering (e.g. "assets/quiz-data/image-quiz/quiz-images/plane-1/").
String imageQuizLevelAssetPrefix(String levelKey) {
  return '$_quizImagePrefix$levelKey/';
}

/// Discovers image asset paths for an image quiz level from the bundle.
/// Returns full asset paths (e.g. assets/quiz-data/image-quiz/quiz-images/plane-1/pilot.png).
/// Excludes macOS .DS_Store and other non-image metadata files.
Future<List<String>> loadImageQuizLevelAssetPaths(String levelKey) async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final prefix = imageQuizLevelAssetPrefix(levelKey);
  final all = manifest.listAssets();
  final paths = all
      .where((String path) => path.startsWith(prefix) && !_isDsStore(path))
      .toList();
  paths.sort();
  return paths;
}

/// Excludes macOS .DS_Store (case-insensitive) so it never appears as an answer.
bool _isDsStore(String path) {
  final name = path.split('/').last.toLowerCase();
  return name == '.ds_store';
}

/// Basename without extension from an asset path (e.g. "assets/quiz-data/image-quiz/quiz-images/plane-1/pilot.png" -> "pilot").
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
