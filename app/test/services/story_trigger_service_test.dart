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
          directoryName: 'a',
          title: 'A',
        ),
        ordinalLevelIndex: 1,
        progressKey: '1_a',
      ),
      SubLevelItem(
        const SubLevel(
          mainLevel: 1,
          directoryName: 'b',
          title: 'B',
        ),
        ordinalLevelIndex: 2,
        progressKey: '1_b',
      ),
      SubLevelItem(
        const SubLevel(
          mainLevel: 1,
          directoryName: 'c',
          title: 'C',
        ),
        ordinalLevelIndex: 3,
        progressKey: '1_c',
      ),
      SubLevelItem(
        const SubLevel(
          mainLevel: 1,
          directoryName: '',
          title: 'Reminder 2',
          kind: 'reminder',
          reminderIndex: 2,
        ),
        ordinalLevelIndex: 4,
        progressKey: '1_reminder_2',
      ),
      SubLevelItem(
        const SubLevel(
          mainLevel: 2,
          directoryName: 'd',
          title: 'D',
        ),
        ordinalLevelIndex: 5,
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
            level: 'A',
          ),
          storyText: const {'en': 'x'},
        ),
        StoryPageConfig(
          eventId: 102,
          pageTemplateId: 1,
          trigger: const StoryTrigger(
            type: StoryTriggerType.beforeLevel,
            level: 'B',
          ),
          storyText: const {'en': 'y'},
        ),
        StoryPageConfig(
          eventId: 103,
          pageTemplateId: 4,
          trigger: const StoryTrigger(
            type: StoryTriggerType.afterLevel,
            level: '',
          ),
          storyText: const {'en': 'z'},
        ),
        StoryPageConfig(
          eventId: 104,
          pageTemplateId: 4,
          trigger: const StoryTrigger(
            type: StoryTriggerType.afterLevel,
            level: 'Reminder 2',
          ),
          storyText: const {'en': 'done'},
        ),
      ],
    );

    test('findBeforeLevelPage returns matching incomplete page by title', () {
      final page = StoryTriggerService.findBeforeLevelPage(
        mainStory: mainStory,
        storyProgress: const StoryProgressState(),
        mainLevelId: 1,
        levelTitle: 'A',
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
        levelTitle: 'A',
        flowSubLevels: flowItems,
      );
      expect(page, isNull);
    });

    test('findAfterLevelPage resolves empty level as last regular title', () {
      final page = StoryTriggerService.findAfterLevelPage(
        mainStory: mainStory,
        storyProgress: const StoryProgressState(),
        mainLevelId: 1,
        levelTitle: 'C',
        flowSubLevels: flowItems,
      );
      expect(page?.eventId, 103);
    });

    test('findAfterLevelPage matches reminder title', () {
      final page = StoryTriggerService.findAfterLevelPage(
        mainStory: mainStory,
        storyProgress: const StoryProgressState(),
        mainLevelId: 1,
        levelTitle: 'Reminder 2',
        flowSubLevels: flowItems,
      );
      expect(page?.eventId, 104);
    });

    test('pagesReadyToMarkCompleted requires trigger level to have a star',
        () {
      final quizProgress = QuizTypeProgress(
        levels: const {
          '1_a': LevelProgress(
              progressKey: '1_a', highestStars: 2, highestDiamonds: 2),
          '1_b': LevelProgress(
              progressKey: '1_b', highestStars: 3, highestDiamonds: 3),
          '1_c': LevelProgress(
              progressKey: '1_c', highestStars: 2, highestDiamonds: 2),
        },
      );

      final ready = StoryTriggerService.pagesReadyToMarkCompleted(
        mainStory: mainStory,
        storyProgress: const StoryProgressState(),
        quizProgress: quizProgress,
        mainLevelId: 1,
        flowSubLevels: flowItems,
      );

      // before_level skipped; after empty→C ready; Reminder 2 not auto-completed.
      expect(ready.map((p) => p.eventId), [103]);
    });

    test('replay rule: no before-level story for unmatched title', () {
      final page = StoryTriggerService.findBeforeLevelPage(
        mainStory: mainStory,
        storyProgress: const StoryProgressState(),
        mainLevelId: 1,
        levelTitle: 'C',
        flowSubLevels: flowItems,
      );

      expect(page, isNull);
    });

    test('resolveTriggerLevelTitle uses configured title', () {
      final page = mainStory.storySequences[1];
      expect(
        StoryTriggerService.resolveTriggerLevelTitle(
          page: page,
          mainLevelId: 1,
          flowSubLevels: flowItems,
        ),
        'B',
      );
    });
  });
}
