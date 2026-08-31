import 'package:flutter/foundation.dart';

import '../utils/cloze_blank.dart';

/// Parsed `questionData` for [imageQuizTemplate-1].
class ImageQuestionData {
  const ImageQuestionData({
    required this.imageName,
    required this.wrongAnswers,
    this.answer,
  });

  final String imageName;
  final List<String> wrongAnswers;

  /// Optional override for the correct answer label shown in MCQ buttons.
  /// When null the image basename is used instead.
  final String? answer;
}

/// Parsed `questionData` for [imageQuizTemplate-2] (noun prompt + pick image).
class ImageQuizTemplate2Data {
  const ImageQuizTemplate2Data({
    required this.imageName,
    required this.wrongAnswers,
    this.answer,
  });

  final String imageName;
  final List<String> wrongAnswers;

  /// Optional override for the correct tile’s option key (same role as [ImageQuestionData.answer]).
  /// When null or empty, [imageName] is used. The correct image file is always [imageName].
  final String? answer;

  /// Stem identifying the correct choice in the shuffled grid (for scoring and option keys).
  String get correctAnswerStem =>
      (answer != null && answer!.isNotEmpty) ? answer! : imageName;
}

/// Parsed `questionData` for template [AppearDisappear].
class AppearDisappearQuestionData {
  const AppearDisappearQuestionData({
    required this.words,
    required this.distractors,
    this.line1,
    this.displayDuration = 1.0,
    this.introPause = 2.0,
    this.imageName,
    this.englishToTranslate = const [],
    this.localTranslation = const {},
    this.trOk = false,
  });

  final List<String> words;
  final List<String> distractors;

  /// Optional conversational prompt shown above the recall sentence.
  final String? line1;
  final double displayDuration;

  /// Pause (seconds) with empty boxes before word reveal starts.
  final double introPause;

  /// Optional image basename under the level folder. Null = no image.
  final String? imageName;
  final List<String> englishToTranslate;
  final Map<String, List<String>> localTranslation;

  /// When true, revealing translation does not count as a wrong answer.
  final bool trOk;
}

/// Parsed `questionData` for template [ClozeSequence].
class ClozeSequenceQuestionData {
  const ClozeSequenceQuestionData({
    required this.sentence,
    required this.answers,
    required this.distractors,
    this.imageName,
    this.line1,
    this.englishToTranslate = const [],
    this.localTranslation = const {},
    this.trOk = false,
  });

  /// English sentence with 2+ underscore blank markers (e.g. `_____`).
  final String sentence;
  final List<String> answers;
  final List<String> distractors;

  /// Optional image basename under the level folder. Null = no image.
  final String? imageName;

  /// Optional spoken prompt line shown above the sentence (e.g. an image question's opening
  /// line, "Are these your tickets?"). Null for the common case of a bare cloze sentence with
  /// no separate prompt — most ClozeSequence rows across the app don't set this.
  final String? line1;
  final List<String> englishToTranslate;
  final Map<String, List<String>> localTranslation;

  /// When true, revealing translation does not count as a wrong answer.
  final bool trOk;
}

/// Parsed `questionData` for [ConvoTemplate-1] (vocabulary or grammar).
class ConvoQuestionData {
  ConvoQuestionData({
    required this.character1,
    required this.character2,
    required this.line1,
    required this.line2,
    required this.answer,
    required this.distractors,
    this.imageName,
    this.englishToTranslate = const [],
    this.localTranslation = const {},
    this.trOk = false,
  });

  /// Mutable: blank in JSON means "no character given" — [loadLevelConfig]
  /// fills it in from [ConversationCharacterPool] after parsing.
  String character1;
  String character2;

  /// English dialogue line for speaker 1 (blank may be in line1 or line2).
  final String line1;

  /// English dialogue line for speaker 2; use `___` / cloze-style blank where needed.
  final String line2;
  final String answer;
  final List<String> distractors;

  /// Optional image basename (no extension) under the level folder.
  final String? imageName;
  final List<String> englishToTranslate;
  final Map<String, List<String>> localTranslation;

  /// When true, revealing translation does not count as a wrong answer.
  final bool trOk;
}

/// [SentenceBuilder]: tiles are only the sentence tokens, shuffled; player taps in [correctOrder].
class SentenceBuilderQuestionData {
  const SentenceBuilderQuestionData({
    required this.correctOrder,
    this.imageName,
    this.line1,
    this.englishToTranslate = const [],
    this.localTranslation = const {},
    this.trOk = false,
  });

  /// Target sentence token sequence (left-to-right).
  final List<String> correctOrder;

  /// Optional image basename under the level folder. Null = no image.
  final String? imageName;

  /// Optional spoken prompt line shown above the tile grid (e.g. an image question's opening
  /// line, "Whose coat is this?"). Null for the common case of no separate prompt.
  final String? line1;
  final List<String> englishToTranslate;
  final Map<String, List<String>> localTranslation;

  /// When true, revealing translation does not count as a wrong answer.
  final bool trOk;
}

/// One left/right pair for [WordPairs].
class WordPairItem {
  const WordPairItem({required this.left, required this.translations});

  final String left;

  /// Locale → translation (e.g. `tr`, `es`, `fr`).
  final Map<String, String> translations;

  String rightForLanguage(String userLanguage) {
    String? normalized(String? value) {
      final trimmed = value?.trim() ?? '';
      return trimmed.isEmpty ? null : trimmed;
    }

    if (userLanguage != 'en') {
      final direct = normalized(translations[userLanguage]);
      if (direct != null) return direct;
    }

    // Prefer common non-English fallbacks before English.
    final tr = normalized(translations['tr']);
    if (tr != null) return tr;
    final es = normalized(translations['es']);
    if (es != null) return es;
    final fr = normalized(translations['fr']);
    if (fr != null) return fr;

    final en = normalized(translations['en']);
    if (en != null) return en;

    for (final value in translations.values) {
      final fallback = normalized(value);
      if (fallback != null) return fallback;
    }

    return left;
  }
}

/// [WordPairs]: 3–6 pairs; UI scrambles the right column.
class WordPairsQuestionData {
  const WordPairsQuestionData({required this.pairs});

  final List<WordPairItem> pairs;
}

/// [DialogueCompletion]: first speaker line + four response options.
class DialogueCompletionQuestionData {
  DialogueCompletionQuestionData({
    required this.character1,
    required this.character2,
    required this.line1,
    required this.answer,
    required this.distractors,
    this.imageName,
    this.englishToTranslate = const [],
    this.localTranslation = const {},
    this.trOk = false,
  });

  /// Mutable: blank in JSON means "no character given" — [loadLevelConfig]
  /// fills it in from [ConversationCharacterPool] after parsing.
  String character1;
  String character2;

  /// English question line (speaker 1); legacy `{"en": "..."}` accepted at parse time.
  final String line1;
  final String answer;
  final List<String> distractors;

  /// Optional image basename (no extension) under the level folder.
  final String? imageName;
  final List<String> englishToTranslate;
  final Map<String, List<String>> localTranslation;

  /// When true, revealing translation does not count as a wrong answer.
  final bool trOk;
}

/// [VideoConversation] answer_type `DialogueCompletion`: pick the correct line from options.
class VideoChoiceAnswerData {
  const VideoChoiceAnswerData(
      {required this.answer, required this.distractors});

  final String answer;
  final List<String> distractors;
}

/// [VideoConversation] answer_type `SentenceBuilder` / `AppearDisappear`: build the full
/// target sentence from shuffled word tiles (optionally mixed with decoy [distractors]).
class VideoSequenceAnswerData {
  const VideoSequenceAnswerData({
    required this.targetSentence,
    this.distractors = const [],
    required this.isRecall,
  });

  final String targetSentence;
  final List<String> distractors;

  /// True for `AppearDisappear` (video already spoke the line — reconstruct it from memory),
  /// false for `SentenceBuilder` (video hasn't spoken it yet — build it cold, then it plays as
  /// confirmation). Both answer_types share this class; this is the only thing that tells them
  /// apart, since the UI prompt/instruction shown differs between the two.
  final bool isRecall;
}

/// [VideoConversation] answer_type `ClozeSequence`: fill blanks in [sentence] using ordered
/// [answers], picking tiles out of `answers + distractors` shuffled together.
class VideoClozeAnswerData {
  const VideoClozeAnswerData({
    required this.sentence,
    required this.answers,
    required this.distractors,
  });

  /// English sentence with 1+ underscore blank markers (e.g. `_____`).
  final String sentence;
  final List<String> answers;
  final List<String> distractors;
}

/// Parsed row for template [VideoConversation]: a video clip `[startAt, pauseAt]` that pauses
/// right when the learner must supply the next line, answered via exactly one of
/// [choiceData] / [sequenceData] / [clozeData] depending on `answer_type`.
class VideoConversationQuestionData {
  const VideoConversationQuestionData({
    required this.videoFile,
    required this.startAt,
    required this.pauseAt,
    this.answerUntil,
    this.choiceData,
    this.sequenceData,
    this.clozeData,
  });

  final String videoFile;
  final Duration startAt;
  final Duration pauseAt;

  /// Timestamp where the post-pause answer/confirmation line ends.
  final Duration? answerUntil;

  final VideoChoiceAnswerData? choiceData;
  final VideoSequenceAnswerData? sequenceData;
  final VideoClozeAnswerData? clozeData;
}

/// Parsed row for template [Chapter]: a passive, non-quiz interstitial card — just an image and
/// a Continue button, e.g. a "movie chapter card" marking the start of the video segment or the
/// switch from the video story into standalone practice questions. Has no `questionData` at all
/// (nothing to answer), unlike every other template.
class ChapterQuestionData {
  const ChapterQuestionData({required this.displayImage});

  /// Image basename (no extension) under the level folder, resolved the same way as other
  /// per-question images (flavor folder first, then level root).
  final String displayImage;
}

/// One entry in `levelQuestions`.
class LevelQuestion {
  const LevelQuestion({
    this.questionId,
    this.audioFile,
    this.audioFile1,
    this.audioFile2,
    this.genders,
    required this.template,
    this.imageData,
    this.imageQuiz2Data,
    this.convoData,
    this.appearDisappearData,
    this.clozeSequenceData,
    this.sentenceBuilderData,
    this.wordPairsData,
    this.dialogueCompletionData,
    this.videoConversationData,
    this.chapterData,
  });

  /// Injected when JSON parse or asset load fails; [ImageQuizScreen] auto-advances with no score.
  static const String kParseErrorTemplate = '_ParseError';

  /// True for rows that were skipped at parse/load and should not be shown.
  bool get isSkipPlaceholder => template == kParseErrorTemplate;

  factory LevelQuestion.parseError({String? questionId}) {
    return LevelQuestion(
      questionId: questionId,
      template: kParseErrorTemplate,
    );
  }

  final String? questionId;
  final String? audioFile;

  /// Optional first clip (top-level JSON). [DialogueCompletion]: question line.
  /// [ConvoTemplate-1]: speaker 1 line, blanks filled with [ConvoQuestionData.answer] in the asset.
  final String? audioFile1;

  /// Optional second clip (top-level JSON). [DialogueCompletion]: correct reply.
  /// [ConvoTemplate-1]: speaker 2 line, blanks filled the same way. Requires [audioFile1] when used.
  final String? audioFile2;

  /// Voice/art casting code: `"m"`/`"f"` for single-person templates
  /// (AppearDisappear, ClozeSequence, SentenceBuilder), or
  /// `"m-m"`/`"f-m"`/`"m-f"`/`"f-f"` for two-speaker templates
  /// (ConvoTemplate-1, DialogueCompletion; order = character1-character2).
  /// Mandatory content for those templates — see `validate_quiz_level_json.py`.
  final String? genders;
  final String template;
  final ImageQuestionData? imageData;
  final ImageQuizTemplate2Data? imageQuiz2Data;
  final ConvoQuestionData? convoData;
  final AppearDisappearQuestionData? appearDisappearData;
  final ClozeSequenceQuestionData? clozeSequenceData;
  final SentenceBuilderQuestionData? sentenceBuilderData;
  final WordPairsQuestionData? wordPairsData;
  final DialogueCompletionQuestionData? dialogueCompletionData;
  final VideoConversationQuestionData? videoConversationData;
  final ChapterQuestionData? chapterData;

  /// True when this question uses an image-mode template (imageQuizTemplate-*).
  bool get isImageTemplate => template.startsWith('imageQuizTemplate');

  /// True for the passive [Chapter] interstitial (no answer, no scoring gate).
  bool get isChapter => template == 'Chapter';
}

/// One entry in [LevelTutorialConfig.steps]: which localized message and character portrait to
/// show the first time this step's key is reached.
class TutorialStepConfig {
  const TutorialStepConfig({
    required this.messageKey,
    this.characterAsset,
  });

  /// Key into `localization.json` (not per-level `translations.json` — this is UI chrome text).
  final String messageKey;
  final String? characterAsset;
}

/// Optional root-level `tutorial` object for a level's `questions.json`. Purely additive guide
/// metadata — absent or `enabled: false` means no tutorial behavior at all, no other change to
/// how the level loads or plays.
class LevelTutorialConfig {
  const LevelTutorialConfig({
    required this.enabled,
    this.showIntro = true,
    this.steps = const {},
  });

  final bool enabled;
  final bool showIntro;

  /// Keyed by template name (e.g. `"DialogueCompletion"`), or `"VideoConversation:<answer_type>"`
  /// for rows inside the video (e.g. `"VideoConversation:SentenceBuilder"`).
  final Map<String, TutorialStepConfig> steps;

  static LevelTutorialConfig? tryParse(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    try {
      final enabled = json['enabled'] as bool? ?? false;
      final showIntro = json['showIntro'] as bool? ?? true;
      final rawSteps = json['steps'];
      final steps = <String, TutorialStepConfig>{};
      if (rawSteps is Map<String, dynamic>) {
        for (final entry in rawSteps.entries) {
          final stepJson = entry.value;
          if (stepJson is! Map<String, dynamic>) continue;
          final messageKey = stepJson['messageKey'] as String?;
          if (messageKey == null) continue;
          steps[entry.key] = TutorialStepConfig(
            messageKey: messageKey,
            characterAsset: stepJson['characterAsset'] as String?,
          );
        }
      }
      return LevelTutorialConfig(
          enabled: enabled, showIntro: showIntro, steps: steps);
    } catch (e) {
      debugPrint('LevelTutorialConfig: malformed tutorial config ignored: $e');
      return null;
    }
  }
}

/// Full level definition from `assets/quiz-data/levels/{directoryName}.json`.
class LevelConfig {
  const LevelConfig(
      {required this.questions, this.timerSeconds, this.tutorial});

  final List<LevelQuestion> questions;

  /// Level-wide monster timer override (seconds). Null = use global `imageQuizTimerSeconds` from `game_config.json`.
  final int? timerSeconds;

  /// Optional guide-overlay config (see [LevelTutorialConfig]). Null = no tutorial behavior.
  final LevelTutorialConfig? tutorial;

  static Map<String, String>? _stringMapOrNull(dynamic value) {
    if (value == null || value is! Map) return null;
    return value.map(
      (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
    );
  }

  /// [ConvoTemplate-1] `line1` / `line2`: plain English string, or legacy `{"en": "..."}` map.
  static String _englishLineField(dynamic raw) {
    if (raw is String) return raw.trim();
    if (raw is Map) {
      final en = raw['en'];
      return en?.toString().trim() ?? '';
    }
    return '';
  }

  /// Validates and builds [ImageQuestionData] for `imageQuizTemplate-1` rows (exactly three wrong answers).
  /// Accepts `wrongAnswers` or `distractors` (the latter is used by the former imageQuizTemplate-3 JSON).
  static ImageQuestionData _parseImageData(Map<String, dynamic> data) {
    final imageName = data['imageName'] as String? ?? '';
    final wrongRaw = data['wrongAnswers'] ?? data['distractors'];
    final wrong =
        (wrongRaw as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    assert(() {
      if (wrong.length != 3) {
        debugPrint(
          'LevelConfig: image question expects exactly 3 wrongAnswers, got ${wrong.length}',
        );
      }
      return true;
    }());
    if (wrong.length != 3) {
      throw FormatException(
        'image question must have exactly 3 wrongAnswers (got ${wrong.length})',
      );
    }
    return ImageQuestionData(
      imageName: imageName,
      wrongAnswers: wrong,
      answer: data['answer'] as String?,
    );
  }

  /// Parses noun + four-image grid settings including optional delays and wrong-answer highlight flag.
  static ImageQuizTemplate2Data _parseImageQuiz2Data(
      Map<String, dynamic> data) {
    final imageName = data['imageName'] as String? ?? '';
    final wrong = (data['wrongAnswers'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    if (wrong.length != 3) {
      throw FormatException(
        'imageQuizTemplate-2 must have exactly 3 wrongAnswers (got ${wrong.length})',
      );
    }
    return ImageQuizTemplate2Data(
      imageName: imageName,
      wrongAnswers: wrong,
      answer: data['answer'] as String?,
    );
  }

  /// Safe coercion of JSON arrays to `List<String>` for word lists and similar fields.
  static List<String> _stringList(dynamic v) {
    if (v is! List) return const [];
    return v.map((e) => e.toString()).toList();
  }

  /// Parses `{"tr": ["...", "..."], "fr": ["..."]}` → `Map<String, List<String>>`.
  static Map<String, List<String>> _stringListMap(dynamic v) {
    if (v is! Map) return const {};
    return Map.fromEntries(
      v.entries.map((e) => MapEntry(e.key.toString(), _stringList(e.value))),
    );
  }

  /// Parses words from either:
  /// - legacy array format: ["I", "love", "tea"]
  /// - new sentence format: "I love tea"
  static List<String> _wordsFromArrayOrSentence(dynamic v) {
    if (v is List) {
      return v.map((e) => e.toString()).toList();
    }
    if (v is String) {
      final trimmed = v.trim();
      if (trimmed.isEmpty) return const [];
      return trimmed.split(RegExp(r'\s+'));
    }
    return const [];
  }

  /// Optional thumbnail basename from `imageName` or `image_file_name`.
  static String? _optionalImageName(Map<String, dynamic> data) {
    final raw = data['imageName'] ?? data['image_file_name'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return null;
  }

  /// Parses appear/disappear sequence question with flexible choice count.
  static AppearDisappearQuestionData _parseAppearDisappear(
    Map<String, dynamic> data,
  ) {
    final words = _wordsFromArrayOrSentence(data['words']);
    final distractors = _stringList(data['distractors']);
    if (words.isEmpty) {
      throw FormatException(
        'AppearDisappear expects at least 1 target word',
      );
    }
    final rawLine1 = data['line1'];
    final line1 = rawLine1 is String && rawLine1.trim().isNotEmpty
        ? rawLine1.trim()
        : null;
    return AppearDisappearQuestionData(
      words: words,
      distractors: distractors,
      line1: line1,
      displayDuration: (data['display_duration'] as num?)?.toDouble() ?? 1.0,
      introPause: (data['intro_pause'] as num?)?.toDouble() ?? 2.0,
      imageName: _optionalImageName(data),
      englishToTranslate: _stringList(data['english_to_translate']),
      localTranslation: _stringListMap(data['local_translation']),
      trOk: (data['tr_ok'] as bool?) ?? false,
    );
  }

  /// Strips light wrapping punctuation so `_____.` / `_____!` / `_____?` count as blanks.
  static String _stripClozeBlankAffixes(String raw) =>
      stripClozeBlankAffixes(raw);

  /// True when a space-delimited token is a blank marker (2+ underscores, optional affixes).
  static bool _isBlankToken(String s) => isClozeBlankToken(s);

  /// Counts blanks in an English sentence string.
  static int _countBlanks(String sentence) =>
      sentence.split(' ').where(_isBlankToken).length;

  /// Parses [ClozeSequence]: plain English sentence string, ordered answers, flexible distractors.
  static ClozeSequenceQuestionData _parseClozeSequence(
    Map<String, dynamic> data,
  ) {
    final rawSentence = data['sentence'];
    if (rawSentence is! String) {
      throw const FormatException(
        'ClozeSequence: sentence must be a plain English string',
      );
    }
    final sentence = rawSentence.trim();
    // Accept 'answer' (array or single string) or 'answers' (array)
    final rawAnswer = data['answer'] ?? data['answers'];
    final List<String> answers;
    if (rawAnswer is List) {
      answers = rawAnswer.map((e) => e.toString()).toList();
    } else if (rawAnswer is String) {
      answers = [rawAnswer];
    } else {
      answers = const [];
    }
    final distractors = _stringList(data['distractors']);
    final blankCount = _countBlanks(sentence);
    if (blankCount != answers.length) {
      throw FormatException(
        'ClozeSequence: ${answers.length} answers but $blankCount blanks in sentence',
      );
    }
    final rawLine1 = data['line1'];
    final line1 = rawLine1 is String && rawLine1.trim().isNotEmpty
        ? rawLine1.trim()
        : null;
    return ClozeSequenceQuestionData(
      sentence: sentence,
      answers: answers,
      distractors: distractors,
      imageName: _optionalImageName(data),
      line1: line1,
      englishToTranslate: _stringList(data['english_to_translate']),
      localTranslation: _stringListMap(data['local_translation']),
      trOk: (data['tr_ok'] as bool?) ?? false,
    );
  }

  /// Builds two-character dialogue data plus answer and distractors for ConvoTemplate-1.
  static ConvoQuestionData _parseConvoData(Map<String, dynamic> data) {
    final rawImageName = data['image_file_name'];
    final String? imageName =
        rawImageName is String && rawImageName.trim().isNotEmpty
            ? rawImageName.trim()
            : null;
    return ConvoQuestionData(
      character1: data['character1'] as String? ?? '',
      character2: data['character2'] as String? ?? '',
      line1: _englishLineField(data['line1']),
      line2: _englishLineField(data['line2']),
      answer: data['answer'] as String? ?? '',
      distractors: (data['distractors'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      imageName: imageName,
      englishToTranslate: _stringList(data['english_to_translate']),
      localTranslation: _stringListMap(data['local_translation']),
      trOk: (data['tr_ok'] as bool?) ?? false,
    );
  }

  /// Parses [SentenceBuilder]: [correct_order] lists the sentence tokens in order (no distractors).
  static SentenceBuilderQuestionData _parseSentenceBuilder(
    Map<String, dynamic> data,
  ) {
    final correctOrder = _wordsFromArrayOrSentence(data['correct_order']);
    if (correctOrder.length < 2) {
      throw FormatException(
        'SentenceBuilder: correct_order must have at least 2 tokens',
      );
    }
    final rawLine1 = data['line1'];
    final line1 = rawLine1 is String && rawLine1.trim().isNotEmpty
        ? rawLine1.trim()
        : null;
    return SentenceBuilderQuestionData(
      correctOrder: correctOrder,
      imageName: _optionalImageName(data),
      line1: line1,
      englishToTranslate: _stringList(data['english_to_translate']),
      localTranslation: _stringListMap(data['local_translation']),
      trOk: (data['tr_ok'] as bool?) ?? false,
    );
  }

  /// Parses [WordPairs] from:
  /// - english_words: ["Good Morning", ...]
  /// - translations: [{"tr":"Gunaydin","es":"..."}, ...]
  static WordPairsQuestionData _parseWordPairs(Map<String, dynamic> data) {
    final englishWords = _stringList(data['english_words']);
    final rawTranslations = data['translations'] as List<dynamic>? ?? const [];
    if (englishWords.length != rawTranslations.length) {
      throw FormatException(
        'WordPairs: english_words.length (${englishWords.length}) '
        'must match translations.length (${rawTranslations.length})',
      );
    }
    final pairs = <WordPairItem>[];
    for (var i = 0; i < englishWords.length; i++) {
      final translationMap = _stringMapOrNull(rawTranslations[i]);
      if (translationMap == null || translationMap.isEmpty) {
        throw FormatException(
          'WordPairs: translations[$i] must be a non-empty locale map',
        );
      }
      pairs.add(
          WordPairItem(left: englishWords[i], translations: translationMap));
    }

    if (pairs.length < 3 || pairs.length > 6) {
      throw FormatException(
        'WordPairs expects 3–6 pairs, got ${pairs.length}',
      );
    }
    return WordPairsQuestionData(pairs: pairs);
  }

  /// Parses [DialogueCompletion].
  static DialogueCompletionQuestionData _parseDialogueCompletion(
    Map<String, dynamic> data,
  ) {
    final distractors = (data['distractors'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    if (distractors.length != 3) {
      throw FormatException(
        'DialogueCompletion must have exactly 3 distractors',
      );
    }
    final rawImageName = data['image_file_name'];
    final String? imageName =
        rawImageName is String && rawImageName.trim().isNotEmpty
            ? rawImageName.trim()
            : null;
    return DialogueCompletionQuestionData(
      character1: data['character1'] as String? ?? '',
      character2: data['character2'] as String? ?? '',
      line1: _englishLineField(data['line1']),
      answer: data['answer'] as String? ?? '',
      distractors: distractors,
      imageName: imageName,
      englishToTranslate: _stringList(data['english_to_translate']),
      localTranslation: _stringListMap(data['local_translation']),
      trOk: (data['tr_ok'] as bool?) ?? false,
    );
  }

  /// Parses a `"MM:SS"` or `"MM:SS.s"` timestamp string into a [Duration].
  static Duration _parseTimestamp(String raw) {
    final parts = raw.trim().split(':');
    if (parts.length != 2) {
      throw FormatException(
          'Invalid timestamp "$raw", expected MM:SS or MM:SS.s');
    }
    final minutes = int.parse(parts[0]);
    final seconds = double.parse(parts[1]);
    return Duration(
      milliseconds: minutes * 60000 + (seconds * 1000).round(),
    );
  }

  /// Parses [VideoConversation]: `videoFile`/`start_at`/`pause_at` live at the row root (not
  /// inside `questionData`); `questionData.answer_type` selects
  /// exactly one of [VideoChoiceAnswerData]/[VideoSequenceAnswerData]/[VideoClozeAnswerData].
  static VideoConversationQuestionData _parseVideoConversation(
    Map<String, dynamic> json,
    Map<String, dynamic> data,
  ) {
    final videoFile = json['videoFile'] as String? ?? '';
    if (videoFile.isEmpty) {
      throw const FormatException('VideoConversation: videoFile is required');
    }
    final startAt = _parseTimestamp(json['start_at'] as String? ?? '');
    final pauseAt = _parseTimestamp(json['pause_at'] as String? ?? '');
    if (startAt >= pauseAt) {
      throw FormatException(
        'VideoConversation: start_at ($startAt) must be before pause_at ($pauseAt)',
      );
    }
    final answerUntil = json['answer_until'] is String
        ? _parseTimestamp(json['answer_until'] as String)
        : null;

    final answerType = data['answer_type'] as String? ?? '';
    VideoChoiceAnswerData? choiceData;
    VideoSequenceAnswerData? sequenceData;
    VideoClozeAnswerData? clozeData;
    switch (answerType) {
      case 'DialogueCompletion':
        choiceData = VideoChoiceAnswerData(
          answer: data['answer'] as String? ?? '',
          distractors: _stringList(data['distractors']),
        );
        break;
      case 'SentenceBuilder':
        sequenceData = VideoSequenceAnswerData(
          targetSentence:
              _wordsFromArrayOrSentence(data['correct_order']).join(' '),
          distractors: _stringList(data['distractors']),
          isRecall: false,
        );
        break;
      case 'AppearDisappear':
        sequenceData = VideoSequenceAnswerData(
          targetSentence: _wordsFromArrayOrSentence(data['words']).join(' '),
          distractors: _stringList(data['distractors']),
          isRecall: true,
        );
        break;
      case 'ClozeSequence':
        final rawAnswer = data['answer'] ?? data['answers'];
        final answers = rawAnswer is List
            ? rawAnswer.map((e) => e.toString()).toList()
            : <String>[];
        clozeData = VideoClozeAnswerData(
          sentence: (data['sentence'] as String? ?? '').trim(),
          answers: answers,
          distractors: _stringList(data['distractors']),
        );
        break;
      default:
        throw FormatException(
          'VideoConversation: unknown answer_type "$answerType"',
        );
    }

    return VideoConversationQuestionData(
      videoFile: videoFile,
      startAt: startAt,
      pauseAt: pauseAt,
      answerUntil: answerUntil,
      choiceData: choiceData,
      sequenceData: sequenceData,
      clozeData: clozeData,
    );
  }

  /// Dispatches one `levelQuestions[]` element to the correct parser based on `template`.
  static LevelQuestion _parseQuestion(Map<String, dynamic> json) {
    final template = json['template'] as String? ?? '';
    if (template == 'Chapter') {
      // No questionData at all for this template — it's not a question.
      final displayImage = json['displayImage'] as String? ?? '';
      if (displayImage.isEmpty) {
        throw const FormatException('Chapter: displayImage is required');
      }
      return LevelQuestion(
        questionId: json['questionId'] as String?,
        template: template,
        chapterData: ChapterQuestionData(displayImage: displayImage),
      );
    }
    final qd = json['questionData'];
    if (qd is! Map<String, dynamic>) {
      throw const FormatException('questionData must be an object');
    }
    ImageQuestionData? imageData;
    ImageQuizTemplate2Data? imageQuiz2Data;
    ConvoQuestionData? convoData;
    AppearDisappearQuestionData? appearDisappearData;
    ClozeSequenceQuestionData? clozeSequenceData;
    SentenceBuilderQuestionData? sentenceBuilderData;
    WordPairsQuestionData? wordPairsData;
    DialogueCompletionQuestionData? dialogueCompletionData;
    VideoConversationQuestionData? videoConversationData;
    switch (template) {
      case 'imageQuizTemplate-1':
        imageData = _parseImageData(qd);
        break;
      case 'imageQuizTemplate-2':
        imageQuiz2Data = _parseImageQuiz2Data(qd);
        break;
      case 'imageQuizTemplate-3':
      case 'imageQuizTemplate-SentenceChoice':
        imageData = _parseImageData(qd);
        break;
      case 'ConvoTemplate-1':
        convoData = _parseConvoData(qd);
        break;
      case 'AppearDisappear':
        appearDisappearData = _parseAppearDisappear(qd);
        break;
      case 'ClozeSequence':
        clozeSequenceData = _parseClozeSequence(qd);
        break;
      case 'SentenceBuilder':
        sentenceBuilderData = _parseSentenceBuilder(qd);
        break;
      case 'WordPairs':
        wordPairsData = _parseWordPairs(qd);
        break;
      case 'DialogueCompletion':
        dialogueCompletionData = _parseDialogueCompletion(qd);
        break;
      case 'VideoConversation':
        videoConversationData = _parseVideoConversation(json, qd);
        break;
      default:
        throw FormatException('Unknown template: $template');
    }
    final normalizedTemplate = switch (template) {
      'imageQuizTemplate-3' => 'imageQuizTemplate-1',
      'imageQuizTemplate-SentenceChoice' => 'imageQuizTemplate-1',
      _ => template,
    };
    return LevelQuestion(
      questionId: json['questionId'] as String?,
      audioFile: json['audio_file'] as String?,
      audioFile1: json['audio_file1'] as String?,
      audioFile2: json['audio_file2'] as String?,
      genders: json['genders'] as String?,
      template: normalizedTemplate,
      imageData: imageData,
      imageQuiz2Data: imageQuiz2Data,
      convoData: convoData,
      appearDisappearData: appearDisappearData,
      clozeSequenceData: clozeSequenceData,
      sentenceBuilderData: sentenceBuilderData,
      wordPairsData: wordPairsData,
      dialogueCompletionData: dialogueCompletionData,
      videoConversationData: videoConversationData,
    );
  }

  /// Entry point from [loadLevelConfig]: reads `levelQuestions` into ordered [LevelQuestion] list.
  factory LevelConfig.fromJson(Map<String, dynamic> json) {
    final list = json['levelQuestions'] as List<dynamic>? ?? [];
    final questions = <LevelQuestion>[];
    for (var i = 0; i < list.length; i++) {
      final e = list[i];
      if (e is! Map<String, dynamic>) {
        debugPrint('levelQuestions[$i] skipped: not an object');
        questions.add(LevelQuestion.parseError());
        continue;
      }
      try {
        questions.add(_parseQuestion(e));
      } catch (ex, st) {
        debugPrint('levelQuestions[$i] skipped: $ex\n$st');
        final id = e['questionId'] is String ? e['questionId'] as String : null;
        questions.add(LevelQuestion.parseError(questionId: id));
      }
    }
    return LevelConfig(
      questions: questions,
      timerSeconds: (json['timer_seconds'] as num?)?.toInt(),
      tutorial: LevelTutorialConfig.tryParse(json['tutorial']),
    );
  }
}
