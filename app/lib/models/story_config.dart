enum StoryTriggerType { beforeLevel, afterLevel }

class StoryTrigger {
  const StoryTrigger({
    required this.type,
    required this.level,
  });

  final StoryTriggerType type;
  // Level index within the main level (1-based).
  final int level;

  static StoryTrigger fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] as String?)?.trim().toLowerCase();
    final type = rawType == 'after_level'
        ? StoryTriggerType.afterLevel
        : StoryTriggerType.beforeLevel;
    return StoryTrigger(
      type: type,
      level: (json['level'] as num?)?.toInt() ?? 1,
    );
  }
}

class StoryPageConfig {
  const StoryPageConfig({
    required this.eventId,
    required this.pageTemplateId,
    required this.trigger,
    required this.coveredLevelsNumber,
    required this.pageTextListForTemplate,
    required this.pageImageListForTemplate,
    required this.pageAnimationListForTemplate,
  });

  final int eventId;
  final int pageTemplateId;
  final StoryTrigger trigger;
  final int coveredLevelsNumber;
  final List<Map<String, String>> pageTextListForTemplate;
  final List<String> pageImageListForTemplate;
  final List<String> pageAnimationListForTemplate;

  static StoryPageConfig fromJson(Map<String, dynamic> json) {
    final textListRaw =
        (json['page_text_list_for_template'] as List<dynamic>? ?? const []);
    final textList = textListRaw.map((entry) {
      final map = <String, String>{};
      if (entry is Map<String, dynamic>) {
        for (final e in entry.entries) {
          map[e.key] = e.value.toString();
        }
      }
      return map;
    }).toList();

    return StoryPageConfig(
      eventId: (json['event_id'] as num?)?.toInt() ?? 0,
      pageTemplateId: (json['page_template_id'] as num?)?.toInt() ?? 1,
      trigger: StoryTrigger.fromJson(
        (json['trigger'] as Map<String, dynamic>? ?? const {}),
      ),
      coveredLevelsNumber:
          (json['covered_levels_number'] as num?)?.toInt() ?? 1,
      pageTextListForTemplate: textList,
      pageImageListForTemplate:
          (json['page_image_list_for_template'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
      pageAnimationListForTemplate:
          (json['page_animation_list_for_template'] as List<dynamic>? ??
                  const [])
              .map((e) => e.toString())
              .toList(),
    );
  }
}

class MainLevelStoryConfig {
  const MainLevelStoryConfig({
    required this.mainLevelId,
    required this.storyIconAssetPath,
    required this.storySequences,
  });

  final int mainLevelId;
  final String? storyIconAssetPath;
  final List<StoryPageConfig> storySequences;

  static MainLevelStoryConfig fromJson(Map<String, dynamic> json) {
    final stories = (json['story_sequences'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(StoryPageConfig.fromJson)
        .toList();
    return MainLevelStoryConfig(
      mainLevelId: (json['main_level_id'] as num?)?.toInt() ?? 0,
      storyIconAssetPath: json['story_icon_asset_path']?.toString(),
      storySequences: stories,
    );
  }
}

class StoryTemplateConfig {
  const StoryTemplateConfig({
    required this.templateId,
    required this.layout,
    required this.requiresText,
    required this.requiresImages,
    required this.requiresAnimation,
  });

  final int templateId;
  final String layout;
  final bool requiresText;
  final bool requiresImages;
  final bool requiresAnimation;

  static StoryTemplateConfig fromJson(Map<String, dynamic> json) {
    return StoryTemplateConfig(
      templateId: (json['template_id'] as num?)?.toInt() ?? 0,
      layout: json['layout']?.toString() ?? 'unknown',
      requiresText: json['requires_text'] == true,
      requiresImages: json['requires_images'] == true,
      requiresAnimation: json['requires_animation'] == true,
    );
  }
}

class StoryConfigData {
  const StoryConfigData({
    required this.mainLevels,
    required this.templatesById,
  });

  final List<MainLevelStoryConfig> mainLevels;
  final Map<int, StoryTemplateConfig> templatesById;

  MainLevelStoryConfig? storyForMainLevel(int mainLevelId) {
    for (final item in mainLevels) {
      if (item.mainLevelId == mainLevelId) return item;
    }
    return null;
  }
}
