import 'dart:convert';

import 'package:flutter/services.dart';

class GameConfig {
  const GameConfig({
    this.autoAdvanceDelaySeconds = 1.5,
    this.imageQuizTimerSeconds = 5,
    this.showCorrectOnWrong = false,
  });

  final double autoAdvanceDelaySeconds;
  final int imageQuizTimerSeconds;
  /// Whether to highlight the correct tile when the player taps the wrong one (imageQuizTemplate-2).
  final bool showCorrectOnWrong;

  static const String _path = 'assets/data/config/game_config.json';

  static Future<GameConfig> load() async {
    try {
      final json = await rootBundle.loadString(_path);
      final map = jsonDecode(json) as Map<String, dynamic>;
      return GameConfig(
        autoAdvanceDelaySeconds:
            (map['autoAdvanceDelaySeconds'] as num?)?.toDouble() ?? 1.5,
        imageQuizTimerSeconds:
            (map['imageQuizTimerSeconds'] as num?)?.toInt() ?? 5,
        showCorrectOnWrong:
            map['showCorrectOnWrong'] as bool? ?? false,
      );
    } catch (e) {
      return const GameConfig();
    }
  }
}
