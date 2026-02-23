import 'dart:convert';

import 'package:flutter/services.dart';

class GameConfig {
  const GameConfig({this.autoAdvanceDelaySeconds = 1.5});

  final double autoAdvanceDelaySeconds;

  static const String _path = 'assets/data/config/game_config.json';

  static Future<GameConfig> load() async {
    try {
      final json = await rootBundle.loadString(_path);
      final map = jsonDecode(json) as Map<String, dynamic>;
      return GameConfig(
        autoAdvanceDelaySeconds:
            (map['autoAdvanceDelaySeconds'] as num?)?.toDouble() ?? 1.5,
      );
    } catch (e) {
      return const GameConfig();
    }
  }
}
