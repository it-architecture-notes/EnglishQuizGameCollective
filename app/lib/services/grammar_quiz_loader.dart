import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/grammar_quiz.dart';

const int kMinGrammarQuestions = 4;

const String _kGrammarCharactersPrefix = 'assets/images/grammar-characters/';

/// Builds the asset path for a grammar level JSON file.
///
/// [iconImageName] comes from [SubLevel.iconImageName] (e.g. "airport").
/// [levelNumber] comes from [SubLevel.levelNumber] (e.g. 1).
/// Result: "assets/quiz-data/grammar-quiz/airport-1.json"
String grammarDataPath(String iconImageName, int levelNumber) {
  return 'assets/quiz-data/grammar-quiz/$iconImageName-$levelNumber.json';
}

/// Loads and parses a [GrammarLevel] for the given level.
///
/// Throws an [Exception] if the file is missing, cannot be parsed, or contains
/// fewer than [kMinGrammarQuestions] questions.
Future<GrammarLevel> loadGrammarLevel(
  String iconImageName,
  int levelNumber,
) async {
  final path = grammarDataPath(iconImageName, levelNumber);
  final String jsonString;
  try {
    jsonString = await rootBundle.loadString(path);
  } catch (e) {
    throw Exception('Grammar data not found: $path');
  }

  final dynamic decoded;
  try {
    decoded = jsonDecode(jsonString);
  } catch (e) {
    throw Exception('Invalid JSON in $path: $e');
  }

  if (decoded is! Map<String, dynamic>) {
    throw Exception('Expected a JSON object in $path');
  }

  final level = GrammarLevel.fromJson(decoded);

  if (level.questions.length < kMinGrammarQuestions) {
    throw Exception(
      'Level needs at least $kMinGrammarQuestions questions '
      '(found ${level.questions.length}) in $path',
    );
  }

  return level;
}

/// Discovers grammar character image asset paths from the bundle.
/// Returns paths like "assets/images/grammar-characters/coach.png".
/// Skips hidden files (names starting with .). Returns empty list if none found.
Future<List<String>> loadGrammarCharacterImages() async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final all = manifest.listAssets();
  return all
      .where((p) =>
          p.startsWith(_kGrammarCharactersPrefix) &&
          !p.split('/').last.startsWith('.'))
      .toList();
}
