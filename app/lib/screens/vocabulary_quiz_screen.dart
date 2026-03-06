import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/level_completion_result.dart';
import '../models/quiz_flow.dart';
import '../models/vocabulary_quiz.dart';
import '../providers/localization_provider.dart';
import '../providers/settings_provider.dart';
import '../services/achievement_service.dart';
import '../services/app_settings_service.dart';
import '../services/audio_service.dart' as audio;
import '../services/game_config_loader.dart';
import '../services/profile_service.dart';
import '../services/quiz_progress_service.dart';
import '../services/vocabulary_quiz_loader.dart';

const double _kMinTouchTarget = 48.0;
const String _kBlank = '_____';

enum _Phase { loading, playing, end }

class VocabularyQuizScreen extends ConsumerStatefulWidget {
  const VocabularyQuizScreen({
    super.key,
    required this.subLevel,
    required this.quizType,
    required this.ordinalLevelIndex,
  });

  final SubLevel subLevel;
  final String quizType;
  /// 1-based position in subLevels list (progression key).
  final int ordinalLevelIndex;

  @override
  ConsumerState<VocabularyQuizScreen> createState() =>
      _VocabularyQuizScreenState();
}

class _VocabularyQuizScreenState extends ConsumerState<VocabularyQuizScreen> {
  _Phase _phase = _Phase.loading;
  String? _loadError;

  VocabularyLevel? _level;
  GameConfig _config = const GameConfig();

  List<VocabularyQuestion> get _questions => _level?.questions ?? [];

  int _currentIndex = 0;
  int _correctCount = 0;
  bool _answerLocked = false;
  bool _showNext = false;
  int? _selectedIndex;
  List<String> _currentOptions = [];

  bool _showTranslation = false;
  bool _conversationUnlocked = false;
  DateTime? _quizStartTime;

  @override
  void initState() {
    super.initState();
    _loadLevel();
  }

  @override
  void dispose() {
    audio.stopQuizMusic();
    super.dispose();
  }

  Future<void> _loadLevel() async {
    try {
      final config = await GameConfig.load();
      final level = await loadVocabularyLevel(
        widget.subLevel.iconImageName,
        widget.subLevel.levelNumber,
      );

      if (mounted) {
        setState(() {
          _config = config;
          _level = level;
          _phase = _Phase.playing;
          _quizStartTime = DateTime.now();
          _currentOptions = _buildOptions(level.questions[0]);
        });
        final musicOn = ref.read(settingsProvider).valueOrNull?.musicOn ?? true;
        audio.startQuizMusic(musicOn: musicOn);
      }
    } catch (e, st) {
      debugPrint('VocabularyQuizScreen _loadLevel: $e\n$st');
      if (mounted) {
        setState(() {
          _loadError = e.toString();
        });
      }
    }
  }

  // ── Options ────────────────────────────────────────────────────────────────

  List<String> _buildOptions(VocabularyQuestion q) {
    final options = [q.answer, ...q.distractors]..shuffle(Random());
    return options;
  }

  // ── Answer handling ────────────────────────────────────────────────────────

  void _onAnswerTap(int optionIndex) {
    if (_answerLocked) return;
    final selected = _currentOptions[optionIndex];
    final correct = _questions[_currentIndex].answer;
    final isCorrect = selected == correct;
    final soundFxOn = ref.read(settingsProvider).valueOrNull?.soundFxOn ?? true;
    if (isCorrect) {
      audio.playCorrect(soundFxOn: soundFxOn);
    } else {
      audio.playWrong(soundFxOn: soundFxOn);
    }
    AchievementService.instance.recordAnswer(isCorrect);
    setState(() {
      _answerLocked = true;
      _selectedIndex = optionIndex;
      if (isCorrect) {
        _correctCount++;
        _showNext = false;
        Future.delayed(
          Duration(
              milliseconds: (_config.autoAdvanceDelaySeconds * 1000).round()),
          () {
            if (!mounted) return;
            _goNext();
          },
        );
      } else {
        _showNext = true;
      }
    });
  }

  void _goNext() {
    if (_currentIndex + 1 >= _questions.length) {
      setState(() {
        _phase = _Phase.end;
        _conversationUnlocked = true;
      });
      return;
    }
    final nextQuestion = _questions[_currentIndex + 1];
    setState(() {
      _currentIndex++;
      _answerLocked = false;
      _showNext = false;
      _selectedIndex = null;
      _currentOptions = _buildOptions(nextQuestion);
    });
  }

  // ── Scoring ────────────────────────────────────────────────────────────────

  int _stars() {
    if (_questions.isEmpty) return 0;
    final rate = (_correctCount / _questions.length) * 100;
    if (rate >= 85) return 3;
    if (rate >= 70) return 2;
    if (rate >= 60) return 1;
    return 0;
  }

  int _diamondsEarned() => _correctCount;

  Future<void> _onEndOk() async {
    final stars = _stars();
    if (_quizStartTime != null) {
      final duration = DateTime.now().difference(_quizStartTime!).inSeconds;
      await AchievementService.instance.recordQuizCompleted(duration);
    }
    if (stars >= 1) {
      await QuizProgressService.instance.recordLevelCompletion(
        quizType: widget.quizType,
        levelNumber: widget.ordinalLevelIndex,
        stars: stars,
        diamondsEarned: _diamondsEarned(),
      );
    }
    if (stars >= 1) {
      await ProfileService.instance.registerQuizCompletion(
        quizType: widget.quizType,
        questionCount: _questions.length,
      );
    }
    if (mounted) {
      Navigator.of(context).pop(LevelCompletionResult(
        ordinalLevelIndex: widget.ordinalLevelIndex,
        completed: stars >= 1,
      ));
    }
  }

  // ── Full conversation panel ────────────────────────────────────────────────

  void _showFullConversation() {
    final strings = ref.read(currentLocalizedStringsProvider).valueOrNull ?? {};
    final title = strings['full_conversation'] ?? 'Full Conversation';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Text(
                    title,
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: _questions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final q = _questions[i];
                      final c1Name = _capitalize(_level?.character1 ?? '');
                      final c2Name = _capitalize(_level?.character2 ?? '');
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$c1Name: ${q.line1Resolved}',
                            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$c2Name: ${q.line2Resolved}',
                            style: Theme.of(ctx).textTheme.bodyMedium,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsProvider, (prev, next) {
      if (next.valueOrNull?.musicOn == true &&
          _phase == _Phase.playing &&
          _level != null) {
        audio.startQuizMusic(musicOn: true);
      }
    });
    final soundFxOn = ref.read(settingsProvider).valueOrNull?.soundFxOn ?? true;
    final strings = ref.watch(currentLocalizedStringsProvider).valueOrNull ?? {};
    final userLanguage = ref.watch(settingsProvider).valueOrNull?.language ?? 'en';
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subLevel.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            audio.playClick(soundFxOn: soundFxOn);
            Navigator.of(context).pop(LevelCompletionResult(
                  ordinalLevelIndex: widget.ordinalLevelIndex,
                  completed: false,
                ));
          },
        ),
      ),
      body: SafeArea(child: _buildBody(soundFxOn, strings, userLanguage)),
    );
  }

  Widget _buildBody(bool soundFxOn, Map<String, String> strings, String userLanguage) {
    if (_loadError != null) {
      return _buildError(soundFxOn, strings);
    }
    return switch (_phase) {
      _Phase.loading => const Center(child: CircularProgressIndicator()),
      _Phase.playing => _buildPlaying(soundFxOn, strings, userLanguage),
      _Phase.end => _buildEnd(soundFxOn, strings),
    };
  }

  Widget _buildError(bool soundFxOn, Map<String, String> strings) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _loadError!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              audio.playClick(soundFxOn: soundFxOn);
              Navigator.of(context).pop(LevelCompletionResult(
                    ordinalLevelIndex: widget.ordinalLevelIndex,
                    completed: false,
                  ));
            },
            child: Text(strings['back_to_levels'] ?? 'Back to Levels'),
          ),
        ],
      ),
    );
  }

  // ── Playing phase ──────────────────────────────────────────────────────────

  String _questionLabel(Map<String, String> strings, int current, int total) {
    final template = strings['question_x_of_y'] ?? 'Question %s / %s';
    return template.replaceFirst('%s', '$current').replaceFirst('%s', '$total');
  }

  Widget _buildPlaying(bool soundFxOn, Map<String, String> strings, String userLanguage) {
    final q = _questions[_currentIndex];
    final total = _questions.length;
    final isLast = _currentIndex + 1 >= total;

    return Column(
      children: [
        // Progress
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            _questionLabel(strings, _currentIndex + 1, total),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),

        // Characters + dialogue
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: _buildCharactersRow(q, userLanguage),
          ),
        ),

        // Answer buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: List.generate(4, (i) => _buildAnswerButton(i, q, soundFxOn)),
          ),
        ),

        // Next / Finish — reserves height so layout doesn't jump
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            height: _kMinTouchTarget + 8,
            child: _showNext
                ? FilledButton(
                    onPressed: () {
                      audio.playClick(soundFxOn: soundFxOn);
                      _goNext();
                    },
                    child: Text(isLast ? (strings['finish'] ?? 'Finish') : (strings['next'] ?? 'Next')),
                  )
                : const SizedBox.shrink(),
          ),
        ),

        // Translate + Full Conversation
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              if (userLanguage != 'en') ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      audio.playClick(soundFxOn: soundFxOn);
                      setState(() => _showTranslation = !_showTranslation);
                    },
                    icon: Icon(
                      _showTranslation
                          ? Icons.translate
                          : Icons.g_translate_outlined,
                      size: 18,
                    ),
                    label: Text(_showTranslation ? (strings['english'] ?? 'English') : (strings['translate'] ?? 'Translate')),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _conversationUnlocked
                      ? () {
                          audio.playClick(soundFxOn: soundFxOn);
                          _showFullConversation();
                        }
                      : null,
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: Text(strings['full_conversation'] ?? 'Full Conversation'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Characters row ─────────────────────────────────────────────────────────

  Widget _buildCharactersRow(VocabularyQuestion q, String userLanguage) {
    final line1Text = _showTranslation
        ? (q.line1[userLanguage] ?? q.line1['en'] ?? '')
        : (q.line1['en'] ?? '');
    final line2Text = _showTranslation
        ? (q.line2[userLanguage] ?? q.line2['en'] ?? '')
        : (q.line2['en'] ?? '');

    final char1 = _level?.character1 ?? '';
    final char2 = _level?.character2 ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildCharacterColumn(
            name: char1,
            dialogueLine: line1Text,
            isActive: q.blankInLine1,
            alignment: CrossAxisAlignment.start,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCharacterColumn(
            name: char2,
            dialogueLine: line2Text,
            isActive: !q.blankInLine1,
            alignment: CrossAxisAlignment.end,
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterColumn({
    required String name,
    required String dialogueLine,
    required bool isActive,
    required CrossAxisAlignment alignment,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        _buildSpeechBubble(
          text: dialogueLine,
          isActive: isActive,
          alignRight: alignment == CrossAxisAlignment.end,
        ),
        const SizedBox(height: 8),
        Text(
          _capitalize(name),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        _buildCharacterAvatar(name, size: 64),
      ],
    );
  }

  Widget _buildCharacterAvatar(String name, {required double size}) {
    final imagePath = 'assets/images/characters/$name.png';
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
            return CircleAvatar(
              radius: size / 2,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSpeechBubble({
    required String text,
    required bool isActive,
    required bool alignRight,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = isActive
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final borderColor =
        isActive ? colorScheme.primary : colorScheme.outlineVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: Radius.circular(alignRight ? 12 : 4),
          bottomRight: Radius.circular(alignRight ? 4 : 12),
        ),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: _buildBubbleText(text, isActive: isActive),
    );
  }

  Widget _buildBubbleText(String text, {required bool isActive}) {
    if (!text.contains(_kBlank)) {
      return Text(
        text,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    // Split on blank and render the blank as a highlighted span
    final parts = text.split(_kBlank);
    final spans = <InlineSpan>[];
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        spans.add(TextSpan(text: parts[i]));
      }
      if (i < parts.length - 1) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1,
                ),
              ),
              child: Text(
                ' ____ ',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
              ),
            ),
          ),
        );
      }
    }

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall,
        children: spans,
      ),
    );
  }

  // ── Answer buttons ─────────────────────────────────────────────────────────

  Widget _buildAnswerButton(int optionIndex, VocabularyQuestion q, bool soundFxOn) {
    final option = _currentOptions[optionIndex];
    final isCorrect = option == q.answer;
    final isSelected = _selectedIndex == optionIndex;

    Color? bgColor;
    Color? fgColor;
    if (_answerLocked) {
      if (isCorrect) {
        bgColor = Colors.green.shade600;
        fgColor = Colors.white;
      } else if (isSelected) {
        bgColor = Colors.red.shade600;
        fgColor = Colors.white;
      }
    }

    final buttonStyle = bgColor != null
        ? ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: fgColor,
            surfaceTintColor: Colors.transparent,
            disabledBackgroundColor: bgColor,
            disabledForegroundColor: fgColor,
            minimumSize: const Size(_kMinTouchTarget, _kMinTouchTarget),
          )
        : ElevatedButton.styleFrom(
            minimumSize: const Size(_kMinTouchTarget, _kMinTouchTarget),
            disabledBackgroundColor: Colors.grey.shade300,
            disabledForegroundColor: Colors.grey.shade800,
            surfaceTintColor: Colors.transparent,
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        height: _kMinTouchTarget + 8,
        child: ElevatedButton(
          onPressed: _answerLocked
              ? null
              : () {
                  audio.playClick(soundFxOn: soundFxOn);
                  _onAnswerTap(optionIndex);
                },
          style: buttonStyle,
          child: Text(
            _capitalize(option),
            style: fgColor != null
                ? Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: fgColor,
                      fontWeight: FontWeight.w600,
                    )
                : Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }

  // ── End panel ──────────────────────────────────────────────────────────────

  Widget _buildEnd(bool soundFxOn, Map<String, String> strings) {
    final stars = _stars();
    final diamonds = _diamondsEarned();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              strings['level_complete'] ?? 'Level complete!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Icon(
                  i < stars ? Icons.star : Icons.star_border,
                  size: 48,
                  color: Colors.amber,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.diamond, color: Colors.blue.shade700, size: 28),
                const SizedBox(width: 8),
                Text(
                  '+$diamonds',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '$_correctCount / ${_questions.length} correct',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                audio.playClick(soundFxOn: soundFxOn);
                _showFullConversation();
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: Text(strings['view_full_conversation'] ?? 'View Full Conversation'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: _kMinTouchTarget + 8,
              child: FilledButton(
                onPressed: () {
                  audio.playClick(soundFxOn: soundFxOn);
                  _onEndOk();
                },
                child: Text(strings['ok'] ?? 'OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Utilities ──────────────────────────────────────────────────────────────

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}
