import 'package:flutter/services.dart';

/// Level key = iconImageName (folder name under quiz-data/levels/, e.g. "airport-1").
String imageQuizLevelKey(String iconImageName) {
  return iconImageName;
}

const String _quizImagePrefix = 'assets/quiz-data/levels/';

/// Prefix with trailing slash for listAssets filtering (e.g. "assets/quiz-data/levels/airport-1/").
String imageQuizLevelAssetPrefix(String levelKey) {
  return '$_quizImagePrefix$levelKey/';
}

/// Discovers image asset paths for an image quiz level from the bundle.
/// Returns full asset paths (e.g. assets/quiz-data/levels/airport-1/pilot.png).
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

const String _animalsPrefix = 'assets/images/animals/';
const String _monstersPrefix = 'assets/images/monsters/';

/// Discovers guest animal names from the bundle (subfolders of assets/images/animals/).
/// Returns unique folder names, e.g. [dog, squirrel, ...], sorted. Empty if none found.
Future<List<String>> discoverGuestAnimalNames() async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final names = <String>{};
  for (final path in manifest.listAssets()) {
    if (!path.startsWith(_animalsPrefix) || _isDsStore(path)) continue;
    final after = path.substring(_animalsPrefix.length);
    final segment = after.split('/').first;
    if (segment.isNotEmpty) names.add(segment);
  }
  final list = names.toList()..sort();
  return list;
}

/// Discovers monster names from the bundle (assets/images/monsters/).
/// If path is monsters/X.png then name is X; if monsters/Subdir/file.png then name is Subdir.
/// Returns unique names, sorted. Empty if none found.
Future<List<String>> discoverMonsterNames() async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final names = <String>{};
  for (final path in manifest.listAssets()) {
    if (!path.startsWith(_monstersPrefix) || _isDsStore(path)) continue;
    final after = path.substring(_monstersPrefix.length);
    final parts = after.split('/');
    if (parts.length == 1) {
      final name = assetPathToBasename(parts.first);
      if (name.isNotEmpty) names.add(name);
    } else {
      if (parts.first.isNotEmpty) names.add(parts.first);
    }
  }
  final list = names.toList()..sort();
  return list;
}
