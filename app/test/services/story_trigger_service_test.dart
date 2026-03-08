import 'package:english_quiz_game/models/quiz_flow.dart';
import 'package:english_quiz_game/models/story_config.dart';
import 'package:english_quiz_game/models/story_progress.dart';
import 'package:english_quiz_game/services/quiz_progress_service.dart';
import 'package:english_quiz_game/services/story_trigger_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StoryTriggerService', () {
    final flowItems = <SubLevelItem>[
      SubLevelItem(
        const SubLevel(
          mainLevel: 1,
          levelNumber: 1,
          iconImageName: 'a',
          title: 'A',
        ),
        ordinalLevelIndex: 1,
      ),
      SubLevelItem(
        const SubLevel(
          mainLevel: 1,
          levelNumber: 2,
          iconImageName: 'b',
          title: 'B',
        ),
        ordinalLevelIndex: 2,
      ),
      SubLevelItem(
        const SubLevel(
          mainLevel: 1,
          levelNumber: 3,
          iconImageName: 'c',
          title: 'C',
        ),
        ordinalLevelIndex: 3,
      ),
      SubLevelItem(
        const SubLevel(
          mainLevel: 2,
          levelNumber: 4,
          iconImageName: 'd',
          title: 'D',
        ),
        ordinalLevelIndex: 4,
      ),
    ];

    final mainStory = MainLevelStoryConfig(
      mainLevelId: 1,
      storyIconAssetPath: null,
      storySequences: [
        StoryPageConfig(
          eventId: 101,
          pageTemplateId: 1,
          trigger: const StoryTrigger(
            type: StoryTriggerType.beforeLevel,
            level: 1,
          ),
          coveredLevelsNumber: 1,
          pageTextListForTemplate: const [],
          pageImageListForTemplate: const [],
          pageAnimationListForTemplate: const [],
        ),
        StoryPageConfig(
          eventId: 102,
          pageTemplateId: 1,
          trigger: const StoryTrigger(
            type: StoryTriggerType.beforeLevel,
            level: 2,
          ),
          coveredLevelsNumber: 2,
          pageTextListForTemplate: const [],
          pageImageListForTemplate: const [],
          pageAnimationListForTemplate: const [],
        ),
        StoryPageConfig(
          eventId: 103,
          pageTemplateId: 3,
          trigger: const StoryTrigger(
            type: StoryTriggerType.afterLevel,
            level: 0,
          ),
          coveredLevelsNumber: 1,
          pageTextListForTemplate: const [],
          pageImageListForTemplate: const [],
          pageAnimationListForTemplate: const [],
        ),
      ],
    );

    test('findBeforeLevelPage returns matching incomplete page', () {
      final page = StoryTriggerService.findBeforeLevelPage(
        mainStory: mainStory,
        storyProgress: const StoryProgressState(),
        mainLevelId: 1,
        currentLocalLevel: 1,
        flowSubLevels: flowItems,
      );
      expect(page?.eventId, 101);
    });

    test('findBeforeLevelPage skips completed page', () {
      final progress = const StoryProgressState().markCompleted(
        mainLevelId: 1,
        eventId: 101,
      );
      final page = StoryTriggerService.findBeforeLevelPage(
        mainStory: mainStory,
        storyProgress: progress,
        mainLevelId: 1,
        currentLocalLevel: 1,
        flowSubLevels: flowItems,
      );
      expect(page, isNull);
    });

    test('findAfterLevelPage resolves level 0 as last level in main', () {
      final page = StoryTriggerService.findAfterLevelPage(
        mainStory: mainStory,
        storyProgress: const StoryProgressState(),
        mainLevelId: 1,
        completedLocalLevel: 3,
        flowSubLevels: flowItems,
      );
      expect(page?.eventId, 103);
    });

    test('pagesReadyToMarkCompleted requires all covered levels passed', () {
      final quizProgress = QuizTypeProgress(
        levels: const {
          1: LevelProgress(levelNumber: 1, highestStars: 2, highestDiamonds: 2),
          2: LevelProgress(levelNumber: 2, highestStars: 3, highestDiamonds: 3),
          3: LevelProgress(levelNumber: 3, highestStars: 0, highestDiamonds: 1),
        },
      );

      final ready = StoryTriggerService.pagesReadyToMarkCompleted(
        mainStory: mainStory,
        storyProgress: const StoryProgressState(),
        quizProgress: quizProgress,
        mainLevelId: 1,
        flowSubLevels: flowItems,
      );

      expect(ready.map((p) => p.eventId), [101]);
    });

    test(
        'replay rule: page covering levels 2-3 is not complete when level 3 fails',
        () {
      final quizProgress = QuizTypeProgress(
        levels: const {
          2: LevelProgress(levelNumber: 2, highestStars: 3, highestDiamonds: 3),
          3: LevelProgress(levelNumber: 3, highestStars: 0, highestDiamonds: 0),
        },
      );

      final ready = StoryTriggerService.pagesReadyToMarkCompleted(
        mainStory: mainStory,
        storyProgress: const StoryProgressState(),
        quizProgress: quizProgress,
        mainLevelId: 1,
        flowSubLevels: flowItems,
      );

      // Event 102 (trigger 2, coverage 2 => levels 2-3) must stay incomplete.
      expect(ready.map((p) => p.eventId).contains(102), isFalse);
    });

    test('replay rule: no before-level story appears for level 3 retry', () {
      final page = StoryTriggerService.findBeforeLevelPage(
        mainStory: mainStory,
        storyProgress: const StoryProgressState(),
        mainLevelId: 1,
        currentLocalLevel: 3,
        flowSubLevels: flowItems,
      );

      // Trigger is at level 2; level 3 retry should not re-show the page.
      expect(page, isNull);
    });

    test('localLevelByOrdinal maps local index per main level', () {
      final map = StoryTriggerService.localLevelByOrdinal(flowItems);
      expect(map[1], 1);
      expect(map[2], 2);
      expect(map[3], 3);
      expect(map[4], 1);
    });
  });
}
