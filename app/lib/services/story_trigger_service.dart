import '../models/quiz_flow.dart';
import '../models/story_config.dart';
import '../models/story_progress.dart';
import 'quiz_progress_service.dart';

class StoryTriggerService {
  const StoryTriggerService._();

  /// Finds an incomplete before-level story whose trigger matches [levelTitle].
  static StoryPageConfig? findBeforeLevelPage({
    required MainLevelStoryConfig? mainStory,
    required StoryProgressState storyProgress,
    required int mainLevelId,
    required String levelTitle,
    required Iterable<SubLevelItem> flowSubLevels,
  }) {
    if (mainStory == null || levelTitle.isEmpty) return null;
    for (final page in mainStory.storySequences) {
      if (page.trigger.type != StoryTriggerType.beforeLevel) continue;
      if (storyProgress.isCompleted(
          mainLevelId: mainLevelId, eventId: page.eventId)) {
        continue;
      }
      final triggerTitle = resolveTriggerLevelTitle(
        page: page,
        mainLevelId: mainLevelId,
        flowSubLevels: flowSubLevels,
      );
      if (triggerTitle == levelTitle) return page;
    }
    return null;
  }

  /// Finds an incomplete after-level story whose trigger matches [levelTitle].
  static StoryPageConfig? findAfterLevelPage({
    required MainLevelStoryConfig? mainStory,
    required StoryProgressState storyProgress,
    required int mainLevelId,
    required String levelTitle,
    required Iterable<SubLevelItem> flowSubLevels,
  }) {
    if (mainStory == null || levelTitle.isEmpty) return null;
    for (final page in mainStory.storySequences) {
      if (page.trigger.type != StoryTriggerType.afterLevel) continue;
      if (storyProgress.isCompleted(
          mainLevelId: mainLevelId, eventId: page.eventId)) {
        continue;
      }
      final triggerTitle = resolveTriggerLevelTitle(
        page: page,
        mainLevelId: mainLevelId,
        flowSubLevels: flowSubLevels,
      );
      if (triggerTitle == levelTitle) return page;
    }
    return null;
  }

  static List<StoryPageConfig> pagesReadyToMarkCompleted({
    required MainLevelStoryConfig? mainStory,
    required StoryProgressState storyProgress,
    required QuizTypeProgress quizProgress,
    required int mainLevelId,
    required Iterable<SubLevelItem> flowSubLevels,
  }) {
    if (mainStory == null) return const [];
    final byTitle = _itemByTitle(flowSubLevels, mainLevelId);

    final ready = <StoryPageConfig>[];
    for (final page in mainStory.storySequences) {
      // before_level pages must be shown to the user — never auto-complete them.
      if (page.trigger.type == StoryTriggerType.beforeLevel) continue;
      if (storyProgress.isCompleted(
          mainLevelId: mainLevelId, eventId: page.eventId)) {
        continue;
      }
      final triggerTitle = resolveTriggerLevelTitle(
        page: page,
        mainLevelId: mainLevelId,
        flowSubLevels: flowSubLevels,
      );
      final item = byTitle[triggerTitle];
      if (item == null) continue;
      // Reminder completion is not stored as quiz stars; skip auto-complete here.
      // Those pages are shown via [findAfterLevelPage] when the reminder finishes.
      if (item.sub.isReminder) continue;
      final stars =
          quizProgress.levels[item.progressKey]?.highestStars ?? 0;
      if (stars >= 1) {
        ready.add(page);
      }
    }
    return ready;
  }

  static Map<int, int> localLevelByOrdinal(
      Iterable<SubLevelItem> flowSubLevels) {
    final localCounterByMain = <int, int>{};
    final localByOrdinal = <int, int>{};
    for (final item in flowSubLevels) {
      final mainLevelId = item.sub.mainLevel;
      final nextLocal = (localCounterByMain[mainLevelId] ?? 0) + 1;
      localCounterByMain[mainLevelId] = nextLocal;
      localByOrdinal[item.ordinalLevelIndex] = nextLocal;
    }
    return localByOrdinal;
  }

  /// Resolves the flow `title` this page triggers on.
  /// Empty [StoryTrigger.level] → last regular level title in [mainLevelId].
  static String resolveTriggerLevelTitle({
    required StoryPageConfig page,
    required int mainLevelId,
    required Iterable<SubLevelItem> flowSubLevels,
  }) {
    final configured = page.trigger.level.trim();
    if (configured.isNotEmpty) return configured;
    return lastRegularLevelTitle(mainLevelId, flowSubLevels) ?? '';
  }

  /// Whether [page]'s trigger points at the last regular level of [mainLevelId].
  static bool isTriggerOnLastRegularLevel({
    required StoryPageConfig page,
    required int mainLevelId,
    required Iterable<SubLevelItem> flowSubLevels,
  }) {
    final triggerTitle = resolveTriggerLevelTitle(
      page: page,
      mainLevelId: mainLevelId,
      flowSubLevels: flowSubLevels,
    );
    final lastTitle = lastRegularLevelTitle(mainLevelId, flowSubLevels);
    return lastTitle != null && triggerTitle == lastTitle;
  }

  /// Last regular level's `title` for [mainLevelId], or null if none.
  static String? lastRegularLevelTitle(
    int mainLevelId,
    Iterable<SubLevelItem> flowSubLevels,
  ) {
    String? last;
    for (final item in flowSubLevels) {
      if (item.sub.mainLevel == mainLevelId && !item.sub.isReminder) {
        last = item.sub.title;
      }
    }
    return last;
  }

  static Map<String, SubLevelItem> _itemByTitle(
    Iterable<SubLevelItem> flowSubLevels,
    int mainLevelId,
  ) {
    final map = <String, SubLevelItem>{};
    for (final item in flowSubLevels) {
      if (item.sub.mainLevel != mainLevelId) continue;
      final title = item.sub.title.trim();
      if (title.isEmpty) continue;
      map[title] = item;
    }
    return map;
  }
}
