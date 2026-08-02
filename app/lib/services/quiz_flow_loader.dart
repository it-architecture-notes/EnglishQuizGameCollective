import 'dart:convert';

import 'package:flutter/services.dart';

import '../app_flavor.dart';
import '../models/quiz_flow.dart';

/// In-memory representation of `game-flow.json` plus main-level metadata for the map.
class QuizFlowData {
  const QuizFlowData({
    required this.subLevels,
    required this.mainLevels,
  });

  final List<SubLevel> subLevels;
  final List<MainLevelMeta> mainLevels;
}

const String _subLevelsPathAdult = 'assets/data/flow/game-flow.json';
const String _subLevelsPathKids = 'assets/data/flow/game-flow-kids.json';
const String _mainLevelsPathAdult =
    'assets/data/flow/game-flow-main-levels.json';
const String _mainLevelsPathKids =
    'assets/data/flow/game-flow-main-levels-kids.json';

/// Loads a flavor's flow asset, falling back to the adult file only when the
/// kids file is missing (kids has fewer/regrouped main levels; adults has no
/// fallback — same asymmetric pattern as `achievement_config_loader.dart`).
Future<String> _loadFlavoredAsset(String adultPath, String kidsPath) async {
  final path = AppConfig.isKids ? kidsPath : adultPath;
  try {
    return await rootBundle.loadString(path);
  } catch (e) {
    if (path == adultPath) {
      throw Exception('Failed to load $path: $e');
    }
    try {
      return await rootBundle.loadString(adultPath);
    } catch (e2) {
      throw Exception('Failed to load $kidsPath or $adultPath: $e2');
    }
  }
}

/// Loads sub-level ordering and main-level banner metadata for the level map UI.
/// Called from [LevelsScreen._loadData] whenever the map needs fresh flow configuration.
Future<QuizFlowData> loadGameFlow() async {
  final subLevelsJson =
      await _loadFlavoredAsset(_subLevelsPathAdult, _subLevelsPathKids);
  final mainLevelsJson =
      await _loadFlavoredAsset(_mainLevelsPathAdult, _mainLevelsPathKids);

  final List<dynamic> subList = jsonDecode(subLevelsJson) as List<dynamic>;
  final List<dynamic> mainList = jsonDecode(mainLevelsJson) as List<dynamic>;

  final subLevels = subList
      .map((e) => SubLevel.fromJson(e as Map<String, dynamic>))
      .toList();
  final mainLevels = mainList
      .map((e) => MainLevelMeta.fromJson(e as Map<String, dynamic>))
      .toList();

  return QuizFlowData(subLevels: subLevels, mainLevels: mainLevels);
}
