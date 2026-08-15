import 'package:shared_preferences/shared_preferences.dart';

/// Persists per-tutorial completion flags using SharedPreferences.
class TutorialService {
  TutorialService._();
  static final TutorialService _instance = TutorialService._();
  static TutorialService get instance => _instance;

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _preferences async =>
      _prefs ??= await SharedPreferences.getInstance();

  static String _key(String tutorialId) => 'tutorial_completed_$tutorialId';

  Future<bool> isCompleted(String tutorialId) async {
    final prefs = await _preferences;
    return prefs.getBool(_key(tutorialId)) ?? false;
  }

  Future<void> markCompleted(String tutorialId) async {
    final prefs = await _preferences;
    await prefs.setBool(_key(tutorialId), true);
  }

  /// Development-only: clears the flag so the tutorial can be replayed.
  Future<void> reset(String tutorialId) async {
    final prefs = await _preferences;
    await prefs.remove(_key(tutorialId));
  }
}
