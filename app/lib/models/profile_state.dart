class ProfileState {
  const ProfileState({
    required this.userId,
    required this.dateJoinedIso,
    required this.avatarName,
    this.avatarAssetPath,
    this.currentStreakByQuizType = const {},
    this.lastPlayedDayByQuizType = const {},
    this.totalQuestionsAnsweredByQuizType = const {},
  });

  final String userId;
  final String dateJoinedIso;
  final String avatarName;
  final String? avatarAssetPath;
  final Map<String, int> currentStreakByQuizType;
  final Map<String, String> lastPlayedDayByQuizType;
  final Map<String, int> totalQuestionsAnsweredByQuizType;

  static const String defaultAvatarName = 'Player';

  factory ProfileState.initial({
    required String userId,
    required DateTime now,
  }) {
    return ProfileState(
      userId: userId,
      dateJoinedIso: now.toIso8601String(),
      avatarName: defaultAvatarName,
      avatarAssetPath: null,
    );
  }

  ProfileState copyWith({
    String? userId,
    String? dateJoinedIso,
    String? avatarName,
    String? avatarAssetPath,
    bool clearAvatarAssetPath = false,
    Map<String, int>? currentStreakByQuizType,
    Map<String, String>? lastPlayedDayByQuizType,
    Map<String, int>? totalQuestionsAnsweredByQuizType,
  }) {
    return ProfileState(
      userId: userId ?? this.userId,
      dateJoinedIso: dateJoinedIso ?? this.dateJoinedIso,
      avatarName: avatarName ?? this.avatarName,
      avatarAssetPath: clearAvatarAssetPath
          ? null
          : (avatarAssetPath ?? this.avatarAssetPath),
      currentStreakByQuizType:
          currentStreakByQuizType ?? this.currentStreakByQuizType,
      lastPlayedDayByQuizType:
          lastPlayedDayByQuizType ?? this.lastPlayedDayByQuizType,
      totalQuestionsAnsweredByQuizType: totalQuestionsAnsweredByQuizType ??
          this.totalQuestionsAnsweredByQuizType,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'dateJoinedIso': dateJoinedIso,
        'avatarName': avatarName,
        'avatarAssetPath': avatarAssetPath,
        'currentStreakByQuizType': currentStreakByQuizType,
        'lastPlayedDayByQuizType': lastPlayedDayByQuizType,
        'totalQuestionsAnsweredByQuizType': totalQuestionsAnsweredByQuizType,
      };

  static ProfileState fromJson(Map<String, dynamic> json) {
    return ProfileState(
      userId: (json['userId'] as String?) ?? '',
      dateJoinedIso: (json['dateJoinedIso'] as String?) ?? '',
      avatarName: (json['avatarName'] as String?) ?? defaultAvatarName,
      avatarAssetPath: json['avatarAssetPath'] as String?,
      currentStreakByQuizType: _intMap(
        json['currentStreakByQuizType'],
      ),
      lastPlayedDayByQuizType: _stringMap(
        json['lastPlayedDayByQuizType'],
      ),
      totalQuestionsAnsweredByQuizType: _intMap(
        json['totalQuestionsAnsweredByQuizType'],
      ),
    );
  }

  static Map<String, int> _intMap(dynamic value) {
    final source = value is Map ? value : const {};
    final output = <String, int>{};
    for (final entry in source.entries) {
      final key = entry.key?.toString();
      if (key == null) continue;
      final intValue = (entry.value as num?)?.toInt();
      if (intValue == null) continue;
      output[key] = intValue;
    }
    return output;
  }

  static Map<String, String> _stringMap(dynamic value) {
    final source = value is Map ? value : const {};
    final output = <String, String>{};
    for (final entry in source.entries) {
      final key = entry.key?.toString();
      final val = entry.value?.toString();
      if (key == null || val == null) continue;
      output[key] = val;
    }
    return output;
  }
}
