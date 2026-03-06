import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:english_quiz_game/services/app_settings_service.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppSettingsService', () {
    test('getLanguage returns en when not set', () async {
      final lang = await AppSettingsService.getLanguage();
      expect(lang, 'en');
    });

    test('setLanguage and getLanguage round-trip', () async {
      await AppSettingsService.setLanguage('fr');
      final lang = await AppSettingsService.getLanguage();
      expect(lang, 'fr');
    });

    test('getMusicOn returns true when not set', () async {
      final on = await AppSettingsService.getMusicOn();
      expect(on, true);
    });

    test('setMusicOn and getMusicOn round-trip', () async {
      await AppSettingsService.setMusicOn(false);
      expect(await AppSettingsService.getMusicOn(), false);
      await AppSettingsService.setMusicOn(true);
      expect(await AppSettingsService.getMusicOn(), true);
    });

    test('getSoundFxOn returns true when not set', () async {
      final on = await AppSettingsService.getSoundFxOn();
      expect(on, true);
    });

    test('setSoundFxOn and getSoundFxOn round-trip', () async {
      await AppSettingsService.setSoundFxOn(false);
      expect(await AppSettingsService.getSoundFxOn(), false);
    });
  });
}
