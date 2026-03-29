import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/story_config.dart';
import '../quiz_game_constants.dart';

Future<StoryConfigData> loadStoryConfig() async {
  const storiesPath = 'assets/data/story/$kQuizGameType-main-level-stories.json';
  const templatesPath = 'assets/data/story/story-templates.json';

  String storiesJson;
  String templatesJson;

  try {
    storiesJson = await rootBundle.loadString(storiesPath);
  } catch (e) {
    throw Exception('Failed to load $storiesPath: $e');
  }

  try {
    templatesJson = await rootBundle.loadString(templatesPath);
  } catch (e) {
    throw Exception('Failed to load $templatesPath: $e');
  }

  final storiesMap = jsonDecode(storiesJson) as Map<String, dynamic>;
  final templatesMap = jsonDecode(templatesJson) as Map<String, dynamic>;

  final mainLevels = (storiesMap['main_levels'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(MainLevelStoryConfig.fromJson)
      .toList();

  final templates =
      (templatesMap['story_templates'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(StoryTemplateConfig.fromJson)
          .toList();

  return StoryConfigData(
    mainLevels: mainLevels,
    templatesById: {for (final t in templates) t.templateId: t},
  );
}
