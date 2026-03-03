import '../models/profile_state.dart';
import 'achievement_config_loader.dart';
import 'achievement_service.dart';
import 'quiz_flow_loader.dart';
import 'quiz_progress_service.dart';

/// Achievement with computed progress.
class AchievementProgress {
  const AchievementProgress({
    required this.definition,
    required this.currentValue,
    required this.goalValue,
    required this.isUnlocked,
    this.progressFraction = 0.0,
  });

  final AchievementDefinition definition;
  final int currentValue;
  final int goalValue;
  final bool isUnlocked;
  final double progressFraction;
}

/// Computes current value for each achievement from stored data.
class AchievementProgressService {
  AchievementProgressService._();
  static final AchievementProgressService _instance =
      AchievementProgressService._();
  static AchievementProgressService get instance => _instance;

  static const List<String> _quizTypes = ['image', 'vocabulary', 'grammar'];

  Future<List<AchievementProgress>> computeProgress({
    required List<AchievementDefinition> definitions,
    required ProfileState profile,
  }) async {
    final achievementState = await AchievementService.instance.loadState();

    int totalQuizzesCompleted = 0;
    int totalPerfectScores = 0;
    int categoriesPlayed = 0;
    final maxStreakDays = profile.currentStreak;
    int totalLevels = 0;
    int levelsWith3Stars = 0;
    int minPerfectPerType = 999;

    for (final quizType in _quizTypes) {
      final progress =
          await QuizProgressService.instance.loadProgress(quizType);
      final completed =
          progress.levels.values.where((l) => l.isCompleted).length;
      final perfect =
          progress.levels.values.where((l) => l.highestStars >= 3).length;

      totalQuizzesCompleted += completed;
      totalPerfectScores += perfect;
      if (completed > 0) categoriesPlayed++;

      try {
        final flow = await loadQuizFlow(quizType);
        totalLevels += flow.subLevels.length;
        for (var i = 0; i < flow.subLevels.length; i++) {
          final ordinal = i + 1;
          if ((progress.levels[ordinal]?.highestStars ?? 0) >= 3) {
            levelsWith3Stars++;
          }
        }
        final perfectInType = progress.levels.values
            .where((l) => l.highestStars >= 3)
            .length;
        if (perfectInType < minPerfectPerType) minPerfectPerType = perfectInType;
      } catch (_) {}
    }

    if (minPerfectPerType == 999) minPerfectPerType = 0;

    final allQuizzes3Stars =
        totalLevels > 0 && levelsWith3Stars >= totalLevels ? 1 : 0;
    final perfect10PerType = minPerfectPerType >= 10 ? 1 : 0;

    final stats = <String, int>{
      'total_quizzes_completed': totalQuizzesCompleted,
      'total_perfect_scores': totalPerfectScores,
      'quizzes_with_3_stars': totalPerfectScores,
      'max_streak_days': maxStreakDays,
      'categories_played': categoriesPlayed,
      'current_correct_streak': achievementState.currentCorrectStreak,
    };

    final bestTime = achievementState.bestQuizTimeSeconds;

    final result = <AchievementProgress>[];
    for (final def in definitions) {
      final (currentValue, isUnlocked, progressFraction) = _evaluate(
        def,
        stats,
        bestTime,
        allQuizzes3Stars,
        perfect10PerType,
      );
      result.add(AchievementProgress(
        definition: def,
        currentValue: currentValue,
        goalValue: def.goalValue,
        isUnlocked: isUnlocked,
        progressFraction: progressFraction,
      ));
    }
    return result;
  }

  (int currentValue, bool isUnlocked, double progressFraction) _evaluate(
    AchievementDefinition def,
    Map<String, int> stats,
    int? bestTime,
    int allQuizzes3Stars,
    int perfect10PerType,
  ) {
    switch (def.trackingKey) {
      case 'total_quizzes_completed':
      case 'quizzes_with_3_stars':
      case 'total_perfect_scores':
      case 'max_streak_days':
      case 'categories_played':
      case 'current_correct_streak':
        final v = stats[def.trackingKey] ?? 0;
        final unlocked = v >= def.goalValue;
        final frac = def.goalValue <= 0
            ? 1.0
            : (v / def.goalValue).clamp(0.0, 1.0);
        return (v, unlocked, frac);

      case 'best_quiz_time_seconds':
        final v = bestTime ?? 999;
        final unlocked = bestTime != null && bestTime <= def.goalValue;
        final frac = def.goalValue <= 0
            ? 1.0
            : (bestTime != null && bestTime <= def.goalValue)
                ? 1.0
                : (bestTime != null)
                    ? (1.0 - (bestTime - def.goalValue) / 60).clamp(0.0, 1.0)
                    : 0.0;
        return (v == 999 ? 0 : v, unlocked, frac.clamp(0.0, 1.0));

      case 'all_quizzes_3_stars':
        return (allQuizzes3Stars, allQuizzes3Stars >= 1, allQuizzes3Stars.toDouble());

      case 'perfect_10_per_type':
        return (perfect10PerType, perfect10PerType >= 1, perfect10PerType.toDouble());

      default:
        return (0, false, 0.0);
    }
  }
}
