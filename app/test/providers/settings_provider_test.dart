import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:english_quiz_game/providers/settings_provider.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsNotifier', () {
    Future<void> waitForLoad(ProviderContainer container) async {
      for (var i = 0; i < 50; i++) {
        await Future.delayed(const Duration(milliseconds: 20));
        if (container.read(settingsProvider).valueOrNull != null) return;
      }
    }

    test('loads default state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await waitForLoad(container);
      final state = container.read(settingsProvider).valueOrNull;
      expect(state, isNotNull);
      expect(state!.language, 'en');
      expect(state.musicOn, true);
      expect(state.soundFxOn, true);
    });

    test('setLanguage updates state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await waitForLoad(container);
      await container.read(settingsProvider.notifier).setLanguage('fr');
      final state = container.read(settingsProvider).valueOrNull;
      expect(state?.language, 'fr');
    });

    test('setMusicOn updates state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await waitForLoad(container);
      await container.read(settingsProvider.notifier).setMusicOn(false);
      expect(container.read(settingsProvider).valueOrNull?.musicOn, false);
      await container.read(settingsProvider.notifier).setMusicOn(true);
      expect(container.read(settingsProvider).valueOrNull?.musicOn, true);
    });

    test('setSoundFxOn updates state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await waitForLoad(container);
      await container.read(settingsProvider.notifier).setSoundFxOn(false);
      expect(container.read(settingsProvider).valueOrNull?.soundFxOn, false);
    });
  });

  group('SettingsState', () {
    test('copyWith preserves unspecified fields', () {
      const state = SettingsState(
        language: 'en',
        musicOn: true,
        soundFxOn: false,
      );
      final updated = state.copyWith(language: 'tr');
      expect(updated.language, 'tr');
      expect(updated.musicOn, true);
      expect(updated.soundFxOn, false);
    });
  });
}
