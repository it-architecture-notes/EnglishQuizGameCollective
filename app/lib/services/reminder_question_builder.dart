import 'dart:math';

import '../models/reminder_progress.dart';

class ReminderQuestionSplit {
  const ReminderQuestionSplit({
    required this.reminderOneQuestionIds,
    required this.reminderTwoQuestionIds,
  });

  final List<String> reminderOneQuestionIds;
  final List<String> reminderTwoQuestionIds;
}

class ReminderQuestionBuilder {
  const ReminderQuestionBuilder._();

  /// Total questions across both reminders (15 + 15).
  static const int kTotalReminderQuestions = 30;

  static ReminderQuestionSplit build({
    required Map<String, int> wrongAnswerCounters,
    required Map<String, int> questionCountByProgressKey,
    Random? random,
  }) {
    final rng = random ?? Random();
    final allIds = <String>[];
    for (final entry in questionCountByProgressKey.entries) {
      for (var index = 0; index < entry.value; index++) {
        allIds.add(buildReminderQuestionId(entry.key, index));
      }
    }

    final allIdSet = allIds.toSet();
    final wrongEntries = wrongAnswerCounters.entries
        .where((entry) => allIdSet.contains(entry.key))
        .toList();
    final wrongIds = wrongEntries.map((entry) => entry.key).toSet();
    final cleanIds = allIds.where((id) => !wrongIds.contains(id)).toList();

    final selected = <String>[];
    if (wrongEntries.length <= kTotalReminderQuestions) {
      selected.addAll(wrongEntries.map((entry) => entry.key));
      cleanIds.shuffle(rng);
      selected.addAll(
        cleanIds.take(max(0, kTotalReminderQuestions - selected.length)),
      );
    } else {
      final groupedByCount = <int, List<String>>{};
      for (final entry in wrongEntries) {
        groupedByCount.putIfAbsent(entry.value, () => <String>[]).add(entry.key);
      }
      final sortedCounts = groupedByCount.keys.toList()
        ..sort((a, b) => b.compareTo(a));
      for (final count in sortedCounts) {
        final ids = groupedByCount[count]!..shuffle(rng);
        for (final id in ids) {
          if (selected.length >= kTotalReminderQuestions) break;
          selected.add(id);
        }
        if (selected.length >= kTotalReminderQuestions) break;
      }
    }

    selected.shuffle(rng);
    final splitIndex = (selected.length / 2).ceil();
    return ReminderQuestionSplit(
      reminderOneQuestionIds: selected.take(splitIndex).toList(),
      reminderTwoQuestionIds: selected.skip(splitIndex).toList(),
    );
  }
}
