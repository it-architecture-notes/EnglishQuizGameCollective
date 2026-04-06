import 'dart:convert';

import 'package:flutter/services.dart';

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

/// Loads sub-level ordering and main-level banner metadata for the level map UI.
/// Called from [LevelsScreen._loadData] whenever the map needs fresh flow configuration.
Future<QuizFlowData> loadGameFlow() async {
  const subLevelsPath = 'assets/data/flow/game-flow.json';
  const mainLevelsPath = 'assets/data/flow/game-flow-main-levels.json';

  String subLevelsJson;
  String mainLevelsJson;
  try {
    subLevelsJson = await rootBundle.loadString(subLevelsPath);
  } catch (e) {
    throw Exception('Failed to load $subLevelsPath: $e');
  }
  try {
    mainLevelsJson = await rootBundle.loadString(mainLevelsPath);
  } catch (e) {
    throw Exception('Failed to load $mainLevelsPath: $e');
  }

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
