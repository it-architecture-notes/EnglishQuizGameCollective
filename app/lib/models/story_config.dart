enum StoryTriggerType { beforeLevel, afterLevel }

class StoryTrigger {
  const StoryTrigger({
    required this.type,
    required this.level,
  });

  final StoryTriggerType type;

  /// `title` from `game-flow.json` for the level this story fires on
  /// (works for regular and reminder levels). Empty string means the last
  /// regular level in the main level.
  final String level;

  static StoryTrigger fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] as String?)?.trim().toLowerCase();
    final type = rawType == 'after_level'
        ? StoryTriggerType.afterLevel
        : StoryTriggerType.beforeLevel;
    final rawLevel = json['level'];
    // Accept string flow title; empty / missing → last regular level.
    final level = (rawLevel?.toString() ?? '').trim();
    return StoryTrigger(
      type: type,
      level: level,
    );
  }
}

class StoryPageConfig {
  const StoryPageConfig({
    required this.eventId,
    required this.pageTemplateId,
    required this.trigger,
    this.storyText = const {},
    this.storyTexts = const [],
    this.characterImage,
    this.sceneImage,
    this.sceneImages = const [],
  });

  final int eventId;
  final int pageTemplateId;
  final StoryTrigger trigger;

  /// Localised copy for single-caption layouts. JSON key: `story_text`.
  /// Shape: { "en": "...", "fr": "..." }
  final Map<String, String> storyText;

  /// Per-slide captions for template 5 (`multi_image_gallery`).
  /// JSON key: `story_texts` — parallel to [sceneImages].
  /// Each entry: { "en": "...", "tr": "..." }
  final List<Map<String, String>> storyTexts;

  /// Optional Flutter asset path for template 1 — bottom-left character sprite.
  /// JSON key: `character_image`.
  final String? characterImage;

  /// Optional Flutter asset path for template 1 / 4 — single scene image.
  /// JSON key: `scene_image`.
  final String? sceneImage;

  /// Ordered scene images for template 5. JSON key: `scene_images`.
  final List<String> sceneImages;

  /// Returns the localised value of [storyText], falling back to English.
  String localizedStoryText(String languageCode) =>
      storyText[languageCode] ?? storyText['en'] ?? '';

  /// Localised caption for slide [index] in a multi-image gallery.
  /// Prefers [storyTexts][index]; falls back to [storyText] when missing.
  String localizedStoryTextAt(int index, String languageCode) {
    if (index >= 0 && index < storyTexts.length) {
      final map = storyTexts[index];
      final v = map[languageCode] ?? map['en'] ?? '';
      if (v.isNotEmpty) return v;
    }
    return localizedStoryText(languageCode);
  }

  static StoryPageConfig fromJson(Map<String, dynamic> json) {
    final storyTextRaw =
        json['story_text'] as Map<String, dynamic>? ?? const {};
    final storyText = storyTextRaw.map(
      (k, v) => MapEntry(k, v.toString()),
    );

    final storyTextsRaw = json['story_texts'] as List<dynamic>? ?? const [];
    final storyTexts = storyTextsRaw
        .whereType<Map>()
        .map(
          (m) => m.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          ),
        )
        .toList(growable: false);

    const storyImagesPrefix = 'assets/images/story/';
    String? _storyImagePath(dynamic raw) {
      final v = raw?.toString().trim();
      if (v == null || v.isEmpty) return null;
      return v.startsWith('assets/') ? v : '$storyImagesPrefix$v';
    }

    final sceneImagesRaw = json['scene_images'] as List<dynamic>? ?? const [];
    final sceneImages = sceneImagesRaw
        .map(_storyImagePath)
        .whereType<String>()
        .toList(growable: false);

    return StoryPageConfig(
      eventId: (json['event_id'] as num?)?.toInt() ?? 0,
      pageTemplateId: (json['page_template_id'] as num?)?.toInt() ?? 1,
      trigger: StoryTrigger.fromJson(
        (json['trigger'] as Map<String, dynamic>? ?? const {}),
      ),
      storyText: storyText,
      storyTexts: storyTexts,
      characterImage: _storyImagePath(json['character_image']),
      sceneImage: _storyImagePath(json['scene_image']),
      sceneImages: sceneImages,
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
