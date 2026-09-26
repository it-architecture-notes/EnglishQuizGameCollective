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

const String _subLevelsPathAdultsIntermediate =
    'assets/data/flow/game-flow-adults-intermediate.json';
const String _subLevelsPathAdultsBeginner =
    'assets/data/flow/game-flow-adults-beginner.json';
const String _subLevelsPathKids = 'assets/data/flow/game-flow-kids.json';
const String _mainLevelsPathAdultsIntermediate =
    'assets/data/flow/game-flow-main-levels-adults-intermediate.json';
const String _mainLevelsPathAdultsBeginner =
    'assets/data/flow/game-flow-main-levels-adults-beginner.json';
const String _mainLevelsPathKids =
    'assets/data/flow/game-flow-main-levels-kids.json';

/// Loads the active flavor's flow asset, falling back to the adults-intermediate file
/// only when the flavor-specific file is missing/unreadable — same asymmetric pattern
/// for `kids` and `adults-beginner`, both smaller/newer flavors than the
/// adults-intermediate baseline. `adults-intermediate` has no fallback of its own.
Future<String> _loadFlavoredAsset(String flavorPath, String fallbackPath) async {
  try {
    return await rootBundle.loadString(flavorPath);
  } catch (e) {
    if (flavorPath == fallbackPath) {
      throw Exception('Failed to load $flavorPath: $e');
    }
    try {
      return await rootBundle.loadString(fallbackPath);
    } catch (e2) {
      throw Exception('Failed to load $flavorPath or $fallbackPath: $e2');
    }
  }
}

String _subLevelsPathForFlavor() => switch (AppConfig.flavor) {
      AppFlavor.kids => _subLevelsPathKids,
      AppFlavor.adultsBeginner => _subLevelsPathAdultsBeginner,
      AppFlavor.adultsIntermediate => _subLevelsPathAdultsIntermediate,
    };

String _mainLevelsPathForFlavor() => switch (AppConfig.flavor) {
      AppFlavor.kids => _mainLevelsPathKids,
      AppFlavor.adultsBeginner => _mainLevelsPathAdultsBeginner,
      AppFlavor.adultsIntermediate => _mainLevelsPathAdultsIntermediate,
    };

/// Loads sub-level ordering and main-level banner metadata for the level map UI.
/// Called from [LevelsScreen._loadData] whenever the map needs fresh flow configuration.
Future<QuizFlowData> loadGameFlow() async {
  final subLevelsJson = await _loadFlavoredAsset(
      _subLevelsPathForFlavor(), _subLevelsPathAdultsIntermediate);
  final mainLevelsJson = await _loadFlavoredAsset(
      _mainLevelsPathForFlavor(), _mainLevelsPathAdultsIntermediate);

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
