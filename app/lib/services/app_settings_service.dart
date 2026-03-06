import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages user-facing app settings persisted via SharedPreferences.
///
/// Stores: language ([getLanguage]/[setLanguage]), music on/off ([getMusicOn]/[setMusicOn]),
/// sound/FX on/off ([getSoundFxOn]/[setSoundFxOn]). Defaults: language "en", music on, sound/FX on.
class AppSettingsService {
  AppSettingsService._();

  static const String _langKey = 'app_language';
  static const String _musicKey = 'app_music_on';
  static const String _soundFxKey = 'app_sound_fx_on';
  static const String _defaultLanguage = 'en';

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _preferences async =>
      _prefs ??= await SharedPreferences.getInstance();

  static Future<String> getLanguage() async {
    try {
      final prefs = await _preferences;
      return prefs.getString(_langKey) ?? _defaultLanguage;
    } catch (e, st) {
      debugPrint('AppSettingsService.getLanguage: $e\n$st');
      return _defaultLanguage;
    }
  }

  static Future<void> setLanguage(String lang) async {
    try {
      final prefs = await _preferences;
      await prefs.setString(_langKey, lang);
    } catch (e, st) {
      debugPrint('AppSettingsService.setLanguage: $e\n$st');
    }
  }

  static Future<bool> getMusicOn() async {
    try {
      final prefs = await _preferences;
      return prefs.getBool(_musicKey) ?? true;
    } catch (e, st) {
      debugPrint('AppSettingsService.getMusicOn: $e\n$st');
      return true;
    }
  }

  static Future<void> setMusicOn(bool value) async {
    try {
      final prefs = await _preferences;
      await prefs.setBool(_musicKey, value);
    } catch (e, st) {
      debugPrint('AppSettingsService.setMusicOn: $e\n$st');
    }
  }

  static Future<bool> getSoundFxOn() async {
    try {
      final prefs = await _preferences;
      return prefs.getBool(_soundFxKey) ?? true;
    } catch (e, st) {
      debugPrint('AppSettingsService.getSoundFxOn: $e\n$st');
      return true;
    }
  }

  static Future<void> setSoundFxOn(bool value) async {
    try {
      final prefs = await _preferences;
      await prefs.setBool(_soundFxKey, value);
    } catch (e, st) {
      debugPrint('AppSettingsService.setSoundFxOn: $e\n$st');
    }
  }
}
