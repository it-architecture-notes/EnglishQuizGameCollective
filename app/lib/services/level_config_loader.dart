import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/level_config.dart';
import '../models/level_translations.dart';

/// Reads one sub-level’s `questions.json` from the asset bundle into a [LevelConfig].
/// Invoked by [QuizRunnerScreen._runRegular], reminder resolution, and [ImageQuizScreen._loadLevel] fallback.
Future<LevelConfig> loadLevelConfig(String iconImageName) async {
  final path = 'assets/quiz-data/levels/$iconImageName/questions.json';
  final String raw;
  try {
    raw = await rootBundle.loadString(path);
  } catch (e) {
    throw Exception('Level config not found: $path ($e)');
  }
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) {
    throw FormatException('Expected object in $path');
  }
  return LevelConfig.fromJson(decoded);
}

/// Optional `translations.json` beside `questions.json`. Returns null if missing, empty, or invalid.
Future<TranslationsPageData?> loadLevelTranslations(String iconImageName) async {
  final path = 'assets/quiz-data/levels/$iconImageName/translations.json';
  try {
    final raw = await rootBundle.loadString(path);
    return TranslationsPageData.parse(raw);
  } catch (_) {
    return null;
  }
}
