import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/level_completion_result.dart';
import '../providers/settings_provider.dart';
import '../models/level_config.dart';
import '../models/quiz_flow.dart';
import '../models/reminder_progress.dart' show parseReminderQuestionId;
import '../services/audio_service.dart' as audio;
import '../services/level_config_loader.dart';
import 'image_quiz_screen.dart';
import 'transitions/custom_page_routes.dart';

/// Loads the level config, splits questions into type-homogeneous phases if needed,
/// and sequences each phase as a separate navigator route. Supports mixed-type levels
/// (e.g. image + vocab questions in the same sub-level).
class QuizRunnerScreen extends ConsumerStatefulWidget {
  const QuizRunnerScreen({
    super.key,
    required this.subLevel,
    required this.ordinalLevelIndex,
    required this.progressKey,
    this.reminderMode = false,
    this.reminderQuestionIds,
    this.reminderSourceLevelsByProgressKey,
  });

  final SubLevel subLevel;
  final int ordinalLevelIndex;
  final String progressKey;
  final bool reminderMode;
  final List<String>? reminderQuestionIds;
  final Map<String, SubLevelItem>? reminderSourceLevelsByProgressKey;

  @override
  ConsumerState<QuizRunnerScreen> createState() => _QuizRunnerScreenState();
}

class _QuizRunnerScreenState extends ConsumerState<QuizRunnerScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    // Defer navigation so the widget is fully mounted first.
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    if (widget.subLevel.isReminder) {
      await _runReminder();
    } else {
      await _runRegular();
    }
  }

  // ─── Regular level ───────────────────────────────────────────────────────

  Future<void> _runRegular() async {
    LevelConfig cfg;
    try {
      cfg = await loadLevelConfig(widget.subLevel.iconImageName);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
      return;
    }

    // Split into consecutive type-homogeneous phases (preserves question order).
    final phases = _splitIntoPhases(cfg);

    bool allCompleted = true;
    for (final phaseCfg in phases) {
      if (!mounted) return;
      final result = await _pushPhase(phaseCfg);
      if (result == null || !result.completed) allCompleted = false;
    }

    if (!mounted) return;
    Navigator.of(context).pop(LevelCompletionResult(
      ordinalLevelIndex: widget.ordinalLevelIndex,
      completed: allCompleted,
    ));
  }

  // ─── Reminder level ──────────────────────────────────────────────────────

  Future<void> _runReminder() async {
    final ids = widget.reminderQuestionIds ?? const <String>[];
    final sources = widget.reminderSourceLevelsByProgressKey ?? {};
    if (ids.isEmpty) {
      if (mounted) setState(() => _error = 'No reminder questions');
      return;
    }

    // Split question IDs by type so each ImageQuizScreen run is type-homogeneous.
    final imageReminderIds = <String>[];
    final convoReminderIds = <String>[];
    final loadedConfigs = <String, LevelConfig>{};
    try {
      for (final id in ids) {
        final (progressKey, questionIndex) = parseReminderQuestionId(id);
        final src = sources[progressKey];
        if (src == null) continue;
        final cfg = loadedConfigs[progressKey] ??=
            await loadLevelConfig(src.sub.iconImageName);
        if (questionIndex >= 0 && questionIndex < cfg.questions.length) {
          if (cfg.questions[questionIndex].type == LevelQuestionType.image) {
            imageReminderIds.add(id);
          } else {
            convoReminderIds.add(id);
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
      return;
    }

    if (imageReminderIds.isEmpty && convoReminderIds.isEmpty) {
      if (mounted) setState(() => _error = 'Could not resolve reminder questions');
      return;
    }

    if (!mounted) return;

    // Run image questions first (if any), then convo questions.
    if (imageReminderIds.isNotEmpty) {
      await Navigator.of(context).push<LevelCompletionResult>(
        popFadeRoute<LevelCompletionResult>(
          ImageQuizScreen(
            subLevel: widget.subLevel,
            ordinalLevelIndex: widget.ordinalLevelIndex,
            progressKey: widget.progressKey,
            reminderMode: true,
            reminderQuestionIds: imageReminderIds,
            reminderSourceLevelsByProgressKey: sources,
          ),
        ),
      );
    }

    if (convoReminderIds.isNotEmpty && mounted) {
      await Navigator.of(context).push<LevelCompletionResult>(
        popFadeRoute<LevelCompletionResult>(
          ImageQuizScreen(
            subLevel: widget.subLevel,
            ordinalLevelIndex: widget.ordinalLevelIndex,
            progressKey: widget.progressKey,
            reminderMode: true,
            reminderQuestionIds: convoReminderIds,
            reminderSourceLevelsByProgressKey: sources,
          ),
        ),
      );
    }

    if (mounted) {
      Navigator.of(context).pop(LevelCompletionResult(
        ordinalLevelIndex: widget.ordinalLevelIndex,
        completed: true,
        isReminder: true,
      ));
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  /// Splits [cfg] into consecutive type-homogeneous sub-configs.
  /// E.g. [img, img, vocab, img] → [{img,img}, {vocab}, {img}]
  List<LevelConfig> _splitIntoPhases(LevelConfig cfg) {
    if (cfg.questions.isEmpty) return [cfg];

    final phases = <LevelConfig>[];
    final current = <LevelQuestion>[];
    LevelQuestionType? currentType;

    for (final q in cfg.questions) {
      final bucket = q.type == LevelQuestionType.image
          ? LevelQuestionType.image
          : LevelQuestionType.vocab; // vocab and grammar share the same screen (ImageQuizScreen convo mode)
      if (currentType == null || bucket == currentType) {
        current.add(q);
        currentType = bucket;
      } else {
        phases.add(LevelConfig(questions: List.unmodifiable(current)));
        current.clear();
        current.add(q);
        currentType = bucket;
      }
    }
    if (current.isNotEmpty) {
      phases.add(LevelConfig(questions: List.unmodifiable(current)));
    }
    return phases;
  }

  /// Pushes the quiz screen for a type-homogeneous [phaseCfg].
  Future<LevelCompletionResult?> _pushPhase(LevelConfig phaseCfg) {
    return Navigator.of(context).push<LevelCompletionResult>(
      popFadeRoute<LevelCompletionResult>(
        ImageQuizScreen(
          subLevel: widget.subLevel,
          ordinalLevelIndex: widget.ordinalLevelIndex,
          progressKey: widget.progressKey,
          preloadedLevelConfig: phaseCfg,
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  void _popToLevels(BuildContext context) {
    final soundFxOn = ref.read(settingsProvider).valueOrNull?.soundFxOn ?? true;
    audio.playClick(soundFxOn: soundFxOn);
    Navigator.of(context).pop(LevelCompletionResult(
      ordinalLevelIndex: widget.ordinalLevelIndex,
      completed: false,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final closeLeading = IconButton(
      icon: const Icon(Icons.close),
      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
      onPressed: () => _popToLevels(context),
    );

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.subLevel.title),
          leading: closeLeading,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error!, textAlign: TextAlign.center),
          ),
        ),
      );
    }
    // Show a loading indicator while async init is running.
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subLevel.title),
        leading: closeLeading,
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
