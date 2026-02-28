import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages user-facing app settings persisted via SharedPreferences.
///
/// Currently stores:
/// - [getLanguage] / [setLanguage]: the user's preferred translation language
///   (BCP-47 code such as "en", "tr", "es"). Defaults to "en".
///
/// The vocabulary quiz screen reads [getLanguage] to decide whether to show
/// the translate toggle. The actual language selection UI lives in the
/// Settings screen (future issue).
class AppSettingsService {
  AppSettingsService._();

  static const String _langKey = 'app_language';
  static const String _defaultLanguage = 'es';

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _preferences async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Returns the user's preferred language code. Defaults to [_defaultLanguage].
  static Future<String> getLanguage() async {
    try {
      final prefs = await _preferences;
      return prefs.getString(_langKey) ?? _defaultLanguage;
    } catch (e, st) {
      debugPrint('AppSettingsService.getLanguage: $e\n$st');
      return _defaultLanguage;
    }
  }

  /// Persists [lang] as the user's preferred language code (e.g. "tr", "es").
  /// Pass "en" to disable translation (hides translate button in vocabulary quiz).
  static Future<void> setLanguage(String lang) async {
    try {
      final prefs = await _preferences;
      await prefs.setString(_langKey, lang);
    } catch (e, st) {
      debugPrint('AppSettingsService.setLanguage: $e\n$st');
    }
  }
}
