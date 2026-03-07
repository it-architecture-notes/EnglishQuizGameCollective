diff --git a/app/assets/data/flow/grammar-quiz-flow.json b/app/assets/data/flow/grammar-quiz-flow.json
index 0c6b9ca..98c7182 100644
--- a/app/assets/data/flow/grammar-quiz-flow.json
+++ b/app/assets/data/flow/grammar-quiz-flow.json
@@ -1,4 +1,4 @@
 [
-  {"mainLevel": 1, "levelNumber": 1, "iconImageName": "verb", "title": "Simple Verbs"},
-  {"mainLevel": 1, "levelNumber": 2, "iconImageName": "noun", "title": "Nouns"}
+  {"mainLevel": 1, "levelNumber": 1, "iconImageName": "airport", "title": "Grammar at the Airport"},
+  {"mainLevel": 1, "levelNumber": 2, "iconImageName": "airport", "title": "More Airport Grammar"}
 ]
diff --git a/app/assets/images/grammar-characters/.gitkeep b/app/assets/images/grammar-characters/.gitkeep
new file mode 100644
index 0000000..e69de29
diff --git a/app/assets/quiz-data/grammar-quiz/airport-1.json b/app/assets/quiz-data/grammar-quiz/airport-1.json
new file mode 100644
index 0000000..4eb5989
--- /dev/null
+++ b/app/assets/quiz-data/grammar-quiz/airport-1.json
@@ -0,0 +1,50 @@
+{
+  "character1": "mike",
+  "character2": "sarah",
+  "questions": [
+    {
+      "questionType": "conversation",
+      "character1": "mike",
+      "character2": "sarah",
+      "line1": {
+        "en": "The flight _____ delayed by an hour."
+      },
+      "line2": {
+        "en": "I hope we can still make our connection."
+      },
+      "answer": "was",
+      "distractors": ["were", "is", "are"]
+    },
+    {
+      "questionType": "word_order",
+      "sentence": "She has already checked in her luggage.",
+      "distractors": [
+        "She already has checked in her luggage.",
+        "Already she has checked in her luggage.",
+        "Her luggage she has already checked in."
+      ]
+    },
+    {
+      "questionType": "banked_cloze",
+      "sentenceWithBlanks": "The plane _____ just _____ from the gate.",
+      "answer": "has/left",
+      "distractors": ["have/left", "had/leave", "has/leave"]
+    },
+    {
+      "questionType": "yes_no",
+      "sentence": "The passengers is waiting at the gate.",
+      "correctAnswer": "no"
+    },
+    {
+      "questionType": "which_correct",
+      "context": "Choosing the correct subject form.",
+      "options": [
+        "Me and my friend are travelling together.",
+        "My friend and I are travelling together.",
+        "My friend and me are travelling together.",
+        "I and my friend are travelling together."
+      ],
+      "correctIndex": 1
+    }
+  ]
+}
diff --git a/app/assets/quiz-data/grammar-quiz/airport-2.json b/app/assets/quiz-data/grammar-quiz/airport-2.json
new file mode 100644
index 0000000..d14c2d9
--- /dev/null
+++ b/app/assets/quiz-data/grammar-quiz/airport-2.json
@@ -0,0 +1,50 @@
+{
+  "character1": "mike",
+  "character2": "sarah",
+  "questions": [
+    {
+      "questionType": "conversation",
+      "character1": "mike",
+      "character2": "sarah",
+      "line1": {
+        "en": "How long _____ you been waiting?"
+      },
+      "line2": {
+        "en": "About forty minutes. The line is very slow."
+      },
+      "answer": "have",
+      "distractors": ["has", "had", "are"]
+    },
+    {
+      "questionType": "which_correct",
+      "context": "Correct use of who/whom.",
+      "options": [
+        "The man who we asked was very helpful.",
+        "The man whom we asked was very helpful.",
+        "The man which we asked was very helpful.",
+        "The man that we asked was very helpful."
+      ],
+      "correctIndex": 0
+    },
+    {
+      "questionType": "banked_cloze",
+      "sentenceWithBlanks": "They _____ _____ to board in ten minutes.",
+      "answer": "will/start",
+      "distractors": ["would/start", "will/starts", "will/starting"]
+    },
+    {
+      "questionType": "yes_no",
+      "sentence": "All passengers must present their boarding pass at the gate.",
+      "correctAnswer": "yes"
+    },
+    {
+      "questionType": "word_order",
+      "sentence": "We had never been to this airport before.",
+      "distractors": [
+        "We never had been to this airport before.",
+        "Never we had been to this airport before.",
+        "We had been never to this airport before."
+      ]
+    }
+  ]
+}
diff --git a/app/lib/models/grammar_quiz.dart b/app/lib/models/grammar_quiz.dart
new file mode 100644
index 0000000..891535e
--- /dev/null
+++ b/app/lib/models/grammar_quiz.dart
@@ -0,0 +1,177 @@
+// Grammar quiz question types and level model.
+// Question types: conversation (vocab-like), word_order, banked_cloze,
+// yes_no, which_correct. Discriminated by [GrammarQuestion.questionType].
+
+/// Base type for a single grammar question.
+abstract class GrammarQuestion {
+  const GrammarQuestion({required this.questionType});
+  final String questionType;
+
+  static GrammarQuestion fromJson(Map<String, dynamic> json) {
+    final type = json['questionType'] as String? ?? '';
+    switch (type) {
+      case 'conversation':
+        return GrammarConversationQuestion.fromJson(json);
+      case 'word_order':
+        return GrammarWordOrderQuestion.fromJson(json);
+      case 'banked_cloze':
+        return GrammarBankedClozeQuestion.fromJson(json);
+      case 'yes_no':
+        return GrammarYesNoQuestion.fromJson(json);
+      case 'which_correct':
+        return GrammarWhichCorrectQuestion.fromJson(json);
+      default:
+        throw ArgumentError('Unknown grammar questionType: $type');
+    }
+  }
+}
+
+/// Two characters, one blank (tense/auxiliary); same shape as vocabulary.
+class GrammarConversationQuestion extends GrammarQuestion {
+  const GrammarConversationQuestion({
+    required this.character1,
+    required this.character2,
+    required this.line1,
+    required this.line2,
+    required this.answer,
+    required this.distractors,
+  }) : super(questionType: 'conversation');
+
+  final String character1;
+  final String character2;
+  final Map<String, String> line1;
+  final Map<String, String> line2;
+  final String answer;
+  final List<String> distractors;
+
+  bool get blankInLine1 => line1['en']?.contains('_____') ?? false;
+
+  static GrammarConversationQuestion fromJson(Map<String, dynamic> json) {
+    Map<String, String> parseLineMap(dynamic value) {
+      if (value is Map) {
+        return value.map((k, v) => MapEntry(k.toString(), v.toString()));
+      }
+      return {};
+    }
+    return GrammarConversationQuestion(
+      character1: json['character1'] as String? ?? '',
+      character2: json['character2'] as String? ?? '',
+      line1: parseLineMap(json['line1']),
+      line2: parseLineMap(json['line2']),
+      answer: json['answer'] as String? ?? '',
+      distractors: (json['distractors'] as List<dynamic>? ?? [])
+          .map((e) => e.toString())
+          .toList(),
+    );
+  }
+}
+
+/// One correct sentence among 4 word-order variants.
+class GrammarWordOrderQuestion extends GrammarQuestion {
+  const GrammarWordOrderQuestion({
+    required this.sentence,
+    required this.distractors,
+  }) : super(questionType: 'word_order');
+
+  final String sentence;
+  final List<String> distractors;
+
+  static GrammarWordOrderQuestion fromJson(Map<String, dynamic> json) {
+    return GrammarWordOrderQuestion(
+      sentence: json['sentence'] as String? ?? '',
+      distractors: (json['distractors'] as List<dynamic>? ?? [])
+          .map((e) => e.toString())
+          .toList(),
+    );
+  }
+}
+
+/// One sentence with multiple blanks; one option fills all (e.g. "was/have/asked").
+class GrammarBankedClozeQuestion extends GrammarQuestion {
+  const GrammarBankedClozeQuestion({
+    required this.sentenceWithBlanks,
+    required this.answer,
+    required this.distractors,
+  }) : super(questionType: 'banked_cloze');
+
+  final String sentenceWithBlanks;
+  final String answer;
+  final List<String> distractors;
+
+  static GrammarBankedClozeQuestion fromJson(Map<String, dynamic> json) {
+    return GrammarBankedClozeQuestion(
+      sentenceWithBlanks: json['sentenceWithBlanks'] as String? ?? '',
+      answer: json['answer'] as String? ?? '',
+      distractors: (json['distractors'] as List<dynamic>? ?? [])
+          .map((e) => e.toString())
+          .toList(),
+    );
+  }
+}
+
+/// Is the sentence grammatically correct? Two options: Yes / No.
+class GrammarYesNoQuestion extends GrammarQuestion {
+  const GrammarYesNoQuestion({
+    required this.sentence,
+    required this.correctAnswer,
+  }) : super(questionType: 'yes_no');
+
+  final String sentence;
+  /// "yes" or "no"
+  final String correctAnswer;
+
+  static GrammarYesNoQuestion fromJson(Map<String, dynamic> json) {
+    return GrammarYesNoQuestion(
+      sentence: json['sentence'] as String? ?? '',
+      correctAnswer: json['correctAnswer'] as String? ?? 'no',
+    );
+  }
+}
+
+/// One of 4 sentences is correct for context.
+class GrammarWhichCorrectQuestion extends GrammarQuestion {
+  const GrammarWhichCorrectQuestion({
+    this.context,
+    required this.options,
+    required this.correctIndex,
+  }) : super(questionType: 'which_correct');
+
+  final String? context;
+  final List<String> options;
+  final int correctIndex;
+
+  static GrammarWhichCorrectQuestion fromJson(Map<String, dynamic> json) {
+    return GrammarWhichCorrectQuestion(
+      context: json['context'] as String?,
+      options: (json['options'] as List<dynamic>? ?? [])
+          .map((e) => e.toString())
+          .toList(),
+      correctIndex: (json['correctIndex'] as num?)?.toInt() ?? 0,
+    );
+  }
+}
+
+/// Full content of one grammar level file.
+class GrammarLevel {
+  const GrammarLevel({
+    this.character1 = '',
+    this.character2 = '',
+    required this.questions,
+  });
+
+  /// Used for first (conversation) question only.
+  final String character1;
+  final String character2;
+  final List<GrammarQuestion> questions;
+
+  static GrammarLevel fromJson(Map<String, dynamic> json) {
+    final rawQuestions = json['questions'] as List<dynamic>? ?? [];
+    return GrammarLevel(
+      character1: json['character1'] as String? ?? '',
+      character2: json['character2'] as String? ?? '',
+      questions: rawQuestions
+          .map((e) => GrammarQuestion.fromJson(e as Map<String, dynamic>))
+          .toList(),
+    );
+  }
+}
diff --git a/app/lib/screens/grammar_quiz_screen.dart b/app/lib/screens/grammar_quiz_screen.dart
new file mode 100644
index 0000000..d80da3a
--- /dev/null
+++ b/app/lib/screens/grammar_quiz_screen.dart
@@ -0,0 +1,741 @@
+import 'dart:math';
+
+import 'package:flutter/material.dart';
+import 'package:flutter_riverpod/flutter_riverpod.dart';
+
+import '../models/grammar_quiz.dart';
+import '../models/level_completion_result.dart';
+import '../models/quiz_flow.dart';
+import '../providers/localization_provider.dart';
+import '../providers/settings_provider.dart';
+import '../services/achievement_service.dart';
+import '../services/audio_service.dart' as audio;
+import '../services/game_config_loader.dart';
+import '../services/grammar_quiz_loader.dart';
+import '../services/profile_service.dart';
+import '../services/quiz_progress_service.dart';
+
+const double _kMinTouchTarget = 48.0;
+const String _kBlank = '_____';
+
+/// Character image names for grammar single-speaker questions (assets/images/grammar-characters/).
+const List<String> _kGrammarCharacterNames = ['host', 'guide', 'narrator'];
+
+enum _Phase { loading, playing, end }
+
+class GrammarQuizScreen extends ConsumerStatefulWidget {
+  const GrammarQuizScreen({
+    super.key,
+    required this.subLevel,
+    required this.quizType,
+    required this.ordinalLevelIndex,
+  });
+
+  final SubLevel subLevel;
+  final String quizType;
+  final int ordinalLevelIndex;
+
+  @override
+  ConsumerState<GrammarQuizScreen> createState() => _GrammarQuizScreenState();
+}
+
+class _GrammarQuizScreenState extends ConsumerState<GrammarQuizScreen> {
+  _Phase _phase = _Phase.loading;
+  String? _loadError;
+
+  GrammarLevel? _level;
+  GameConfig _config = const GameConfig();
+
+  List<GrammarQuestion> get _questions => _level?.questions ?? [];
+
+  int _currentIndex = 0;
+  int _correctCount = 0;
+  bool _answerLocked = false;
+  bool _showNext = false;
+  int? _selectedIndex;
+  List<String> _currentOptions = [];
+  String _correctAnswer = '';
+
+  final Random _random = Random();
+  DateTime? _quizStartTime;
+
+  @override
+  void initState() {
+    super.initState();
+    _loadLevel();
+  }
+
+  @override
+  void dispose() {
+    audio.stopQuizMusic();
+    super.dispose();
+  }
+
+  Future<void> _loadLevel() async {
+    try {
+      final config = await GameConfig.load();
+      final level = await loadGrammarLevel(
+        widget.subLevel.iconImageName,
+        widget.subLevel.levelNumber,
+      );
+
+      if (mounted) {
+        final (options, correct) = _buildOptionsFor(level.questions[0], level);
+        setState(() {
+          _config = config;
+          _level = level;
+          _phase = _Phase.playing;
+          _quizStartTime = DateTime.now();
+          _currentOptions = options;
+          _correctAnswer = correct;
+        });
+        final musicOn = ref.read(settingsProvider).valueOrNull?.musicOn ?? true;
+        audio.startQuizMusic(musicOn: musicOn);
+      }
+    } catch (e, st) {
+      debugPrint('GrammarQuizScreen _loadLevel: $e\n$st');
+      if (mounted) {
+        setState(() => _loadError = e.toString());
+      }
+    }
+  }
+
+  (List<String>, String) _buildOptionsFor(GrammarQuestion q, GrammarLevel level) {
+    return switch (q) {
+      GrammarConversationQuestion() => (
+          [q.answer, ...q.distractors]..shuffle(_random),
+          q.answer,
+        ),
+      GrammarWordOrderQuestion() => (
+          [q.sentence, ...q.distractors]..shuffle(_random),
+          q.sentence,
+        ),
+      GrammarBankedClozeQuestion() => (
+          [q.answer, ...q.distractors]..shuffle(_random),
+          q.answer,
+        ),
+      GrammarYesNoQuestion() => (
+          ['Yes', 'No'],
+          q.correctAnswer.toLowerCase() == 'yes' ? 'Yes' : 'No',
+        ),
+      GrammarWhichCorrectQuestion() => (
+          List<String>.from(q.options)..shuffle(_random),
+          q.options[q.correctIndex],
+        ),
+      _ => throw StateError('Unsupported grammar question type: ${q.questionType}'),
+    };
+  }
+
+  void _onAnswerTap(int optionIndex) {
+    if (_answerLocked) return;
+    final selected = _currentOptions[optionIndex];
+    final isCorrect = selected == _correctAnswer;
+    final soundFxOn = ref.read(settingsProvider).valueOrNull?.soundFxOn ?? true;
+    if (isCorrect) {
+      audio.playCorrect(soundFxOn: soundFxOn);
+    } else {
+      audio.playWrong(soundFxOn: soundFxOn);
+    }
+    AchievementService.instance.recordAnswer(isCorrect);
+    setState(() {
+      _answerLocked = true;
+      _selectedIndex = optionIndex;
+      if (isCorrect) {
+        _correctCount++;
+        _showNext = false;
+        Future.delayed(
+          Duration(milliseconds: (_config.autoAdvanceDelaySeconds * 1000).round()),
+          () {
+            if (!mounted) return;
+            _goNext();
+          },
+        );
+      } else {
+        _showNext = true;
+      }
+    });
+  }
+
+  void _goNext() {
+    if (_currentIndex + 1 >= _questions.length) {
+      setState(() => _phase = _Phase.end);
+      return;
+    }
+    final nextQ = _questions[_currentIndex + 1];
+    final (options, correct) = _buildOptionsFor(nextQ, _level!);
+    setState(() {
+      _currentIndex++;
+      _answerLocked = false;
+      _showNext = false;
+      _selectedIndex = null;
+      _currentOptions = options;
+      _correctAnswer = correct;
+    });
+  }
+
+  int _stars() {
+    if (_questions.isEmpty) return 0;
+    final rate = (_correctCount / _questions.length) * 100;
+    if (rate >= 85) return 3;
+    if (rate >= 70) return 2;
+    if (rate >= 60) return 1;
+    return 0;
+  }
+
+  int _diamondsEarned() => _correctCount;
+
+  Future<void> _onEndOk() async {
+    final stars = _stars();
+    if (_quizStartTime != null) {
+      final duration = DateTime.now().difference(_quizStartTime!).inSeconds;
+      await AchievementService.instance.recordQuizCompleted(duration);
+    }
+    if (stars >= 1) {
+      await QuizProgressService.instance.recordLevelCompletion(
+        quizType: widget.quizType,
+        levelNumber: widget.ordinalLevelIndex,
+        stars: stars,
+        diamondsEarned: _diamondsEarned(),
+      );
+    }
+    if (stars >= 1) {
+      await ProfileService.instance.registerQuizCompletion(
+        quizType: widget.quizType,
+        questionCount: _questions.length,
+      );
+    }
+    if (mounted) {
+      Navigator.of(context).pop(LevelCompletionResult(
+        ordinalLevelIndex: widget.ordinalLevelIndex,
+        completed: stars >= 1,
+      ));
+    }
+  }
+
+  String _questionLabel(Map<String, String> strings, int current, int total) {
+    final template = strings['question_x_of_y'] ?? 'Question %s / %s';
+    return template.replaceFirst('%s', '$current').replaceFirst('%s', '$total');
+  }
+
+  String _capitalize(String s) {
+    if (s.isEmpty) return s;
+    return s[0].toUpperCase() + s.substring(1).toLowerCase();
+  }
+
+  @override
+  Widget build(BuildContext context) {
+    ref.listen(settingsProvider, (prev, next) {
+      if (next.valueOrNull?.musicOn == true &&
+          _phase == _Phase.playing &&
+          _level != null) {
+        audio.startQuizMusic(musicOn: true);
+      }
+    });
+    final soundFxOn = ref.read(settingsProvider).valueOrNull?.soundFxOn ?? true;
+    final strings = ref.watch(currentLocalizedStringsProvider).valueOrNull ?? {};
+    return Scaffold(
+      appBar: AppBar(
+        title: Text(widget.subLevel.title),
+        leading: IconButton(
+          icon: const Icon(Icons.arrow_back),
+          onPressed: () {
+            audio.playClick(soundFxOn: soundFxOn);
+            Navigator.of(context).pop(LevelCompletionResult(
+              ordinalLevelIndex: widget.ordinalLevelIndex,
+              completed: false,
+            ));
+          },
+        ),
+      ),
+      body: SafeArea(child: _buildBody(soundFxOn, strings)),
+    );
+  }
+
+  Widget _buildBody(bool soundFxOn, Map<String, String> strings) {
+    if (_loadError != null) return _buildError(soundFxOn, strings);
+    return switch (_phase) {
+      _Phase.loading => const Center(child: CircularProgressIndicator()),
+      _Phase.playing => _buildPlaying(soundFxOn, strings),
+      _Phase.end => _buildEnd(soundFxOn, strings),
+    };
+  }
+
+  Widget _buildError(bool soundFxOn, Map<String, String> strings) {
+    return Padding(
+      padding: const EdgeInsets.all(24),
+      child: Column(
+        mainAxisAlignment: MainAxisAlignment.center,
+        children: [
+          Text(
+            _loadError!,
+            textAlign: TextAlign.center,
+            style: TextStyle(color: Theme.of(context).colorScheme.error),
+          ),
+          const SizedBox(height: 24),
+          FilledButton(
+            onPressed: () {
+              audio.playClick(soundFxOn: soundFxOn);
+              Navigator.of(context).pop(LevelCompletionResult(
+                ordinalLevelIndex: widget.ordinalLevelIndex,
+                completed: false,
+              ));
+            },
+            child: Text(strings['back_to_levels'] ?? 'Back to Levels'),
+          ),
+        ],
+      ),
+    );
+  }
+
+  Widget _buildPlaying(bool soundFxOn, Map<String, String> strings) {
+    final q = _questions[_currentIndex];
+    final total = _questions.length;
+    final isLast = _currentIndex + 1 >= total;
+    final isConversation = q is GrammarConversationQuestion;
+    final optionCount = q is GrammarYesNoQuestion ? 2 : 4;
+
+    return Column(
+      children: [
+        Padding(
+          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
+          child: Text(
+            _questionLabel(strings, _currentIndex + 1, total),
+            style: Theme.of(context).textTheme.labelLarge?.copyWith(
+                  color: Theme.of(context).colorScheme.primary,
+                  fontWeight: FontWeight.w600,
+                ),
+          ),
+        ),
+        Expanded(
+          child: Padding(
+            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
+            child: isConversation
+                ? _buildConversationLayout(q)
+                : _buildNonConversationLayout(q),
+          ),
+        ),
+        Padding(
+          padding: const EdgeInsets.symmetric(horizontal: 16),
+          child: Column(
+            children: List.generate(
+              optionCount,
+              (i) => _buildAnswerButton(i, soundFxOn),
+            ),
+          ),
+        ),
+        Padding(
+          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
+          child: SizedBox(
+            width: double.infinity,
+            height: _kMinTouchTarget + 8,
+            child: _showNext
+                ? FilledButton(
+                    onPressed: () {
+                      audio.playClick(soundFxOn: soundFxOn);
+                      _goNext();
+                    },
+                    child: Text(
+                      isLast
+                          ? (strings['finish'] ?? 'Finish')
+                          : (strings['next'] ?? 'Next'),
+                    ),
+                  )
+                : const SizedBox.shrink(),
+          ),
+        ),
+      ],
+    );
+  }
+
+  Widget _buildConversationLayout(GrammarConversationQuestion q) {
+    final char1 = q.character1.isNotEmpty ? q.character1 : _level!.character1;
+    final char2 = q.character2.isNotEmpty ? q.character2 : _level!.character2;
+    final line1Text = q.line1['en'] ?? '';
+    final line2Text = q.line2['en'] ?? '';
+
+    return Row(
+      crossAxisAlignment: CrossAxisAlignment.start,
+      children: [
+        Expanded(
+          child: _buildCharacterColumn(
+            name: char1,
+            dialogueLine: line1Text,
+            isActive: q.blankInLine1,
+            alignment: CrossAxisAlignment.start,
+            vocabularyCharacters: true,
+          ),
+        ),
+        const SizedBox(width: 8),
+        Expanded(
+          child: _buildCharacterColumn(
+            name: char2,
+            dialogueLine: line2Text,
+            isActive: !q.blankInLine1,
+            alignment: CrossAxisAlignment.end,
+            vocabularyCharacters: true,
+          ),
+        ),
+      ],
+    );
+  }
+
+  /// Short question-only text for the bubble (single-character layout).
+  String _bubbleQuestionText(GrammarQuestion q) {
+    return switch (q) {
+      GrammarWordOrderQuestion() => 'Which sentence is correct?',
+      GrammarBankedClozeQuestion() => 'Fill in the blanks:',
+      GrammarYesNoQuestion() => 'Is this sentence correct?',
+      GrammarWhichCorrectQuestion() => 'Which is correct?',
+      _ => '',
+    };
+  }
+
+  /// Main content text for the field between character+bubble and answer buttons.
+  String _contentText(GrammarQuestion q) {
+    return switch (q) {
+      GrammarWordOrderQuestion() => '', // options are on the buttons
+      GrammarBankedClozeQuestion() => q.sentenceWithBlanks,
+      GrammarYesNoQuestion() => q.sentence,
+      GrammarWhichCorrectQuestion() => q.context ?? '',
+      _ => '',
+    };
+  }
+
+  Widget _buildNonConversationLayout(GrammarQuestion q) {
+    final characterName = _kGrammarCharacterNames[
+        _random.nextInt(_kGrammarCharacterNames.length)];
+    final bubbleText = _bubbleQuestionText(q);
+    final content = _contentText(q);
+    // For yes/no: only show correct-answer field when the sentence is wrong (correct is No).
+    // When the sentence is correct (correct is Yes) and user said No, no need to show extra text.
+    final wrongAndShowCorrect = _answerLocked &&
+        _selectedIndex != null &&
+        _currentOptions[_selectedIndex!] != _correctAnswer;
+    final showCorrectAnswer = wrongAndShowCorrect &&
+        !(q is GrammarYesNoQuestion && _correctAnswer == 'Yes');
+
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        // Character + bubble (question only)
+        Row(
+          crossAxisAlignment: CrossAxisAlignment.end,
+          children: [
+            _buildSpeechBubble(
+              text: bubbleText,
+              isActive: true,
+              alignRight: false,
+            ),
+            const SizedBox(width: 12),
+            _buildCharacterAvatar(characterName, vocabularyCharacters: false),
+          ],
+        ),
+        const SizedBox(height: 16),
+        // Content field (sentence, sentenceWithBlanks, or context)
+        if (content.isNotEmpty)
+          Container(
+            width: double.infinity,
+            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
+            decoration: BoxDecoration(
+              color: Theme.of(context).colorScheme.surfaceContainerHighest,
+              borderRadius: BorderRadius.circular(8),
+              border: Border.all(
+                color: Theme.of(context).colorScheme.outlineVariant,
+              ),
+            ),
+            child: Text(
+              content,
+              style: Theme.of(context).textTheme.bodyLarge,
+            ),
+          ),
+        if (content.isNotEmpty) const SizedBox(height: 12),
+        // Correct answer field (when user answered wrong)
+        if (showCorrectAnswer) ...[
+          Container(
+            width: double.infinity,
+            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
+            decoration: BoxDecoration(
+              color: Colors.green.shade50,
+              borderRadius: BorderRadius.circular(8),
+              border: Border.all(color: Colors.green.shade200),
+            ),
+            child: Row(
+              children: [
+                Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
+                const SizedBox(width: 8),
+                Expanded(
+                  child: Text(
+                    'Correct answer: $_correctAnswer',
+                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
+                          fontWeight: FontWeight.w600,
+                          color: Colors.green.shade900,
+                        ),
+                  ),
+                ),
+              ],
+            ),
+          ),
+          const SizedBox(height: 12),
+        ],
+      ],
+    );
+  }
+
+  Widget _buildCharacterColumn({
+    required String name,
+    required String dialogueLine,
+    required bool isActive,
+    required CrossAxisAlignment alignment,
+    required bool vocabularyCharacters,
+  }) {
+    return Column(
+      crossAxisAlignment: alignment,
+      children: [
+        _buildSpeechBubble(
+          text: dialogueLine,
+          isActive: isActive,
+          alignRight: alignment == CrossAxisAlignment.end,
+        ),
+        const SizedBox(height: 8),
+        Text(
+          _capitalize(name),
+          style: Theme.of(context).textTheme.labelMedium?.copyWith(
+                fontWeight: FontWeight.w600,
+              ),
+          overflow: TextOverflow.ellipsis,
+        ),
+        const SizedBox(height: 4),
+        _buildCharacterAvatar(name, vocabularyCharacters: vocabularyCharacters),
+      ],
+    );
+  }
+
+  Widget _buildCharacterAvatar(String name, {required bool vocabularyCharacters}) {
+    final base = vocabularyCharacters ? 'characters' : 'grammar-characters';
+    final imagePath = 'assets/images/$base/$name.png';
+    return SizedBox(
+      width: 64,
+      height: 64,
+      child: ClipRRect(
+        borderRadius: BorderRadius.circular(32),
+        child: Image.asset(
+          imagePath,
+          fit: BoxFit.cover,
+          errorBuilder: (_, __, ___) {
+            final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
+            return CircleAvatar(
+              radius: 32,
+              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
+              child: Text(
+                initial,
+                style: TextStyle(
+                  fontSize: 24,
+                  fontWeight: FontWeight.w700,
+                  color: Theme.of(context).colorScheme.onPrimaryContainer,
+                ),
+              ),
+            );
+          },
+        ),
+      ),
+    );
+  }
+
+  Widget _buildSpeechBubble({
+    required String text,
+    required bool isActive,
+    required bool alignRight,
+  }) {
+    final colorScheme = Theme.of(context).colorScheme;
+    final bgColor = isActive
+        ? colorScheme.primaryContainer
+        : colorScheme.surfaceContainerHighest;
+    final borderColor =
+        isActive ? colorScheme.primary : colorScheme.outlineVariant;
+
+    return Container(
+      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
+      decoration: BoxDecoration(
+        color: bgColor,
+        borderRadius: BorderRadius.only(
+          topLeft: const Radius.circular(12),
+          topRight: const Radius.circular(12),
+          bottomLeft: Radius.circular(alignRight ? 12 : 4),
+          bottomRight: Radius.circular(alignRight ? 4 : 12),
+        ),
+        border: Border.all(color: borderColor, width: 1.5),
+      ),
+      child: text.contains(_kBlank)
+          ? _buildBubbleTextWithBlank(text)
+          : Text(text, style: Theme.of(context).textTheme.bodyMedium),
+    );
+  }
+
+  Widget _buildBubbleTextWithBlank(String text) {
+    final parts = text.split(_kBlank);
+    final spans = <InlineSpan>[];
+    for (var i = 0; i < parts.length; i++) {
+      if (parts[i].isNotEmpty) {
+        spans.add(TextSpan(text: parts[i]));
+      }
+      if (i < parts.length - 1) {
+        spans.add(
+          WidgetSpan(
+            alignment: PlaceholderAlignment.middle,
+            child: Container(
+              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
+              decoration: BoxDecoration(
+                color: Theme.of(context)
+                    .colorScheme
+                    .primary
+                    .withValues(alpha: 0.15),
+                borderRadius: BorderRadius.circular(4),
+                border: Border.all(
+                  color: Theme.of(context).colorScheme.primary,
+                  width: 1,
+                ),
+              ),
+              child: Text(
+                ' ____ ',
+                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
+                      color: Theme.of(context).colorScheme.primary,
+                      fontWeight: FontWeight.w700,
+                    ),
+              ),
+            ),
+          ),
+        );
+      }
+    }
+    return RichText(
+      text: TextSpan(
+        style: Theme.of(context).textTheme.bodyMedium,
+        children: spans,
+      ),
+    );
+  }
+
+  Widget _buildAnswerButton(int optionIndex, bool soundFxOn) {
+    final option = _currentOptions[optionIndex];
+    final isCorrect = option == _correctAnswer;
+    final isSelected = _selectedIndex == optionIndex;
+
+    Color? bgColor;
+    Color? fgColor;
+    if (_answerLocked) {
+      if (isCorrect) {
+        bgColor = Colors.green.shade600;
+        fgColor = Colors.white;
+      } else if (isSelected) {
+        bgColor = Colors.red.shade600;
+        fgColor = Colors.white;
+      }
+    }
+
+    final buttonStyle = bgColor != null
+        ? ElevatedButton.styleFrom(
+            backgroundColor: bgColor,
+            foregroundColor: fgColor,
+            surfaceTintColor: Colors.transparent,
+            disabledBackgroundColor: bgColor,
+            disabledForegroundColor: fgColor,
+            minimumSize: const Size(_kMinTouchTarget, _kMinTouchTarget),
+          )
+        : ElevatedButton.styleFrom(
+            minimumSize: const Size(_kMinTouchTarget, _kMinTouchTarget),
+            disabledBackgroundColor: Colors.grey.shade300,
+            disabledForegroundColor: Colors.grey.shade800,
+            surfaceTintColor: Colors.transparent,
+          );
+
+    return Padding(
+      padding: const EdgeInsets.only(bottom: 10),
+      child: SizedBox(
+        width: double.infinity,
+        height: _kMinTouchTarget + 8,
+        child: ElevatedButton(
+          onPressed: _answerLocked
+              ? null
+              : () {
+                  audio.playClick(soundFxOn: soundFxOn);
+                  _onAnswerTap(optionIndex);
+                },
+          style: buttonStyle,
+          child: Text(
+            option,
+            style: fgColor != null
+                ? Theme.of(context).textTheme.titleMedium?.copyWith(
+                      color: fgColor,
+                      fontWeight: FontWeight.w600,
+                    )
+                : Theme.of(context).textTheme.titleMedium,
+            maxLines: 2,
+            overflow: TextOverflow.ellipsis,
+            textAlign: TextAlign.center,
+          ),
+        ),
+      ),
+    );
+  }
+
+  Widget _buildEnd(bool soundFxOn, Map<String, String> strings) {
+    final stars = _stars();
+    final diamonds = _diamondsEarned();
+
+    return Center(
+      child: Padding(
+        padding: const EdgeInsets.all(24),
+        child: Column(
+          mainAxisSize: MainAxisSize.min,
+          children: [
+            Text(
+              strings['level_complete'] ?? 'Level complete!',
+              style: Theme.of(context).textTheme.headlineSmall,
+            ),
+            const SizedBox(height: 24),
+            Row(
+              mainAxisAlignment: MainAxisAlignment.center,
+              children: List.generate(
+                3,
+                (i) => Icon(
+                  i < stars ? Icons.star : Icons.star_border,
+                  size: 48,
+                  color: Colors.amber,
+                ),
+              ),
+            ),
+            const SizedBox(height: 16),
+            Row(
+              mainAxisAlignment: MainAxisAlignment.center,
+              children: [
+                Icon(Icons.diamond, color: Colors.blue.shade700, size: 28),
+                const SizedBox(width: 8),
+                Text(
+                  '+$diamonds',
+                  style: Theme.of(context).textTheme.titleLarge,
+                ),
+              ],
+            ),
+            const SizedBox(height: 16),
+            Text(
+              '$_correctCount / ${_questions.length} correct',
+              style: Theme.of(context).textTheme.bodyLarge,
+            ),
+            const SizedBox(height: 24),
+            SizedBox(
+              width: double.infinity,
+              height: _kMinTouchTarget + 8,
+              child: FilledButton(
+                onPressed: () {
+                  audio.playClick(soundFxOn: soundFxOn);
+                  _onEndOk();
+                },
+                child: Text(strings['ok'] ?? 'OK'),
+              ),
+            ),
+          ],
+        ),
+      ),
+    );
+  }
+}
diff --git a/app/lib/screens/levels_screen.dart b/app/lib/screens/levels_screen.dart
index f55cf76..e674f40 100644
--- a/app/lib/screens/levels_screen.dart
+++ b/app/lib/screens/levels_screen.dart
@@ -11,6 +11,7 @@ import '../providers/settings_provider.dart';
 import '../services/audio_service.dart' as audio;
 import '../services/quiz_flow_loader.dart';
 import '../services/quiz_progress_service.dart';
+import 'grammar_quiz_screen.dart';
 import 'image_quiz_screen.dart';
 import 'placeholders/quiz_placeholder_screen.dart';
 import 'transitions/custom_page_routes.dart';
@@ -553,11 +554,17 @@ class _LevelsScreenState extends ConsumerState<LevelsScreen> {
                   subLevel: sub,
                   ordinalLevelIndex: subLevelItem.ordinalLevelIndex,
                 )
-              : QuizPlaceholderScreen(
-                  quizType: widget.quizType,
-                  subLevel: sub,
-                  ordinalLevelIndex: subLevelItem.ordinalLevelIndex,
-                ),
+              : widget.quizType == 'grammar'
+                  ? GrammarQuizScreen(
+                      quizType: widget.quizType,
+                      subLevel: sub,
+                      ordinalLevelIndex: subLevelItem.ordinalLevelIndex,
+                    )
+                  : QuizPlaceholderScreen(
+                      quizType: widget.quizType,
+                      subLevel: sub,
+                      ordinalLevelIndex: subLevelItem.ordinalLevelIndex,
+                    ),
     );
 
     final result =
diff --git a/app/lib/services/grammar_quiz_loader.dart b/app/lib/services/grammar_quiz_loader.dart
new file mode 100644
index 0000000..bdf66db
--- /dev/null
+++ b/app/lib/services/grammar_quiz_loader.dart
@@ -0,0 +1,55 @@
+import 'dart:convert';
+
+import 'package:flutter/services.dart';
+
+import '../models/grammar_quiz.dart';
+
+const int kMinGrammarQuestions = 4;
+
+/// Builds the asset path for a grammar level JSON file.
+///
+/// [iconImageName] comes from [SubLevel.iconImageName] (e.g. "airport").
+/// [levelNumber] comes from [SubLevel.levelNumber] (e.g. 1).
+/// Result: "assets/quiz-data/grammar-quiz/airport-1.json"
+String grammarDataPath(String iconImageName, int levelNumber) {
+  return 'assets/quiz-data/grammar-quiz/$iconImageName-$levelNumber.json';
+}
+
+/// Loads and parses a [GrammarLevel] for the given level.
+///
+/// Throws an [Exception] if the file is missing, cannot be parsed, or contains
+/// fewer than [kMinGrammarQuestions] questions.
+Future<GrammarLevel> loadGrammarLevel(
+  String iconImageName,
+  int levelNumber,
+) async {
+  final path = grammarDataPath(iconImageName, levelNumber);
+  final String jsonString;
+  try {
+    jsonString = await rootBundle.loadString(path);
+  } catch (e) {
+    throw Exception('Grammar data not found: $path');
+  }
+
+  final dynamic decoded;
+  try {
+    decoded = jsonDecode(jsonString);
+  } catch (e) {
+    throw Exception('Invalid JSON in $path: $e');
+  }
+
+  if (decoded is! Map<String, dynamic>) {
+    throw Exception('Expected a JSON object in $path');
+  }
+
+  final level = GrammarLevel.fromJson(decoded);
+
+  if (level.questions.length < kMinGrammarQuestions) {
+    throw Exception(
+      'Level needs at least $kMinGrammarQuestions questions '
+      '(found ${level.questions.length}) in $path',
+    );
+  }
+
+  return level;
+}
diff --git a/app/pubspec.yaml b/app/pubspec.yaml
index 39f4fa5..8a7b2ba 100644
--- a/app/pubspec.yaml
+++ b/app/pubspec.yaml
@@ -28,6 +28,7 @@ flutter:
     - assets/images/backgrounds/tablet_1610/
     - assets/images/buttons/
     - assets/images/characters/
+    - assets/images/grammar-characters/
     - assets/images/avatars/
     - assets/images/level-icons/
     - assets/images/achievements/
