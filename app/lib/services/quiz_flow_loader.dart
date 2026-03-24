import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/quiz_flow.dart';

/// Result of loading flow data for the unified game.
class QuizFlowData {
  const QuizFlowData({
    required this.subLevels,
    required this.mainLevels,
  });

  final List<SubLevel> subLevels;
  final List<MainLevelMeta> mainLevels;
}

/// Loads `assets/data/flow/game-flow.json` and `game-flow-main-levels.json`.
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
