/// Persisted state for the Friends panel (freed animals, hint seen).
class FriendsState {
  const FriendsState({
    this.freedAnimalIds = const {},
    this.hintDismissed = false,
  });

  final Set<String> freedAnimalIds;
  final bool hintDismissed;

  Map<String, dynamic> toJson() => {
        'freedAnimalIds': freedAnimalIds.toList(),
        'hintDismissed': hintDismissed,
      };

  static FriendsState fromJson(Map<String, dynamic> json) {
    final ids = json['freedAnimalIds'];
    final list = ids is List
        ? (ids)
            .map((e) => e?.toString())
            .whereType<String>()
            .toSet()
        : <String>{};
    return FriendsState(
      freedAnimalIds: list,
      hintDismissed: json['hintDismissed'] as bool? ?? false,
    );
  }

  FriendsState copyWith({
    Set<String>? freedAnimalIds,
    bool? hintDismissed,
  }) {
    return FriendsState(
      freedAnimalIds: freedAnimalIds ?? this.freedAnimalIds,
      hintDismissed: hintDismissed ?? this.hintDismissed,
    );
  }
}
