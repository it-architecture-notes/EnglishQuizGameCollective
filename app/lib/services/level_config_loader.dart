import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/level_config.dart';

/// Loads `assets/quiz-data/levels/{iconImageName}/questions.json`.
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
