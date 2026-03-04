import 'package:flutter_test/flutter_test.dart';
import 'package:english_quiz_game/services/friends_config_loader.dart';

void main() {
  group('FriendAnimalDefinition', () {
    test('fromJson parses id, image, diamondCost, name', () {
      final def = FriendAnimalDefinition.fromJson({
        'id': 'bear',
        'image': 'bear',
        'diamondCost': 10,
        'name': 'Bear',
      });
      expect(def.id, 'bear');
      expect(def.image, 'bear');
      expect(def.diamondCost, 10);
      expect(def.name, 'Bear');
      expect(def.displayName, 'Bear');
      expect(def.imageAssetPath, 'assets/images/friends/bear.png');
    });

    test('displayName falls back to id when name is null', () {
      final def = FriendAnimalDefinition.fromJson({
        'id': 'fox',
        'image': 'fox',
        'diamondCost': 12,
      });
      expect(def.displayName, 'fox');
    });

    test('image falls back to id when image key is missing', () {
      final def = FriendAnimalDefinition.fromJson({
        'id': 'lion',
        'diamondCost': 15,
        'name': 'Lion',
      });
      expect(def.image, 'lion');
      expect(def.imageAssetPath, 'assets/images/friends/lion.png');
    });

    test('diamondCost defaults to 0 when missing or null', () {
      final def = FriendAnimalDefinition.fromJson({
        'id': 'rabbit',
        'image': 'rabbit',
      });
      expect(def.diamondCost, 0);
    });

    test('diamondCost parses num as int', () {
      final def = FriendAnimalDefinition.fromJson({
        'id': 'panda',
        'image': 'panda',
        'diamondCost': 25.0,
      });
      expect(def.diamondCost, 25);
    });
  });

  group('loadFriendsConfig', () {
    testWidgets('loads animals from asset bundle', (tester) async {
      await tester.runAsync(() async {
        final list = await loadFriendsConfig();
        expect(list.length, 12);
        expect(list.first.id, 'bear');
        expect(list.first.diamondCost, 10);
        expect(list.first.displayName, 'Bear');
      });
    });
  });
}
