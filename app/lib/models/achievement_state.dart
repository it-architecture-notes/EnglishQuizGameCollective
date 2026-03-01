/// Persisted state for achievement tracking (quiz time, correct streak).
class AchievementState {
  const AchievementState({
    this.bestQuizTimeSeconds,
    this.currentCorrectStreak = 0,
  });

  /// Best (minimum) quiz completion time in seconds. Null = never completed.
  final int? bestQuizTimeSeconds;

  /// Consecutive correct answers across quizzes. Resets on wrong answer.
  final int currentCorrectStreak;

  Map<String, dynamic> toJson() => {
        if (bestQuizTimeSeconds != null) 'bestQuizTimeSeconds': bestQuizTimeSeconds,
        'currentCorrectStreak': currentCorrectStreak,
      };

  static AchievementState fromJson(Map<String, dynamic> json) {
    return AchievementState(
      bestQuizTimeSeconds: (json['bestQuizTimeSeconds'] as num?)?.toInt(),
      currentCorrectStreak: (json['currentCorrectStreak'] as num?)?.toInt() ?? 0,
    );
  }

  AchievementState copyWith({
    int? bestQuizTimeSeconds,
    int? currentCorrectStreak,
    bool clearBestQuizTime = false,
  }) {
    return AchievementState(
      bestQuizTimeSeconds: clearBestQuizTime
          ? null
          : (bestQuizTimeSeconds ?? this.bestQuizTimeSeconds),
      currentCorrectStreak: currentCorrectStreak ?? this.currentCorrectStreak,
    );
  }
}
