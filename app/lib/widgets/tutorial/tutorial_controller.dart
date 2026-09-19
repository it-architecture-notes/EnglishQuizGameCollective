import 'package:flutter/material.dart';

import '../../models/level_config.dart';

/// Owns guide-overlay state only: which step (if any) is currently showing its character/message
/// card. Each configured step key (a template name, or `"VideoConversation:<answer type>"`) shows
/// its guide **once per level entry** — the first time its answer controls render — not on every
/// question that maps to it. Deliberately **not** persisted across playthroughs: every fresh entry
/// into the level gets a brand-new `TutorialController` with empty state, so the guide is
/// available every time, not just once ever. (`TutorialService` still exists for a possible future
/// "seen once" opt-in, just isn't consulted here.)
///
/// Has no knowledge of scoring, reminders, or achievements, and never calls `_goNext` — it only
/// reacts to two external signals, both driven from `image_quiz_screen.dart`: [maybeShowFor]
/// (the answer controls for a configured step just rendered) and [onUserActed] (the learner
/// answered that step's question — right or wrong, see "guide not enforcer" in the tutorial
/// plan). Any other quiz behavior — locking, red highlights, scoring, reminders — is completely
/// unaffected by this class's existence.
class TutorialController extends ChangeNotifier {
  TutorialController({required this.config, required this.tutorialId});

  final LevelTutorialConfig config;
  final String tutorialId;

  bool _loaded = false;
  bool _disposed = false;

  String? _activeStepKey;
  final Set<String> _shownStepKeys = {};

  bool get isReady => _loaded;

  /// Non-null while a step's character/message card should be visible.
  String? get activeMessageKey =>
      _activeStepKey == null ? null : config.steps[_activeStepKey]!.messageKey;
  String? get activeCharacterAsset => _activeStepKey == null
      ? null
      : config.steps[_activeStepKey]!.characterAsset;

  Future<void> load() async {
    if (_disposed) return;
    _loaded = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  bool get _shouldRun => config.enabled && _loaded;

  /// The `messageKey` configured for [stepKey], regardless of whether its guide has been shown
  /// yet — for the always-on footer hint, which is independent of the once-per-level overlay.
  String? messageKeyFor(String stepKey) => config.steps[stepKey]?.messageKey;

  /// Shows this step's guide the first time it's called for [stepKey] in this level entry;
  /// a no-op on every subsequent call for the same key (see class doc). Returns true exactly
  /// when this call is the one that shows it, so the caller can suppress other guidance
  /// (e.g. a footer hint) on this specific question — not just while the overlay is visible.
  bool maybeShowFor(String stepKey) {
    if (!_shouldRun || !_shownStepKeys.add(stepKey)) return false;
    if (!config.steps.containsKey(stepKey)) return false;
    _activeStepKey = stepKey;
    notifyListeners();
    return true;
  }

  void confirmActive() {
    if (_activeStepKey == null) return;
    _activeStepKey = null;
    notifyListeners();
  }

  /// Called once per answered question (from `_handleInteractiveConvoOutcome`), regardless of
  /// whether the answer was correct — the guide's job is done once the learner acts on it.
  void onUserActed(String stepKey) {
    if (_activeStepKey != stepKey) return;
    _activeStepKey = null;
    notifyListeners();
  }

  /// Dismisses the active guide when the learner moves to the next question.
  void dismissActive() {
    if (_activeStepKey == null) return;
    _activeStepKey = null;
    notifyListeners();
  }
}
