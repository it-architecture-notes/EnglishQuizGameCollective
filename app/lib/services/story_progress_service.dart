import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/story_progress.dart';

class StoryProgressService {
  StoryProgressService._();
  static final StoryProgressService _instance = StoryProgressService._();
  static StoryProgressService get instance => _instance;

  static const String _keyPrefix = 'story_progress_';
  static String _key(String quizType) => '$_keyPrefix$quizType';

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _preferences async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<StoryProgressState> loadProgress(String quizType) async {
    try {
      final prefs = await _preferences;
      final raw = prefs.getString(_key(quizType));
      if (raw == null) return const StoryProgressState();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return StoryProgressState.fromJson(map);
    } catch (e, st) {
      debugPrint('StoryProgressService.loadProgress($quizType): $e\n$st');
      return const StoryProgressState();
    }
  }

  Future<void> saveProgress(String quizType, StoryProgressState state) async {
    try {
      final prefs = await _preferences;
      await prefs.setString(
        _key(quizType),
        const JsonEncoder.withIndent('  ').convert(state.toJson()),
      );
    } catch (e, st) {
      debugPrint('StoryProgressService.saveProgress($quizType): $e\n$st');
    }
  }

  Future<StoryProgressState> markCompleted({
    required String quizType,
    required StoryProgressState current,
    required int mainLevelId,
    required int eventId,
  }) async {
    final updated = current.markCompleted(
      mainLevelId: mainLevelId,
      eventId: eventId,
    );
    await saveProgress(quizType, updated);
    return updated;
  }
}
