import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/vocabulary_quiz.dart';

const int kMinVocabularyQuestions = 4;

/// Builds the asset path for a vocabulary level JSON file.
///
/// [iconImageName] comes from [SubLevel.iconImageName] (e.g. "airport").
/// [levelNumber] comes from [SubLevel.levelNumber] (e.g. 1).
/// Result: "assets/quiz-data/vocabulary-quiz/airport-1.json"
String vocabularyDataPath(String iconImageName, int levelNumber) {
  return 'assets/quiz-data/vocabulary-quiz/$iconImageName-$levelNumber.json';
}

/// Loads and parses a [VocabularyLevel] for the given level.
///
/// Throws an [Exception] if the file is missing, cannot be parsed, or contains
/// fewer than [kMinVocabularyQuestions] questions.
Future<VocabularyLevel> loadVocabularyLevel(
  String iconImageName,
  int levelNumber,
) async {
  final path = vocabularyDataPath(iconImageName, levelNumber);
  final String jsonString;
  try {
    jsonString = await rootBundle.loadString(path);
  } catch (e) {
    throw Exception('Vocabulary data not found: $path');
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

  final level = VocabularyLevel.fromJson(decoded);

  if (level.questions.length < kMinVocabularyQuestions) {
    throw Exception(
      'Level needs at least $kMinVocabularyQuestions questions '
      '(found ${level.questions.length}) in $path',
    );
  }

  return level;
}
