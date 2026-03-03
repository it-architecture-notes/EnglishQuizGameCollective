class ProfileState {
  const ProfileState({
    required this.userId,
    required this.dateJoinedIso,
    required this.avatarName,
    this.avatarAssetPath,
    this.lastPlayedDay,
    this.currentStreak = 0,
    this.totalQuestionsAnsweredByQuizType = const {},
  });

  final String userId;
  final String dateJoinedIso;
  final String avatarName;
  final String? avatarAssetPath;
  /// Last calendar day (YYYY-MM-DD) user completed any level with ≥1 star.
  final String? lastPlayedDay;
  /// Consecutive calendar days with at least one completed level (any quiz type).
  final int currentStreak;
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
    String? lastPlayedDay,
    int? currentStreak,
    Map<String, int>? totalQuestionsAnsweredByQuizType,
  }) {
    return ProfileState(
      userId: userId ?? this.userId,
      dateJoinedIso: dateJoinedIso ?? this.dateJoinedIso,
      avatarName: avatarName ?? this.avatarName,
      avatarAssetPath: clearAvatarAssetPath
          ? null
          : (avatarAssetPath ?? this.avatarAssetPath),
      lastPlayedDay: lastPlayedDay ?? this.lastPlayedDay,
      currentStreak: currentStreak ?? this.currentStreak,
      totalQuestionsAnsweredByQuizType: totalQuestionsAnsweredByQuizType ??
          this.totalQuestionsAnsweredByQuizType,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'dateJoinedIso': dateJoinedIso,
        'avatarName': avatarName,
        'avatarAssetPath': avatarAssetPath,
        'lastPlayedDay': lastPlayedDay,
        'currentStreak': currentStreak,
        'totalQuestionsAnsweredByQuizType': totalQuestionsAnsweredByQuizType,
      };

  static ProfileState fromJson(Map<String, dynamic> json) {
    final lastPlayedDay = json['lastPlayedDay'] as String?;
    final currentStreak = (json['currentStreak'] as num?)?.toInt();

    if (lastPlayedDay != null && currentStreak != null) {
      return ProfileState(
        userId: (json['userId'] as String?) ?? '',
        dateJoinedIso: (json['dateJoinedIso'] as String?) ?? '',
        avatarName: (json['avatarName'] as String?) ?? defaultAvatarName,
        avatarAssetPath: json['avatarAssetPath'] as String?,
        lastPlayedDay: lastPlayedDay,
        currentStreak: currentStreak,
        totalQuestionsAnsweredByQuizType: _intMap(
          json['totalQuestionsAnsweredByQuizType'],
        ),
      );
    }
    final oldLastByType = _stringMap(json['lastPlayedDayByQuizType']);
    final oldStreakByType = _intMap(json['currentStreakByQuizType']);
    String? migratedLast = lastPlayedDay;
    int migratedStreak = currentStreak ?? 0;
    if (oldLastByType.isNotEmpty) {
      final sorted = oldLastByType.values.toList()..sort();
      migratedLast = sorted.last;
    }
    if (oldStreakByType.isNotEmpty) {
      migratedStreak = oldStreakByType.values.fold(0, (a, b) => a > b ? a : b);
    }
    return ProfileState(
      userId: (json['userId'] as String?) ?? '',
      dateJoinedIso: (json['dateJoinedIso'] as String?) ?? '',
      avatarName: (json['avatarName'] as String?) ?? defaultAvatarName,
      avatarAssetPath: json['avatarAssetPath'] as String?,
      lastPlayedDay: migratedLast,
      currentStreak: migratedStreak,
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
