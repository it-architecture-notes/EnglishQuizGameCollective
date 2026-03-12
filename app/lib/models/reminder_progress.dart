String buildReminderQuestionId(int levelNumber, int questionIndex) {
  return '${levelNumber}_$questionIndex';
}

(int levelNumber, int questionIndex) parseReminderQuestionId(String questionId) {
  final underscoreIndex = questionId.indexOf('_');
  if (underscoreIndex <= 0 || underscoreIndex >= questionId.length - 1) {
    throw ArgumentError('Invalid reminder question id: $questionId');
  }
  final levelNumber = int.parse(questionId.substring(0, underscoreIndex));
  final questionIndex = int.parse(questionId.substring(underscoreIndex + 1));
  return (levelNumber, questionIndex);
}

class ReminderLevelState {
  const ReminderLevelState({
    this.isCompleted = false,
    this.questionIds = const [],
  });

  final bool isCompleted;
  final List<String> questionIds;

  ReminderLevelState copyWith({
    bool? isCompleted,
    List<String>? questionIds,
  }) {
    return ReminderLevelState(
      isCompleted: isCompleted ?? this.isCompleted,
      questionIds: questionIds ?? this.questionIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'isCompleted': isCompleted,
        'questionIds': questionIds,
      };

  static ReminderLevelState fromJson(Map<String, dynamic> json) {
    return ReminderLevelState(
      isCompleted: json['isCompleted'] as bool? ?? false,
      questionIds: (json['questionIds'] as List<dynamic>? ?? [])
          .map((value) => value.toString())
          .toList(),
    );
  }
}

class ReminderProgressData {
  const ReminderProgressData({
    this.wrongAnswerCounters = const {},
    this.remindersByMainLevel = const {},
  });

  final Map<String, int> wrongAnswerCounters;
  final Map<int, List<ReminderLevelState>> remindersByMainLevel;

  ReminderLevelState reminderState(int mainLevel, int reminderIndex) {
    final states = remindersByMainLevel[mainLevel];
    final listIndex = reminderIndex - 1;
    if (states == null || listIndex < 0 || listIndex >= states.length) {
      return const ReminderLevelState();
    }
    return states[listIndex];
  }

  bool isReminderCompleted(int mainLevel, int reminderIndex) {
    return reminderState(mainLevel, reminderIndex).isCompleted;
  }

  ReminderProgressData copyWith({
    Map<String, int>? wrongAnswerCounters,
    Map<int, List<ReminderLevelState>>? remindersByMainLevel,
  }) {
    return ReminderProgressData(
      wrongAnswerCounters: wrongAnswerCounters ?? this.wrongAnswerCounters,
      remindersByMainLevel: remindersByMainLevel ?? this.remindersByMainLevel,
    );
  }

  Map<String, dynamic> toJson() => {
        'wrongAnswerCounters': wrongAnswerCounters,
        'remindersByMainLevel': remindersByMainLevel.map(
          (mainLevel, states) => MapEntry(
            mainLevel.toString(),
            states.map((state) => state.toJson()).toList(),
          ),
        ),
      };

  static ReminderProgressData fromJson(Map<String, dynamic> json) {
    final rawCounters =
        json['wrongAnswerCounters'] as Map<String, dynamic>? ?? const {};
    final counters = <String, int>{};
    for (final entry in rawCounters.entries) {
      counters[entry.key] = (entry.value as num?)?.toInt() ?? 0;
    }

    final rawReminders =
        json['remindersByMainLevel'] as Map<String, dynamic>? ?? const {};
    final reminders = <int, List<ReminderLevelState>>{};
    for (final entry in rawReminders.entries) {
      final mainLevel = int.tryParse(entry.key);
      final values = entry.value as List<dynamic>? ?? const [];
      if (mainLevel == null) continue;
      reminders[mainLevel] = values
          .whereType<Map<String, dynamic>>()
          .map(ReminderLevelState.fromJson)
          .toList();
    }

    return ReminderProgressData(
      wrongAnswerCounters: counters,
      remindersByMainLevel: reminders,
    );
  }
}
