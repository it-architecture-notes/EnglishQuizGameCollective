import 'package:flutter_test/flutter_test.dart';
import 'package:english_quiz_game/models/friends_state.dart';

void main() {
  group('FriendsState', () {
    test('default constructor has empty freedAnimalIds and hintDismissed false', () {
      const state = FriendsState();
      expect(state.freedAnimalIds, isEmpty);
      expect(state.hintDismissed, false);
    });

    test('fromJson parses freedAnimalIds list and hintDismissed', () {
      final state = FriendsState.fromJson({
        'freedAnimalIds': ['bear', 'lion'],
        'hintDismissed': true,
      });
      expect(state.freedAnimalIds, {'bear', 'lion'});
      expect(state.hintDismissed, true);
    });

    test('fromJson handles empty freedAnimalIds', () {
      final state = FriendsState.fromJson({
        'freedAnimalIds': [],
        'hintDismissed': false,
      });
      expect(state.freedAnimalIds, isEmpty);
      expect(state.hintDismissed, false);
    });

    test('fromJson defaults hintDismissed to false when missing', () {
      final state = FriendsState.fromJson({
        'freedAnimalIds': ['bear'],
      });
      expect(state.hintDismissed, false);
    });

    test('fromJson handles non-list freedAnimalIds as empty set', () {
      final state = FriendsState.fromJson({
        'freedAnimalIds': null,
        'hintDismissed': false,
      });
      expect(state.freedAnimalIds, isEmpty);
    });

    test('toJson round-trips with fromJson', () {
      const state = FriendsState(
        freedAnimalIds: {'bear', 'lion'},
        hintDismissed: true,
      );
      final json = state.toJson();
      final restored = FriendsState.fromJson(json);
      expect(restored.freedAnimalIds, state.freedAnimalIds);
      expect(restored.hintDismissed, state.hintDismissed);
    });

    test('copyWith updates only provided fields', () {
      const state = FriendsState(
        freedAnimalIds: {'bear'},
        hintDismissed: false,
      );
      final updated = state.copyWith(hintDismissed: true);
      expect(updated.freedAnimalIds, {'bear'});
      expect(updated.hintDismissed, true);

      final updated2 = state.copyWith(freedAnimalIds: {'bear', 'lion'});
      expect(updated2.freedAnimalIds, {'bear', 'lion'});
      expect(updated2.hintDismissed, false);
    });

    test('copyWith preserves existing when null passed', () {
      const state = FriendsState(
        freedAnimalIds: {'bear'},
        hintDismissed: true,
      );
      final same = state.copyWith();
      expect(same.freedAnimalIds, state.freedAnimalIds);
      expect(same.hintDismissed, state.hintDismissed);
    });
  });
}
