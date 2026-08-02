import 'package:flutter/services.dart';

import '../app_flavor.dart';

/// Level key = directoryName (folder name under quiz-data/levels/, e.g. "travel-1").
String imageQuizLevelKey(String directoryName) {
  return directoryName;
}

const String _quizImagePrefix = 'assets/quiz-data/levels/';

/// Prefix with trailing slash for listAssets filtering (e.g. "assets/quiz-data/levels/travel-1/").
String imageQuizLevelAssetPrefix(String levelKey) {
  return '$_quizImagePrefix$levelKey/';
}

/// The two flavor subfolder prefixes under a level (`.../kids/`, `.../adults/`),
/// used to exclude flavor-specific content when scanning the shared root pool.
List<String> _flavorSubfolderPrefixes(String rootPrefix) =>
    ['kids', 'adults'].map((f) => '$rootPrefix$f/').toList();

/// Discovers image asset paths for an image quiz level from the bundle.
/// Returns full asset paths (e.g. assets/quiz-data/levels/travel-1/pilot.png).
///
/// Prefers `{levelKey}/{flavor}/` when that subfolder has any images (a
/// curated, flavor-specific set); otherwise falls back to the level's root
/// images, excluding both flavor subfolders so they're never double-counted
/// as generic root vocabulary. Excludes macOS .DS_Store either way.
Future<List<String>> loadImageQuizLevelAssetPaths(String levelKey) async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final rootPrefix = imageQuizLevelAssetPrefix(levelKey);
  final flavorPrefix = '$rootPrefix${AppConfig.flavorDir}/';
  final all = manifest.listAssets();

  final flavorPaths = all
      .where((p) => p.startsWith(flavorPrefix) && !_isDsStore(p))
      .toList();
  if (flavorPaths.isNotEmpty) {
    flavorPaths.sort();
    return flavorPaths;
  }

  final subfolderPrefixes = _flavorSubfolderPrefixes(rootPrefix);
  final rootPaths = all
      .where((p) =>
          p.startsWith(rootPrefix) &&
          !_isDsStore(p) &&
          !subfolderPrefixes.any(p.startsWith))
      .toList();
  rootPaths.sort();
  return rootPaths;
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
