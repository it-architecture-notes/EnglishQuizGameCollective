/// One sub-level entry from [quiz-type]-quiz-flow.json.
class SubLevel {
  const SubLevel({
    required this.mainLevel,
    required this.iconImageName,
    required this.title,
    this.kind = 'regular',
    this.reminderIndex = 0,
  });

  final int mainLevel;
  final String iconImageName;
  final String title;
  final String kind;
  final int reminderIndex;

  bool get isReminder => kind == 'reminder';

  /// Stable progress key used for persisting completion state.
  /// Regular level: "{mainLevel}_{iconImageName}", e.g. "1_travel-1".
  /// Reminder level: "{mainLevel}_reminder_{reminderIndex}", e.g. "1_reminder_1".
  String get progressKey => isReminder
      ? '${mainLevel}_reminder_$reminderIndex'
      : '${mainLevel}_$iconImageName';

  static SubLevel fromJson(Map<String, dynamic> json) {
    return SubLevel(
      mainLevel: json['mainLevel'] as int,
      iconImageName: json['iconImageName'] as String,
      title: json['title'] as String,
      kind: json['kind'] as String? ?? 'regular',
      reminderIndex: (json['reminderIndex'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Main-level metadata from [quiz-type]-flow-main-levels.json.
class MainLevelMeta {
  const MainLevelMeta({
    required this.mainLevel,
    required this.title,
  });

  final int mainLevel;
  final String title;

  static MainLevelMeta fromJson(Map<String, dynamic> json) {
    return MainLevelMeta(
      mainLevel: json['mainLevel'] as int,
      title: json['title'] as String,
    );
  }
}

/// One item in the levels list: a banner or a sub-level cell (banners + cells count toward batch size).
sealed class LevelListItem {}

class BannerItem extends LevelListItem {
  BannerItem(this.meta);
  final MainLevelMeta meta;
}

class SubLevelItem extends LevelListItem {
  SubLevelItem(this.sub, {required this.ordinalLevelIndex, required this.progressKey});
  final SubLevel sub;
  /// 1-based position in the subLevels array; used for scroll navigation only.
  final int ordinalLevelIndex;
  /// Stable progress key derived from SubLevel.progressKey at build time.
  final String progressKey;
}
