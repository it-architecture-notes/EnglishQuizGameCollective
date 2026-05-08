import '../models/quiz_flow.dart';
import '../models/story_config.dart';
import '../models/story_progress.dart';
import 'quiz_progress_service.dart';

class StoryTriggerService {
  const StoryTriggerService._();

  static StoryPageConfig? findBeforeLevelPage({
    required MainLevelStoryConfig? mainStory,
    required StoryProgressState storyProgress,
    required int mainLevelId,
    required int currentLocalLevel,
    required Iterable<SubLevelItem> flowSubLevels,
  }) {
    if (mainStory == null) return null;
    for (final page in mainStory.storySequences) {
      if (page.trigger.type != StoryTriggerType.beforeLevel) continue;
      if (storyProgress.isCompleted(
          mainLevelId: mainLevelId, eventId: page.eventId)) {
        continue;
      }
      final triggerLevel = _resolveTriggerLevel(
        page: page,
        mainLevelId: mainLevelId,
        flowSubLevels: flowSubLevels,
      );
      if (triggerLevel == currentLocalLevel) return page;
    }
    return null;
  }

  static StoryPageConfig? findAfterLevelPage({
    required MainLevelStoryConfig? mainStory,
    required StoryProgressState storyProgress,
    required int mainLevelId,
    required int completedLocalLevel,
    required Iterable<SubLevelItem> flowSubLevels,
  }) {
    if (mainStory == null) return null;
    for (final page in mainStory.storySequences) {
      if (page.trigger.type != StoryTriggerType.afterLevel) continue;
      if (storyProgress.isCompleted(
          mainLevelId: mainLevelId, eventId: page.eventId)) {
        continue;
      }
      final triggerLevel = _resolveTriggerLevel(
        page: page,
        mainLevelId: mainLevelId,
        flowSubLevels: flowSubLevels,
      );
      if (triggerLevel == completedLocalLevel) return page;
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
    final mappers = _buildMappers(flowSubLevels);
    final byLocal = mappers[mainLevelId] ?? const <int, String>{};

    final ready = <StoryPageConfig>[];
    for (final page in mainStory.storySequences) {
      // before_level pages must be shown to the user — never auto-complete them.
      if (page.trigger.type == StoryTriggerType.beforeLevel) continue;
      if (storyProgress.isCompleted(
          mainLevelId: mainLevelId, eventId: page.eventId)) {
        continue;
      }
      final triggerLevel = _resolveTriggerLevel(
        page: page,
        mainLevelId: mainLevelId,
        flowSubLevels: flowSubLevels,
      );
      final progressKey = byLocal[triggerLevel];
      final stars = progressKey == null
          ? 0
          : quizProgress.levels[progressKey]?.highestStars ?? 0;
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

  static int resolveTriggerLevel({
    required StoryPageConfig page,
    required int mainLevelId,
    required Iterable<SubLevelItem> flowSubLevels,
  }) {
    return _resolveTriggerLevel(
      page: page,
      mainLevelId: mainLevelId,
      flowSubLevels: flowSubLevels,
    );
  }

  static int _resolveTriggerLevel({
    required StoryPageConfig page,
    required int mainLevelId,
    required Iterable<SubLevelItem> flowSubLevels,
  }) {
    if (page.trigger.level > 0) return page.trigger.level;
    final byMain =
        _buildMappers(flowSubLevels)[mainLevelId] ?? const <int, String>{};
    if (byMain.isEmpty) return 1;
    return byMain.keys.reduce((a, b) => a > b ? a : b);
  }

  static Map<int, Map<int, String>> _buildMappers(
      Iterable<SubLevelItem> flowSubLevels) {
    final localCounterByMain = <int, int>{};
    final mapper = <int, Map<int, String>>{};

    for (final item in flowSubLevels) {
      final mainLevelId = item.sub.mainLevel;
      final nextLocal = (localCounterByMain[mainLevelId] ?? 0) + 1;
      localCounterByMain[mainLevelId] = nextLocal;
      mapper.putIfAbsent(mainLevelId, () => <int, String>{})[nextLocal] =
          item.progressKey;
    }
    return mapper;
  }
}
