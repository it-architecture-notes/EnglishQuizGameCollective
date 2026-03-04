import 'dart:convert';

import 'package:flutter/services.dart';

class FriendAnimalDefinition {
  const FriendAnimalDefinition({
    required this.id,
    required this.image,
    required this.diamondCost,
    this.name,
  });

  final String id;
  final String image;
  final int diamondCost;
  final String? name;

  static FriendAnimalDefinition fromJson(Map<String, dynamic> json) {
    return FriendAnimalDefinition(
      id: json['id'] as String,
      image: json['image'] as String? ?? json['id'] as String,
      diamondCost: (json['diamondCost'] as num?)?.toInt() ?? 0,
      name: json['name'] as String?,
    );
  }

  String get displayName => name ?? id;
  String get imageAssetPath => 'assets/images/friends/$image.png';
}

const String _path = 'assets/data/config/friends.json';

Future<List<FriendAnimalDefinition>> loadFriendsConfig() async {
  try {
    final json = await rootBundle.loadString(_path);
    final map = jsonDecode(json) as Map<String, dynamic>;
    final list = map['animals'] as List<dynamic>? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(FriendAnimalDefinition.fromJson)
        .toList();
  } catch (e, st) {
    assert(false, 'Failed to load friends config: $e\n$st');
    return [];
  }
}
