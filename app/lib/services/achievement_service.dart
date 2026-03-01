import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/achievement_state.dart';

/// Persists and updates achievement-related state (quiz time, correct streak).
class AchievementService {
  AchievementService._();
  static final AchievementService _instance = AchievementService._();
  static AchievementService get instance => _instance;

  static const String _key = 'achievement_state';

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _preferences async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<AchievementState> loadState() async {
    try {
      final prefs = await _preferences;
      final json = prefs.getString(_key);
      if (json == null) return const AchievementState();
      final map = jsonDecode(json) as Map<String, dynamic>;
      return AchievementState.fromJson(map);
    } catch (e, st) {
      debugPrint('AchievementService.loadState: $e\n$st');
      return const AchievementState();
    }
  }

  Future<void> _saveState(AchievementState state) async {
    try {
      final prefs = await _preferences;
      await prefs.setString(
        _key,
        const JsonEncoder.withIndent('  ').convert(state.toJson()),
      );
    } catch (e, st) {
      debugPrint('AchievementService._saveState: $e\n$st');
    }
  }

  /// Call when user answers a question. [correct] = was the answer correct.
  Future<void> recordAnswer(bool correct) async {
    final state = await loadState();
    final next = correct
        ? state.copyWith(currentCorrectStreak: state.currentCorrectStreak + 1)
        : state.copyWith(currentCorrectStreak: 0);
    await _saveState(next);
  }

  /// Call when quiz is completed (OK pressed). [durationSeconds] = time taken.
  Future<void> recordQuizCompleted(int durationSeconds) async {
    final state = await loadState();
    final currentBest = state.bestQuizTimeSeconds;
    if (currentBest != null && durationSeconds >= currentBest) return;
    await _saveState(
      state.copyWith(bestQuizTimeSeconds: durationSeconds),
    );
  }
}
