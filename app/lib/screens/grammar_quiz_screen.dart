import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/grammar_quiz.dart';
import '../models/level_completion_result.dart';
import '../models/quiz_flow.dart';
import '../providers/localization_provider.dart';
import '../providers/settings_provider.dart';
import '../services/achievement_service.dart';
import '../services/audio_service.dart' as audio;
import '../services/game_config_loader.dart';
import '../services/grammar_quiz_loader.dart';
import '../services/profile_service.dart';
import '../services/quiz_progress_service.dart';

const double _kMinTouchTarget = 48.0;
const String _kBlank = '_____';

/// Fallback when no grammar character images are found in the bundle.
const List<String> _kGrammarCharacterFallbacks = [
  'assets/images/grammar-characters/host.png',
  'assets/images/grammar-characters/guide.png',
  'assets/images/grammar-characters/narrator.png',
];

enum _Phase { loading, playing, end }

class GrammarQuizScreen extends ConsumerStatefulWidget {
  const GrammarQuizScreen({
    super.key,
    required this.subLevel,
    required this.quizType,
    required this.ordinalLevelIndex,
  });

  final SubLevel subLevel;
  final String quizType;
  final int ordinalLevelIndex;

  @override
  ConsumerState<GrammarQuizScreen> createState() => _GrammarQuizScreenState();
}

class _GrammarQuizScreenState extends ConsumerState<GrammarQuizScreen> {
  _Phase _phase = _Phase.loading;
  String? _loadError;

  GrammarLevel? _level;
  GameConfig _config = const GameConfig();

  List<GrammarQuestion> get _questions => _level?.questions ?? [];

  int _currentIndex = 0;
  int _correctCount = 0;
  bool _answerLocked = false;
  bool _showNext = false;
  int? _selectedIndex;
  List<String> _currentOptions = [];
  String _correctAnswer = '';

  final Random _random = Random();
  DateTime? _quizStartTime;

  /// Discovered or fallback paths for grammar character images (non-conversation questions).
  List<String> _grammarCharacterPaths = [];
  /// One path per question index for non-conversation questions.
  final Map<int, String> _questionCharacterPath = {};

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
      final level = await loadGrammarLevel(
        widget.subLevel.iconImageName,
        widget.subLevel.levelNumber,
      );
      final characterPaths = await loadGrammarCharacterImages();
      final paths = characterPaths.isNotEmpty
          ? characterPaths
          : _kGrammarCharacterFallbacks;

      if (mounted) {
        final strings = ref.read(currentLocalizedStringsProvider).valueOrNull ?? {};
        final (options, correct) = _buildOptionsFor(level.questions[0], level, strings);

        final charMap = <int, String>{};
        for (var i = 0; i < level.questions.length; i++) {
          if (level.questions[i] is! GrammarConversationQuestion && paths.isNotEmpty) {
            charMap[i] = paths[_random.nextInt(paths.length)];
          }
        }

        setState(() {
          _config = config;
          _level = level;
          _grammarCharacterPaths = paths;
          _questionCharacterPath
            ..clear()
            ..addAll(charMap);
          _phase = _Phase.playing;
          _quizStartTime = DateTime.now();
          _currentOptions = options;
          _correctAnswer = correct;
        });
        final musicOn = ref.read(settingsProvider).valueOrNull?.musicOn ?? true;
        audio.startQuizMusic(musicOn: musicOn);
      }
    } catch (e, st) {
      debugPrint('GrammarQuizScreen _loadLevel: $e\n$st');
      if (mounted) {
        setState(() => _loadError = e.toString());
      }
    }
  }

  (List<String>, String) _buildOptionsFor(
    GrammarQuestion q,
    GrammarLevel level,
    Map<String, String> strings,
  ) {
    return switch (q) {
      GrammarConversationQuestion() => (
          [q.answer, ...q.distractors]..shuffle(_random),
          q.answer,
        ),
      GrammarWordOrderQuestion() => (
          [q.sentence, ...q.distractors]..shuffle(_random),
          q.sentence,
        ),
      GrammarBankedClozeQuestion() => (
          [q.answer, ...q.distractors]..shuffle(_random),
          q.answer,
        ),
      GrammarYesNoQuestion() => (
          [
            strings['grammar_yes'] ?? 'Yes',
            strings['grammar_no'] ?? 'No',
          ],
          q.correctAnswer.toLowerCase() == 'yes'
              ? (strings['grammar_yes'] ?? 'Yes')
              : (strings['grammar_no'] ?? 'No'),
        ),
      GrammarWhichCorrectQuestion() => (
          List<String>.from(q.options)..shuffle(_random),
          q.options[q.correctIndex],
        ),
      _ => throw StateError('Unsupported grammar question type: ${q.questionType}'),
    };
  }

  void _onAnswerTap(int optionIndex) {
    if (_answerLocked) return;
    final selected = _currentOptions[optionIndex];
    final isCorrect = selected == _correctAnswer;
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
          Duration(milliseconds: (_config.autoAdvanceDelaySeconds * 1000).round()),
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
      setState(() => _phase = _Phase.end);
      return;
    }
    final nextQ = _questions[_currentIndex + 1];
    final strings = ref.read(currentLocalizedStringsProvider).valueOrNull ?? {};
    final (options, correct) = _buildOptionsFor(nextQ, _level!, strings);
    setState(() {
      _currentIndex++;
      _answerLocked = false;
      _showNext = false;
      _selectedIndex = null;
      _currentOptions = options;
      _correctAnswer = correct;
    });
  }

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

  String _questionLabel(Map<String, String> strings, int current, int total) {
    final template = strings['question_x_of_y'] ?? 'Question %s / %s';
    return template.replaceFirst('%s', '$current').replaceFirst('%s', '$total');
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

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
      body: SafeArea(child: _buildBody(soundFxOn, strings)),
    );
  }

  Widget _buildBody(bool soundFxOn, Map<String, String> strings) {
    if (_loadError != null) return _buildError(soundFxOn, strings);
    return switch (_phase) {
      _Phase.loading => const Center(child: CircularProgressIndicator()),
      _Phase.playing => _buildPlaying(soundFxOn, strings),
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

  Widget _buildPlaying(bool soundFxOn, Map<String, String> strings) {
    final q = _questions[_currentIndex];
    final total = _questions.length;
    final isLast = _currentIndex + 1 >= total;
    final isConversation = q is GrammarConversationQuestion;
    final optionCount = q is GrammarYesNoQuestion ? 2 : 4;

    return Column(
      children: [
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
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: isConversation
                ? _buildConversationLayout(q)
                : _buildNonConversationLayout(q, strings),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: List.generate(
              optionCount,
              (i) => _buildAnswerButton(i, soundFxOn),
            ),
          ),
        ),
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
                    child: Text(
                      isLast
                          ? (strings['finish'] ?? 'Finish')
                          : (strings['next'] ?? 'Next'),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildConversationLayout(GrammarConversationQuestion q) {
    final char1 = q.character1.isNotEmpty ? q.character1 : _level!.character1;
    final char2 = q.character2.isNotEmpty ? q.character2 : _level!.character2;
    final line1Text = q.line1['en'] ?? '';
    final line2Text = q.line2['en'] ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildCharacterColumn(
            name: char1,
            dialogueLine: line1Text,
            isActive: q.blankInLine1,
            alignment: CrossAxisAlignment.start,
            vocabularyCharacters: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCharacterColumn(
            name: char2,
            dialogueLine: line2Text,
            isActive: !q.blankInLine1,
            alignment: CrossAxisAlignment.end,
            vocabularyCharacters: true,
          ),
        ),
      ],
    );
  }

  /// Short question-only text for the bubble (single-character layout). Uses localized strings.
  String _bubbleQuestionText(GrammarQuestion q, Map<String, String> strings) {
    return switch (q) {
      GrammarWordOrderQuestion() =>
          strings['grammar_find_correct_order'] ?? 'Which sentence is correct?',
      GrammarBankedClozeQuestion() =>
          strings['grammar_fill_blanks'] ?? 'Fill in the blanks:',
      GrammarYesNoQuestion() =>
          strings['grammar_is_correct'] ?? 'Is this sentence correct?',
      GrammarWhichCorrectQuestion() =>
          strings['grammar_which_correct'] ?? 'Which is correct?',
      _ => '',
    };
  }

  /// Main content text for the field between character+bubble and answer buttons.
  String _contentText(GrammarQuestion q) {
    return switch (q) {
      GrammarWordOrderQuestion() => '', // options are on the buttons
      GrammarBankedClozeQuestion() => q.sentenceWithBlanks,
      GrammarYesNoQuestion() => q.sentence,
      GrammarWhichCorrectQuestion() => q.context ?? '',
      _ => '',
    };
  }

  /// Fills blanks in [sentenceWithBlanks] (_____) with words from [answer] (e.g. "has/left").
  String _fillBlanks(String sentenceWithBlanks, String answer) {
    final parts = sentenceWithBlanks.split(_kBlank);
    final words = answer.split('/');
    if (parts.length != words.length + 1) return sentenceWithBlanks;
    final buffer = StringBuffer();
    for (var i = 0; i < words.length; i++) {
      buffer.write(parts[i]);
      buffer.write(words[i].trim());
    }
    buffer.write(parts.last);
    return buffer.toString();
  }

  Widget _buildNonConversationLayout(GrammarQuestion q, Map<String, String> strings) {
    final characterPath = _questionCharacterPath[_currentIndex] ??
        (_grammarCharacterPaths.isNotEmpty ? _grammarCharacterPaths.first : null);
    final bubbleText = _bubbleQuestionText(q, strings);
    final content = _contentText(q);

    // For banked_cloze only: when user answered wrong, show full correct sentence
    // (buttons only show the missing words, not the full sentence).
    final bool showBankedClozeCorrectSentence = q is GrammarBankedClozeQuestion &&
        _answerLocked &&
        _selectedIndex != null &&
        _currentOptions[_selectedIndex!] != _correctAnswer;

    // For yes/no: when user answered wrong, show correct answer (or corrected sentence)
    // so it's explicit; the button is green but a separate line makes it clear.
    final bool showYesNoCorrectAnswer = q is GrammarYesNoQuestion &&
        _answerLocked &&
        _selectedIndex != null &&
        _currentOptions[_selectedIndex!] != _correctAnswer;
    final String? yesNoCorrectText = showYesNoCorrectAnswer
        ? (q.correction ??
            '${strings['grammar_correct_answer'] ?? 'Correct answer:'} $_correctAnswer')
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Character + bubble (question only)
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildSpeechBubble(
              text: bubbleText,
              isActive: true,
              alignRight: false,
            ),
            const SizedBox(width: 12),
            _buildGrammarCharacterAvatar(characterPath),
          ],
        ),
        const SizedBox(height: 16),
        // Content field (sentence, sentenceWithBlanks, or context)
        if (content.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Text(
              content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        if (content.isNotEmpty) const SizedBox(height: 12),
        // Banked cloze: full correct sentence when user got it wrong
        if (showBankedClozeCorrectSentence) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _fillBlanks(q.sentenceWithBlanks, _correctAnswer),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade900,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
        // Yes/No: show correct answer or corrected sentence when user got it wrong
        if (yesNoCorrectText != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    yesNoCorrectText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade900,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGrammarCharacterAvatar(String? assetPath) {
    const double size = 64;
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: assetPath != null
            ? Image.asset(
                assetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallbackGrammarAvatar(size),
              )
            : _buildFallbackGrammarAvatar(size),
      ),
    );
  }

  Widget _buildFallbackGrammarAvatar(double size) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(
        Icons.school,
        size: size * 0.5,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildCharacterColumn({
    required String name,
    required String dialogueLine,
    required bool isActive,
    required CrossAxisAlignment alignment,
    required bool vocabularyCharacters,
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
        _buildCharacterAvatar(name, vocabularyCharacters: vocabularyCharacters),
      ],
    );
  }

  Widget _buildCharacterAvatar(String name, {required bool vocabularyCharacters}) {
    final base = vocabularyCharacters ? 'characters' : 'grammar-characters';
    final imagePath = 'assets/images/$base/$name.png';
    return SizedBox(
      width: 64,
      height: 64,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
            return CircleAvatar(
              radius: 32,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 24,
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
      child: text.contains(_kBlank)
          ? _buildBubbleTextWithBlank(text)
          : Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }

  Widget _buildBubbleTextWithBlank(String text) {
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
        );
      }
    }
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium,
        children: spans,
      ),
    );
  }

  Widget _buildAnswerButton(int optionIndex, bool soundFxOn) {
    final option = _currentOptions[optionIndex];
    final isCorrect = option == _correctAnswer;
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
            option,
            style: fgColor != null
                ? Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: fgColor,
                      fontWeight: FontWeight.w600,
                    )
                : Theme.of(context).textTheme.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

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
}
