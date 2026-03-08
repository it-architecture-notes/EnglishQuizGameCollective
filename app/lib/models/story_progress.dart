class StoryProgressState {
  const StoryProgressState({
    this.completedEventIdsByMainLevel = const {},
  });

  final Map<int, Set<int>> completedEventIdsByMainLevel;

  bool isCompleted({
    required int mainLevelId,
    required int eventId,
  }) {
    return completedEventIdsByMainLevel[mainLevelId]?.contains(eventId) == true;
  }

  StoryProgressState markCompleted({
    required int mainLevelId,
    required int eventId,
  }) {
    final updated = <int, Set<int>>{};
    for (final entry in completedEventIdsByMainLevel.entries) {
      updated[entry.key] = Set<int>.from(entry.value);
    }
    updated.putIfAbsent(mainLevelId, () => <int>{}).add(eventId);
    return StoryProgressState(completedEventIdsByMainLevel: updated);
  }

  Map<String, dynamic> toJson() {
    return {
      'completedEventIdsByMainLevel': completedEventIdsByMainLevel.map(
        (mainLevelId, eventIds) =>
            MapEntry(mainLevelId.toString(), eventIds.toList()..sort()),
      ),
    };
  }

  static StoryProgressState fromJson(Map<String, dynamic> json) {
    final raw =
        json['completedEventIdsByMainLevel'] as Map<String, dynamic>? ?? {};
    final parsed = <int, Set<int>>{};
    for (final entry in raw.entries) {
      final mainLevelId = int.tryParse(entry.key);
      if (mainLevelId == null) continue;
      final list = (entry.value as List<dynamic>? ?? const [])
          .map((e) => (e as num?)?.toInt())
          .whereType<int>()
          .toSet();
      parsed[mainLevelId] = list;
    }
    return StoryProgressState(completedEventIdsByMainLevel: parsed);
  }
}
