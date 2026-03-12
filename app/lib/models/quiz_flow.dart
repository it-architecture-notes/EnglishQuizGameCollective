/// One sub-level entry from [quiz-type]-quiz-flow.json.
class SubLevel {
  const SubLevel({
    required this.mainLevel,
    required this.levelNumber,
    required this.iconImageName,
    required this.title,
    this.kind = 'regular',
    this.reminderIndex = 0,
  });

  final int mainLevel;
  /// Unique level number within this quiz type; regular levels stay sequential,
  /// reminder levels use a high non-colliding value.
  final int levelNumber;
  final String iconImageName;
  final String title;
  final String kind;
  final int reminderIndex;

  bool get isReminder => kind == 'reminder';

  static SubLevel fromJson(Map<String, dynamic> json) {
    return SubLevel(
      mainLevel: json['mainLevel'] as int,
      levelNumber: json['levelNumber'] as int,
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
  SubLevelItem(this.sub, {required this.ordinalLevelIndex});
  final SubLevel sub;
  /// Progress key used by map navigation and quiz completion callbacks.
  /// For regular levels this matches the historical level numbering.
  final int ordinalLevelIndex;
}
