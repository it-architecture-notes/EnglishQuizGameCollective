import 'dart:convert';

import 'package:flutter/services.dart';

import '../app_flavor.dart';
import '../models/level_config.dart';
import '../models/level_translations.dart';
import 'app_settings_service.dart';
import 'conversation_character_pool.dart';

/// Reads one sub-level’s `questions.json` from the asset bundle into a [LevelConfig].
/// Invoked by [QuizRunnerScreen._runRegular], reminder resolution, and [ImageQuizScreen._loadLevel] fallback.
///
/// Tries `{directoryName}/{flavor}/questions.json` first (e.g. `greetings/kids/questions.json`)
/// and falls back to the level's root `questions.json` if that level hasn't
/// been migrated to a flavor-specific folder yet. Applies to both flavors —
/// a level with no `adults/` subfolder still resolves via its root file.
Future<LevelConfig> loadLevelConfig(String directoryName) async {
  final base = 'assets/quiz-data/levels/$directoryName';
  final flavorPath = '$base/${AppConfig.flavorDir}/questions.json';
  final rootPath = '$base/questions.json';
  String? raw;
  try {
    raw = await rootBundle.loadString(flavorPath);
  } catch (_) {
    try {
      raw = await rootBundle.loadString(rootPath);
    } catch (_) {
      raw = null;
    }
  }
  if (raw == null) {
    throw Exception('Level config not found: $flavorPath (or $rootPath)');
  }
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) {
    throw FormatException('Expected object in questions.json for $directoryName');
  }
  final config = LevelConfig.fromJson(decoded);
  await _resolveConversationCharacterNames(config);
  return config;
}

/// Fills in blank `character1`/`character2` on ConvoTemplate-1/DialogueCompletion
/// rows with a randomly-picked, locale-appropriate name — one pool built per
/// level load, reused for every question in that level. Authored names are
/// never touched (see [ConversationCharacterPool.resolveNames]).
Future<void> _resolveConversationCharacterNames(LevelConfig config) async {
  final hasConversational = config.questions
      .any((q) => q.convoData != null || q.dialogueCompletionData != null);
  if (!hasConversational) return;

  final userLanguage = await AppSettingsService.getLanguage();
  final pool = await ConversationCharacterPool.loadForLanguage(userLanguage);

  for (final question in config.questions) {
    final convo = question.convoData;
    if (convo != null) {
      final (c1, c2) =
          pool.resolveNames(question.genders, convo.character1, convo.character2);
      convo.character1 = c1;
      convo.character2 = c2;
    }
    final dialogue = question.dialogueCompletionData;
    if (dialogue != null) {
      final (c1, c2) =
          pool.resolveNames(question.genders, dialogue.character1, dialogue.character2);
      dialogue.character1 = c1;
      dialogue.character2 = c2;
    }
  }
}

/// Optional `translations.json` beside `questions.json`. Returns null if missing, empty, or invalid.
///
/// Tries `{directoryName}/{flavor}/translations.json` first, falling back to
/// the level's root `translations.json` — same rule as [loadLevelConfig].
Future<TranslationsPageData?> loadLevelTranslations(String directoryName) async {
  final base = 'assets/quiz-data/levels/$directoryName';
  final flavorPath = '$base/${AppConfig.flavorDir}/translations.json';
  final rootPath = '$base/translations.json';
  try {
    final raw = await rootBundle.loadString(flavorPath);
    return TranslationsPageData.parse(raw);
  } catch (_) {
    try {
      final raw = await rootBundle.loadString(rootPath);
      return TranslationsPageData.parse(raw);
    } catch (_) {
      return null;
    }
  }
}
