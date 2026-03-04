import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:english_quiz_game/models/friends_state.dart';
import 'package:english_quiz_game/services/friends_service.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FriendsService', () {
    test('loadState returns default state when no stored data', () async {
      final state = await FriendsService.instance.loadState();
      expect(state.freedAnimalIds, isEmpty);
      expect(state.hintDismissed, false);
    });

    test('saveState and loadState round-trip', () async {
      const state = FriendsState(
        freedAnimalIds: {'bear', 'lion'},
        hintDismissed: true,
      );
      await FriendsService.instance.saveState(state);
      final loaded = await FriendsService.instance.loadState();
      expect(loaded.freedAnimalIds, state.freedAnimalIds);
      expect(loaded.hintDismissed, true);
    });

    test('loadState parses stored JSON', () async {
      const state = FriendsState(
        freedAnimalIds: {'elephant'},
        hintDismissed: false,
      );
      await FriendsService.instance.saveState(state);
      final loaded = await FriendsService.instance.loadState();
      expect(loaded.freedAnimalIds, {'elephant'});
      expect(loaded.hintDismissed, false);
    });

    test('loadState returns default on invalid JSON', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('friends_state', 'not valid json');
      final loaded = await FriendsService.instance.loadState();
      expect(loaded.freedAnimalIds, isEmpty);
      expect(loaded.hintDismissed, false);
    });
  });
}
