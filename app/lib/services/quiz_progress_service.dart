import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-level progress for a quiz type.
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

  Map<String, dynamic> toJson() => {
        'progressKey': progressKey,
        'highestStars': highestStars,
        'highestDiamonds': highestDiamonds,
      };

  static LevelProgress fromJson(Map<String, dynamic> json) {
    return LevelProgress(
      progressKey: json['progressKey'] as String,
      highestStars: (json['highestStars'] as num?)?.toInt() ?? 0,
      highestDiamonds: (json['highestDiamonds'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Full progress for one quiz type (e.g. image).
class QuizTypeProgress {
  const QuizTypeProgress({
    this.levels = const {},
    this.totalDiamonds = 0,
  });

  final Map<String, LevelProgress> levels;
  final int totalDiamonds;

  LevelProgress level(String progressKey) =>
      levels[progressKey] ?? LevelProgress(progressKey: progressKey);

  Map<String, dynamic> toJson() => {
        'levels': levels.map(
          (k, v) => MapEntry(k, v.toJson()),
        ),
        'totalDiamonds': totalDiamonds,
      };

  static QuizTypeProgress fromJson(Map<String, dynamic> json) {
    final levelsMap = json['levels'] as Map<String, dynamic>? ?? {};
    final levels = <String, LevelProgress>{};
    for (final e in levelsMap.entries) {
      if (e.value is Map<String, dynamic>) {
        final data = e.value as Map<String, dynamic>;
        // Support old int-keyed format (pre-migration): reconstruct a LevelProgress
        // with progressKey = the map key (string form of old int).
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

/// Persists quiz progress per quiz type using SharedPreferences.
/// On web (Chrome), data stays in localStorage for the origin; run on the same
/// port to keep your progress across sessions.
class QuizProgressService {
  QuizProgressService._();
  static final QuizProgressService _instance = QuizProgressService._();
  static QuizProgressService get instance => _instance;

  static const String _keyPrefix = 'quiz_progress_';
  static String _key(String quizType) => '$_keyPrefix$quizType';

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _preferences async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Loads progress for [quizType]. Returns default (empty) if missing or invalid.
  Future<QuizTypeProgress> loadProgress(String quizType) async {
    try {
      final prefs = await _preferences;
      final json = prefs.getString(_key(quizType));
      if (json == null) return const QuizTypeProgress();
      final map = jsonDecode(json) as Map<String, dynamic>;
      return QuizTypeProgress.fromJson(map);
    } catch (e, st) {
      debugPrint('QuizProgressService.loadProgress($quizType): $e\n$st');
      return const QuizTypeProgress();
    }
  }

  /// Saves progress for [quizType].
  Future<void> saveProgress(String quizType, QuizTypeProgress progress) async {
    try {
      final prefs = await _preferences;
      await prefs.setString(
        _key(quizType),
        const JsonEncoder.withIndent('  ').convert(progress.toJson()),
      );
    } catch (e, st) {
      debugPrint('QuizProgressService.saveProgress($quizType): $e\n$st');
    }
  }

  /// Records level completion: updates stars (max), diamonds (delta on replay), and persists.
  /// Call only after end-of-level screen when level is completed (≥1 star).
  Future<QuizTypeProgress> recordLevelCompletion({
    required String quizType,
    required String progressKey,
    required int stars,
    required int diamondsEarned,
  }) async {
    final current = await loadProgress(quizType);
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
    await saveProgress(quizType, updated);
    return updated;
  }
}
