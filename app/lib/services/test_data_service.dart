import 'package:shared_preferences/shared_preferences.dart';

import '../models/achievement_state.dart';
import '../models/reminder_progress.dart';
import '../models/story_progress.dart';
import 'achievement_service.dart';
import 'profile_service.dart';
import 'quiz_progress_service.dart';
import 'reminder_progress_service.dart';
import 'story_progress_service.dart';

/// Debug prefs and clearing persisted test-related state. Settings (debug) only.
class TestDataService {
  TestDataService._();
  static final TestDataService _instance = TestDataService._();
  static TestDataService get instance => _instance;

  static const String _kShortQuizAfter3With2Stars =
      'debug_quiz_end_after_3_with_2_stars';

  /// When enabled, [ImageQuizScreen] ends after the 3rd answered question
  /// and awards 2 stars (until cleared or app data reset).
  Future<void> seedShortQuizEndAfter3With2Stars() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShortQuizAfter3With2Stars, true);
  }

  Future<bool> isShortQuizEndAfter3With2Stars() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShortQuizAfter3With2Stars) ?? false;
  }

  Future<void> _clearShortQuizDebugFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kShortQuizAfter3With2Stars);
  }

  /// Clears quiz progress, reminders, story progress, achievements, streak,
  /// and the short-quiz debug flag.
  Future<void> clearTestData() async {
    await _clearShortQuizDebugFlag();
    await QuizProgressService.instance.saveProgress(const QuizTypeProgress());
    await ReminderProgressService.instance.saveProgress(const ReminderProgressData());
    await StoryProgressService.instance.saveProgress(const StoryProgressState());
    await AchievementService.instance.saveStateForTesting(const AchievementState());
    final profile = await ProfileService.instance.loadOrCreateProfile();
    await ProfileService.instance.saveProfile(
      profile.copyWith(currentStreak: 0),
    );
  }
}
