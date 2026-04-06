import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stable quiz-mode id for storage keys, story asset paths, and profile (`'game'` — do not rename without migration).
const String kQuizGameType = 'game';

/// Per-level progress.
class LevelProgress {
  const LevelProgress({
    required this.progressKey,
    this.highestStars = 0,
    this.highestDiamonds = 0,
  });

  final String progressKey;
  final int highestStars;
  final int highestDiamonds;

  bool get isCompleted => highestStars >= 1;

  /// Serializes this row for persistence inside [QuizTypeProgress.toJson].
  Map<String, dynamic> toJson() => {
        'progressKey': progressKey,
        'highestStars': highestStars,
        'highestDiamonds': highestDiamonds,
      };

  /// Rebuilds stored per-level progress from SharedPreferences JSON.
  static LevelProgress fromJson(Map<String, dynamic> json) {
    return LevelProgress(
      progressKey: json['progressKey'] as String,
      highestStars: (json['highestStars'] as num?)?.toInt() ?? 0,
      highestDiamonds: (json['highestDiamonds'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Full progress for the unified game.
class QuizTypeProgress {
  const QuizTypeProgress({
    this.levels = const {},
    this.totalDiamonds = 0,
  });

  final Map<String, LevelProgress> levels;
  final int totalDiamonds;

  /// Returns saved progress for [progressKey] or a fresh zeroed row if none exists yet.
  LevelProgress level(String progressKey) =>
      levels[progressKey] ?? LevelProgress(progressKey: progressKey);

  /// Snapshot of all levels and total diamonds for [saveProgress].
  Map<String, dynamic> toJson() => {
        'levels': levels.map(
          (k, v) => MapEntry(k, v.toJson()),
        ),
        'totalDiamonds': totalDiamonds,
      };

  /// Parses the full progress blob from disk after [loadProgress] reads the prefs string.
  static QuizTypeProgress fromJson(Map<String, dynamic> json) {
    final levelsMap = json['levels'] as Map<String, dynamic>? ?? {};
    final levels = <String, LevelProgress>{};
    for (final e in levelsMap.entries) {
      if (e.value is Map<String, dynamic>) {
        final data = e.value as Map<String, dynamic>;
        final progressKey = data['progressKey'] as String? ?? e.key;
        levels[e.key] = LevelProgress(
          progressKey: progressKey,
          highestStars: (data['highestStars'] as num?)?.toInt() ?? 0,
          highestDiamonds: (data['highestDiamonds'] as num?)?.toInt() ?? 0,
        );
      }
    }
    return QuizTypeProgress(
      levels: levels,
      totalDiamonds: (json['totalDiamonds'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Persists unified game progress using SharedPreferences.
class QuizProgressService {
  QuizProgressService._();
  static final QuizProgressService _instance = QuizProgressService._();
  static QuizProgressService get instance => _instance;

  static const String _storageKey = 'quiz_progress_$kQuizGameType';

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _preferences async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Reads persisted stars/diamonds map for the level map and completion logic.
  /// Returns an empty [QuizTypeProgress] if nothing valid is stored yet or JSON fails to parse.
  Future<QuizTypeProgress> loadProgress() async {
    try {
      final prefs = await _preferences;
      final json = prefs.getString(_storageKey);
      if (json == null) return const QuizTypeProgress();
      final map = jsonDecode(json) as Map<String, dynamic>;
      return QuizTypeProgress.fromJson(map);
    } catch (e, st) {
      debugPrint('QuizProgressService.loadProgress: $e\n$st');
      return const QuizTypeProgress();
    }
  }

  /// Writes the entire progress graph to SharedPreferences after any mutation.
  /// Called by [recordLevelCompletion] and any future APIs that update level state.
  Future<void> saveProgress(QuizTypeProgress progress) async {
    try {
      final prefs = await _preferences;
      await prefs.setString(
        _storageKey,
        const JsonEncoder.withIndent('  ').convert(progress.toJson()),
      );
    } catch (e, st) {
      debugPrint('QuizProgressService.saveProgress: $e\n$st');
    }
  }

  /// Merges a finished quiz’s star tier and diamond high-water mark, bumps global diamonds on improvement.
  /// Invoked from [ImageQuizScreen._onEndOk] when the player passes (at least one star).
  Future<QuizTypeProgress> recordLevelCompletion({
    required String progressKey,
    required int stars,
    required int diamondsEarned,
  }) async {
    final current = await loadProgress();
    final existing = current.level(progressKey);
    final newStars = stars > existing.highestStars ? stars : existing.highestStars;
    final diamondDelta = diamondsEarned > existing.highestDiamonds
        ? diamondsEarned - existing.highestDiamonds
        : 0;
    final updatedLevels = Map<String, LevelProgress>.from(current.levels)
      ..[progressKey] = LevelProgress(
        progressKey: progressKey,
        highestStars: newStars,
        highestDiamonds: diamondsEarned > existing.highestDiamonds
            ? diamondsEarned
            : existing.highestDiamonds,
      );
    final updated = QuizTypeProgress(
      levels: updatedLevels,
      totalDiamonds: current.totalDiamonds + diamondDelta,
    );
    await saveProgress(updated);
    return updated;
  }
}
