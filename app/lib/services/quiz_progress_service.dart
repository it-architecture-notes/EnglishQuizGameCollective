import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Per-level progress for a quiz type.
class LevelProgress {
  const LevelProgress({
    required this.levelNumber,
    this.highestStars = 0,
    this.highestDiamonds = 0,
  });

  final int levelNumber;
  final int highestStars;
  final int highestDiamonds;

  bool get isCompleted => highestStars >= 1;

  Map<String, dynamic> toJson() => {
        'levelNumber': levelNumber,
        'highestStars': highestStars,
        'highestDiamonds': highestDiamonds,
      };

  static LevelProgress fromJson(Map<String, dynamic> json) {
    return LevelProgress(
      levelNumber: json['levelNumber'] as int,
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

  final Map<int, LevelProgress> levels;
  final int totalDiamonds;

  /// Level numbers that are unlocked (level 1 always; N+1 if level N is completed).
  Set<int> get unlockedLevelNumbers {
    final unlocked = <int>{1};
    int maxCompleted = 0;
    for (final p in levels.values) {
      if (p.isCompleted && p.levelNumber > maxCompleted) {
        maxCompleted = p.levelNumber;
      }
    }
    for (var i = 1; i <= maxCompleted + 1; i++) {
      unlocked.add(i);
    }
    return unlocked;
  }

  LevelProgress level(int levelNumber) =>
      levels[levelNumber] ?? LevelProgress(levelNumber: levelNumber);

  Map<String, dynamic> toJson() => {
        'levels': levels.map(
          (k, v) => MapEntry(k.toString(), v.toJson()),
        ),
        'totalDiamonds': totalDiamonds,
      };

  static QuizTypeProgress fromJson(Map<String, dynamic> json) {
    final levelsMap = json['levels'] as Map<String, dynamic>? ?? {};
    final levels = <int, LevelProgress>{};
    for (final e in levelsMap.entries) {
      final k = int.tryParse(e.key);
      if (k != null && e.value is Map<String, dynamic>) {
        levels[k] = LevelProgress.fromJson(e.value as Map<String, dynamic>);
      }
    }
    return QuizTypeProgress(
      levels: levels,
      totalDiamonds: (json['totalDiamonds'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Persists quiz progress per quiz type to a JSON file in app documents directory.
class QuizProgressService {
  QuizProgressService._();
  static final QuizProgressService _instance = QuizProgressService._();
  static QuizProgressService get instance => _instance;

  static String _fileName(String quizType) => '${quizType}_progress.json';

  Future<File> _fileFor(String quizType) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/${_fileName(quizType)}');
  }

  /// Loads progress for [quizType]. Returns default (empty) if file missing or invalid.
  Future<QuizTypeProgress> loadProgress(String quizType) async {
    try {
      final file = await _fileFor(quizType);
      if (!await file.exists()) return const QuizTypeProgress();
      final content = await file.readAsString();
      final map = jsonDecode(content) as Map<String, dynamic>;
      return QuizTypeProgress.fromJson(map);
    } catch (e, st) {
      debugPrint('QuizProgressService.loadProgress($quizType): $e\n$st');
      return const QuizTypeProgress();
    }
  }

  /// Saves progress for [quizType].
  Future<void> saveProgress(String quizType, QuizTypeProgress progress) async {
    try {
      final file = await _fileFor(quizType);
      await file.writeAsString(
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
    required int levelNumber,
    required int stars,
    required int diamondsEarned,
  }) async {
    final current = await loadProgress(quizType);
    final existing = current.level(levelNumber);
    final newStars = stars > existing.highestStars ? stars : existing.highestStars;
    final diamondDelta = diamondsEarned > existing.highestDiamonds
        ? diamondsEarned - existing.highestDiamonds
        : 0;
    final updatedLevels = Map<int, LevelProgress>.from(current.levels)
      ..[levelNumber] = LevelProgress(
        levelNumber: levelNumber,
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
