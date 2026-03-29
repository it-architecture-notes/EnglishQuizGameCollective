import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../quiz_game_constants.dart';

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

/// Full progress for the unified game.
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

  /// Loads progress. Returns default (empty) if missing or invalid.
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

  /// Saves progress.
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

  /// Records level completion: updates stars (max), diamonds (delta on replay), and persists.
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
