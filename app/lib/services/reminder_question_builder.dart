import 'dart:math';

class ReminderQuestionSplit {
  const ReminderQuestionSplit({
    required this.reminderOneQuestionIds,
    required this.reminderTwoQuestionIds,
  });

  final List<String> reminderOneQuestionIds;
  final List<String> reminderTwoQuestionIds;
}

/// Every answerable question in a main level, classified into the four reminder groups.
/// Built once per main level (across all its sub-levels) before generating reminders.
class MainLevelReminderPool {
  MainLevelReminderPool({
    List<String>? standaloneIds,
    List<String>? imageIds,
    List<String>? wordPairsIds,
    Map<String, List<String>>? videoGroups,
  })  : standaloneIds = standaloneIds ?? <String>[],
        imageIds = imageIds ?? <String>[],
        wordPairsIds = wordPairsIds ?? <String>[],
        videoGroups = videoGroups ?? <String, List<String>>{};

  /// ConvoTemplate-1, DialogueCompletion, ClozeSequence, SentenceBuilder, AppearDisappear —
  /// with or without an image; anything answerable that isn't image/WordPairs/video.
  final List<String> standaloneIds;

  /// imageQuizTemplate-1 / imageQuizTemplate-2.
  final List<String> imageIds;

  /// WordPairs.
  final List<String> wordPairsIds;

  /// VideoConversation questions, grouped by video identity (`progressKey::videoFile`),
  /// each list preserving the question's original in-`questions.json` order.
  final Map<String, List<String>> videoGroups;
}

class ReminderQuestionBuilder {
  const ReminderQuestionBuilder._();

  static const int _standalonePerReminder = 2;
  static const int _imagePerReminder = 2;
  static const int _wordPairsPerReminder = 1;

  /// Composition when a main level has no video questions at all: the video slot's share
  /// is redistributed into standalone/image instead of leaving the reminder shorter.
  static const int _standaloneNoVideoPerReminder = 5;
  static const int _imageNoVideoPerReminder = 5;

  static ReminderQuestionSplit build({
    required Map<String, int> wrongAnswerCounters,
    required MainLevelReminderPool pool,
    Random? random,
  }) {
    final rng = random ?? Random();

    // Mutable working copies — picks are removed as they're consumed so the two reminders
    // never repeat the same question.
    final standalone = List<String>.from(pool.standaloneIds);
    final image = List<String>.from(pool.imageIds);
    final wordPairs = List<String>.from(pool.wordPairsIds);
    final videos = <String, List<String>>{
      for (final entry in pool.videoGroups.entries)
        entry.key: List<String>.from(entry.value),
    };

    final reminderOne = _buildOneReminder(
      wrongAnswerCounters: wrongAnswerCounters,
      standalone: standalone,
      image: image,
      wordPairs: wordPairs,
      videos: videos,
      rng: rng,
    );
    final reminderTwo = _buildOneReminder(
      wrongAnswerCounters: wrongAnswerCounters,
      standalone: standalone,
      image: image,
      wordPairs: wordPairs,
      videos: videos,
      rng: rng,
    );

    return ReminderQuestionSplit(
      reminderOneQuestionIds: reminderOne,
      reminderTwoQuestionIds: reminderTwo,
    );
  }

  /// Builds one reminder level's question list, mutating the shared pools (removing
  /// whatever it picks) so a second call for the other reminder doesn't repeat them.
  static List<String> _buildOneReminder({
    required Map<String, int> wrongAnswerCounters,
    required List<String> standalone,
    required List<String> image,
    required List<String> wordPairs,
    required Map<String, List<String>> videos,
    required Random rng,
  }) {
    List<String>? videoBlock;
    if (videos.isNotEmpty) {
      var bestTotal = -1;
      var candidates = <String>[];
      for (final entry in videos.entries) {
        final total = entry.value
            .fold<int>(0, (sum, id) => sum + (wrongAnswerCounters[id] ?? 0));
        if (total > bestTotal) {
          bestTotal = total;
          candidates = [entry.key];
        } else if (total == bestTotal) {
          candidates.add(entry.key);
        }
      }
      candidates.shuffle(rng);
      final chosenKey = candidates.first;
      videoBlock = videos.remove(chosenKey);
    }

    final noVideo = videoBlock == null;
    final standaloneCount = noVideo ? _standaloneNoVideoPerReminder : _standalonePerReminder;
    final imageCount = noVideo ? _imageNoVideoPerReminder : _imagePerReminder;

    final picked = <String>[
      ..._pickFromGroup(standalone, standaloneCount, wrongAnswerCounters, rng),
      ..._pickFromGroup(image, imageCount, wrongAnswerCounters, rng),
      ..._pickFromGroup(wordPairs, _wordPairsPerReminder, wrongAnswerCounters, rng),
    ]..shuffle(rng);

    // Video questions must stay contiguous and in original order — never mixed in with the
    // shuffled standalone/image/WordPairs picks, or the shared video controller's
    // continueExistingPlayback/seek assumptions break.
    return videoBlock == null ? picked : [...videoBlock, ...picked];
  }

  /// Prioritizes the highest wrong-answer counters within [pool] (ties shuffled), falling
  /// back to a random pick from the remaining untouched questions if there aren't enough
  /// wrong ones to fill [count]. Removes whatever it picks from [pool] in place.
  static List<String> _pickFromGroup(
    List<String> pool,
    int count,
    Map<String, int> wrongAnswerCounters,
    Random rng,
  ) {
    if (pool.isEmpty || count <= 0) return const [];

    final groupedByCount = <int, List<String>>{};
    for (final id in pool) {
      final c = wrongAnswerCounters[id] ?? 0;
      if (c > 0) groupedByCount.putIfAbsent(c, () => <String>[]).add(id);
    }
    final sortedCounts = groupedByCount.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final picked = <String>[];
    for (final c in sortedCounts) {
      final ids = groupedByCount[c]!..shuffle(rng);
      for (final id in ids) {
        if (picked.length >= count) break;
        picked.add(id);
      }
      if (picked.length >= count) break;
    }
    if (picked.length < count) {
      final remaining = pool.where((id) => !picked.contains(id)).toList()
        ..shuffle(rng);
      picked.addAll(remaining.take(count - picked.length));
    }

    pool.removeWhere(picked.contains);
    return picked;
  }
}
