import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_settings_service.dart';
import '../services/audio_service.dart' as audio;

class SettingsState {
  const SettingsState({
    required this.language,
    required this.musicOn,
    required this.soundFxOn,
    required this.showAllLevels,
    required this.testModeOn,
  });

  final String language;
  final bool musicOn;
  final bool soundFxOn;
  final bool showAllLevels;

  /// When true, every level ends after the first answered question and awards
  /// 2 stars if that question was answered correctly (fast end-to-end testing).
  final bool testModeOn;

  SettingsState copyWith({
    String? language,
    bool? musicOn,
    bool? soundFxOn,
    bool? showAllLevels,
    bool? testModeOn,
  }) {
    return SettingsState(
      language: language ?? this.language,
      musicOn: musicOn ?? this.musicOn,
      soundFxOn: soundFxOn ?? this.soundFxOn,
      showAllLevels: showAllLevels ?? this.showAllLevels,
      testModeOn: testModeOn ?? this.testModeOn,
    );
  }
}

class SettingsNotifier extends StateNotifier<AsyncValue<SettingsState>> {
  SettingsNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final language = await AppSettingsService.getLanguage();
      final musicOn = await AppSettingsService.getMusicOn();
      final soundFxOn = await AppSettingsService.getSoundFxOn();
      final showAllLevels = await AppSettingsService.getShowAllLevels();
      final testModeOn = await AppSettingsService.getTestModeOn();
      state = AsyncValue.data(SettingsState(
        language: language,
        musicOn: musicOn,
        soundFxOn: soundFxOn,
        showAllLevels: showAllLevels,
        testModeOn: testModeOn,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setLanguage(String lang) async {
    await AppSettingsService.setLanguage(lang);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(language: lang));
    }
  }

  Future<void> setMusicOn(bool value) async {
    await AppSettingsService.setMusicOn(value);
    if (!value) await audio.stopQuizMusic();
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(musicOn: value));
    }
  }

  Future<void> setSoundFxOn(bool value) async {
    await AppSettingsService.setSoundFxOn(value);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(soundFxOn: value));
    }
  }

  Future<void> setShowAllLevels(bool value) async {
    await AppSettingsService.setShowAllLevels(value);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(showAllLevels: value));
    }
  }

  Future<void> setTestModeOn(bool value) async {
    await AppSettingsService.setTestModeOn(value);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(testModeOn: value));
    }
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<SettingsState>>((ref) {
  return SettingsNotifier();
});
