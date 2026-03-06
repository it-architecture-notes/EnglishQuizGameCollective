import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_settings_service.dart';
import '../services/audio_service.dart' as audio;

class SettingsState {
  const SettingsState({
    required this.language,
    required this.musicOn,
    required this.soundFxOn,
  });

  final String language;
  final bool musicOn;
  final bool soundFxOn;

  SettingsState copyWith({
    String? language,
    bool? musicOn,
    bool? soundFxOn,
  }) {
    return SettingsState(
      language: language ?? this.language,
      musicOn: musicOn ?? this.musicOn,
      soundFxOn: soundFxOn ?? this.soundFxOn,
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
      state = AsyncValue.data(SettingsState(
        language: language,
        musicOn: musicOn,
        soundFxOn: soundFxOn,
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
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<SettingsState>>((ref) {
  return SettingsNotifier();
});
