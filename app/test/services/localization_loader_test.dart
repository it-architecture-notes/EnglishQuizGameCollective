import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:english_quiz_game/services/localization_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalizationLoader', () {
    test('loadAll returns map with expected language codes', () async {
      final all = await LocalizationLoader.loadAll();
      expect(all.keys, contains('en'));
      expect(all.keys, contains('fr'));
      expect(all.keys, contains('es'));
      expect(all.keys, contains('tr'));
    });

    test('loadAll returns string map per language', () async {
      final all = await LocalizationLoader.loadAll();
      final en = all['en'];
      expect(en, isNotNull);
      expect(en!['settings_title'], 'Settings');
      expect(en['level_complete'], isNotNull);
    });

    test('availableLanguageCodes returns sorted list', () async {
      final codes = await LocalizationLoader.availableLanguageCodes();
      expect(codes, isNotEmpty);
      final sorted = codes.toList()..sort();
      expect(codes, equals(sorted));
    });

    test('string returns key for language', () async {
      final value = await LocalizationLoader.string('settings_title', lang: 'fr');
      expect(value, isNotEmpty);
      expect(value, isNot('settings_title'));
    });
  });
}
