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
          iconImageName: 'a',
          title: 'A',
        ),
        ordinalLevelIndex: 1,
        progressKey: '1_a',
      ),
      SubLevelItem(
        const SubLevel(
          mainLevel: 1,
          iconImageName: 'b',
          title: 'B',
        ),
        ordinalLevelIndex: 2,
        progressKey: '1_b',
      ),
      SubLevelItem(
        const SubLevel(
          mainLevel: 1,
          iconImageName: 'c',
          title: 'C',
        ),
        ordinalLevelIndex: 3,
        progressKey: '1_c',
      ),
      SubLevelItem(
        const SubLevel(
          mainLevel: 2,
          iconImageName: 'd',
          title: 'D',
        ),
        ordinalLevelIndex: 4,
        progressKey: '2_d',
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
          storyText: const {'en': 'x'},
        ),
        StoryPageConfig(
          eventId: 102,
          pageTemplateId: 1,
          trigger: const StoryTrigger(
            type: StoryTriggerType.beforeLevel,
            level: 2,
          ),
          storyText: const {'en': 'y'},
        ),
        StoryPageConfig(
          eventId: 103,
          pageTemplateId: 4,
          trigger: const StoryTrigger(
            type: StoryTriggerType.afterLevel,
            level: 0,
          ),
          storyText: const {'en': 'z'},
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

    test('pagesReadyToMarkCompleted requires trigger local level to have a star',
        () {
      final quizProgress = QuizTypeProgress(
        levels: const {
          '1_a': LevelProgress(
              progressKey: '1_a', highestStars: 2, highestDiamonds: 2),
          '1_b': LevelProgress(
              progressKey: '1_b', highestStars: 3, highestDiamonds: 3),
          '1_c': LevelProgress(
              progressKey: '1_c', highestStars: 0, highestDiamonds: 1),
        },
      );

      final ready = StoryTriggerService.pagesReadyToMarkCompleted(
        mainStory: mainStory,
        storyProgress: const StoryProgressState(),
        quizProgress: quizProgress,
        mainLevelId: 1,
        flowSubLevels: flowItems,
      );

      expect(ready.map((p) => p.eventId), [101, 102]);
    });

    test(
        'pagesReadyToMarkCompleted skips page when its trigger level has no star',
        () {
      final quizProgress = QuizTypeProgress(
        levels: const {
          '1_b': LevelProgress(
              progressKey: '1_b', highestStars: 0, highestDiamonds: 0),
          '1_c': LevelProgress(
              progressKey: '1_c', highestStars: 3, highestDiamonds: 3),
        },
      );

      final ready = StoryTriggerService.pagesReadyToMarkCompleted(
        mainStory: mainStory,
        storyProgress: const StoryProgressState(),
        quizProgress: quizProgress,
        mainLevelId: 1,
        flowSubLevels: flowItems,
      );

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
