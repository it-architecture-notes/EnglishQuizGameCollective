/// One sub-level entry from [quiz-type]-quiz-flow.json.
class SubLevel {
  const SubLevel({
    required this.mainLevel,
    required this.levelNumber,
    required this.iconImageName,
    required this.title,
  });

  final int mainLevel;
  /// Unique level number within this quiz type (1-based); use for progress and state.
  final int levelNumber;
  final String iconImageName;
  final String title;

  static SubLevel fromJson(Map<String, dynamic> json) {
    return SubLevel(
      mainLevel: json['mainLevel'] as int,
      levelNumber: json['levelNumber'] as int,
      iconImageName: json['iconImageName'] as String,
      title: json['title'] as String,
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
  /// 1-based position in subLevels list (progression key).
  final int ordinalLevelIndex;
}
