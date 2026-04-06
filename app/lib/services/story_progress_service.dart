import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/story_progress.dart';
import 'quiz_progress_service.dart';

class StoryProgressService {
  StoryProgressService._();
  static final StoryProgressService _instance = StoryProgressService._();
  static StoryProgressService get instance => _instance;

  static const String _storageKey = 'story_progress_$kQuizGameType';

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _preferences async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<StoryProgressState> loadProgress() async {
    try {
      final prefs = await _preferences;
      final raw = prefs.getString(_storageKey);
      if (raw == null) return const StoryProgressState();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return StoryProgressState.fromJson(map);
    } catch (e, st) {
      debugPrint('StoryProgressService.loadProgress: $e\n$st');
      return const StoryProgressState();
    }
  }

  Future<void> saveProgress(StoryProgressState state) async {
    try {
      final prefs = await _preferences;
      await prefs.setString(
        _storageKey,
        const JsonEncoder.withIndent('  ').convert(state.toJson()),
      );
    } catch (e, st) {
      debugPrint('StoryProgressService.saveProgress: $e\n$st');
    }
  }

  Future<StoryProgressState> markCompleted({
    required StoryProgressState current,
    required int mainLevelId,
    required int eventId,
  }) async {
    final updated = current.markCompleted(
      mainLevelId: mainLevelId,
      eventId: eventId,
    );
    await saveProgress(updated);
    return updated;
  }
}
