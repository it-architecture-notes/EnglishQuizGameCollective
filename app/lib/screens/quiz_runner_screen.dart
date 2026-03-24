import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/level_config.dart';
import '../models/quiz_flow.dart';
import '../models/reminder_progress.dart' show parseReminderQuestionId;
import '../quiz_game_constants.dart';
import '../services/level_config_loader.dart';
import 'image_quiz_screen.dart';
import 'vocabulary_quiz_screen.dart';

/// Routes to image or vocabulary (convo) quiz based on unified [LevelConfig].
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
  Widget? _resolved;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    if (widget.subLevel.isReminder) {
      await _resolveReminder();
      return;
    }
    try {
      final cfg = await loadLevelConfig(widget.subLevel.iconImageName);
      if (!mounted) return;
      setState(() {
        _resolved = _buildForConfig(cfg);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _resolveReminder() async {
    final ids = widget.reminderQuestionIds ?? const <String>[];
    final sources = widget.reminderSourceLevelsByProgressKey ?? {};
    if (ids.isEmpty) {
      setState(() => _error = 'No reminder questions');
      return;
    }
    final types = <LevelQuestionType>{};
    try {
      for (final id in ids) {
        final (progressKey, questionIndex) = parseReminderQuestionId(id);
        final src = sources[progressKey];
        if (src == null) continue;
        final cfg = await loadLevelConfig(src.sub.iconImageName);
        if (questionIndex < 0 || questionIndex >= cfg.questions.length) {
          continue;
        }
        types.add(cfg.questions[questionIndex].type);
      }
      if (types.isEmpty) {
        setState(() => _error = 'Could not resolve reminder questions');
        return;
      }
      final hasImage = types.contains(LevelQuestionType.image);
      final hasConvo = types.contains(LevelQuestionType.vocab) ||
          types.contains(LevelQuestionType.grammar);
      if (hasImage && hasConvo) {
        setState(
          () => _error =
              'Mixed-type reminders are not supported in this build.',
        );
        return;
      }
      if (!mounted) return;
      setState(() {
        if (hasImage) {
          _resolved = ImageQuizScreen(
            subLevel: widget.subLevel,
            quizType: kQuizGameType,
            ordinalLevelIndex: widget.ordinalLevelIndex,
            progressKey: widget.progressKey,
            reminderMode: true,
            reminderQuestionIds: widget.reminderQuestionIds,
            reminderSourceLevelsByProgressKey:
                widget.reminderSourceLevelsByProgressKey,
          );
        } else if (hasConvo) {
          _resolved = VocabularyQuizScreen(
            subLevel: widget.subLevel,
            quizType: kQuizGameType,
            ordinalLevelIndex: widget.ordinalLevelIndex,
            progressKey: widget.progressKey,
            reminderMode: true,
            reminderQuestionIds: widget.reminderQuestionIds,
            reminderSourceLevelsByProgressKey:
                widget.reminderSourceLevelsByProgressKey,
          );
        } else {
          _error = 'Unsupported reminder question types';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Widget _buildForConfig(LevelConfig cfg) {
    final types = cfg.questions.map((q) => q.type).toSet();
    if (types.length == 1 && types.first == LevelQuestionType.image) {
      return ImageQuizScreen(
        subLevel: widget.subLevel,
        quizType: kQuizGameType,
        ordinalLevelIndex: widget.ordinalLevelIndex,
        progressKey: widget.progressKey,
        preloadedLevelConfig: cfg,
      );
    }
    if (types.isNotEmpty &&
        types.every(
          (t) =>
              t == LevelQuestionType.vocab || t == LevelQuestionType.grammar,
        )) {
      return VocabularyQuizScreen(
        subLevel: widget.subLevel,
        quizType: kQuizGameType,
        ordinalLevelIndex: widget.ordinalLevelIndex,
        progressKey: widget.progressKey,
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.subLevel.title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Mixed question types are not supported for "${widget.subLevel.iconImageName}" yet.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.subLevel.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    if (_resolved != null) {
      return _resolved!;
    }
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
