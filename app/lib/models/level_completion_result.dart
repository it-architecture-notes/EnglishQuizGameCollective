/// Result passed when a quiz screen pops after level completion.
class LevelCompletionResult {
  const LevelCompletionResult({
    required this.ordinalLevelIndex,
    required this.completed,
  });

  /// 1-based position in the subLevels list (progression key).
  final int ordinalLevelIndex;

  /// True if user earned at least 1 star (level passed).
  final bool completed;
}
