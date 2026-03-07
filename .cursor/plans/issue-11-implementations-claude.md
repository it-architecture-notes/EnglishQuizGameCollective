diff --git a/app/assets/data/config/localization.json b/app/assets/data/config/localization.json
index 263f8f7..247519b 100644
--- a/app/assets/data/config/localization.json
+++ b/app/assets/data/config/localization.json
@@ -48,7 +48,14 @@
     "quiz_view_conversation": "View Full Conversation",
     "quiz_ok": "OK",
     "quiz_coming_soon": "Coming soon",
-    "common_cancel": "Cancel"
+    "common_cancel": "Cancel",
+
+    "grammar_find_correct_order": "Find the correctly ordered sentence.",
+    "grammar_is_correct": "Is this grammatically correct?",
+    "grammar_which_correct": "Which sentence is grammatically correct?",
+    "grammar_fill_blanks": "Fill in the blanks.",
+    "grammar_yes": "Yes",
+    "grammar_no": "No"
   },
   "es": {
     "home_image_quiz": "Quiz de Imágenes",
@@ -99,7 +106,14 @@
     "quiz_view_conversation": "Ver Conversación Completa",
     "quiz_ok": "OK",
     "quiz_coming_soon": "Próximamente",
-    "common_cancel": "Cancelar"
+    "common_cancel": "Cancelar",
+
+    "grammar_find_correct_order": "Encuentra la oración correctamente ordenada.",
+    "grammar_is_correct": "¿Es gramaticalmente correcta?",
+    "grammar_which_correct": "¿Qué oración es gramaticalmente correcta?",
+    "grammar_fill_blanks": "Completa los espacios en blanco.",
+    "grammar_yes": "Sí",
+    "grammar_no": "No"
   },
   "fr": {
     "home_image_quiz": "Quiz d'Images",
@@ -150,7 +164,14 @@
     "quiz_view_conversation": "Voir la Conversation Complète",
     "quiz_ok": "OK",
     "quiz_coming_soon": "Bientôt disponible",
-    "common_cancel": "Annuler"
+    "common_cancel": "Annuler",
+
+    "grammar_find_correct_order": "Trouvez la phrase correctement ordonnée.",
+    "grammar_is_correct": "Cette phrase est-elle grammaticalement correcte ?",
+    "grammar_which_correct": "Quelle phrase est grammaticalement correcte ?",
+    "grammar_fill_blanks": "Remplissez les blancs.",
+    "grammar_yes": "Oui",
+    "grammar_no": "Non"
   },
   "tr": {
     "home_image_quiz": "Resim Testi",
@@ -201,6 +222,13 @@
     "quiz_view_conversation": "Tam Konuşmayı Gör",
     "quiz_ok": "Tamam",
     "quiz_coming_soon": "Yakında",
-    "common_cancel": "İptal"
+    "common_cancel": "İptal",
+
+    "grammar_find_correct_order": "Doğru sıralanmış cümleyi bulun.",
+    "grammar_is_correct": "Bu cümle dilbilgisi açısından doğru mu?",
+    "grammar_which_correct": "Hangi cümle dilbilgisi açısından doğru?",
+    "grammar_fill_blanks": "Boşlukları doldurun.",
+    "grammar_yes": "Evet",
+    "grammar_no": "Hayır"
   }
 }
diff --git a/app/assets/images/grammar-characters/coach.png b/app/assets/images/grammar-characters/coach.png
new file mode 100644
index 0000000..837a4ea
Binary files /dev/null and b/app/assets/images/grammar-characters/coach.png differ
diff --git a/app/assets/images/grammar-characters/professor.png b/app/assets/images/grammar-characters/professor.png
new file mode 100644
index 0000000..d8d2259
Binary files /dev/null and b/app/assets/images/grammar-characters/professor.png differ
diff --git a/app/assets/images/grammar-characters/teacher.png b/app/assets/images/grammar-characters/teacher.png
new file mode 100644
index 0000000..8df89d4
Binary files /dev/null and b/app/assets/images/grammar-characters/teacher.png differ
diff --git a/app/assets/images/grammar-characters/tutor.png b/app/assets/images/grammar-characters/tutor.png
new file mode 100644
index 0000000..4734db5
Binary files /dev/null and b/app/assets/images/grammar-characters/tutor.png differ
diff --git a/app/assets/quiz-data/grammar-quiz/airport-1.json b/app/assets/quiz-data/grammar-quiz/airport-1.json
new file mode 100644
index 0000000..55a0c72
--- /dev/null
+++ b/app/assets/quiz-data/grammar-quiz/airport-1.json
@@ -0,0 +1,73 @@
+{
+  "character1": "mike",
+  "character2": "sarah",
+  "questions": [
+    {
+      "type": "conversation_blank",
+      "line1": { "en": "I _____ to the airport yesterday." },
+      "line2": { "en": "Oh really? How was your flight?" },
+      "answer": "went",
+      "distractors": ["goed", "goes", "going"]
+    },
+    {
+      "type": "sentence_ordering",
+      "prompt": "Find the correctly ordered sentence.",
+      "answer": "The plane is landing on the runway.",
+      "distractors": [
+        "The runway is landing on the plane.",
+        "Landing the plane is on runway the.",
+        "On the runway plane the is landing."
+      ]
+    },
+    {
+      "type": "banked_cloze",
+      "sentence": "She _____ already _____ her boarding pass.",
+      "answer": "has/printed",
+      "distractors": [
+        "have/printed",
+        "has/print",
+        "had/printing"
+      ]
+    },
+    {
+      "type": "yes_no",
+      "sentence": "She don't have a passport.",
+      "answer": "no",
+      "correction": "She doesn't have a passport.",
+      "distractors": []
+    },
+    {
+      "type": "which_is_correct",
+      "prompt": "Which sentence is grammatically correct?",
+      "answer": "The passengers are waiting at the gate.",
+      "distractors": [
+        "The passengers is waiting at the gate.",
+        "The passengers waiting are at the gate.",
+        "The passengers at the gate is waiting."
+      ]
+    },
+    {
+      "type": "conversation_blank",
+      "line1": { "en": "Excuse me, where _____ the departure gate?" },
+      "line2": { "en": "It's on the second floor, to the right." },
+      "answer": "is",
+      "distractors": ["are", "be", "were"]
+    },
+    {
+      "type": "yes_no",
+      "sentence": "They have been waiting for two hours.",
+      "answer": "yes",
+      "distractors": []
+    },
+    {
+      "type": "sentence_ordering",
+      "prompt": "Find the correctly ordered sentence.",
+      "answer": "We need to check in before the flight.",
+      "distractors": [
+        "We to check in need before the flight.",
+        "Before the flight we need check in to.",
+        "Need we to check in the flight before."
+      ]
+    }
+  ]
+}
diff --git a/app/assets/quiz-data/grammar-quiz/airport-2.json b/app/assets/quiz-data/grammar-quiz/airport-2.json
new file mode 100644
index 0000000..5cf94f3
--- /dev/null
+++ b/app/assets/quiz-data/grammar-quiz/airport-2.json
@@ -0,0 +1,73 @@
+{
+  "character1": "mike",
+  "character2": "sarah",
+  "questions": [
+    {
+      "type": "conversation_blank",
+      "line1": { "en": "Can you hand me my _____? It's in the overhead bin." },
+      "line2": { "en": "Sure, is it the black one?" },
+      "answer": "luggage",
+      "distractors": ["luggages", "baggaging", "lugging"]
+    },
+    {
+      "type": "which_is_correct",
+      "prompt": "Which sentence is grammatically correct?",
+      "answer": "There are many suitcases on the carousel.",
+      "distractors": [
+        "There is many suitcases on the carousel.",
+        "There are much suitcases on the carousel.",
+        "There is much suitcase on the carousel."
+      ]
+    },
+    {
+      "type": "banked_cloze",
+      "sentence": "The _____ showed her _____ to the security _____.",
+      "answer": "passenger/ticket/officer",
+      "distractors": [
+        "passengers/tickets/officers",
+        "passenger/tickets/officer",
+        "passengers/ticket/officers"
+      ]
+    },
+    {
+      "type": "yes_no",
+      "sentence": "The informations on the board is correct.",
+      "answer": "no",
+      "correction": "The information on the board is correct.",
+      "distractors": []
+    },
+    {
+      "type": "sentence_ordering",
+      "prompt": "Find the correctly ordered sentence.",
+      "answer": "The pilot announced the arrival time.",
+      "distractors": [
+        "The pilot the arrival time announced.",
+        "Announced the pilot the arrival time.",
+        "The arrival time the pilot announced."
+      ]
+    },
+    {
+      "type": "conversation_blank",
+      "line1": { "en": "How many _____ of luggage do you have?" },
+      "line2": { "en": "I have two bags and one backpack." },
+      "answer": "pieces",
+      "distractors": ["piece", "peaces", "piecies"]
+    },
+    {
+      "type": "yes_no",
+      "sentence": "Each passenger needs their own boarding pass.",
+      "answer": "yes",
+      "distractors": []
+    },
+    {
+      "type": "which_is_correct",
+      "prompt": "Which sentence is grammatically correct?",
+      "answer": "The children were excited about the trip.",
+      "distractors": [
+        "The childrens were excited about the trip.",
+        "The children was excited about the trip.",
+        "The childs were excited about the trip."
+      ]
+    }
+  ]
+}
diff --git a/app/lib/models/grammar_quiz.dart b/app/lib/models/grammar_quiz.dart
new file mode 100644
index 0000000..d2f0067
--- /dev/null
+++ b/app/lib/models/grammar_quiz.dart
@@ -0,0 +1,98 @@
+enum GrammarQuestionType {
+  conversationBlank,
+  sentenceOrdering,
+  bankedCloze,
+  yesNo,
+  whichIsCorrect,
+}
+
+GrammarQuestionType _parseType(String raw) {
+  return switch (raw) {
+    'conversation_blank' => GrammarQuestionType.conversationBlank,
+    'sentence_ordering' => GrammarQuestionType.sentenceOrdering,
+    'banked_cloze' => GrammarQuestionType.bankedCloze,
+    'yes_no' => GrammarQuestionType.yesNo,
+    'which_is_correct' => GrammarQuestionType.whichIsCorrect,
+    _ => throw ArgumentError('Unknown grammar question type: $raw'),
+  };
+}
+
+class GrammarQuestion {
+  const GrammarQuestion({
+    required this.type,
+    required this.answer,
+    required this.distractors,
+    this.line1,
+    this.line2,
+    this.sentence,
+    this.prompt,
+    this.correction,
+  });
+
+  final GrammarQuestionType type;
+  final String answer;
+  final List<String> distractors;
+
+  /// Character 1 dialogue (conversation_blank only).
+  final Map<String, String>? line1;
+
+  /// Character 2 dialogue (conversation_blank only).
+  final Map<String, String>? line2;
+
+  /// Sentence with blanks or to judge (bankedCloze, yesNo).
+  final String? sentence;
+
+  /// Instruction text in speech bubble (sentenceOrdering, whichIsCorrect).
+  final String? prompt;
+
+  /// Corrected sentence for yesNo questions where answer is "no".
+  final String? correction;
+
+  bool get blankInLine1 => line1?['en']?.contains('_____') ?? false;
+
+  static GrammarQuestion fromJson(Map<String, dynamic> json) {
+    Map<String, String>? parseLineMap(dynamic value) {
+      if (value == null) return null;
+      if (value is Map) {
+        return value.map((k, v) => MapEntry(k.toString(), v.toString()));
+      }
+      return null;
+    }
+
+    return GrammarQuestion(
+      type: _parseType(json['type'] as String),
+      answer: json['answer'] as String? ?? '',
+      distractors: (json['distractors'] as List<dynamic>? ?? [])
+          .map((e) => e.toString())
+          .toList(),
+      line1: parseLineMap(json['line1']),
+      line2: parseLineMap(json['line2']),
+      sentence: json['sentence'] as String?,
+      prompt: json['prompt'] as String?,
+      correction: json['correction'] as String?,
+    );
+  }
+}
+
+class GrammarLevel {
+  const GrammarLevel({
+    required this.character1,
+    required this.character2,
+    required this.questions,
+  });
+
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
index 0000000..8118316
--- /dev/null
+++ b/app/lib/screens/grammar_quiz_screen.dart
@@ -0,0 +1,795 @@
+import 'dart:math';
+
+import 'package:flutter/material.dart';
+import 'package:flutter_riverpod/flutter_riverpod.dart';
+
+import '../models/grammar_quiz.dart';
+import '../models/level_completion_result.dart';
+import '../models/quiz_flow.dart';
+import '../providers/settings_provider.dart';
+import '../services/audio_service.dart' as audio;
+import '../services/game_config_loader.dart';
+import '../services/global_stats_service.dart';
+import '../services/grammar_quiz_loader.dart';
+import '../services/localization_service.dart';
+import '../services/quiz_progress_service.dart';
+
+const double _kMinTouchTarget = 48.0;
+const String _kBlank = '_____';
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
+  DateTime? _quizStartTime;
+
+  List<GrammarQuestion> get _questions => _level?.questions ?? [];
+
+  int _currentIndex = 0;
+  int _correctCount = 0;
+  bool _answerLocked = false;
+  bool _showNext = false;
+  int? _selectedIndex;
+  List<String> _currentOptions = [];
+
+  // Character image randomly assigned per question (types 2-5).
+  final Map<int, String> _questionCharacterMap = {};
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
+      // Load grammar character images for non-conversation questions.
+      final charImages = await loadGrammarCharacterImages();
+      final rng = Random();
+
+      // Pre-assign a random character image to each non-conversation question.
+      final charMap = <int, String>{};
+      for (var i = 0; i < level.questions.length; i++) {
+        if (level.questions[i].type != GrammarQuestionType.conversationBlank &&
+            charImages.isNotEmpty) {
+          charMap[i] = charImages[rng.nextInt(charImages.length)];
+        }
+      }
+
+      if (mounted) {
+        final musicOn = ref.read(settingsProvider).musicOn;
+        audio.startQuizMusic(musicOn: musicOn);
+        setState(() {
+          _config = config;
+          _level = level;
+          _questionCharacterMap.addAll(charMap);
+          _phase = _Phase.playing;
+          _quizStartTime = DateTime.now();
+          _currentOptions = _buildOptions(level.questions[0]);
+        });
+      }
+    } catch (e, st) {
+      debugPrint('GrammarQuizScreen _loadLevel: $e\n$st');
+      if (mounted) {
+        setState(() {
+          _loadError = e.toString();
+        });
+      }
+    }
+  }
+
+  // ── Options ──────────────────────────────────────────────────────────────────
+
+  List<String> _buildOptions(GrammarQuestion q) {
+    if (q.type == GrammarQuestionType.yesNo) {
+      return ['Yes', 'No'];
+    }
+    final options = [q.answer, ...q.distractors]..shuffle(Random());
+    return options;
+  }
+
+  // ── Answer handling ────────────────────────────────────────────────────────
+
+  void _onAnswerTap(int optionIndex) {
+    if (_answerLocked) return;
+    final soundFxOn = ref.read(settingsProvider).sfxOn;
+    final q = _questions[_currentIndex];
+    final selected = _currentOptions[optionIndex];
+
+    final bool isCorrect;
+    if (q.type == GrammarQuestionType.yesNo) {
+      isCorrect = selected.toLowerCase() == q.answer.toLowerCase();
+    } else {
+      isCorrect = selected == q.answer;
+    }
+
+    if (isCorrect) {
+      audio.playCorrect(soundFxOn: soundFxOn);
+      GlobalStatsService.instance.incrementCorrectStreak();
+    } else {
+      audio.playWrong(soundFxOn: soundFxOn);
+      GlobalStatsService.instance.resetCorrectStreak();
+    }
+
+    setState(() {
+      _answerLocked = true;
+      _selectedIndex = optionIndex;
+      if (isCorrect) {
+        _correctCount++;
+        _showNext = false;
+        Future.delayed(
+          Duration(
+              milliseconds:
+                  (_config.autoAdvanceDelaySeconds * 1000).round()),
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
+    setState(() {
+      _currentIndex++;
+      _answerLocked = false;
+      _showNext = false;
+      _selectedIndex = null;
+      _currentOptions = _buildOptions(nextQ);
+    });
+  }
+
+  // ── Scoring ──────────────────────────────────────────────────────────────────
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
+    if (stars >= 1) {
+      final elapsedMs = _quizStartTime != null
+          ? DateTime.now().difference(_quizStartTime!).inMilliseconds
+          : 0;
+      await QuizProgressService.instance.recordLevelCompletion(
+        quizType: widget.quizType,
+        levelNumber: widget.subLevel.levelNumber,
+        stars: stars,
+        diamondsEarned: _diamondsEarned(),
+        questionsAnswered: _questions.length,
+        elapsedMs: elapsedMs,
+        iconImageName: widget.subLevel.iconImageName,
+      );
+    }
+    if (mounted) {
+      Navigator.of(context).pop(
+        LevelCompletionResult(
+          ordinalLevelIndex: widget.ordinalLevelIndex,
+          completed: stars >= 1,
+        ),
+      );
+    }
+  }
+
+  // ── Build ────────────────────────────────────────────────────────────────────
+
+  @override
+  Widget build(BuildContext context) {
+    final lang = ref.watch(settingsProvider).language;
+    return Scaffold(
+      appBar: AppBar(
+        title: Text(widget.subLevel.title),
+        leading: IconButton(
+          icon: const Icon(Icons.arrow_back),
+          onPressed: () => Navigator.of(context).pop(),
+        ),
+      ),
+      body: SafeArea(child: _buildBody(lang)),
+    );
+  }
+
+  Widget _buildBody(String lang) {
+    if (_loadError != null) return _buildError(lang);
+    return switch (_phase) {
+      _Phase.loading => const Center(child: CircularProgressIndicator()),
+      _Phase.playing => _buildPlaying(lang),
+      _Phase.end => _buildEnd(lang),
+    };
+  }
+
+  Widget _buildError(String lang) {
+    final loc = LocalizationService.instance;
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
+            onPressed: () => Navigator.of(context).pop(),
+            child: Text(loc.tr(lang, 'quiz_back_to_levels')),
+          ),
+        ],
+      ),
+    );
+  }
+
+  // ── Playing phase ────────────────────────────────────────────────────────────
+
+  Widget _buildPlaying(String lang) {
+    final q = _questions[_currentIndex];
+    final total = _questions.length;
+    final isLast = _currentIndex + 1 >= total;
+    final loc = LocalizationService.instance;
+
+    return Column(
+      children: [
+        // Progress
+        Padding(
+          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
+          child: Text(
+            loc
+                .tr(lang, 'quiz_progress')
+                .replaceAll('{current}', '${_currentIndex + 1}')
+                .replaceAll('{total}', '$total'),
+            style: Theme.of(context).textTheme.labelLarge?.copyWith(
+                  color: Theme.of(context).colorScheme.primary,
+                  fontWeight: FontWeight.w600,
+                ),
+          ),
+        ),
+
+        // Question area (type-specific)
+        Expanded(
+          child: Padding(
+            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
+            child: _buildQuestionArea(q, lang),
+          ),
+        ),
+
+        // Answer buttons
+        Padding(
+          padding: const EdgeInsets.symmetric(horizontal: 16),
+          child: _buildAnswerButtons(q),
+        ),
+
+        // Next / Finish
+        Padding(
+          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
+          child: SizedBox(
+            width: double.infinity,
+            height: _kMinTouchTarget + 8,
+            child: _showNext
+                ? FilledButton(
+                    onPressed: _goNext,
+                    child: Text(isLast
+                        ? loc.tr(lang, 'quiz_finish')
+                        : loc.tr(lang, 'quiz_next')),
+                  )
+                : const SizedBox.shrink(),
+          ),
+        ),
+      ],
+    );
+  }
+
+  // ── Question area (type-specific) ────────────────────────────────────────────
+
+  Widget _buildQuestionArea(GrammarQuestion q, String lang) {
+    switch (q.type) {
+      case GrammarQuestionType.conversationBlank:
+        return _buildConversationBlank(q);
+      case GrammarQuestionType.sentenceOrdering:
+        return _buildCharacterWithPrompt(
+          prompt: q.prompt ?? LocalizationService.instance.tr(lang, 'grammar_find_correct_order'),
+        );
+      case GrammarQuestionType.bankedCloze:
+        return _buildCharacterWithPrompt(
+          prompt: LocalizationService.instance.tr(lang, 'grammar_fill_blanks'),
+          contentText: q.sentence,
+        );
+      case GrammarQuestionType.yesNo:
+        return _buildCharacterWithPrompt(
+          prompt: LocalizationService.instance.tr(lang, 'grammar_is_correct'),
+          contentText: q.sentence,
+          correction: _shouldShowCorrection(q) ? q.correction : null,
+        );
+      case GrammarQuestionType.whichIsCorrect:
+        return _buildCharacterWithPrompt(
+          prompt: q.prompt ?? LocalizationService.instance.tr(lang, 'grammar_which_correct'),
+        );
+    }
+  }
+
+  /// Show correction only when answer is locked AND the user got it wrong
+  /// AND the sentence is actually incorrect (answer == "no").
+  bool _shouldShowCorrection(GrammarQuestion q) {
+    if (!_answerLocked || q.correction == null) return false;
+    final selected = _currentOptions[_selectedIndex!];
+    final isCorrect = selected.toLowerCase() == q.answer.toLowerCase();
+    return !isCorrect;
+  }
+
+  // ── Type 1: Conversation blank ────────────────────────────────────────────
+
+  Widget _buildConversationBlank(GrammarQuestion q) {
+    final line1Text = q.line1?['en'] ?? '';
+    final line2Text = q.line2?['en'] ?? '';
+    final char1 = _level?.character1 ?? '';
+    final char2 = _level?.character2 ?? '';
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
+          ),
+        ),
+        const SizedBox(width: 8),
+        Expanded(
+          child: _buildCharacterColumn(
+            name: char2,
+            dialogueLine: line2Text,
+            isActive: !q.blankInLine1,
+            alignment: CrossAxisAlignment.end,
+          ),
+        ),
+      ],
+    );
+  }
+
+  Widget _buildCharacterColumn({
+    required String name,
+    required String dialogueLine,
+    required bool isActive,
+    required CrossAxisAlignment alignment,
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
+        _buildConversationAvatar(name, size: 64),
+      ],
+    );
+  }
+
+  Widget _buildConversationAvatar(String name, {required double size}) {
+    final imagePath = 'assets/images/characters/$name.png';
+    return SizedBox(
+      width: size,
+      height: size,
+      child: ClipRRect(
+        borderRadius: BorderRadius.circular(size / 2),
+        child: Image.asset(
+          imagePath,
+          fit: BoxFit.cover,
+          errorBuilder: (_, __, ___) {
+            final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
+            return CircleAvatar(
+              radius: size / 2,
+              backgroundColor:
+                  Theme.of(context).colorScheme.primaryContainer,
+              child: Text(
+                initial,
+                style: TextStyle(
+                  fontSize: size * 0.4,
+                  fontWeight: FontWeight.w700,
+                  color:
+                      Theme.of(context).colorScheme.onPrimaryContainer,
+                ),
+              ),
+            );
+          },
+        ),
+      ),
+    );
+  }
+
+  // ── Types 2-5: Character + prompt bubble + content field ────────────────
+
+  Widget _buildCharacterWithPrompt({
+    required String prompt,
+    String? contentText,
+    String? correction,
+  }) {
+    final charImage = _questionCharacterMap[_currentIndex];
+    return Column(
+      mainAxisAlignment: MainAxisAlignment.center,
+      children: [
+        // Bubble above character — only the prompt/question
+        _buildSpeechBubble(text: prompt, isActive: true, alignRight: false),
+        const SizedBox(height: 12),
+        _buildGrammarCharacter(charImage, size: 100),
+        // Content field between character and answer buttons
+        if (contentText != null) ...[
+          const SizedBox(height: 12),
+          _buildContentField(contentText),
+        ],
+        // Correction field for wrong yes/no answers
+        if (correction != null) ...[
+          const SizedBox(height: 8),
+          _buildCorrectionField(correction),
+        ],
+      ],
+    );
+  }
+
+  Widget _buildContentField(String text) {
+    return Container(
+      width: double.infinity,
+      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
+      decoration: BoxDecoration(
+        color: Theme.of(context).colorScheme.surfaceContainerHighest,
+        borderRadius: BorderRadius.circular(10),
+        border: Border.all(
+          color: Theme.of(context).colorScheme.outlineVariant,
+          width: 1,
+        ),
+      ),
+      child: _buildBubbleText(text, isActive: true),
+    );
+  }
+
+  Widget _buildCorrectionField(String text) {
+    return Container(
+      width: double.infinity,
+      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
+      decoration: BoxDecoration(
+        color: Colors.green.shade50,
+        borderRadius: BorderRadius.circular(10),
+        border: Border.all(color: Colors.green.shade300, width: 1),
+      ),
+      child: Row(
+        children: [
+          Icon(Icons.check_circle, color: Colors.green.shade600, size: 18),
+          const SizedBox(width: 8),
+          Expanded(
+            child: Text(
+              text,
+              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
+                    color: Colors.green.shade800,
+                    fontWeight: FontWeight.w600,
+                  ),
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+
+  Widget _buildGrammarCharacter(String? imagePath, {required double size}) {
+    return SizedBox(
+      width: size,
+      height: size,
+      child: ClipRRect(
+        borderRadius: BorderRadius.circular(size / 2),
+        child: imagePath != null
+            ? Image.asset(
+                imagePath,
+                fit: BoxFit.cover,
+                errorBuilder: (_, __, ___) => _buildFallbackAvatar(size),
+              )
+            : _buildFallbackAvatar(size),
+      ),
+    );
+  }
+
+  Widget _buildFallbackAvatar(double size) {
+    return CircleAvatar(
+      radius: size / 2,
+      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
+      child: Icon(
+        Icons.school,
+        size: size * 0.5,
+        color: Theme.of(context).colorScheme.onPrimaryContainer,
+      ),
+    );
+  }
+
+  // ── Speech bubble ─────────────────────────────────────────────────────────
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
+      child: _buildBubbleText(text, isActive: isActive),
+    );
+  }
+
+  Widget _buildBubbleText(String text, {required bool isActive}) {
+    if (!text.contains(_kBlank)) {
+      return Text(text, style: Theme.of(context).textTheme.bodySmall);
+    }
+
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
+              padding:
+                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
+                style: Theme.of(context).textTheme.bodySmall?.copyWith(
+                      color: Theme.of(context).colorScheme.primary,
+                      fontWeight: FontWeight.w700,
+                      letterSpacing: 1,
+                    ),
+              ),
+            ),
+          ),
+        );
+      }
+    }
+
+    return RichText(
+      text: TextSpan(
+        style: Theme.of(context).textTheme.bodySmall,
+        children: spans,
+      ),
+    );
+  }
+
+  // ── Answer buttons ────────────────────────────────────────────────────────
+
+  Widget _buildAnswerButtons(GrammarQuestion q) {
+    if (q.type == GrammarQuestionType.yesNo) {
+      return _buildYesNoButtons(q);
+    }
+    return Column(
+      children: List.generate(
+        _currentOptions.length,
+        (i) => _buildAnswerButton(i, q),
+      ),
+    );
+  }
+
+  Widget _buildYesNoButtons(GrammarQuestion q) {
+    return Row(
+      children: [
+        Expanded(child: _buildAnswerButton(0, q)),
+        const SizedBox(width: 12),
+        Expanded(child: _buildAnswerButton(1, q)),
+      ],
+    );
+  }
+
+  Widget _buildAnswerButton(int optionIndex, GrammarQuestion q) {
+    final option = _currentOptions[optionIndex];
+
+    final bool isCorrectOption;
+    if (q.type == GrammarQuestionType.yesNo) {
+      isCorrectOption = option.toLowerCase() == q.answer.toLowerCase();
+    } else {
+      isCorrectOption = option == q.answer;
+    }
+
+    final isSelected = _selectedIndex == optionIndex;
+
+    Color? bgColor;
+    Color? fgColor;
+    if (_answerLocked) {
+      if (isCorrectOption) {
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
+        child: ConstrainedBox(
+          constraints: const BoxConstraints(minHeight: _kMinTouchTarget + 8),
+          child: ElevatedButton(
+            onPressed: _answerLocked ? null : () => _onAnswerTap(optionIndex),
+            style: buttonStyle,
+            child: Text(
+              option,
+              textAlign: TextAlign.center,
+              style: fgColor != null
+                  ? Theme.of(context).textTheme.titleMedium?.copyWith(
+                        color: fgColor,
+                        fontWeight: FontWeight.w600,
+                      )
+                  : Theme.of(context).textTheme.titleMedium,
+            ),
+          ),
+        ),
+      ),
+    );
+  }
+
+  // ── End screen ────────────────────────────────────────────────────────────
+
+  Widget _buildEnd(String lang) {
+    final stars = _stars();
+    final diamonds = _diamondsEarned();
+    final loc = LocalizationService.instance;
+
+    return Center(
+      child: Padding(
+        padding: const EdgeInsets.all(24),
+        child: Column(
+          mainAxisSize: MainAxisSize.min,
+          children: [
+            Text(
+              loc.tr(lang, 'quiz_level_complete'),
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
+                onPressed: _onEndOk,
+                child: Text(loc.tr(lang, 'quiz_ok')),
+              ),
+            ),
+          ],
+        ),
+      ),
+    );
+  }
+
+  // ── Utilities ────────────────────────────────────────────────────────────────
+
+  String _capitalize(String s) {
+    if (s.isEmpty) return s;
+    return s[0].toUpperCase() + s.substring(1).toLowerCase();
+  }
+}
diff --git a/app/lib/screens/levels_screen.dart b/app/lib/screens/levels_screen.dart
index 5b8c695..2e7bc31 100644
--- a/app/lib/screens/levels_screen.dart
+++ b/app/lib/screens/levels_screen.dart
@@ -10,6 +10,7 @@ import '../providers/settings_provider.dart';
 import '../services/localization_service.dart';
 import '../services/quiz_flow_loader.dart';
 import '../services/quiz_progress_service.dart';
+import 'grammar_quiz_screen.dart';
 import 'image_quiz_screen.dart';
 import 'placeholders/quiz_placeholder_screen.dart';
 import 'transitions/custom_page_routes.dart';
@@ -528,11 +529,17 @@ class _LevelsScreenState extends ConsumerState<LevelsScreen> {
                 subLevel: sub,
                 ordinalLevelIndex: subLevelItem.ordinalLevelIndex,
               ))
-            : popFadeRoute<LevelCompletionResult>(QuizPlaceholderScreen(
-                quizType: widget.quizType,
-                subLevel: sub,
-                ordinalLevelIndex: subLevelItem.ordinalLevelIndex,
-              ));
+            : widget.quizType == 'grammar'
+                ? popFadeRoute<LevelCompletionResult>(GrammarQuizScreen(
+                    quizType: widget.quizType,
+                    subLevel: sub,
+                    ordinalLevelIndex: subLevelItem.ordinalLevelIndex,
+                  ))
+                : popFadeRoute<LevelCompletionResult>(QuizPlaceholderScreen(
+                    quizType: widget.quizType,
+                    subLevel: sub,
+                    ordinalLevelIndex: subLevelItem.ordinalLevelIndex,
+                  ));
 
     final result = await Navigator.of(context).push<LevelCompletionResult>(route);
     if (!mounted) return;
diff --git a/app/lib/services/grammar_quiz_loader.dart b/app/lib/services/grammar_quiz_loader.dart
new file mode 100644
index 0000000..426fb70
--- /dev/null
+++ b/app/lib/services/grammar_quiz_loader.dart
@@ -0,0 +1,59 @@
+import 'dart:convert';
+
+import 'package:flutter/services.dart';
+
+import '../models/grammar_quiz.dart';
+
+const int kMinGrammarQuestions = 4;
+
+const String _characterImagePrefix = 'assets/images/grammar-characters/';
+
+String grammarDataPath(String iconImageName, int levelNumber) {
+  return 'assets/quiz-data/grammar-quiz/$iconImageName-$levelNumber.json';
+}
+
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
+
+/// Discovers grammar character image paths from the asset bundle.
+Future<List<String>> loadGrammarCharacterImages() async {
+  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
+  final all = manifest.listAssets();
+  return all
+      .where((p) =>
+          p.startsWith(_characterImagePrefix) &&
+          !p.split('/').last.toLowerCase().startsWith('.'))
+      .toList();
+}
diff --git a/app/pubspec.yaml b/app/pubspec.yaml
index 4ec65aa..b91c095 100644
--- a/app/pubspec.yaml
+++ b/app/pubspec.yaml
@@ -31,6 +31,7 @@ flutter:
     - assets/images/avatars/
     - assets/images/level-icons/
     - assets/images/animals/
+    - assets/images/grammar-characters/
     - assets/audio/
     - assets/data/state/
     - assets/data/config/
