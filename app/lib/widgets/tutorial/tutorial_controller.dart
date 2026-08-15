import 'dart:async';

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

  String? _activeStepKey;
  final Set<String> _shownStepKeys = {};
  Completer<void>? _beforePlaybackCompleter;

  bool get isReady => _loaded;

  /// Non-null while a step's character/message card should be visible.
  String? get activeMessageKey =>
      _activeStepKey == null ? null : config.steps[_activeStepKey]!.messageKey;
  String? get activeCharacterAsset => _activeStepKey == null
      ? null
      : config.steps[_activeStepKey]!.characterAsset;

  Future<void> load() async {
    _loaded = true;
    notifyListeners();
  }

  bool get _shouldRun => config.enabled && _loaded;

  /// Shows this step's guide the first time it's called for [stepKey] in this level entry;
  /// a no-op on every subsequent call for the same key (see class doc).
  void maybeShowFor(String stepKey) {
    if (!_shouldRun || !_shownStepKeys.add(stepKey)) return;
    if (!config.steps.containsKey(stepKey)) return;
    _activeStepKey = stepKey;
    notifyListeners();
  }

  Future<void> showBeforePlayback(String stepKey) {
    if (!_shouldRun || _shownStepKeys.contains(stepKey)) {
      return Future<void>.value();
    }
    if (!config.steps.containsKey(stepKey)) return Future<void>.value();
    _shownStepKeys.add(stepKey);
    final completer = Completer<void>();
    _beforePlaybackCompleter = completer;
    _activeStepKey = stepKey;
    notifyListeners();
    return completer.future;
  }

  void confirmActive() {
    if (_activeStepKey == null) return;
    final completer = _beforePlaybackCompleter;
    _beforePlaybackCompleter = null;
    _activeStepKey = null;
    notifyListeners();
    if (completer != null && !completer.isCompleted) completer.complete();
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
