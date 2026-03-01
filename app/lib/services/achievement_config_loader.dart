import 'dart:convert';

import 'package:flutter/services.dart';

/// One achievement definition from config.
class AchievementDefinition {
  const AchievementDefinition({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.goalValue,
    required this.trackingKey,
    this.showProgressBar = false,
    this.phase,
  });

  final String id;
  final String type; // "milestone" or "progress"
  final String title;
  final String description;
  final String icon;
  final int goalValue;
  final String trackingKey;
  final bool showProgressBar;
  final String? phase;

  static AchievementDefinition fromJson(Map<String, dynamic> json) {
    return AchievementDefinition(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'milestone',
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String? ?? '',
      goalValue: (json['goal_value'] as num?)?.toInt() ?? 1,
      trackingKey: json['tracking_key'] as String,
      showProgressBar: json['show_progress_bar'] as bool? ?? false,
      phase: json['phase'] as String?,
    );
  }
}

const String _path = 'assets/data/config/achievements.json';

/// Loads achievement definitions from assets.
Future<List<AchievementDefinition>> loadAchievementConfig() async {
  try {
    final json = await rootBundle.loadString(_path);
    final map = jsonDecode(json) as Map<String, dynamic>;
    final list = map['achievements'] as List<dynamic>? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(AchievementDefinition.fromJson)
        .toList();
  } catch (e, st) {
    assert(false, 'Failed to load achievements config: $e\n$st');
    return [];
  }
}
