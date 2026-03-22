import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quiz_flow.dart';
import '../models/reminder_progress.dart';
import 'quiz_progress_service.dart';
import 'reminder_question_builder.dart';

class ReminderProgressService {
  ReminderProgressService._();

  static final ReminderProgressService _instance = ReminderProgressService._();
  static ReminderProgressService get instance => _instance;

  static const String _keyPrefix = 'reminder_progress_';
  static String _key(String quizType) => '$_keyPrefix$quizType';

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _preferences async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<ReminderProgressData> loadProgress(String quizType) async {
    try {
      final prefs = await _preferences;
      final json = prefs.getString(_key(quizType));
      if (json == null) return const ReminderProgressData();
      final map = jsonDecode(json) as Map<String, dynamic>;
      return ReminderProgressData.fromJson(map);
    } catch (e, st) {
      debugPrint('ReminderProgressService.loadProgress($quizType): $e\n$st');
      return const ReminderProgressData();
    }
  }

  Future<void> saveProgress(
    String quizType,
    ReminderProgressData progress,
  ) async {
    try {
      final prefs = await _preferences;
      await prefs.setString(
        _key(quizType),
        const JsonEncoder.withIndent('  ').convert(progress.toJson()),
      );
    } catch (e, st) {
      debugPrint('ReminderProgressService.saveProgress($quizType): $e\n$st');
    }
  }

  Future<ReminderProgressData> recordWrongAnswer(
    String quizType,
    String questionId,
  ) async {
    final current = await loadProgress(quizType);
    final counters = Map<String, int>.from(current.wrongAnswerCounters);
    counters[questionId] = (counters[questionId] ?? 0) + 1;
    final updated = current.copyWith(wrongAnswerCounters: counters);
    await saveProgress(quizType, updated);
    return updated;
  }

  Future<ReminderProgressData> generateReminderQuestions({
    required String quizType,
    required int mainLevel,
    required Map<String, int> questionCountByProgressKey,
  }) async {
    final current = await loadProgress(quizType);
    final split = ReminderQuestionBuilder.build(
      wrongAnswerCounters: current.wrongAnswerCounters,
      questionCountByProgressKey: questionCountByProgressKey,
    );
    final remindersByMainLevel =
        Map<int, List<ReminderLevelState>>.from(current.remindersByMainLevel);
    remindersByMainLevel[mainLevel] = [
      ReminderLevelState(questionIds: split.reminderOneQuestionIds),
      ReminderLevelState(questionIds: split.reminderTwoQuestionIds),
    ];
    final updated = current.copyWith(remindersByMainLevel: remindersByMainLevel);
    await saveProgress(quizType, updated);
    return updated;
  }

  Future<ReminderProgressData> markReminderCompleted({
    required String quizType,
    required int mainLevel,
    required int reminderIndex,
    required List<String> answeredIds,
  }) async {
    final current = await loadProgress(quizType);
    final counters = Map<String, int>.from(current.wrongAnswerCounters)
      ..removeWhere((questionId, _) => answeredIds.contains(questionId));
    final remindersByMainLevel =
        Map<int, List<ReminderLevelState>>.from(current.remindersByMainLevel);
    final states = List<ReminderLevelState>.from(
      remindersByMainLevel[mainLevel] ??
          const [ReminderLevelState(), ReminderLevelState()],
    );
    final listIndex = reminderIndex - 1;
    while (states.length <= listIndex) {
      states.add(const ReminderLevelState());
    }
    states[listIndex] = states[listIndex].copyWith(isCompleted: true);
    remindersByMainLevel[mainLevel] = states;
    final updated = current.copyWith(
      wrongAnswerCounters: counters,
      remindersByMainLevel: remindersByMainLevel,
    );
    await saveProgress(quizType, updated);
    return updated;
  }

  bool isReminderCompleted({
    required ReminderProgressData data,
    required int mainLevel,
    required int reminderIndex,
  }) {
    return data.isReminderCompleted(mainLevel, reminderIndex);
  }

  bool isReminderUnlocked({
    required ReminderProgressData data,
    required QuizTypeProgress quizProgress,
    required int mainLevel,
    required int reminderIndex,
    required Iterable<SubLevelItem> regularFlowSubLevels,
  }) {
    if (reminderIndex <= 1) {
      final regularItems = regularFlowSubLevels
          .where((item) => item.sub.mainLevel == mainLevel)
          .toList();
      if (regularItems.isEmpty) return false;
      for (final item in regularItems) {
        final stars = quizProgress.levels[item.progressKey]?.highestStars ?? 0;
        if (stars < 1) return false;
      }
      return true;
    }
    return data.isReminderCompleted(mainLevel, reminderIndex - 1);
  }
}
