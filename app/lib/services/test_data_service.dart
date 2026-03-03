import '../models/achievement_state.dart';
import 'achievement_service.dart';
import 'profile_service.dart';
import 'quiz_progress_service.dart';

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
      imageLevels[i.toString()] = {
        'levelNumber': i,
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
        '1': {'levelNumber': 1, 'highestStars': 3, 'highestDiamonds': 0},
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
    await AchievementService.instance.saveStateForTesting(
      const AchievementState(),
    );
    final profile = await ProfileService.instance.loadOrCreateProfile();
    await ProfileService.instance.saveProfile(
      profile.copyWith(currentStreak: 0),
    );
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
