import '../models/achievement_state.dart';
import '../models/reminder_progress.dart';
import '../models/story_progress.dart';
import 'achievement_service.dart';
import 'image_quiz_level_loader.dart';
import 'profile_service.dart';
import 'quiz_progress_service.dart';
import 'quiz_flow_loader.dart';
import 'reminder_progress_service.dart';
import 'story_progress_service.dart';

/// Seeds persisted state for testing Issue-8 achievements and streaks.
/// Use from Settings panel only.
class TestDataService {
  TestDataService._();
  static final TestDataService _instance = TestDataService._();
  static TestDataService get instance => _instance;

  static String _dayKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  /// Seeds profile, quiz progress, and achievement state so multiple
  /// trophies are unlocked or near-unlock for manual verification.
  /// Unlocks: First Quiz, First Perfect, 3-Day Streak, Lightning, Flash,
  /// 10 Quizzes 3 Stars, 50 Quizzes Completed, Brainiac.
  Future<void> seedTrophyTestData() async {
    final now = DateTime.now().toLocal();
    final today = _dayKey(now);

    final profile = await ProfileService.instance.loadOrCreateProfile();
    final updatedProfile = profile.copyWith(
      lastPlayedDay: today,
      currentStreak: 3,
      totalQuestionsAnsweredByQuizType: {
        'image': 500,
        'vocabulary': 20,
      },
    );
    await ProfileService.instance.saveProfile(updatedProfile);

    final imageLevels = <String, Map<String, dynamic>>{};
    for (var i = 1; i <= 50; i++) {
      final key = 'test_level_$i';
      imageLevels[key] = {
        'progressKey': key,
        'highestStars': i <= 10 ? 3 : 1,
        'highestDiamonds': 0,
      };
    }
    final imageProgress = QuizTypeProgress.fromJson({
      'levels': imageLevels,
      'totalDiamonds': 0,
    });
    await QuizProgressService.instance.saveProgress('image', imageProgress);

    final vocabProgress = QuizTypeProgress.fromJson({
      'levels': <String, Map<String, dynamic>>{
        '1_airport-1': {
          'progressKey': '1_airport-1',
          'highestStars': 3,
          'highestDiamonds': 0,
        },
      },
      'totalDiamonds': 0,
    });
    await QuizProgressService.instance.saveProgress('vocabulary', vocabProgress);

    await AchievementService.instance.saveStateForTesting(
      const AchievementState(
        bestQuizTimeSeconds: 10,
        currentCorrectStreak: 50,
      ),
    );
  }

  /// Sets profile so that completing one level today gives a 3-day streak.
  /// lastPlayedDay = yesterday, currentStreak = 2.
  Future<void> seedStreakTestData3Day() async {
    final now = DateTime.now().toLocal();
    final yesterday = _dayKey(now.subtract(const Duration(days: 1)));

    final profile = await ProfileService.instance.loadOrCreateProfile();
    final updated = profile.copyWith(
      lastPlayedDay: yesterday,
      currentStreak: 2,
    );
    await ProfileService.instance.saveProfile(updated);
  }

  /// Clears seeded test data: quiz progress (image, vocabulary, grammar),
  /// achievement state, and profile streak so tests can be re-run from a clean state.
  Future<void> clearTestData() async {
    await QuizProgressService.instance.saveProgress(
      'image',
      const QuizTypeProgress(),
    );
    await QuizProgressService.instance.saveProgress(
      'vocabulary',
      const QuizTypeProgress(),
    );
    await QuizProgressService.instance.saveProgress(
      'grammar',
      const QuizTypeProgress(),
    );
    await ReminderProgressService.instance.saveProgress(
      'image',
      const ReminderProgressData(),
    );
    await ReminderProgressService.instance.saveProgress(
      'vocabulary',
      const ReminderProgressData(),
    );
    await ReminderProgressService.instance.saveProgress(
      'grammar',
      const ReminderProgressData(),
    );
    await StoryProgressService.instance.saveProgress(
      'image',
      const StoryProgressState(),
    );
    await StoryProgressService.instance.saveProgress(
      'vocabulary',
      const StoryProgressState(),
    );
    await StoryProgressService.instance.saveProgress(
      'grammar',
      const StoryProgressState(),
    );
    await AchievementService.instance.saveStateForTesting(
      const AchievementState(),
    );
    final profile = await ProfileService.instance.loadOrCreateProfile();
    await ProfileService.instance.saveProfile(
      profile.copyWith(currentStreak: 0),
    );
  }

  /// Seeds image quiz so the first 10 levels appear completed with 2 stars each.
  /// Use to test levels screen (e.g. current level = 11 at top).
  Future<void> seedImageQuizFirst10Levels2Stars() async {
    const stars = 2;
    const diamondsPerLevel = 2;
    final levels = <String, LevelProgress>{};
    for (var i = 1; i <= 10; i++) {
      final key = 'test_level_$i';
      levels[key] = LevelProgress(
        progressKey: key,
        highestStars: stars,
        highestDiamonds: diamondsPerLevel,
      );
    }
    final progress = QuizTypeProgress(
      levels: levels,
      totalDiamonds: 10 * diamondsPerLevel,
    );
    await QuizProgressService.instance.saveProgress('image', progress);
  }

  /// Seeds image quiz main level 1 so all regular levels are completed with
  /// 2 stars and the first 3 questions of each level are marked wrong once.
  /// This is intended to unlock Reminder 1 and let reminder generation run
  /// against realistic wrong-answer counters.
  Future<void> seedImageMainLevel1ReminderTest() async {
    final flow = await loadGameFlow();
    final mainLevelOneLevels = flow.subLevels
        .where((subLevel) => subLevel.mainLevel == 1 && !subLevel.isReminder)
        .toList(growable: false);

    final levels = <String, LevelProgress>{};
    final wrongAnswerCounters = <String, int>{};
    var totalDiamonds = 0;

    for (final subLevel in mainLevelOneLevels) {
      final levelKey = imageQuizLevelKey(subLevel.iconImageName);
      List<String> paths = const [];
      try {
        paths = await loadImageQuizLevelAssetPaths(levelKey);
      } catch (_) {
        paths = const [];
      }
      final questionCount = paths.length;
      final diamonds = questionCount >= 3 ? questionCount - 3 : 0;
      totalDiamonds += diamonds;
      final progressKey = subLevel.progressKey;
      levels[progressKey] = LevelProgress(
        progressKey: progressKey,
        highestStars: 2,
        highestDiamonds: diamonds,
      );
      final wrongQuestionsToSeed = questionCount >= 3 ? 3 : questionCount;
      for (var i = 0; i < wrongQuestionsToSeed; i++) {
        wrongAnswerCounters[buildReminderQuestionId(progressKey, i)] = 1;
      }
    }

    await QuizProgressService.instance.saveProgress(
      'image',
      QuizTypeProgress(
        levels: levels,
        totalDiamonds: totalDiamonds,
      ),
    );
    await ReminderProgressService.instance.saveProgress(
      'image',
      ReminderProgressData(
        wrongAnswerCounters: wrongAnswerCounters,
        remindersByMainLevel: const {
          1: [ReminderLevelState(), ReminderLevelState()],
        },
      ),
    );
    await StoryProgressService.instance.saveProgress(
      'image',
      const StoryProgressState(),
    );
  }

  /// Seeds image quiz progress with [totalDiamonds] so Friends panel
  /// shows that many diamonds for testing (e.g. 150).
  Future<void> seedDiamondsForFriendsTest(int totalDiamonds) async {
    final imageProgress = QuizTypeProgress.fromJson({
      'levels': <String, Map<String, dynamic>>{
        '1_airport': {
          'progressKey': '1_airport',
          'highestStars': 1,
          'highestDiamonds': 5,
        },
      },
      'totalDiamonds': totalDiamonds,
    });
    await QuizProgressService.instance.saveProgress('image', imageProgress);
  }

  /// Sets profile so that completing one level today gives a 30-day streak.
  /// lastPlayedDay = 29 days ago, currentStreak = 29.
  Future<void> seedStreakTestData30Day() async {
    final now = DateTime.now().toLocal();
    final daysAgo = _dayKey(now.subtract(const Duration(days: 29)));

    final profile = await ProfileService.instance.loadOrCreateProfile();
    final updated = profile.copyWith(
      lastPlayedDay: daysAgo,
      currentStreak: 29,
    );
    await ProfileService.instance.saveProfile(updated);
  }
}
